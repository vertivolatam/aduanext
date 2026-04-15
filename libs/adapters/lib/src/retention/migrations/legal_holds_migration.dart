/// Embedded migration 0001 (retention) — `legal_holds` table + RLS.
///
/// Canonical source of truth is the sibling
/// `0001_legal_holds.sql` file. This Dart list lets the adapter ship
/// the migration without reading the filesystem at runtime (matches
/// the audit-log `tenant_isolation_migration.dart` pattern — same
/// rationale: AOT-compiled server binaries can't rely on relative
/// asset paths). The Postgres Dart driver does not accept
/// multi-statement batches on a prepared statement, so each statement
/// is issued separately. Keep the two files in sync.
library;

/// All migration statements, applied in order. Every statement is
/// idempotent and assumes that audit-log migration 0002 has already
/// installed `current_app_tenant()`, `set_app_tenant()` and the
/// `aduanext_app` role.
const List<String> legalHoldsMigrationStatements = [
  // 1. Base table.
  '''
CREATE TABLE IF NOT EXISTS legal_holds (
  id                     TEXT         PRIMARY KEY,
  tenant_id              TEXT         NOT NULL,
  entity_type            TEXT         NOT NULL,
  entity_id              TEXT         NOT NULL,
  reason                 TEXT         NOT NULL,
  set_by_actor_id        TEXT         NOT NULL,
  set_at                 TIMESTAMPTZ  NOT NULL,
  released_at            TIMESTAMPTZ,
  released_by_actor_id   TEXT
)
''',

  // 2. Partial unique index — at most one active hold per entity.
  '''
CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_holds_active_unique
  ON legal_holds (tenant_id, entity_type, entity_id)
  WHERE released_at IS NULL
''',

  // 3. Admin / history index.
  '''
CREATE INDEX IF NOT EXISTS idx_legal_holds_tenant_set_at
  ON legal_holds (tenant_id, set_at DESC)
''',

  // 4. Grants for the non-bypassing app role. No DELETE — holds are
  //    append-only; release is an UPDATE.
  'GRANT SELECT, INSERT, UPDATE ON TABLE legal_holds TO aduanext_app',

  // 5. NOT NULL guard for older deployments.
  r'''
DO $ensure_not_null$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'legal_holds' AND column_name = 'tenant_id'
      AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE legal_holds ALTER COLUMN tenant_id SET NOT NULL;
  END IF;
END
$ensure_not_null$
''',

  // 6. Enable + FORCE RLS.
  'ALTER TABLE legal_holds ENABLE ROW LEVEL SECURITY',
  'ALTER TABLE legal_holds FORCE ROW LEVEL SECURITY',

  // 7. SELECT policy.
  'DROP POLICY IF EXISTS legal_holds_tenant_select ON legal_holds',
  r'''
CREATE POLICY legal_holds_tenant_select ON legal_holds
  FOR SELECT
  USING (
    tenant_id = current_app_tenant()
    OR current_setting('app.bypass_rls', true) = 'admin'
  )
''',

  // 8. INSERT policy.
  'DROP POLICY IF EXISTS legal_holds_tenant_insert ON legal_holds',
  r'''
CREATE POLICY legal_holds_tenant_insert ON legal_holds
  FOR INSERT
  WITH CHECK (tenant_id = current_app_tenant())
''',

  // 9. UPDATE policy.
  'DROP POLICY IF EXISTS legal_holds_tenant_update ON legal_holds',
  r'''
CREATE POLICY legal_holds_tenant_update ON legal_holds
  FOR UPDATE
  USING (tenant_id = current_app_tenant())
  WITH CHECK (tenant_id = current_app_tenant())
''',
];
