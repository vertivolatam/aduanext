/// HTTP handlers for liveness and readiness probes.
///
/// * `GET /livez` — cheap liveness probe (`{"status":"alive"}`). Used by
///   the Helm chart / Kubernetes liveness probe; must NEVER depend on any
///   downstream. Designed to return quickly even when Postgres or the
///   sidecar are broken.
/// * `GET /readyz` — readiness probe. Checks the hacienda-sidecar via a
///   TCP connect (cheapest truthful reachability signal that does not
///   need valid OIDC credentials) and the audit log via
///   `verifyChainIntegrity('health','ping')`. Orchestrators stop routing
///   traffic when any dependency is degraded.
///
/// Both endpoints are read-only and do not mutate any state.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:shelf/shelf.dart';

/// Result of a single dependency probe. Serialized to JSON.
class DependencyProbe {
  final String name;
  final bool ok;
  final int elapsedMicros;
  final String? detail;

  const DependencyProbe({
    required this.name,
    required this.ok,
    required this.elapsedMicros,
    this.detail,
  });

  Map<String, Object?> toJson() => {
        'name': name,
        'ok': ok,
        'elapsed_us': elapsedMicros,
        if (detail != null) 'detail': detail,
      };
}

/// Builds the set of handlers. Exposed as a function (not a class) so a
/// shelf router can register them directly.
class HealthEndpoints {
  final AuditLogPort auditLog;

  /// Host+port of the hacienda-sidecar gRPC server. We probe it via a
  /// TCP connect rather than `AuthProviderPort.isAuthenticated` because
  /// the auth port is intentionally GrpcError-safe (returns `false` on
  /// transport failure — unsuitable as a reachability signal).
  final String sidecarHost;
  final int sidecarPort;

  /// Per-probe deadline. Tunable primarily for tests.
  final Duration probeTimeout;

  /// Optional TCP connector — overridden in tests so we don't rely on
  /// [Socket.connect] hitting a real port.
  final Future<Socket> Function(String host, int port, {Duration? timeout})
      socketConnector;

  HealthEndpoints({
    required this.auditLog,
    required this.sidecarHost,
    required this.sidecarPort,
    this.probeTimeout = const Duration(seconds: 2),
    Future<Socket> Function(String host, int port, {Duration? timeout})?
        socketConnector,
  }) : socketConnector = socketConnector ?? _defaultConnect;

  static Future<Socket> _defaultConnect(
    String host,
    int port, {
    Duration? timeout,
  }) {
    return Socket.connect(host, port, timeout: timeout);
  }

  /// Liveness: cheap, always succeeds unless the event loop is jammed.
  Response liveness(Request _) {
    return Response.ok(
      jsonEncode({'status': 'alive'}),
      headers: const {'content-type': 'application/json'},
    );
  }

  /// Readiness: probes sidecar and audit log in parallel; returns 200 only
  /// if both come back healthy. A degraded dependency yields HTTP 503 so
  /// Kubernetes can evict this pod from the Service endpoints.
  Future<Response> readiness(Request _) async {
    final probes = await Future.wait([
      _probeSidecar(),
      _probeAuditLog(),
    ]);
    final allOk = probes.every((p) => p.ok);
    final body = jsonEncode({
      'status': allOk ? 'ready' : 'degraded',
      'dependencies': probes.map((p) => p.toJson()).toList(),
    });
    return Response(
      allOk ? 200 : 503,
      body: body,
      headers: const {'content-type': 'application/json'},
    );
  }

  Future<DependencyProbe> _probeSidecar() async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await socketConnector(
        sidecarHost,
        sidecarPort,
        timeout: probeTimeout,
      );
      sw.stop();
      return DependencyProbe(
        name: 'hacienda-sidecar',
        ok: true,
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } on SocketException catch (e) {
      sw.stop();
      return DependencyProbe(
        name: 'hacienda-sidecar',
        ok: false,
        elapsedMicros: sw.elapsedMicroseconds,
        detail: 'unreachable: ${e.message}',
      );
    } on TimeoutException {
      sw.stop();
      return DependencyProbe(
        name: 'hacienda-sidecar',
        ok: false,
        elapsedMicros: sw.elapsedMicroseconds,
        detail: 'timeout after ${probeTimeout.inMilliseconds}ms',
      );
    } catch (e) {
      sw.stop();
      return DependencyProbe(
        name: 'hacienda-sidecar',
        ok: false,
        elapsedMicros: sw.elapsedMicroseconds,
        detail: e.toString(),
      );
    } finally {
      // Drop the socket eagerly — we only wanted the handshake.
      await socket?.close();
    }
  }

  Future<DependencyProbe> _probeAuditLog() async {
    final sw = Stopwatch()..start();
    try {
      // verifyChainIntegrity on an empty entity round-trips a SELECT —
      // cheapest way to prove Postgres is reachable without touching real
      // data. Returns true for an empty chain (contract).
      final ok = await auditLog
          .verifyChainIntegrity('health', 'ping')
          .timeout(probeTimeout);
      sw.stop();
      return DependencyProbe(
        name: 'audit-log',
        ok: ok,
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } on TimeoutException {
      sw.stop();
      return DependencyProbe(
        name: 'audit-log',
        ok: false,
        elapsedMicros: sw.elapsedMicroseconds,
        detail: 'timeout after ${probeTimeout.inMilliseconds}ms',
      );
    } catch (e) {
      sw.stop();
      return DependencyProbe(
        name: 'audit-log',
        ok: false,
        elapsedMicros: sw.elapsedMicroseconds,
        detail: e.toString(),
      );
    }
  }
}
