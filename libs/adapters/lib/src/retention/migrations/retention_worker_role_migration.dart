/// Embedded migration 0002 (retention) — `aduanext_retention_worker`
/// dedicated Postgres role.
///
/// Canonical source of truth is the sibling
/// `0002_retention_worker_role.sql` file. This Dart list lets the
/// adapter ship the migration without reading the filesystem at
/// runtime (matches the audit-log + legal-holds migration pattern).
/// Keep the two files in sync.
///
/// The migration assumes the audit-log migration 0002
/// (`tenant_isolation_migration.dart`) has already installed
/// `current_app_tenant()`, `set_app_tenant()`, `set_app_bypass_rls()`
/// and the `aduanext_app` role, AND that retention migration 0001
/// (`legal_holds_migration.dart`) has created the `legal_holds` table.
///
/// Apply via [applyRetentionWorkerRoleMigration] so production boots
/// (which run migrations as a privileged admin role) can invoke it
/// before the RetentionWorker opens its narrow connection.
library;

import 'package:postgres/postgres.dart';

/// All migration statements, applied in order. Every statement is
/// idempotent.
const List<String> retentionWorkerRoleMigrationStatements = [
  // 1. Create the role if missing; reset NOINHERIT + NOBYPASSRLS even
  //    when it already exists so older deployments converge.
  r'''
DO $retention_worker_role$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'aduanext_retention_worker'
  ) THEN
    CREATE ROLE aduanext_retention_worker LOGIN NOINHERIT NOBYPASSRLS;
  ELSE
    ALTER ROLE aduanext_retention_worker NOINHERIT NOBYPASSRLS;
  END IF;
END
$retention_worker_role$
''',

  // 2. Narrow grants on audit_events.
  'GRANT SELECT, DELETE ON TABLE audit_events TO aduanext_retention_worker',

  // 3. Narrow grants on legal_holds.
  'GRANT SELECT, INSERT, UPDATE ON TABLE legal_holds '
      'TO aduanext_retention_worker',

  // 4. Session-config helpers needed to scope cross-tenant iteration
  //    + tenant context for legal-hold queries.
  'GRANT EXECUTE ON FUNCTION set_app_bypass_rls(TEXT) '
      'TO aduanext_retention_worker',
  'GRANT EXECUTE ON FUNCTION set_app_tenant(TEXT) '
      'TO aduanext_retention_worker',
  'GRANT EXECUTE ON FUNCTION current_app_tenant() '
      'TO aduanext_retention_worker',

  // 5. Belt-and-braces — strip BYPASSRLS if an older deployment had it.
  'ALTER ROLE aduanext_retention_worker NOBYPASSRLS',
];

/// Apply the retention-worker role migration against [connection].
///
/// Intended to be called from boot code that already holds a
/// privileged connection (the container's superuser / migration
/// role). Idempotent — every statement is `IF NOT EXISTS` or carries
/// its own idempotency guard. Returns normally on success; rethrows
/// the first Postgres error on failure so the boot fast-fails rather
/// than silently leaving the RetentionWorker with superuser rights.
Future<void> applyRetentionWorkerRoleMigration(Connection connection) async {
  for (final stmt in retentionWorkerRoleMigrationStatements) {
    await connection.execute(stmt);
  }
}

/// Set a password on the `aduanext_retention_worker` role.
///
/// Separated from [applyRetentionWorkerRoleMigration] because the
/// password lives in secrets (Kubernetes secret, Vault, ...) that are
/// not part of the migration SQL. Call this as the second step of a
/// production boot, with the password read from a secret manager.
///
/// Idempotent: re-running with the same password is a no-op; running
/// with a different password rotates it.
Future<void> setRetentionWorkerRolePassword(
  Connection connection, {
  required String password,
}) async {
  if (password.isEmpty) {
    throw ArgumentError.value(
      password,
      'password',
      'aduanext_retention_worker password must be non-empty',
    );
  }
  // Use the format that avoids quoting the password into SQL. The
  // postgres driver does not support parameterised role passwords —
  // ALTER ROLE ... PASSWORD only accepts a string literal. We therefore
  // escape single quotes manually and fail loudly if the caller hands
  // us a password containing characters that would break the literal
  // (newlines, null bytes).
  if (password.contains('\u0000') || password.contains('\n')) {
    throw ArgumentError.value(
      password,
      'password',
      'password contains forbidden control characters',
    );
  }
  final escaped = password.replaceAll("'", "''");
  await connection.execute(
    "ALTER ROLE aduanext_retention_worker PASSWORD '$escaped'",
  );
}
