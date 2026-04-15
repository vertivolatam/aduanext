/// PostgreSQL legal-hold adapter integration tests.
///
/// REQUIREMENT: The `postgres_test` container from the root
/// `docker-compose.yaml` must be running. From repo root:
///
///     make db-up
///
/// Like the audit-log tests, we connect to `localhost:9190`, DB
/// `aduanext_test`, user `postgres`. Password comes from env
/// `POSTGRES_TEST_PASSWORD`. If that env var is absent the group is
/// skipped with a clear message.
///
/// Every test TRUNCATEs the table so ordering is irrelevant.
///
/// The adapter's `ensureSchema` assumes audit-log migration 0002 has
/// already installed `set_app_tenant()` + `aduanext_app`, so we bootstrap
/// the audit schema first via `PostgresAuditLogAdapter.openForTesting`.
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

  group('PostgresLegalHoldAdapter', () {
    late PostgresAuditLogAdapter auditBootstrap;
    late PostgresLegalHoldAdapter adapter;

    setUp(() async {
      // Bootstrap the audit-log schema to install the shared RLS
      // helpers (set_app_tenant, current_app_tenant, aduanext_app).
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
      await adapter.debugTruncateForTesting();
      await adapter.setSessionTenant('tenant-1');
    });

    tearDown(() async {
      await adapter.debugSetSessionRole(null);
      await adapter.close();
      await auditBootstrap.close();
    });

    LegalHold hold({
      String tenantId = 'tenant-1',
      String entityType = 'Declaration',
      String entityId = 'DUA-001',
      String reason = 'DGA case 2026-0042',
      String setBy = 'admin-7',
      DateTime? setAt,
    }) {
      return LegalHold(
        tenantId: tenantId,
        entityType: entityType,
        entityId: entityId,
        reason: reason,
        setByActorId: setBy,
        setAt: setAt ?? DateTime.utc(2026, 1, 1),
      );
    }

    test('place + isHeld + historyFor round-trip', () async {
      await adapter.place(hold());
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-001',
          now: DateTime.utc(2026, 2, 1),
        ),
        isTrue,
      );
      final history = await adapter.historyFor(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      expect(history, hasLength(1));
      expect(history.single.reason, 'DGA case 2026-0042');
      expect(history.single.releasedAt, isNull);
    });

    test('cannot place two active holds on the same key', () async {
      await adapter.place(hold(reason: 'first'));
      await expectLater(
        adapter.place(hold(reason: 'second')),
        throwsStateError,
      );
    });

    test('release followed by isHeld reports not-held', () async {
      await adapter.place(hold());
      await adapter.release(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
        releasedByActorId: 'admin-7',
        releasedAt: DateTime.utc(2026, 6, 1),
      );
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-001',
          now: DateTime.utc(2026, 7, 1),
        ),
        isFalse,
      );
    });

    test('release is a no-op when no active hold exists', () async {
      // Should not throw, should not create any rows.
      await adapter.release(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
        releasedByActorId: 'admin-7',
        releasedAt: DateTime.utc(2026, 6, 1),
      );
      final history = await adapter.historyFor(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      expect(history, isEmpty);
    });

    test('release then place again is allowed and history has 2 entries',
        () async {
      await adapter.place(hold(
        reason: 'first',
        setAt: DateTime.utc(2026, 1, 1),
      ));
      await adapter.release(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
        releasedByActorId: 'admin-7',
        releasedAt: DateTime.utc(2026, 6, 1),
      );
      await adapter.place(hold(
        reason: 'second',
        setAt: DateTime.utc(2026, 7, 1),
      ));
      final history = await adapter.historyFor(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      expect(history, hasLength(2));
      // historyFor orders by set_at DESC — newest first.
      expect(history.first.reason, 'second');
      expect(history.last.reason, 'first');
      expect(history.first.releasedAt, isNull);
      expect(history.last.releasedAt, isNotNull);
    });

    test('multiple active holds on different entities coexist', () async {
      await adapter.place(hold(entityId: 'DUA-001'));
      await adapter.place(hold(entityId: 'DUA-002'));
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-001',
          now: DateTime.utc(2026, 2, 1),
        ),
        isTrue,
      );
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-002',
          now: DateTime.utc(2026, 2, 1),
        ),
        isTrue,
      );
    });

    test('isHeld with a releasedAt in the future still reports held',
        () async {
      await adapter.place(hold());
      await adapter.release(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
        releasedByActorId: 'admin-7',
        releasedAt: DateTime.utc(2026, 12, 31),
      );
      // `now` is before the scheduled release → still held.
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-001',
          now: DateTime.utc(2026, 6, 1),
        ),
        isTrue,
      );
      // `now` past the release → not held.
      expect(
        await adapter.isHeld(
          tenantId: 'tenant-1',
          entityType: 'Declaration',
          entityId: 'DUA-001',
          now: DateTime.utc(2027, 1, 1),
        ),
        isFalse,
      );
    });

    test('ensureSchema is idempotent (safe to re-run)', () async {
      // setUp already ran it once; run it again — must not throw.
      await adapter.ensureSchema();
      await adapter.ensureSchema();
      // And the table is still usable.
      await adapter.place(hold());
      final history = await adapter.historyFor(
        tenantId: 'tenant-1',
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      expect(history, hasLength(1));
    });
  }, skip: skipReason);
}
