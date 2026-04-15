-- Migration 0002 — Tenant isolation via Postgres Row-Level Security.
--
-- Purpose: defense in depth. Even when application middleware forgets
-- to filter by tenant, the database MUST reject cross-tenant reads /
-- writes. Policies key on `tenant_id` via a session-local GUC
-- (`app.current_tenant_id`) that the adapter sets on every operation.
--
-- Idempotent: every statement here is safe to run on an already-
-- migrated database. `PostgresAuditLogAdapter.ensureSchema()` runs it
-- at every boot. A proper migration tool (Flyway / dbmate) is tracked
-- separately.
--
-- Admin bypass: if the GUC `app.bypass_rls` is `'admin'`, the SELECT
-- policy lets the row through regardless of tenant. The bypass MUST
-- be set only after the application records an audit event for the
-- bypass itself (see PostgresAuditLogAdapter.withAdminBypass).
--
-- References: VRTV-62, LGA Art. 30 / reference_legal_framework.

-- Non-bypassing app role. Postgres superusers bypass RLS even with
-- FORCE; middleware + tests use SET ROLE to exercise the policies.
DO $outer$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aduanext_app') THEN
    CREATE ROLE aduanext_app NOLOGIN NOBYPASSRLS;
  ELSE
    ALTER ROLE aduanext_app NOBYPASSRLS;
  END IF;
END
$outer$;

GRANT SELECT, INSERT ON TABLE audit_events TO aduanext_app;
GRANT USAGE, SELECT ON SEQUENCE audit_events_id_seq TO aduanext_app;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'audit_events' AND column_name = 'tenant_id'
      AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE audit_events ALTER COLUMN tenant_id SET NOT NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_entity
  ON audit_events (tenant_id, entity_type, entity_id);

CREATE OR REPLACE FUNCTION set_app_tenant(p_tenant_id TEXT)
RETURNS VOID AS $fn$
BEGIN
  PERFORM set_config('app.current_tenant_id', p_tenant_id, true);
END;
$fn$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION current_app_tenant()
RETURNS TEXT AS $fn$
BEGIN
  RETURN NULLIF(current_setting('app.current_tenant_id', true), '');
END;
$fn$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION set_app_bypass_rls(p_flag TEXT)
RETURNS VOID AS $fn$
BEGIN
  PERFORM set_config('app.bypass_rls', p_flag, true);
END;
$fn$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION set_app_tenant(TEXT) TO aduanext_app;
GRANT EXECUTE ON FUNCTION current_app_tenant() TO aduanext_app;
GRANT EXECUTE ON FUNCTION set_app_bypass_rls(TEXT) TO aduanext_app;

ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS audit_events_tenant_select ON audit_events;
CREATE POLICY audit_events_tenant_select ON audit_events
  FOR SELECT
  USING (
    tenant_id = current_app_tenant()
    OR current_setting('app.bypass_rls', true) = 'admin'
  );

DROP POLICY IF EXISTS audit_events_tenant_insert ON audit_events;
CREATE POLICY audit_events_tenant_insert ON audit_events
  FOR INSERT
  WITH CHECK (
    tenant_id = current_app_tenant()
  );

-- Append-only: no UPDATE / DELETE policies. With RLS enabled + FORCE
-- on, absence of a policy means "deny" for those verbs.
