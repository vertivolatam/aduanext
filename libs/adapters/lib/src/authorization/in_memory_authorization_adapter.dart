/// In-memory [AuthorizationPort] adapter — for unit tests and local-dev
/// runs only. A production deployment wires [KeycloakAuthorizationAdapter]
/// (shipping in a follow-up) which reads roles + tenant membership from
/// a validated JWT.
///
/// The in-memory adapter takes a fixed [User] + selected tenant id at
/// construction and honors the contract of [AuthorizationPort] exactly
/// (role hierarchy, active-membership checks, consistent exceptions).
library;

import 'package:aduanext_domain/aduanext_domain.dart';

/// In-memory authorization adapter.
class InMemoryAuthorizationAdapter implements AuthorizationPort {
  /// The authenticated user. Null means "no user bound to request".
  final User? _user;

  /// The tenant selected for the current request. Null means
  /// "no tenant selected".
  final String? _selectedTenantId;

  /// Clock for active-membership checks.
  final DateTime Function() _now;

  InMemoryAuthorizationAdapter({
    required User? user,
    required String? selectedTenantId,
    DateTime Function()? now,
  })  : _user = user,
        _selectedTenantId = selectedTenantId,
        _now = now ?? DateTime.now;

  @override
  User currentUser() {
    final u = _user;
    if (u == null) {
      throw const AuthorizationException(
        code: 'unauthenticated',
        message: 'No authenticated user is bound to this request.',
      );
    }
    return u;
  }

  @override
  String currentTenantId() {
    final t = _selectedTenantId;
    if (t == null || t.isEmpty) {
      throw const AuthorizationException(
        code: 'tenant-not-selected',
        message: 'No tenant has been selected for this request.',
      );
    }
    return t;
  }

  @override
  TenantMembership? currentMembership() {
    if (_user == null || _selectedTenantId == null) return null;
    for (final m in _user.memberships) {
      if (m.tenantId == _selectedTenantId && m.isActiveAt(_now())) {
        return m;
      }
    }
    return null;
  }

  @override
  bool hasRole(Role role) {
    final m = currentMembership();
    return m != null && m.role.satisfies(role);
  }

  @override
  bool canActFor(String tenantId) {
    if (_user == null) return false;
    for (final m in _user.memberships) {
      if (m.tenantId == tenantId && m.isActiveAt(_now())) return true;
    }
    return false;
  }

  @override
  void requireRole(Role role) {
    // Evaluate currentUser + currentTenant so the right
    // AuthorizationException is thrown when the caller lacks either.
    currentUser();
    currentTenantId();
    if (!hasRole(role)) {
      throw AuthorizationException(
        code: 'role-denied',
        message:
            'Current user does not hold at least role "${role.code}" '
            'in tenant "${_selectedTenantId ?? ""}".',
        tenantId: _selectedTenantId,
        requiredRole: role,
      );
    }
  }

  @override
  void requireTenant(String tenantId) {
    currentUser();
    if (!canActFor(tenantId)) {
      throw AuthorizationException(
        code: 'tenant-denied',
        message:
            'Current user is not an active member of tenant "$tenantId".',
        tenantId: tenantId,
      );
    }
  }
}
