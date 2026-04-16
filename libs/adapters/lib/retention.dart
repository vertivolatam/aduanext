/// Retention adapters implementing [LegalHoldPort] +
/// [RetentionPurgeablePort] and supporting the VRTV-57 retention worker.
///
/// * [InMemoryLegalHoldAdapter] — for tests and dev runs.
/// * [PostgresLegalHoldAdapter] — for the Serverpod server deploy
///   (VRTV-73). Assumes audit-log migration 0002 has already installed
///   `current_app_tenant()` / `set_app_tenant()` + the `aduanext_app`
///   non-bypassing role (they are reused across tables).
/// * [PostgresAuditRetentionAdapter] — wraps the audit_events table as
///   a `RetentionPurgeablePort` so the retention worker can archive
///   and purge aged chains while preserving chain integrity via a
///   `RetentionPurge` tombstone event (VRTV-74).
library;

export 'src/retention/in_memory_legal_hold_adapter.dart';
export 'src/retention/migrations/retention_worker_role_migration.dart';
export 'src/retention/postgres_audit_retention_adapter.dart';
export 'src/retention/postgres_legal_hold_adapter.dart';
