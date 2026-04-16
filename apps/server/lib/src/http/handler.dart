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
///
/// VRTV-79 wires the dispatch endpoints (submit / rectify / get / list)
/// with a per-tenant [TokenBucketRegistry] applied to the submit route.
library;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/container.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/rate_limiter.dart';
import 'dispatch_endpoints.dart';
import 'health_endpoint.dart';
import 'routes.dart';

/// Default submit-endpoint rate-limit settings. Chosen to allow a busy
/// agency (10 submits / minute / tenant) without starving during a
/// batch run; re-tunable via constructor injection for tests.
const int defaultSubmitBurst = 10;
const int defaultSubmitRefillPerMinute = 10;

/// Builds the root [Handler] wired to the given [container].
///
/// If [AppContainer.authPortFactory] is null (Keycloak not configured —
/// dev-only path), the protected routes are still registered but every
/// hit returns 503 from the auth pipeline so we never leak an
/// unauthenticated path in production.
///
/// [submitRateLimit] — override the default rate-limiter config (e.g.
/// tests that want a wider bucket). When `null`, a registry with
/// [defaultSubmitBurst] / [defaultSubmitRefillPerMinute] is constructed.
Handler buildHandler(
  AppContainer container, {
  List<ProtectedRoute>? routes,
  TokenBucketRegistry? submitRateLimit,
}) {
  final health = HealthEndpoints(
    auditLog: container.auditLog,
    sidecarHost: container.config.sidecarHost,
    sidecarPort: container.config.sidecarPort,
  );

  final dispatchEndpoints = DispatchEndpoints(
    deps: DispatchEndpointDeps(
      authProvider: container.authProvider,
      customsGateway: container.customsGateway,
      signing: container.signing,
      pkcs11Signing: container.pkcs11Signing,
      auditLog: container.auditLog,
      // preValidate: (wired when VRTV-42 DI lands — default null is
      //               fine, handler skips the step gracefully).
    ),
  );

  final rateLimiter = submitRateLimit ??
      TokenBucketRegistry(
        capacity: defaultSubmitBurst,
        refillRate: defaultSubmitRefillPerMinute,
        refillInterval: const Duration(minutes: 1),
      );

  // Authenticated sub-router — wrapped by authMiddleware below.
  final protectedRouter = Router();
  registerProtectedRoutes(
    protectedRouter,
    routes ??
        defaultRouteTable(
          dispatchEndpoints: dispatchEndpoints,
          submitRateLimiter: rateLimiter,
        ),
  );

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
