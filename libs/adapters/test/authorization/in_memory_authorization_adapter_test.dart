/// Unit tests for [InMemoryAuthorizationAdapter].
///
/// Drives every public method of [AuthorizationPort] through the
/// in-memory adapter so the domain contract (unauthenticated /
/// tenant-not-selected / role-denied / tenant-denied exception codes
/// and their payload shape) is pinned down.
library;

import 'package:aduanext_adapters/authorization.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryAuthorizationAdapter', () {
    final now = DateTime.utc(2026, 4, 14);

    User buildUser({
      String tenantId = 't1',
      Role role = Role.agent,
      DateTime? expires,
    }) {
      return User(
        id: 'u',
        email: 'a@b',
        memberships: {
          TenantMembership(
            userId: 'u',
            tenantId: tenantId,
            role: role,
            since: DateTime.utc(2026, 1, 1),
            expires: expires,
          ),
        },
      );
    }

    test(
      'currentUser throws unauthenticated when no user is bound',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: null,
          selectedTenantId: 't1',
          now: () => now,
        );
        expect(
          adapter.currentUser,
          throwsA(isA<AuthorizationException>()
              .having((e) => e.code, 'code', 'unauthenticated')),
        );
      },
    );

    test(
      'currentTenantId throws tenant-not-selected when no tenant is bound',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(),
          selectedTenantId: null,
          now: () => now,
        );
        expect(
          adapter.currentTenantId,
          throwsA(isA<AuthorizationException>()
              .having((e) => e.code, 'code', 'tenant-not-selected')),
        );
      },
    );

    test(
      'requireRole throws role-denied with requiredRole on an importer',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(role: Role.importer),
          selectedTenantId: 't1',
          now: () => now,
        );
        expect(
          () => adapter.requireRole(Role.agent),
          throwsA(
            isA<AuthorizationException>()
                .having((e) => e.code, 'code', 'role-denied')
                .having((e) => e.requiredRole, 'requiredRole', Role.agent)
                .having((e) => e.tenantId, 'tenantId', 't1'),
          ),
        );
      },
    );

    test(
      'requireRole succeeds when the actor outranks the required role',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(role: Role.supervisor),
          selectedTenantId: 't1',
          now: () => now,
        );
        adapter.requireRole(Role.agent); // does not throw
      },
    );

    test(
      'requireTenant throws tenant-denied when the user has no active '
      'membership in the tenant',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(tenantId: 't1'),
          selectedTenantId: 't1',
          now: () => now,
        );
        expect(
          () => adapter.requireTenant('t-other'),
          throwsA(
            isA<AuthorizationException>()
                .having((e) => e.code, 'code', 'tenant-denied')
                .having((e) => e.tenantId, 'tenantId', 't-other'),
          ),
        );
      },
    );

    test(
      'requireTenant rejects expired memberships (defense-in-depth vs '
      'stale JWTs)',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(
            tenantId: 't1',
            expires: DateTime.utc(2026, 2, 1),
          ),
          selectedTenantId: 't1',
          now: () => now,
        );
        expect(
          () => adapter.requireTenant('t1'),
          throwsA(isA<AuthorizationException>()
              .having((e) => e.code, 'code', 'tenant-denied')),
        );
      },
    );

    test('hasRole / canActFor return the right boolean without throwing', () {
      final adapter = InMemoryAuthorizationAdapter(
        user: buildUser(role: Role.admin),
        selectedTenantId: 't1',
        now: () => now,
      );
      expect(adapter.hasRole(Role.agent), isTrue);
      expect(adapter.hasRole(Role.admin), isTrue);
      expect(adapter.canActFor('t1'), isTrue);
      expect(adapter.canActFor('t-other'), isFalse);
    });

    test(
      'currentMembership returns the active membership or null (never throws)',
      () {
        final adapter = InMemoryAuthorizationAdapter(
          user: buildUser(role: Role.agent),
          selectedTenantId: 't1',
          now: () => now,
        );
        expect(adapter.currentMembership()?.role, Role.agent);

        final withoutUser = InMemoryAuthorizationAdapter(
          user: null,
          selectedTenantId: null,
          now: () => now,
        );
        expect(withoutUser.currentMembership(), isNull);
      },
    );
  });
}
