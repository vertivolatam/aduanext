/// PostgreSQL Row-Level Security integration tests for `legal_holds`.
///
/// Same model as `postgres_audit_log_rls_test.dart`:
///   * `SET ROLE aduanext_app` drops superuser BYPASSRLS so policies
///     actually apply.
///   * Seed data as the superuser (no role set) so multi-tenant
///     fixtures exist; then switch roles + bind tenants to assert
///     isolation.
///
/// Requires the `postgres_test` container — skipped if
/// `POSTGRES_TEST_PASSWORD` is not set.
library;

import 'dart:io' show Platform;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_adapters/retention.dart';
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

  LegalHold mk({
    required String tenantId,
    String entityId = 'DUA-001',
    String entityType = 'Declaration',
    String reason = 'case-1',
  }) {
    return LegalHold(
      tenantId: tenantId,
      entityType: entityType,
      entityId: entityId,
      reason: reason,
      setByActorId: 'admin-7',
      setAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('legal_holds RLS policies', () {
    late PostgresAuditLogAdapter auditBootstrap;
    late PostgresLegalHoldAdapter adapter;

    setUp(() async {
      auditBootstrap = await PostgresAuditLogAdapter.openForTesting(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password ?? '',
      );
      adapter = await PostgresLegalHoldAdapter.openForTesting(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password ?? '',
      );
      // Seed rows as superuser so every tenant has history before we
      // drop to aduanext_app.
      await adapter.debugTruncateForTesting();
      await adapter.setSessionTenant('tenant-a');
      await adapter.place(mk(tenantId: 'tenant-a', entityId: 'A-1'));
      await adapter.setSessionTenant('tenant-b');
      await adapter.place(mk(tenantId: 'tenant-b', entityId: 'B-1'));
    });

    tearDown(() async {
      await adapter.debugSetSessionRole(null);
      await adapter.close();
      await auditBootstrap.close();
    });

    test('user in tenant A cannot SELECT tenant B holds', () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      final own = await adapter.historyFor(
        tenantId: 'tenant-a',
        entityType: 'Declaration',
        entityId: 'A-1',
      );
      expect(own, hasLength(1));
      expect(own.single.tenantId, 'tenant-a');

      // Even a direct raw query with tenant-b coordinates yields 0
      // rows because RLS filters by current_app_tenant().
      final cross = await adapter.debugRawConnection.execute(
        "SELECT tenant_id FROM legal_holds WHERE entity_id = 'B-1'",
      );
      expect(cross, isEmpty);
    });

    test('user in tenant A cannot INSERT a hold with tenant_id = B',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      await expectLater(
        adapter.place(mk(tenantId: 'tenant-b', entityId: 'A-2')),
        throwsA(isA<Exception>()),
      );
    });

    test('admin bypass allows cross-tenant SELECT', () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      await adapter.setSessionAdminBypass(true);
      try {
        final rows = await adapter.debugRawConnection.execute(
          'SELECT tenant_id FROM legal_holds',
        );
        final tenants = rows.map((r) => r[0] as String).toSet();
        expect(tenants, containsAll(<String>{'tenant-a', 'tenant-b'}));
      } finally {
        await adapter.setSessionAdminBypass(false);
      }
    });

    test('unset tenant returns zero rows (fail-secure default)',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant(null);
      final rows = await adapter.debugRawConnection.execute(
        'SELECT COUNT(*) FROM legal_holds',
      );
      expect((rows.first[0] as int), 0);
    });

    test('UPDATE cross-tenant is denied even with a bound tenant',
        () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      // Try to rewrite tenant-b's row. WITH CHECK makes the UPDATE a
      // no-op from tenant-a's perspective (0 rows match the USING
      // clause) — the row must NOT be mutated.
      await adapter.debugRawConnection.execute(
        "UPDATE legal_holds SET reason = 'tampered' "
        "WHERE entity_id = 'B-1'",
      );
      // Confirm the foreign row is untouched using admin bypass.
      await adapter.setSessionAdminBypass(true);
      final rows = await adapter.debugRawConnection.execute(
        "SELECT reason FROM legal_holds WHERE entity_id = 'B-1'",
      );
      await adapter.setSessionAdminBypass(false);
      expect(rows.single[0], 'case-1');
    });

    test('DELETE is denied (no policy permits it)', () async {
      await adapter.debugSetSessionRole('aduanext_app');
      await adapter.setSessionTenant('tenant-a');
      await expectLater(
        adapter.debugRawConnection.execute(
          "DELETE FROM legal_holds WHERE tenant_id = 'tenant-a'",
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'concurrent tenants on separate connections do not leak',
      () async {
        final adapter2 = await PostgresLegalHoldAdapter.openForTesting(
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

          final a = await adapter.historyFor(
            tenantId: 'tenant-a',
            entityType: 'Declaration',
            entityId: 'A-1',
          );
          final b = await adapter2.historyFor(
            tenantId: 'tenant-b',
            entityType: 'Declaration',
            entityId: 'B-1',
          );
          final crossA = await adapter.historyFor(
            tenantId: 'tenant-a',
            entityType: 'Declaration',
            entityId: 'B-1',
          );
          final crossB = await adapter2.historyFor(
            tenantId: 'tenant-b',
            entityType: 'Declaration',
            entityId: 'A-1',
          );

          expect(a.every((h) => h.tenantId == 'tenant-a'), isTrue);
          expect(b.every((h) => h.tenantId == 'tenant-b'), isTrue);
          expect(crossA, isEmpty);
          expect(crossB, isEmpty);
        } finally {
          await adapter2.debugSetSessionRole(null);
          await adapter2.close();
        }
      },
    );
  }, skip: skipReason);
}
