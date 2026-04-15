/// Port: Authorization — request-scoped access to the current user +
/// tenant context.
///
/// Every application-layer handler that mutates state MUST consult this
/// port BEFORE touching any other port. It is the single choke point
/// for "who is acting, on behalf of whom, and with what privileges" —
/// the other ports (AuthProviderPort, AuditLogPort, ...) are
/// tenant-agnostic by design.
///
/// The concrete adapter is wired per-request by the server (Keycloak
/// JWT parsing + claim validation in production; a fixed fixture for
/// tests).
library;

import '../authorization/role.dart';
import '../authorization/tenant_membership.dart';
import '../authorization/user.dart';

/// Raised when the caller is not permitted to perform the requested
/// action in the current context.
///
/// This is NOT a "login prompt" signal (that's [AuthenticationException]
/// from the auth provider port). It's "you're authenticated but you
/// don't have this privilege in this tenant."
class AuthorizationException implements Exception {
  /// Stable code for log matching and i18n. Use kebab-case.
  final String code;

  /// Human-readable message. Safe to show in UI.
  final String message;

  /// Tenant the action was attempted against (null if the violation is
  /// role-only, unrelated to tenant scope).
  final String? tenantId;

  /// Minimum role required (null if the violation is tenant-only).
  final Role? requiredRole;

  const AuthorizationException({
    required this.code,
    required this.message,
    this.tenantId,
    this.requiredRole,
  });

  @override
  String toString() => 'AuthorizationException($code): $message';
}

/// Port: request-scoped authorization context.
abstract class AuthorizationPort {
  /// The currently-authenticated user.
  ///
  /// MUST throw [AuthorizationException] with code `unauthenticated`
  /// if no user is bound to the request.
  User currentUser();

  /// The tenant the current request is acting against.
  ///
  /// MUST throw [AuthorizationException] with code
  /// `tenant-not-selected` if the request has no tenant context.
  String currentTenantId();

  /// Returns the active membership in [currentTenantId], or `null` if
  /// none. NEVER throws — use this for `if (hasRole(...))` branching.
  TenantMembership? currentMembership();

  /// `true` iff the current user has at least [role] in the current
  /// tenant (role hierarchy applies — an admin satisfies `Role.agent`).
  bool hasRole(Role role);

  /// `true` iff the current user is a member of [tenantId] (active at
  /// the current clock).
  bool canActFor(String tenantId);

  /// Throws [AuthorizationException] with code `role-denied` unless
  /// the current user has at least [role] in the current tenant.
  void requireRole(Role role);

  /// Throws [AuthorizationException] with code `tenant-denied` unless
  /// the current user is an active member of [tenantId].
  void requireTenant(String tenantId);
}
