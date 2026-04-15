/// Unit tests for the authorization value objects + entities.
///
/// Covers:
/// - [Role] hierarchy semantics (outranks, satisfies, fromCode).
/// - [TenantMembership.isActiveAt] time window checks.
/// - [User.roleInTenantAt] / [User.canActIn] multi-tenant lookups.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Role', () {
    test('level ordering matches hierarchy', () {
      expect(Role.fiscalizador.level < Role.importer.level, isTrue);
      expect(Role.importer.level < Role.agent.level, isTrue);
      expect(Role.agent.level < Role.supervisor.level, isTrue);
      expect(Role.supervisor.level < Role.admin.level, isTrue);
    });

    test('outranks is strict', () {
      expect(Role.admin.outranks(Role.agent), isTrue);
      expect(Role.agent.outranks(Role.agent), isFalse);
      expect(Role.agent.outranks(Role.supervisor), isFalse);
    });

    test('satisfies is >= in hierarchy', () {
      expect(Role.admin.satisfies(Role.agent), isTrue);
      expect(Role.agent.satisfies(Role.agent), isTrue);
      expect(Role.importer.satisfies(Role.agent), isFalse);
    });

    test('fromCode round-trips every enum value', () {
      for (final r in Role.values) {
        expect(Role.fromCode(r.code), r);
      }
    });

    test('fromCode returns null for unknown input', () {
      expect(Role.fromCode('emperor'), isNull);
      expect(Role.fromCode(''), isNull);
    });
  });

  group('TenantMembership.isActiveAt', () {
    final since = DateTime.utc(2026, 1, 1);
    final expires = DateTime.utc(2026, 12, 31);

    TenantMembership build({DateTime? exp}) => TenantMembership(
          userId: 'u',
          tenantId: 't',
          role: Role.agent,
          since: since,
          expires: exp,
        );

    test('rejects time before the since instant', () {
      final m = build();
      expect(m.isActiveAt(DateTime.utc(2025, 12, 31)), isFalse);
    });

    test('accepts time at/after since with no expiry', () {
      final m = build();
      expect(m.isActiveAt(since), isTrue);
      expect(m.isActiveAt(DateTime.utc(2100, 1, 1)), isTrue);
    });

    test('rejects time at/after expiry', () {
      final m = build(exp: expires);
      expect(m.isActiveAt(expires), isFalse,
          reason: 'expiry is exclusive — at `expires`, membership is over.');
      expect(m.isActiveAt(DateTime.utc(2027, 1, 1)), isFalse);
    });

    test('accepts time strictly before expiry', () {
      final m = build(exp: expires);
      expect(m.isActiveAt(DateTime.utc(2026, 6, 1)), isTrue);
    });
  });

  group('User.roleInTenantAt / canActIn', () {
    final now = DateTime.utc(2026, 4, 14);

    TenantMembership m({
      String tenantId = 't1',
      Role role = Role.agent,
      DateTime? expires,
    }) =>
        TenantMembership(
          userId: 'u',
          tenantId: tenantId,
          role: role,
          since: DateTime.utc(2026, 1, 1),
          expires: expires,
        );

    test('returns the role for an active membership', () {
      final u = User(
        id: 'u',
        email: 'a@b',
        memberships: {m(tenantId: 't1', role: Role.supervisor)},
      );
      expect(u.roleInTenantAt('t1', now), Role.supervisor);
    });

    test('returns null when the membership is expired', () {
      final u = User(
        id: 'u',
        email: 'a@b',
        memberships: {
          m(tenantId: 't1', role: Role.agent, expires: DateTime.utc(2026, 2, 1))
        },
      );
      expect(u.roleInTenantAt('t1', now), isNull);
    });

    test('returns null for a tenant the user never belonged to', () {
      final u = User(
        id: 'u',
        email: 'a@b',
        memberships: {m(tenantId: 't1')},
      );
      expect(u.roleInTenantAt('t-ghost', now), isNull);
    });

    test('canActIn honors role hierarchy', () {
      final u = User(
        id: 'u',
        email: 'a@b',
        memberships: {m(tenantId: 't1', role: Role.admin)},
      );
      expect(
        u.canActIn(tenantId: 't1', minimumRole: Role.agent, now: now),
        isTrue,
      );
      expect(
        u.canActIn(tenantId: 't1', minimumRole: Role.admin, now: now),
        isTrue,
      );
      expect(
        u.canActIn(tenantId: 't-other', minimumRole: Role.importer, now: now),
        isFalse,
      );
    });
  });
}
