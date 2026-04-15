/// Role — coarse-grained authorization label carried by a [User]'s
/// [TenantMembership].
///
/// Role hierarchy (least -> most privileged within a tenant):
///
///   fiscalizador < importer < agent < supervisor < admin
///
/// NOTE: this ordering is intentional so `role.outranks(other)` can be
/// expressed as an ordinal comparison. Do NOT reorder without touching
/// [Role.level] and every caller of [outranks].
library;

/// Coarse-grained authorization labels within a tenant.
enum Role {
  /// Read-only DGA simulator / compliance observer. Can view declarations
  /// and audit events but cannot submit, sign, or classify.
  fiscalizador(level: 0, code: 'fiscalizador'),

  /// A pyme employee acting on behalf of their own company. Can prepare
  /// draft declarations but cannot sign (must delegate to an `agent`
  /// through a mandato).
  importer(level: 10, code: 'importer'),

  /// Licensed customs agent (auxiliar de funcion publica, LGA Art. 28).
  /// Can prepare, sign, and submit declarations.
  agent(level: 20, code: 'agent'),

  /// Agency supervisor. Can manage junior agents within their agency
  /// tenant (invite, deactivate, review submissions).
  supervisor(level: 30, code: 'supervisor'),

  /// Tenant owner / billing contact. Can manage tenant settings and
  /// remove any member.
  admin(level: 40, code: 'admin');

  /// Privilege level — higher outranks lower. See file-level doc
  /// warning: do not reorder declaration without updating this value.
  final int level;

  /// Stable string representation used in JWT claims, audit payloads,
  /// and the Keycloak client role mapper.
  final String code;

  const Role({required this.level, required this.code});

  /// Parse a role code string (from JWT or user input). Returns `null`
  /// for unknown codes so callers can decide whether to fail-closed.
  static Role? fromCode(String code) {
    for (final r in Role.values) {
      if (r.code == code) return r;
    }
    return null;
  }

  /// `true` iff this role has strictly more privilege than [other].
  bool outranks(Role other) => level > other.level;

  /// `true` iff this role has at least the privilege of [minimum].
  bool satisfies(Role minimum) => level >= minimum.level;
}
