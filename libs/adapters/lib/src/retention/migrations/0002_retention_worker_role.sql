-- Migration 0002 (retention) — dedicated `aduanext_retention_worker`
-- Postgres role with narrow grants.
--
-- Purpose: production hardening of the RetentionWorker (VRTV-74). In
-- dev the worker inherits the container's Postgres role — often a
-- superuser — which means a bug in the worker could DROP TABLE or
-- otherwise corrupt the database. In production the worker connects
-- as `aduanext_retention_worker` which can only SELECT / DELETE on
-- `audit_events` and SELECT / INSERT / UPDATE on `legal_holds`; any
-- other verb raises `permission denied for table`.
--
-- BYPASSRLS is explicitly NOT granted — the worker iterates tenants
-- via the `app.bypass_rls = 'admin'` GUC (from VRTV-62) which is
-- already audit-logged via `PostgresAuditLogAdapter.withAdminBypass`.
-- Giving the role BYPASSRLS would make cross-tenant reads invisible
-- to the audit trail.
--
-- Idempotent: safe to re-run on an already-migrated database. The
-- adapter's `PostgresRetentionWorkerRoleMigration.apply()` invokes
-- this at the privileged boot step that runs migrations.
--
-- References: VRTV-57 (retention), VRTV-62 (RLS pattern), VRTV-74
-- (worker DI), VRTV-75 (this migration).

DO $outer$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'aduanext_retention_worker'
  ) THEN
    CREATE ROLE aduanext_retention_worker LOGIN NOINHERIT NOBYPASSRLS;
  ELSE
    ALTER ROLE aduanext_retention_worker NOINHERIT NOBYPASSRLS;
  END IF;
END
$outer$;

-- Narrow grants on audit_events: the worker reads candidates + deletes
-- purged entities. No INSERT — the worker appends tombstones via the
-- normal `AuditLogPort` interface, which the audit adapter routes
-- through its own Postgres session (running as `aduanext_app`) so the
-- chain-hashing path stays consistent.
GRANT SELECT, DELETE ON TABLE audit_events TO aduanext_retention_worker;

-- legal_holds: SELECT to check holds before purging, INSERT + UPDATE
-- for administrative actions (not done by the worker today but kept
-- for symmetry with legal_hold_port clients). No DELETE — holds are
-- append-only with a `released_at` transition; deletes would corrupt
-- the audit chain.
GRANT SELECT, INSERT, UPDATE ON TABLE legal_holds TO aduanext_retention_worker;

-- Session-config helpers: the worker MUST be able to set
-- `app.bypass_rls = 'admin'` so it can iterate rows across tenants
-- while RLS is still enforced on every other role. The helper
-- functions themselves are defined in the audit migration 0002.
GRANT EXECUTE ON FUNCTION set_app_bypass_rls(TEXT)
  TO aduanext_retention_worker;
GRANT EXECUTE ON FUNCTION set_app_tenant(TEXT)
  TO aduanext_retention_worker;
GRANT EXECUTE ON FUNCTION current_app_tenant()
  TO aduanext_retention_worker;

-- Belt-and-braces: if an older deployment granted BYPASSRLS by
-- accident, strip it here. Idempotent — a no-op if the role never
-- had the privilege.
ALTER ROLE aduanext_retention_worker NOBYPASSRLS;
