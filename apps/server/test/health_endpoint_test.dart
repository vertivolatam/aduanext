/// Smoke tests for [HealthEndpoints].
///
/// Uses fake Ports rather than the real gRPC / Postgres stack — those
/// dependencies are already covered end-to-end in libs/adapters tests.
/// Here we only care about the shelf contract: status codes, JSON shape,
/// and the probe aggregation logic.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_server/aduanext_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

Future<Socket> _alwaysReachable(
  String host,
  int port, {
  Duration? timeout,
}) async {
  // Return a real socket pair loopback-connected in-process so we don't
  // need to reach a real host for "happy path" probes.
  final server =
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final socket = await Socket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
    timeout: timeout,
  );
  // Dispose the accept side — we only care that connect succeeded.
  server.listen((c) => c.close()).asFuture<void>();
  unawaited(server.close());
  return socket;
}

Future<Socket> _alwaysUnreachable(
  String host,
  int port, {
  Duration? timeout,
}) async {
  throw const SocketException('Connection refused');
}

Future<Socket> _alwaysTimeout(
  String host,
  int port, {
  Duration? timeout,
}) async {
  throw TimeoutException('slow');
}

void main() {
  group('HealthEndpoints', () {
    test('/livez always returns 200 with status:alive', () async {
      final endpoints = HealthEndpoints(
        auditLog: _ThrowingAudit(),
        sidecarHost: 'irrelevant',
        sidecarPort: 0,
        socketConnector: _alwaysUnreachable,
      );
      final response = endpoints.liveness(
        Request('GET', Uri.parse('http://x/livez')),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString());
      expect(body, {'status': 'alive'});
    });

    test('/readyz returns 200 when both dependencies are healthy', () async {
      final endpoints = HealthEndpoints(
        auditLog: _HealthyAudit(),
        sidecarHost: 'fake',
        sidecarPort: 50051,
        socketConnector: _alwaysReachable,
      );
      final response = await endpoints
          .readiness(Request('GET', Uri.parse('http://x/readyz')));
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString())
          as Map<String, Object?>;
      expect(body['status'], 'ready');
      final deps = body['dependencies'] as List<dynamic>;
      expect(deps, hasLength(2));
      final byName = {
        for (final d in deps)
          (d as Map<String, Object?>)['name'] as String: d,
      };
      expect(byName['hacienda-sidecar']?['ok'], isTrue);
      expect(byName['audit-log']?['ok'], isTrue);
    });

    test(
      '/readyz returns 503 when sidecar connect throws SocketException',
      () async {
        final endpoints = HealthEndpoints(
          auditLog: _HealthyAudit(),
          sidecarHost: 'fake',
          sidecarPort: 50051,
          socketConnector: _alwaysUnreachable,
        );
        final response = await endpoints
            .readiness(Request('GET', Uri.parse('http://x/readyz')));
        expect(response.statusCode, 503);
        final body = jsonDecode(await response.readAsString())
            as Map<String, Object?>;
        expect(body['status'], 'degraded');
        final deps = (body['dependencies'] as List<dynamic>)
            .cast<Map<String, Object?>>();
        final sidecar =
            deps.firstWhere((d) => d['name'] == 'hacienda-sidecar');
        expect(sidecar['ok'], isFalse);
        expect(sidecar['detail'], contains('unreachable'));
      },
    );

    test('/readyz returns 503 when sidecar connect times out', () async {
      final endpoints = HealthEndpoints(
        auditLog: _HealthyAudit(),
        sidecarHost: 'fake',
        sidecarPort: 50051,
        probeTimeout: const Duration(milliseconds: 250),
        socketConnector: _alwaysTimeout,
      );
      final response = await endpoints
          .readiness(Request('GET', Uri.parse('http://x/readyz')));
      expect(response.statusCode, 503);
      final body = jsonDecode(await response.readAsString())
          as Map<String, Object?>;
      final deps = (body['dependencies'] as List<dynamic>)
          .cast<Map<String, Object?>>();
      final sidecar =
          deps.firstWhere((d) => d['name'] == 'hacienda-sidecar');
      expect(sidecar['ok'], isFalse);
      expect(sidecar['detail'], contains('timeout'));
    });

    test('/readyz returns 503 when audit log throws', () async {
      final endpoints = HealthEndpoints(
        auditLog: _ThrowingAudit(),
        sidecarHost: 'fake',
        sidecarPort: 50051,
        socketConnector: _alwaysReachable,
      );
      final response = await endpoints
          .readiness(Request('GET', Uri.parse('http://x/readyz')));
      expect(response.statusCode, 503);
      final body = jsonDecode(await response.readAsString())
          as Map<String, Object?>;
      final deps = (body['dependencies'] as List<dynamic>)
          .cast<Map<String, Object?>>();
      final audit = deps.firstWhere((d) => d['name'] == 'audit-log');
      expect(audit['ok'], isFalse);
      expect(audit['detail'], isNotNull);
    });
  });

  group('ServerConfig', () {
    test('applies defaults when no env vars are set', () {
      final cfg = ServerConfig.fromEnv(const {});
      expect(cfg.httpHost, '0.0.0.0');
      expect(cfg.httpPort, 8180);
      expect(cfg.sidecarHost, 'localhost');
      expect(cfg.sidecarPort, 50051);
      expect(cfg.postgresUrl, isNull);
      expect(cfg.p12CertPath, isNull);
    });

    test('overrides defaults from env', () {
      final cfg = ServerConfig.fromEnv(const {
        'ADUANEXT_HTTP_HOST': '127.0.0.1',
        'ADUANEXT_HTTP_PORT': '9090',
        'HACIENDA_SIDECAR_HOST': 'sidecar.prod',
        'HACIENDA_SIDECAR_PORT': '51000',
        'HACIENDA_DEFAULT_CLIENT_ID': 'aduanext-prod',
        'HACIENDA_P12_PATH': '/secrets/cert.p12',
        'HACIENDA_P12_PIN': 'hunter2',
        'ADUANEXT_POSTGRES_URL':
            'postgres://a:b@db.prod:5432/aduanext',
      });
      expect(cfg.httpHost, '127.0.0.1');
      expect(cfg.httpPort, 9090);
      expect(cfg.sidecarHost, 'sidecar.prod');
      expect(cfg.sidecarPort, 51000);
      expect(cfg.defaultClientId, 'aduanext-prod');
      expect(cfg.p12CertPath, '/secrets/cert.p12');
      expect(cfg.p12Pin, 'hunter2');
      expect(cfg.postgresUrl, 'postgres://a:b@db.prod:5432/aduanext');
    });

    test('falls back to defaults on unparseable port values', () {
      final cfg = ServerConfig.fromEnv(const {
        'ADUANEXT_HTTP_PORT': 'not-a-port',
        'HACIENDA_SIDECAR_PORT': 'also-not',
      });
      expect(cfg.httpPort, 8180);
      expect(cfg.sidecarPort, 50051);
    });
  });
}

// -----------------------------------------------------------------------------
// Tiny fakes — kept in this file to avoid a dedicated helpers dir for one test.
// -----------------------------------------------------------------------------

class _HealthyAudit implements AuditLogPort {
  @override
  Future<String> append(AuditEvent event) async => 'fake-hash';

  @override
  Future<List<AuditEvent>> queryByEntity(String _, String __) async => const [];

  @override
  Future<bool> verifyChainIntegrity(String _, String __) async => true;
}

class _ThrowingAudit implements AuditLogPort {
  @override
  Future<String> append(AuditEvent event) async => throw StateError('down');

  @override
  Future<List<AuditEvent>> queryByEntity(String _, String __) async =>
      throw StateError('down');

  @override
  Future<bool> verifyChainIntegrity(String _, String __) async =>
      throw StateError('down');
}
