-- Migration 0001 (retention) — legal_holds table + RLS.
--
-- Purpose: persist `LegalHold` instances produced by the VRTV-57
-- retention subsystem. Every write / read is tenant-scoped. We rely
-- on the same `current_app_tenant()` / `set_app_tenant()` helpers
-- installed by the audit-log migration 0002 (see
-- `lib/src/audit/migrations/0002_tenant_isolation.sql`). This file
-- therefore MUST be applied AFTER that migration; the retention
-- adapter's `ensureSchema()` guarantees the ordering.
--
-- Primary key is the surrogate `id` (UUID as TEXT to avoid pulling in
-- the `uuid-ossp` extension just for this table). Logical identity is
-- `(tenant_id, entity_type, entity_id, set_at)`; the partial unique
-- index below forbids two ACTIVE holds for the same
-- `(tenant_id, entity_type, entity_id)` coordinates.
--
-- Idempotent: every statement is safe to run on an already-migrated
-- database. The Dart adapter's `ensureSchema()` runs it at every boot.
--
-- References: VRTV-57 (retention policy), VRTV-62 (RLS pattern),
-- VRTV-73 (this migration).

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
);

-- Partial unique index: at most one ACTIVE hold per entity.
CREATE UNIQUE INDEX IF NOT EXISTS idx_legal_holds_active_unique
  ON legal_holds (tenant_id, entity_type, entity_id)
  WHERE released_at IS NULL;

-- Query-path index for admin history / fiscalizador audit export.
CREATE INDEX IF NOT EXISTS idx_legal_holds_tenant_set_at
  ON legal_holds (tenant_id, set_at DESC);

-- Grants: the non-bypassing app role (created by audit migration 0002)
-- needs SELECT / INSERT / UPDATE. No DELETE — holds are append-only
-- with a release transition; hard deletes would corrupt the audit
-- trail.
GRANT SELECT, INSERT, UPDATE ON TABLE legal_holds TO aduanext_app;

-- Enforce NOT NULL on tenant_id (already declared above, this is a
-- belt-and-braces guard for older deployments).
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
$ensure_not_null$;

-- Enable + FORCE RLS.
ALTER TABLE legal_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_holds FORCE ROW LEVEL SECURITY;

-- SELECT policy: own tenant OR admin-bypass.
DROP POLICY IF EXISTS legal_holds_tenant_select ON legal_holds;
CREATE POLICY legal_holds_tenant_select ON legal_holds
  FOR SELECT
  USING (
    tenant_id = current_app_tenant()
    OR current_setting('app.bypass_rls', true) = 'admin'
  );

-- INSERT policy: new row MUST carry the caller's tenant.
DROP POLICY IF EXISTS legal_holds_tenant_insert ON legal_holds;
CREATE POLICY legal_holds_tenant_insert ON legal_holds
  FOR INSERT
  WITH CHECK (tenant_id = current_app_tenant());

-- UPDATE policy: only the owning tenant may release a hold, and the
-- UPDATE must preserve the tenant_id (WITH CHECK prevents
-- cross-tenant rewrites even via direct SQL).
DROP POLICY IF EXISTS legal_holds_tenant_update ON legal_holds;
CREATE POLICY legal_holds_tenant_update ON legal_holds
  FOR UPDATE
  USING (tenant_id = current_app_tenant())
  WITH CHECK (tenant_id = current_app_tenant());
