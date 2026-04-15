/// Assembles the shelf [Handler] for the AduaNext HTTP API.
///
/// Pipeline:
///   logRequests → root router
///                 ├─ /livez, /readyz   (PUBLIC — no auth)
///                 └─ /*                → authMiddleware → protected router
///                                         → per-route roleGuard → handler
///
/// Public routes (`/livez`, `/readyz`) bypass auth entirely so
/// Kubernetes liveness probes never need a Bearer token. Every other
/// route is wrapped by [authMiddleware] (extracts + validates the JWT,
/// attaches a [RequestContext]) and then by a per-route [roleGuard]
/// applied through [registerProtectedRoutes].
library;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/container.dart';
import '../middleware/auth_middleware.dart';
import 'health_endpoint.dart';
import 'routes.dart';

/// Builds the root [Handler] wired to the given [container].
///
/// If [AppContainer.authPortFactory] is null (Keycloak not configured —
/// dev-only path), the protected routes are still registered but every
/// hit returns 503 from the auth pipeline so we never leak an
/// unauthenticated path in production.
Handler buildHandler(
  AppContainer container, {
  List<ProtectedRoute>? routes,
}) {
  final health = HealthEndpoints(
    auditLog: container.auditLog,
    sidecarHost: container.config.sidecarHost,
    sidecarPort: container.config.sidecarPort,
  );

  // Authenticated sub-router — wrapped by authMiddleware below.
  final protectedRouter = Router();
  registerProtectedRoutes(protectedRouter, routes ?? defaultRouteTable());

  final factory = container.authPortFactory;
  final Handler protectedPipeline;
  if (factory != null) {
    protectedPipeline = const Pipeline()
        .addMiddleware(authMiddleware(factory))
        .addHandler(protectedRouter.call);
  } else {
    // Fail-closed when Keycloak isn't configured — never serve
    // protected routes unauthenticated.
    protectedPipeline = (Request _) async {
      return Response(
        503,
        body: '{"error":"auth_unavailable","code":"AUTH_NOT_CONFIGURED",'
            '"message":"Keycloak adapter is not configured on this server"}',
        headers: const {'content-type': 'application/json'},
      );
    };
  }

  final root = Router()
    ..get('/livez', health.liveness)
    ..get('/readyz', health.readiness)
    ..mount('/', protectedPipeline);

  return const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(root.call);
}
