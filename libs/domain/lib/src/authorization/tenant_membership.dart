/// TenantMembership — a value object linking a [User] to a [Tenant] with
/// a specific [Role] and time window.
///
/// A user can be a member of multiple tenants (e.g. an agency supervisor
/// who also freelances on the side). Each membership is independent —
/// role + time window are per-tenant.
library;

import 'package:meta/meta.dart';

import 'role.dart';

@immutable
class TenantMembership {
  final String userId;
  final String tenantId;
  final Role role;

  /// Start of the membership window (UTC). The user CANNOT act on behalf
  /// of the tenant before this moment.
  final DateTime since;

  /// Optional end of the membership window (UTC). `null` means open-ended
  /// ("active until revoked"). Expired memberships MUST be rejected by
  /// [AuthorizationPort] even if the JWT still carries them — this is a
  /// defense-in-depth rule against stale tokens.
  final DateTime? expires;

  const TenantMembership({
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.since,
    this.expires,
  });

  /// `true` iff the membership is currently active at [now] (UTC).
  bool isActiveAt(DateTime now) {
    final utcNow = now.toUtc();
    if (utcNow.isBefore(since.toUtc())) return false;
    final exp = expires;
    if (exp != null && !utcNow.isBefore(exp.toUtc())) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is TenantMembership &&
      other.userId == userId &&
      other.tenantId == tenantId &&
      other.role == role &&
      other.since == since &&
      other.expires == expires;

  @override
  int get hashCode =>
      Object.hash(userId, tenantId, role, since, expires);

  @override
  String toString() =>
      'TenantMembership($userId, $tenantId, $role, since=$since, '
      'expires=${expires ?? "open"})';
}
