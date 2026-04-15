/// Embedded migration 0002 — Tenant isolation via Postgres RLS.
///
/// The canonical source of truth is the sibling `0002_tenant_isolation.sql`
/// file — this Dart list of statements lets the adapter ship the
/// migration without depending on filesystem layout (important for
/// AOT-compiled server binaries). The postgres Dart driver does not
/// accept multi-statement batches on a prepared statement, so each
/// statement is issued separately. Keep the two files in sync.
library;

/// All migration statements, applied in order. Every statement is
/// idempotent.
const List<String> tenantIsolationMigrationStatements = [
  // 1. Create / reset the non-bypassing app role.
  r'''
DO $outer$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'aduanext_app') THEN
    CREATE ROLE aduanext_app NOLOGIN NOBYPASSRLS;
  ELSE
    ALTER ROLE aduanext_app NOBYPASSRLS;
  END IF;
END
$outer$
''',

  // 2. Grants for the app role.
  'GRANT SELECT, INSERT ON TABLE audit_events TO aduanext_app',
  'GRANT USAGE, SELECT ON SEQUENCE audit_events_id_seq TO aduanext_app',

  // 3. Enforce NOT NULL on tenant_id (guard — the base schema already
  //    declares NOT NULL, but older deployments may lack it).
  r'''
DO $ensure_not_null$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'audit_events' AND column_name = 'tenant_id'
      AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE audit_events ALTER COLUMN tenant_id SET NOT NULL;
  END IF;
END
$ensure_not_null$
''',

  // 4. Index for fiscalizador-style (tenant + entity) scans.
  '''
CREATE INDEX IF NOT EXISTS idx_audit_events_tenant_entity
  ON audit_events (tenant_id, entity_type, entity_id)
''',

  // 5. Session GUC helper functions.
  r'''
CREATE OR REPLACE FUNCTION set_app_tenant(p_tenant_id TEXT)
RETURNS VOID AS $fn$
BEGIN
  PERFORM set_config('app.current_tenant_id', p_tenant_id, true);
END;
$fn$ LANGUAGE plpgsql
''',
  r'''
CREATE OR REPLACE FUNCTION current_app_tenant()
RETURNS TEXT AS $fn$
BEGIN
  RETURN NULLIF(current_setting('app.current_tenant_id', true), '');
END;
$fn$ LANGUAGE plpgsql
''',
  r'''
CREATE OR REPLACE FUNCTION set_app_bypass_rls(p_flag TEXT)
RETURNS VOID AS $fn$
BEGIN
  PERFORM set_config('app.bypass_rls', p_flag, true);
END;
$fn$ LANGUAGE plpgsql
''',

  // 6. Function grants.
  'GRANT EXECUTE ON FUNCTION set_app_tenant(TEXT) TO aduanext_app',
  'GRANT EXECUTE ON FUNCTION current_app_tenant() TO aduanext_app',
  'GRANT EXECUTE ON FUNCTION set_app_bypass_rls(TEXT) TO aduanext_app',

  // 7. Enable + FORCE RLS so table-owner and app role both honour it.
  'ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY',
  'ALTER TABLE audit_events FORCE ROW LEVEL SECURITY',

  // 8. SELECT + INSERT policies.
  'DROP POLICY IF EXISTS audit_events_tenant_select ON audit_events',
  r'''
CREATE POLICY audit_events_tenant_select ON audit_events
  FOR SELECT
  USING (
    tenant_id = current_app_tenant()
    OR current_setting('app.bypass_rls', true) = 'admin'
  )
''',
  'DROP POLICY IF EXISTS audit_events_tenant_insert ON audit_events',
  r'''
CREATE POLICY audit_events_tenant_insert ON audit_events
  FOR INSERT
  WITH CHECK (
    tenant_id = current_app_tenant()
  )
''',
];
