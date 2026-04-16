/// Static inspection tests for the `aduanext_retention_worker` role
/// migration (VRTV-75).
///
/// These are intentionally SQL-string-level assertions rather than
/// Postgres integration tests — the SQL itself is idempotent and
/// applied by `AppContainer.boot()`, and the actual permission
/// enforcement is covered by the separate integration suite that
/// spins up a real Postgres. Here we lock the invariants the VRTV-75
/// security contract depends on so a future edit can't silently
/// regress them.
///
/// Invariants asserted:
///   1. The role is created with NOBYPASSRLS (SRD rule 2: no silent
///      cross-tenant reads).
///   2. The role is created with NOINHERIT (it must not pick up
///      `aduanext_app`'s grants transitively).
///   3. The role has SELECT + DELETE on `audit_events` — and NOTHING
///      ELSE on that table (no INSERT, no UPDATE, no TRUNCATE).
///   4. The role has SELECT + INSERT + UPDATE on `legal_holds` — and
///      NO DELETE (append-only contract).
///   5. Every statement is idempotent (CREATE ... IF NOT EXISTS /
///      ALTER ROLE / DO $$ IF NOT EXISTS).
library;

import 'package:aduanext_adapters/retention.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  group('retentionWorkerRoleMigrationStatements', () {
    final all = retentionWorkerRoleMigrationStatements.join('\n');

    test('creates the role with NOBYPASSRLS + NOINHERIT + LOGIN', () {
      expect(all, contains('aduanext_retention_worker'));
      expect(all, contains('NOBYPASSRLS'));
      expect(all, contains('NOINHERIT'));
      expect(all, contains('LOGIN'));
    });

    test('creation is idempotent (IF NOT EXISTS / ALTER ROLE guard)',
        () {
      expect(all, contains('IF NOT EXISTS'));
      expect(all, contains('ALTER ROLE aduanext_retention_worker'));
    });

    test('grants SELECT + DELETE on audit_events', () {
      expect(
        all,
        contains(
          'GRANT SELECT, DELETE ON TABLE audit_events '
          'TO aduanext_retention_worker',
        ),
      );
    });

    test('does NOT grant INSERT/UPDATE/TRUNCATE on audit_events', () {
      // Audit tombstones flow through the normal AuditLogPort, which
      // uses the `aduanext_app` session. The retention worker itself
      // must never INSERT directly — otherwise the chain-hash path
      // bypasses the hasher.
      final auditLines = retentionWorkerRoleMigrationStatements
          .where((s) => s.contains('audit_events'));
      for (final line in auditLines) {
        expect(line, isNot(contains('INSERT')),
            reason: 'audit_events must NOT grant INSERT to the worker');
        expect(line, isNot(contains('UPDATE')),
            reason: 'audit_events must NOT grant UPDATE to the worker');
        expect(line, isNot(contains('TRUNCATE')),
            reason: 'audit_events must NOT grant TRUNCATE to the worker');
      }
    });

    test('grants SELECT + INSERT + UPDATE on legal_holds (no DELETE)',
        () {
      expect(
        all,
        contains(
          'GRANT SELECT, INSERT, UPDATE ON TABLE legal_holds',
        ),
      );
      final legalHoldLines = retentionWorkerRoleMigrationStatements
          .where((s) => s.contains('legal_holds'));
      for (final line in legalHoldLines) {
        expect(line, isNot(contains('DELETE')),
            reason: 'legal_holds must be append-only');
      }
    });

    test('grants EXECUTE on the tenant-isolation helper functions',
        () {
      expect(all, contains('set_app_bypass_rls'));
      expect(all, contains('set_app_tenant'));
      expect(all, contains('current_app_tenant'));
    });

    test('final statement re-applies NOBYPASSRLS belt-and-braces', () {
      expect(
        retentionWorkerRoleMigrationStatements.last,
        'ALTER ROLE aduanext_retention_worker NOBYPASSRLS',
      );
    });
  });

  group('setRetentionWorkerRolePassword', () {
    test('rejects empty password', () {
      expect(
        () => setRetentionWorkerRolePassword(
          _NullConnection(),
          password: '',
        ),
        throwsArgumentError,
      );
    });

    test('rejects passwords with newlines or null bytes', () {
      expect(
        () => setRetentionWorkerRolePassword(
          _NullConnection(),
          password: 'contains\nnewline',
        ),
        throwsArgumentError,
      );
      expect(
        () => setRetentionWorkerRolePassword(
          _NullConnection(),
          password: 'contains\u0000nul',
        ),
        throwsArgumentError,
      );
    });
  });
}

/// Dummy [Connection] stand-in that rejects every call — we only use
/// it to reach the validation guards in
/// [setRetentionWorkerRolePassword]. If the guards pass we want the
/// test to fail fast because we never actually want to hit Postgres
/// from a unit test.
class _NullConnection implements Connection {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('test stub should never be reached');
}
