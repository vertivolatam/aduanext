/// User — an authenticated principal acting against AduaNext.
///
/// A user is NOT directly associated with a single tenant; instead,
/// they hold a set of [TenantMembership]s. The currently-selected tenant
/// for a request comes from the authorization context (typically a
/// custom JWT claim or a query parameter validated by middleware).
library;

import 'package:meta/meta.dart';

import 'role.dart';
import 'tenant_membership.dart';

/// Source of truth for the user's identity. Extensible — we will add
/// `LocalDev` and `Google` later without affecting callers.
enum UserAuthProvider {
  /// Keycloak (production + staging).
  keycloak,

  /// Local dev-mode with static user/password. Never used in prod.
  localDev,
}

@immutable
class User {
  /// Stable identifier. For Keycloak this maps to the `sub` claim.
  final String id;

  /// Primary email. Unique per [authProvider] but we don't rely on that —
  /// the [id] is the authoritative key.
  final String email;

  /// Active memberships. May be empty for a freshly-registered user
  /// before they accept any invitation.
  final Set<TenantMembership> memberships;

  final UserAuthProvider authProvider;

  User({
    required this.id,
    required this.email,
    required Set<TenantMembership> memberships,
    this.authProvider = UserAuthProvider.keycloak,
  }) : memberships = Set<TenantMembership>.unmodifiable(memberships);

  /// Returns the subset of memberships that are active at [now].
  Iterable<TenantMembership> activeMembershipsAt(DateTime now) {
    return memberships.where((m) => m.isActiveAt(now));
  }

  /// Returns the active role the user holds in [tenantId] at [now], or
  /// `null` if no such active membership exists.
  Role? roleInTenantAt(String tenantId, DateTime now) {
    for (final m in memberships) {
      if (m.tenantId == tenantId && m.isActiveAt(now)) return m.role;
    }
    return null;
  }

  /// `true` iff the user has an active membership in [tenantId] at [now]
  /// whose role [Role.satisfies] the [minimumRole].
  bool canActIn({
    required String tenantId,
    required Role minimumRole,
    required DateTime now,
  }) {
    final r = roleInTenantAt(tenantId, now);
    return r != null && r.satisfies(minimumRole);
  }
}
