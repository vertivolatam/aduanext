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
import 'package:aduanext_adapters/retention.dart';
import 'package:aduanext_adapters/storage.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';

import '../config/retention_config.dart';
import '../middleware/auth_middleware.dart';
import '../workers/retention_worker.dart';
import 'server_config.dart';

final _log = Logger('aduanext.container');

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

  /// Retention configuration snapshot. Captured so health probes and
  /// ops tooling can inspect the effective policy without re-reading
  /// the environment.
  final RetentionConfig retention;

  /// Legal-hold port — `PostgresLegalHoldAdapter` when the Postgres
  /// URL is configured AND retention is enabled; otherwise the
  /// in-memory fallback. Non-null so [SubmitDeclarationHandler] and
  /// the retention worker both have something to call.
  final LegalHoldPort legalHold;

  /// Retention worker instance. Non-null when
  /// [RetentionConfig.enabled] is `true` and a Postgres audit log is
  /// wired — the worker needs both (nothing to purge without the
  /// audit table, nothing to schedule without the flag). Callers are
  /// responsible for [RetentionWorker.start] / [RetentionWorker.stop].
  final RetentionWorker? retentionWorker;

  /// Factory for the per-request [AuthorizationPort]. `null` when
  /// Keycloak is not configured (dev mode without `KEYCLOAK_*` env
  /// vars). The HTTP pipeline interprets `null` as "fail closed" —
  /// every protected route returns 503.
  final PortFactory? authPortFactory;

  /// Owned reference to the [JwksCache] so [close] can release the
  /// underlying HTTP client.
  final JwksCache? _jwksCache;

  /// Postgres adapters we own and must close on shutdown. The legal
  /// hold adapter is reused across requests; the retention purge
  /// adapter only runs inside the worker but still holds a connection.
  final PostgresLegalHoldAdapter? _postgresLegalHold;

  /// Dedicated Postgres connection for the RetentionWorker — owned by
  /// the container and closed on shutdown. Non-null when retention is
  /// enabled AND `ADUANEXT_RETENTION_DB_URL` resolves. When null, the
  /// worker re-uses the audit adapter's connection (with a loud
  /// warning logged at boot; acceptable for dev, violates VRTV-75 in
  /// production).
  final Connection? _retentionConnection;

  AppContainer._({
    required this.config,
    required this.grpcChannel,
    required this.authProvider,
    required this.customsGateway,
    required this.tariffCatalog,
    required this.signing,
    required this.pkcs11Signing,
    required this.auditLog,
    required this.retention,
    required this.legalHold,
    required this.retentionWorker,
    required this.authPortFactory,
    required JwksCache? jwksCache,
    required PostgresLegalHoldAdapter? postgresLegalHold,
    required Connection? retentionConnection,
  })  : _jwksCache = jwksCache,
        _postgresLegalHold = postgresLegalHold,
        _retentionConnection = retentionConnection;

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
    PostgresAuditLogAdapter? postgresAudit;
    if (pgUrl != null && pgUrl.isNotEmpty) {
      postgresAudit = await _openPostgresAudit(pgUrl);
      auditLog = postgresAudit;
    } else {
      // Explicitly dev-mode: in-memory audit keeps the server bootable for
      // smoke tests. Production deployments MUST set ADUANEXT_POSTGRES_URL.
      auditLog = InMemoryAuditLogAdapter();
    }

    // Retention subsystem (VRTV-57 + VRTV-74). Opt-in: the worker
    // only runs when `ADUANEXT_RETENTION_ENABLED=true` AND a Postgres
    // audit log is wired. In every other mode we still expose an
    // in-memory LegalHoldPort so SubmitDeclarationHandler can call it.
    final retentionConfig = RetentionConfig.fromEnv();
    PostgresLegalHoldAdapter? postgresLegalHold;
    LegalHoldPort legalHold;
    if (retentionConfig.enabled &&
        pgUrl != null &&
        pgUrl.isNotEmpty) {
      postgresLegalHold = await _openPostgresLegalHold(pgUrl);
      legalHold = postgresLegalHold;
    } else {
      legalHold = InMemoryLegalHoldAdapter();
    }

    RetentionWorker? retentionWorker;
    Connection? retentionConnection;
    if (retentionConfig.enabled && postgresAudit != null) {
      final archiveRoot = Directory(retentionConfig.archivePath);
      if (!archiveRoot.existsSync()) {
        archiveRoot.createSync(recursive: true);
      }
      final archive = FilesystemArchiveAdapter(rootPath: archiveRoot);

      // VRTV-75: apply the retention-worker role migration on the
      // ADMIN connection (postgresAudit) before opening the worker's
      // narrow connection. The migration is idempotent — safe to run
      // every boot. Running it here, under the container's privileged
      // role, is the only place the superuser-level DDL lives.
      await applyRetentionWorkerRoleMigration(
        postgresAudit.debugRawConnection,
      );

      // Decide which Postgres connection the worker uses.
      //
      //   * If `ADUANEXT_RETENTION_DB_URL` is set, open a dedicated
      //     Connection that logs in as `aduanext_retention_worker`
      //     (narrow grants). This is the production mode required by
      //     VRTV-75.
      //   * Otherwise, reuse the audit adapter's connection. This is
      //     strictly a dev fallback and is logged as a warning so ops
      //     catches it in the boot diagnostics.
      final Connection workerConnection;
      final retentionUrl = retentionConfig.retentionDbUrl;
      if (retentionUrl != null && retentionUrl.isNotEmpty) {
        workerConnection =
            await _openRetentionConnection(retentionUrl);
        retentionConnection = workerConnection;
        _log.info(
          'retention.worker.connection dedicated role configured '
          '(ADUANEXT_RETENTION_DB_URL is set)',
        );
      } else {
        _log.warning(
          'retention.worker.connection falling back to the main '
          'Postgres role because ADUANEXT_RETENTION_DB_URL is not '
          'set. This is acceptable for dev but violates the VRTV-75 '
          'production hardening contract — set the env var + create '
          'the `aduanext_retention_worker` role on the production '
          'database.',
        );
        workerConnection = postgresAudit.debugRawConnection;
      }

      final auditRetention = PostgresAuditRetentionAdapter(
        connection: workerConnection,
        auditLog: auditLog,
      );
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [auditRetention],
        legalHold: legalHold,
        archive: archive,
        policies: retentionConfig.asPolicies(),
      );
      retentionWorker = RetentionWorker(
        handler: handler,
        dailyHourUtc: retentionConfig.runAtHourUtc,
        dailyMinuteUtc: retentionConfig.runAtMinuteUtc,
      );
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
      retention: retentionConfig,
      legalHold: legalHold,
      retentionWorker: retentionWorker,
      authPortFactory: authPortFactory,
      jwksCache: jwksCache,
      postgresLegalHold: postgresLegalHold,
      retentionConnection: retentionConnection,
    );
  }

  /// Open a dedicated [Connection] for the RetentionWorker using the
  /// supplied URL. Expected to authenticate as the
  /// `aduanext_retention_worker` role (narrow grants — see migration
  /// 0002).
  static Future<Connection> _openRetentionConnection(String url) async {
    final endpoint = _parsePostgresUrl(url);
    return Connection.open(
      endpoint,
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  /// Parse the shared Postgres URL and open a [PostgresLegalHoldAdapter]
  /// with the schema created (idempotent). Reuses the same parsing
  /// logic as [_openPostgresAudit] — both adapters target the same
  /// database.
  static Future<PostgresLegalHoldAdapter> _openPostgresLegalHold(
    String url,
  ) async {
    final endpoint = _parsePostgresUrl(url);
    return PostgresLegalHoldAdapter.open(
      endpoint: endpoint,
      ensureSchema: true,
    );
  }

  /// Parse `postgres://user:password@host:port/database` into an [Endpoint]
  /// and open the audit log adapter with schema creation enabled.
  static Future<PostgresAuditLogAdapter> _openPostgresAudit(String url) async {
    return PostgresAuditLogAdapter.open(
      endpoint: _parsePostgresUrl(url),
      ensureSchema: true,
    );
  }

  /// Parse `postgres://user:password@host:port/database` into an
  /// [Endpoint]. Shared by every adapter that targets the primary
  /// Postgres database (audit log, legal holds).
  static Endpoint _parsePostgresUrl(String url) {
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
    return Endpoint(
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: database,
      username: username,
      password: password,
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

    // Worker first — stops the periodic timer + awaits any in-flight
    // run so the Postgres connection is still valid for that last run.
    final worker = retentionWorker;
    if (worker != null) {
      await guarded(worker.stop);
    }

    await guarded(() => grpcChannel.shutdown());

    // Close the dedicated retention connection (if any) BEFORE the
    // audit adapter because the worker has already stopped and the
    // retention connection only matters up to this point.
    final retentionConn = _retentionConnection;
    if (retentionConn != null && retentionConn.isOpen) {
      await guarded(retentionConn.close);
    }

    final audit = auditLog;
    if (audit is PostgresAuditLogAdapter) {
      await guarded(audit.close);
    }
    final legalHoldAdapter = _postgresLegalHold;
    if (legalHoldAdapter != null) {
      await guarded(legalHoldAdapter.close);
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
