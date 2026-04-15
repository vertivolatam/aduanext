/// RequestContext — the per-request bundle holding the authenticated
/// user, the selected tenant id, and the AuthorizationPort that
/// downstream handlers use to enforce role / tenant guards.
///
/// The middleware in `auth_middleware.dart` injects an instance into
/// the shelf [Request] via `request.change(context: ...)`. Handlers
/// reach it through the [requestContext] extension.
///
/// Public routes (e.g. `/livez`, `/readyz`) never carry a context.
/// Calling [requestContext] on an unauthenticated request raises a
/// [StateError] — that is a programming bug (route was registered as
/// protected but its handler was reached without the auth middleware).
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:shelf/shelf.dart';

/// Symbolic key used inside `Request.context` so we don't collide with
/// shelf's own keys or anything user code may stash later.
const String _contextKey = 'aduanext.request_context';

/// Per-request authorization context.
class RequestContext {
  /// Authenticated user (already validated by the JWKS-backed adapter).
  final User user;

  /// Tenant id the caller is acting against. May be `null` for endpoints
  /// that do not require tenant context (e.g. `/me`, `/tenants` listing).
  final String? selectedTenantId;

  /// Authorization port — request-scoped — already aware of [user] and
  /// [selectedTenantId]. Handlers MUST go through this port (never read
  /// [user] / [selectedTenantId] directly for guarding).
  final AuthorizationPort authorization;

  /// Stable id for log correlation. Generated once per request by the
  /// auth middleware (or carried over from an upstream `X-Request-Id`).
  final String requestId;

  const RequestContext({
    required this.user,
    required this.selectedTenantId,
    required this.authorization,
    required this.requestId,
  });
}

extension RequestContextExt on Request {
  /// Returns the [RequestContext] attached by the auth middleware.
  /// Throws [StateError] if called on an unauthenticated request.
  RequestContext get requestContext {
    final ctx = context[_contextKey];
    if (ctx is! RequestContext) {
      throw StateError(
        'No RequestContext on this request — handler was reached without '
        'the auth middleware. Check the route registration.',
      );
    }
    return ctx;
  }

  /// `null`-safe variant for diagnostics / public endpoints.
  RequestContext? get requestContextOrNull {
    final ctx = context[_contextKey];
    return ctx is RequestContext ? ctx : null;
  }

  /// Returns a copy of this request with [context] attached.
  Request withRequestContext(RequestContext context) {
    return change(context: {_contextKey: context});
  }
}
