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
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../middleware/role_guard.dart';

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

  const ProtectedRoute({
    required this.method,
    required this.path,
    required this.allowed,
    required this.handler,
  });
}

/// The canonical route table. Today it carries placeholder handlers
/// because the use-case implementations land in subsequent issues; each
/// `_unimplemented` entry returns 501 so the route table can be
/// integration-tested against the auth + role-guard pipeline before the
/// real handlers exist.
List<ProtectedRoute> defaultRouteTable() {
  return [
    ProtectedRoute(
      method: 'POST',
      path: '/api/dispatches/submit',
      allowed: const {Role.agent, Role.importer},
      handler: _unimplemented('submit-dispatch (VRTV-38)'),
    ),
    ProtectedRoute(
      method: 'POST',
      path: '/api/classifications/confirm',
      allowed: const {Role.agent, Role.supervisor},
      handler: _unimplemented('confirm-classification'),
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
      handler: _unimplemented('get-dispatch'),
    ),
    ProtectedRoute(
      method: 'POST',
      path: '/api/dispatches/<id>/rectify',
      allowed: const {Role.agent, Role.supervisor},
      handler: _unimplemented('rectify-dispatch'),
    ),
    ProtectedRoute(
      method: 'GET',
      path: '/api/audit/export',
      allowed: const {Role.admin, Role.fiscalizador},
      handler: _unimplemented('export-audit'),
    ),
  ];
}

/// Register the [routes] on the [router], wrapping each handler in the
/// per-route [roleGuard]. The router itself is then expected to be
/// wrapped by the global [authMiddleware] in `handler.dart`.
void registerProtectedRoutes(Router router, List<ProtectedRoute> routes) {
  for (final route in routes) {
    final guarded = const Pipeline()
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
