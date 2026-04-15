/// Dependency container for the AduaNext primary server.
///
/// This is the single place where concrete adapters are constructed and
/// handed to use cases / HTTP handlers. Everywhere else depends on Ports
/// (domain interfaces) — that's how we keep the Explicit Architecture
/// dependency-flow invariant:
///
///   apps/server -> libs/application -> libs/domain <- libs/adapters
///
/// We intentionally avoid a DI framework (dart_frog_di, injector, etc.).
/// For a single-process server a hand-written struct is clearer, cheaper
/// to reason about, and trivially testable.
library;

import 'dart:io';

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_adapters/authorization.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:postgres/postgres.dart';

import '../middleware/auth_middleware.dart';
import 'server_config.dart';

/// The wired container. Built once at startup via [AppContainer.boot] and
/// torn down via [close] on shutdown.
class AppContainer {
  final ServerConfig config;
  final GrpcChannelManager grpcChannel;
  final AuthProviderPort authProvider;
  final CustomsGatewayPort customsGateway;
  final TariffCatalogPort tariffCatalog;
  final SigningPort? signing; // null if p12 not configured (dev without cert)

  /// PKCS#11 hardware-token signing. Non-null when
  /// `PKCS11_HELPER_PATH` resolves to an existing binary at boot.
  /// When null, SubmitDeclarationHandler fails-closed for any command
  /// carrying [HardwareTokenCredentials] rather than silently falling
  /// back to software signing.
  final Pkcs11SigningPort? pkcs11Signing;

  final AuditLogPort auditLog;

  /// Factory for the per-request [AuthorizationPort]. `null` when
  /// Keycloak is not configured (dev mode without `KEYCLOAK_*` env
  /// vars). The HTTP pipeline interprets `null` as "fail closed" —
  /// every protected route returns 503.
  final PortFactory? authPortFactory;

  /// Owned reference to the [JwksCache] so [close] can release the
  /// underlying HTTP client.
  final JwksCache? _jwksCache;

  AppContainer._({
    required this.config,
    required this.grpcChannel,
    required this.authProvider,
    required this.customsGateway,
    required this.tariffCatalog,
    required this.signing,
    required this.pkcs11Signing,
    required this.auditLog,
    required this.authPortFactory,
    required JwksCache? jwksCache,
  }) : _jwksCache = jwksCache;

  /// Build the container from [config]. Blocks on network I/O (opens the
  /// Postgres connection if configured) — call once during startup.
  static Future<AppContainer> boot(ServerConfig config) async {
    final grpcChannel = GrpcChannelManager(
      host: config.sidecarHost,
      port: config.sidecarPort,
    );

    final authProvider = AtenaAuthAdapter(
      channelManager: grpcChannel,
      defaultClientId: config.defaultClientId,
    );
    final customsGateway = AtenaCustomsGatewayAdapter(
      channelManager: grpcChannel,
    );
    final tariffCatalog = RimmTariffCatalogAdapter(
      channelManager: grpcChannel,
    );

    SigningPort? signing;
    final p12Path = config.p12CertPath;
    final p12Pin = config.p12Pin;
    if (p12Path != null && p12Pin != null) {
      final p12File = File(p12Path);
      if (!p12File.existsSync()) {
        throw StateError(
          'HACIENDA_P12_PATH points to a non-existent file: $p12Path',
        );
      }
      signing = HaciendaSigningAdapter(
        channelManager: grpcChannel,
        p12Bytes: await p12File.readAsBytes(),
        p12Pin: p12Pin,
      );
    }

    // PKCS#11 hardware-token signing (VRTV-70). Only wired when the
    // helper binary path resolves to an existing executable at boot.
    // The adapter itself is lazy (fresh process per request) so we
    // don't need to probe the binary here beyond existence.
    Pkcs11SigningPort? pkcs11Signing;
    final pkcs11Path = config.pkcs11HelperPath;
    if (pkcs11Path != null && pkcs11Path.isNotEmpty) {
      if (!File(pkcs11Path).existsSync()) {
        throw StateError(
          'PKCS11_HELPER_PATH points to a non-existent file: $pkcs11Path',
        );
      }
      pkcs11Signing = SubprocessPkcs11SigningAdapter(
        helperBinaryPath: pkcs11Path,
      );
    }

    final AuditLogPort auditLog;
    final pgUrl = config.postgresUrl;
    if (pgUrl != null && pgUrl.isNotEmpty) {
      auditLog = await _openPostgresAudit(pgUrl);
    } else {
      // Explicitly dev-mode: in-memory audit keeps the server bootable for
      // smoke tests. Production deployments MUST set ADUANEXT_POSTGRES_URL.
      auditLog = InMemoryAuditLogAdapter();
    }

    JwksCache? jwksCache;
    PortFactory? authPortFactory;
    final jwksUri = config.keycloakJwksUri;
    final issuer = config.keycloakIssuer;
    final audience = config.keycloakAudience;
    if (jwksUri != null && issuer != null && audience != null) {
      jwksCache = JwksCache(jwksUri: Uri.parse(jwksUri));
      final keycloakFactory = KeycloakAuthorizationAdapterFactory(
        jwksCache: jwksCache,
        expectedIssuer: issuer,
        expectedAudience: audience,
      );
      authPortFactory = ({
        required String? bearerToken,
        required String? selectedTenantId,
      }) =>
          keycloakFactory.forRequest(
            bearerToken: bearerToken,
            selectedTenantId: selectedTenantId,
          );
    }

    return AppContainer._(
      config: config,
      grpcChannel: grpcChannel,
      authProvider: authProvider,
      customsGateway: customsGateway,
      tariffCatalog: tariffCatalog,
      signing: signing,
      pkcs11Signing: pkcs11Signing,
      auditLog: auditLog,
      authPortFactory: authPortFactory,
      jwksCache: jwksCache,
    );
  }

  /// Parse `postgres://user:password@host:port/database` into an [Endpoint]
  /// and open the audit log adapter with schema creation enabled.
  static Future<PostgresAuditLogAdapter> _openPostgresAudit(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme != 'postgres' && uri.scheme != 'postgresql') {
      throw ArgumentError.value(
        url,
        'postgresUrl',
        'Expected postgres:// or postgresql:// URL',
      );
    }
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.isNotEmpty ? userInfo[0] : 'postgres';
    final password = userInfo.length > 1 ? userInfo[1] : '';
    final database =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'aduanext';

    return PostgresAuditLogAdapter.open(
      endpoint: Endpoint(
        host: uri.host.isEmpty ? 'localhost' : uri.host,
        port: uri.port == 0 ? 5432 : uri.port,
        database: database,
        username: username,
        password: password,
      ),
      ensureSchema: true,
    );
  }

  /// Tear down all owned resources. Idempotent.
  Future<void> close() async {
    // Best-effort — log and continue so one broken dep doesn't block others.
    final errors = <Object>[];

    Future<void> guarded(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        errors.add(e);
      }
    }

    await guarded(() => grpcChannel.shutdown());
    final audit = auditLog;
    if (audit is PostgresAuditLogAdapter) {
      await guarded(audit.close);
    }
    final jwks = _jwksCache;
    if (jwks != null) {
      await guarded(() async => jwks.close());
    }

    if (errors.isNotEmpty) {
      // Surface the first — caller's log should capture the rest via the
      // guarded swallows. We don't rethrow all because shutdown is best-
      // effort and we want every disposer to run.
      throw StateError(
        'AppContainer.close() encountered ${errors.length} error(s); '
        'first: ${errors.first}',
      );
    }
  }
}
