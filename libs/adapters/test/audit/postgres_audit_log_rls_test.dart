/// PostgreSQL Row-Level Security integration tests for the audit log.
///
/// These tests exercise migration 0002 (`tenant_isolation`). They
/// require the `postgres_test` docker-compose container to be
/// running — see the sibling `postgres_audit_log_adapter_test.dart`
/// for connection details.
///
/// Why we `SET ROLE aduanext_app`: Postgres superusers bypass RLS even
/// when the table is `FORCE`d. Middleware in production connects as a
/// non-superuser role, so the policies DO apply. In tests we emulate
/// that by SET ROLE'ing to `aduanext_app` before each assertion.
library;

import 'dart:io' show Platform;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  final password = Platform.environment['POSTGRES_TEST_PASSWORD'];
  final host = Platform.environment['POSTGRES_TEST_HOST'] ?? 'localhost';
  final port =
      int.tryParse(Platform.environment['POSTGRES_TEST_PORT'] ?? '') ?? 9190;
  final db = Platform.environment['POSTGRES_TEST_DB'] ?? 'aduanext_test';
  final user = Platform.environment['POSTGRES_TEST_USER'] ?? 'postgres';

  final skipReason = password == null || password.isEmpty
      ? 'POSTGRES_TEST_PASSWORD not set — run `make db-up` and export .env'
      : null;

  AuditEvent draft({
    required String tenantId,
    String entityType = 'Declaration',
    String entityId = 'DUA-001',
    String action = 'created',
  }) {
    return AuditEvent.draft(
      entityType: entityType,
      entityId: entityId,
      action: action,
      actorId: 'user-42',
      tenantId: tenantId,
      payload: {'status': 'draft', 'tenant': tenantId},
      clientTimestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
    );
  }

  group('Audit log RLS policies', () {
    late PostgresAuditLogAdapter adapter;

    setUp(() async {
      adapter = await PostgresAuditLogAdapter.openForTesting(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password ?? '',
        now: () => DateTime.utc(2026, 4, 13, 10, 0, 0),
      );
      // Seed data as superuser (bypass RLS) so tests have events for
      // multiple tenants available.
      await adapter.debugTruncateForTesting();
      await adapter.setSessionTenant('tenant-a');
      await adapter.append(draft(tenantId: 'tenant-a', entityId: 'A-1'));
      await adapter.append(draft(
        tenantId: 'tenant-a',
        entityId: 'A-1',
        action: 'classified',
      ));
      await adapter.setSessionTenant('tenant-b');
      await adapter.append(draft(tenantId: 'tenant-b', entityId: 'B-1'));
    });

    tearDown(() async {
      // Always restore the superuser role before closing so teardown
      // queries (TRUNCATE etc.) run without RLS getting in the way.
      await adapter.debugSetSessionRole(null);
      await adapter.close();
    });

    test('user in tenant A cannot SELECT tenant B\'s audit events',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');

      final ownRows = await adapter.queryByEntity('Declaration', 'A-1');
      expect(ownRows, hasLength(2));
      expect(ownRows.every((e) => e.tenantId == 'tenant-a'), isTrue);

      final crossRows = await adapter.queryByEntity('Declaration', 'B-1');
      expect(
        crossRows,
        isEmpty,
        reason: 'RLS must filter tenant-b rows when tenant-a is active',
      );
    });

    test('user in tenant A cannot INSERT an event with tenant_id = B',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');

      // Build an event whose tenant_id is B — INSERT WITH CHECK must
      // reject it because `current_app_tenant()` returns 'tenant-a'.
      await expectLater(
        adapter.append(draft(
          tenantId: 'tenant-b',
          entityId: 'A-2',
        )),
        throwsA(isA<Exception>()),
      );
    });

    test('admin bypass allows cross-tenant SELECT', () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      await adapter.setSessionAdminBypass(true);
      try {
        final a = await adapter.queryByEntity('Declaration', 'A-1');
        final b = await adapter.queryByEntity('Declaration', 'B-1');
        expect(a, hasLength(2));
        expect(
          b,
          hasLength(1),
          reason: 'Admin bypass must expose tenant-b rows to tenant-a '
              'caller',
        );
      } finally {
        await adapter.setSessionAdminBypass(false);
      }
    });

    test('unset tenant → zero rows returned (fail-secure default)',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant(null);

      final rows = await adapter.queryByEntity('Declaration', 'A-1');
      expect(
        rows,
        isEmpty,
        reason: 'With no tenant bound and no admin bypass, RLS must '
            'return zero rows regardless of what is on disk',
      );
    });

    test('concurrent tenants on separate connections do not leak',
        () async {
      // Open a second independent adapter. Each runs its own Postgres
      // session — the `set_app_tenant` GUC is session-local, so tenant
      // A on adapter1 MUST NOT influence tenant B on adapter2.
      final adapter2 = await PostgresAuditLogAdapter.openForTesting(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password ?? '',
      );
      try {
        await adapter.debugSetSessionRole('aduanext_app');
        await adapter2.debugSetSessionRole('aduanext_app');
        await adapter.setSessionTenant('tenant-a');
        await adapter2.setSessionTenant('tenant-b');

        final aRows = await adapter.queryByEntity('Declaration', 'A-1');
        final bRows = await adapter2.queryByEntity('Declaration', 'B-1');
        final crossA = await adapter.queryByEntity('Declaration', 'B-1');
        final crossB = await adapter2.queryByEntity('Declaration', 'A-1');

        expect(aRows.every((e) => e.tenantId == 'tenant-a'), isTrue);
        expect(bRows.every((e) => e.tenantId == 'tenant-b'), isTrue);
        expect(crossA, isEmpty);
        expect(crossB, isEmpty);
      } finally {
        await adapter2.debugSetSessionRole(null);
        await adapter2.close();
      }
    });

    test('UPDATE / DELETE are denied even with a bound tenant', () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      // Raw UPDATE via the adapter's debug connection — there is no
      // policy permitting UPDATE on audit_events, so it must fail.
      await expectLater(
        adapter.debugRawConnection.execute(
          "UPDATE audit_events SET action = 'tampered' "
          "WHERE tenant_id = 'tenant-a'",
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        adapter.debugRawConnection.execute(
          "DELETE FROM audit_events WHERE tenant_id = 'tenant-a'",
        ),
        throwsA(isA<Exception>()),
      );
    });
  }, skip: skipReason);
}
