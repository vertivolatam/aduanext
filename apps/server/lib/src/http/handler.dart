/// Assembles the shelf [Handler] for the AduaNext HTTP API.
///
/// Today the API exposes only health probes (VRTV-37 scope). Per-entity
/// CRUD endpoints arrive with their use cases in subsequent issues
/// (VRTV-38 submit declaration, VRTV-42 pre-validation, ...).
library;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/container.dart';
import 'health_endpoint.dart';

/// Builds the root [Handler] wired to the given [container].
///
/// The returned handler has request logging applied via
/// [logRequests] — production deployments should replace this with a
/// structured-logging middleware, but the built-in keeps the MVP
/// observable from the start.
Handler buildHandler(AppContainer container) {
  final health = HealthEndpoints(
    auditLog: container.auditLog,
    sidecarHost: container.config.sidecarHost,
    sidecarPort: container.config.sidecarPort,
  );

  final router = Router()
    ..get('/livez', health.liveness)
    ..get('/readyz', health.readiness);

  return const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);
}
