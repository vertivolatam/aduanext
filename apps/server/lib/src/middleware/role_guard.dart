/// `roleGuard` — middleware that ensures the request's authenticated
/// user holds at least one of [allowed] roles in the current tenant.
///
/// Usage:
///
/// ```dart
/// router.post(
///   '/api/dispatches/submit',
///   const Pipeline()
///     .addMiddleware(roleGuard({Role.agent, Role.importer}))
///     .addHandler(submitDispatchHandler),
/// );
/// ```
///
/// Behavior:
/// * If no [RequestContext] is on the request → 500 `INTERNAL_ERROR`
///   (programmer bug — guard must be wrapped by `authMiddleware`).
/// * If `requireTenant` fails → 403 `WRONG_TENANT`.
/// * If the user does not satisfy any role in [allowed] → 403
///   `INSUFFICIENT_ROLE`.
/// * Otherwise: delegates to the inner handler.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../http/error_responses.dart';
import '../http/request_context.dart';

final _log = Logger('aduanext.role_guard');

/// Build a role-checking middleware. [allowed] is the set of roles
/// that may proceed; the user must hold at least ONE of them with
/// the role-hierarchy semantics of [Role.satisfies] (so e.g. an
/// `admin` satisfies `Role.agent`).
Middleware roleGuard(Set<Role> allowed) {
  if (allowed.isEmpty) {
    throw ArgumentError.value(allowed, 'allowed', 'must be non-empty');
  }
  return (Handler inner) {
    return (Request request) async {
      final ctx = request.requestContextOrNull;
      if (ctx == null) {
        _log.severe(
          'roleGuard reached without RequestContext — auth middleware '
          'is missing in the pipeline.',
        );
        return errorResponse(
          status: 500,
          error: 'internal_error',
          code: ErrorCodes.internalError,
          message: 'Server misconfiguration',
          requestId: 'req_unknown',
        );
      }

      // Tenant must be selected for any tenant-scoped action.
      final tenantId = ctx.selectedTenantId;
      if (tenantId == null || tenantId.isEmpty) {
        return errorResponse(
          status: 400,
          error: 'tenant_required',
          code: ErrorCodes.wrongTenant,
          message: 'Missing X-Tenant-Id header',
          requestId: ctx.requestId,
        );
      }

      try {
        ctx.authorization.requireTenant(tenantId);
      } on AuthorizationException catch (e) {
        return errorResponse(
          status: 403,
          error: 'authorization_failed',
          code: ErrorCodes.wrongTenant,
          message: e.message,
          requestId: ctx.requestId,
        );
      }

      // hasRole honours role hierarchy — admin satisfies agent etc.
      final ok = allowed.any(ctx.authorization.hasRole);
      if (!ok) {
        final names = allowed.map((r) => r.code).toList()..sort();
        return errorResponse(
          status: 403,
          error: 'authorization_failed',
          code: ErrorCodes.insufficientRole,
          message: 'This action requires one of: ${names.join(", ")}',
          requestId: ctx.requestId,
        );
      }

      return inner(request);
    };
  };
}
