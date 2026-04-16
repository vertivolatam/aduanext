/// Declarative route table for the AduaNext HTTP API.
///
/// Each [ProtectedRoute] pairs an HTTP verb + path with the set of roles
/// that are allowed to invoke it and the [Handler] that does the work.
/// Public routes (`/livez`, `/readyz`) are registered separately by
/// [registerPublicRoutes] and bypass the auth middleware entirely.
///
/// As use-case handlers land (VRTV-38 submit, VRTV-42 pre-validation,
/// VRTV-59 onboarding, ...), they are appended here. Keeping the table
/// in one file makes it easy to audit "which roles can hit which
/// endpoint" — important for the SOC report and the Costa Rican
/// ciberseguridad audit.
///
/// VRTV-79 adds the versioned `/api/v1/dispatches/*` family — the four
/// endpoints the Flutter client needs to invoke the North Star submit
/// flow. The legacy (unversioned) placeholders under `/api/dispatches/*`
/// remain for one release so deployed clients don't break; they return
/// 501 and will be removed in a follow-up.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware/rate_limiter.dart';
import '../middleware/role_guard.dart';
import 'dispatch_endpoints.dart';

/// One entry in the route table.
class ProtectedRoute {
  /// HTTP verb. Lower-case (matches shelf_router's API).
  final String method;

  /// Path with optional `<param>` placeholders (shelf_router syntax).
  final String path;

  /// Set of roles allowed to invoke this route (role hierarchy applies).
  final Set<Role> allowed;

  /// The handler that executes when the guard lets the request through.
  final Handler handler;

  /// Optional per-route middlewares applied BEFORE the role guard. Used
  /// by submit endpoints to enforce per-tenant rate limiting. The order
  /// is: `...extraMiddlewares` → `roleGuard(allowed)` → [handler], so
  /// rate-limit rejection happens after authentication (the middleware
  /// reads the tenant from the request context) but before the use-case
  /// round-trip.
  final List<Middleware> extraMiddlewares;

  const ProtectedRoute({
    required this.method,
    required this.path,
    required this.allowed,
    required this.handler,
    this.extraMiddlewares = const [],
  });
}

/// Builds the default route table using the wired [DispatchEndpoints].
///
/// When [dispatchEndpoints] is null, the dispatch family is registered
/// as 501-returning placeholders so the route surface is still
/// discoverable in dev-without-container smoke tests.
///
/// [submitRateLimiter] — optional tenant-scoped rate limiter for the
/// submit endpoint. Passed through from the AppContainer in
/// `handler.dart`. When omitted (tests) the endpoint is still wired but
/// has no cap.
List<ProtectedRoute> defaultRouteTable({
  DispatchEndpoints? dispatchEndpoints,
  TokenBucketRegistry? submitRateLimiter,
}) {
  final submitHandler = dispatchEndpoints?.submit ??
      _unimplemented('submit-dispatch (VRTV-79 not wired)');
  final rectifyHandler = dispatchEndpoints?.rectify ??
      _unimplemented('rectify-dispatch (VRTV-79 not wired)');
  final getHandler = dispatchEndpoints?.get ??
      _unimplemented('get-dispatch (VRTV-79 not wired)');
  final listHandler = dispatchEndpoints?.list ??
      _unimplemented('list-dispatches (VRTV-79 not wired)');

  final submitMiddlewares = <Middleware>[];
  if (submitRateLimiter != null) {
    submitMiddlewares.add(rateLimitMiddleware(registry: submitRateLimiter));
  }

  return [
    // ── v1 (VRTV-79) — North Star wire-up ────────────────────────────
    ProtectedRoute(
      method: 'POST',
      path: '/api/v1/dispatches/submit',
      allowed: const {Role.agent, Role.importer},
      handler: submitHandler,
      extraMiddlewares: submitMiddlewares,
    ),
    ProtectedRoute(
      method: 'POST',
      path: '/api/v1/dispatches/<id>/rectify',
      allowed: const {Role.agent, Role.supervisor},
      handler: rectifyHandler,
    ),
    ProtectedRoute(
      method: 'GET',
      path: '/api/v1/dispatches/<id>',
      allowed: const {
        Role.agent,
        Role.importer,
        Role.supervisor,
        Role.admin,
      },
      handler: getHandler,
    ),
    ProtectedRoute(
      method: 'GET',
      path: '/api/v1/dispatches',
      allowed: const {
        Role.agent,
        Role.importer,
        Role.supervisor,
        Role.admin,
      },
      handler: listHandler,
    ),

    // ── Other features — still placeholders ──────────────────────────
    ProtectedRoute(
      method: 'POST',
      path: '/api/classifications/confirm',
      allowed: const {Role.agent, Role.supervisor},
      handler: _unimplemented('confirm-classification'),
    ),
    ProtectedRoute(
      method: 'GET',
      path: '/api/audit/export',
      allowed: const {Role.admin, Role.fiscalizador},
      handler: _unimplemented('export-audit'),
    ),

    // ── Legacy unversioned placeholders (to be removed in next pass) ─
    //
    // The v0 paths were declared in the original route table but never
    // implemented. Keeping them as 501 while clients migrate prevents
    // "unexpected 404" error paths during the rollout window. Next
    // release removes these entries entirely — tracked as a follow-up.
    ProtectedRoute(
      method: 'POST',
      path: '/api/dispatches/submit',
      allowed: const {Role.agent, Role.importer},
      handler: _unimplemented('submit-dispatch (use /api/v1 — legacy)'),
    ),
    ProtectedRoute(
      method: 'GET',
      path: '/api/dispatches/<id>',
      allowed: const {
        Role.agent,
        Role.importer,
        Role.supervisor,
        Role.admin,
      },
      handler: _unimplemented('get-dispatch (use /api/v1 — legacy)'),
    ),
    ProtectedRoute(
      method: 'POST',
      path: '/api/dispatches/<id>/rectify',
      allowed: const {Role.agent, Role.supervisor},
      handler: _unimplemented('rectify-dispatch (use /api/v1 — legacy)'),
    ),
  ];
}

/// Register the [routes] on the [router], wrapping each handler in the
/// per-route [roleGuard]. The router itself is then expected to be
/// wrapped by the global [authMiddleware] in `handler.dart`.
void registerProtectedRoutes(Router router, List<ProtectedRoute> routes) {
  for (final route in routes) {
    var pipeline = const Pipeline();
    for (final mw in route.extraMiddlewares) {
      pipeline = pipeline.addMiddleware(mw);
    }
    final guarded = pipeline
        .addMiddleware(roleGuard(route.allowed))
        .addHandler(route.handler);
    _registerOn(router, route.method, route.path, guarded);
  }
}

/// Internal helper because shelf_router's `Router` exposes verb-specific
/// methods (`get`, `post`, ...) rather than a generic `add` call.
void _registerOn(
  Router router,
  String method,
  String path,
  Handler handler,
) {
  switch (method.toUpperCase()) {
    case 'GET':
      router.get(path, handler);
      break;
    case 'POST':
      router.post(path, handler);
      break;
    case 'PUT':
      router.put(path, handler);
      break;
    case 'PATCH':
      router.patch(path, handler);
      break;
    case 'DELETE':
      router.delete(path, handler);
      break;
    default:
      throw ArgumentError.value(method, 'method', 'unsupported HTTP verb');
  }
}

Handler _unimplemented(String name) {
  return (Request _) {
    return Response(
      501,
      body: '{"error":"not_implemented","handler":"$name"}',
      headers: const {'content-type': 'application/json'},
    );
  };
}
