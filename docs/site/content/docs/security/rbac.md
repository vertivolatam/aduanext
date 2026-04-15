# RBAC + multi-tenant isolation

AduaNext enforces role-based access control (RBAC) on a **per-tenant**
basis. Every write path in the application layer goes through an
`AuthorizationPort` checkpoint before touching business state.

This document covers the domain model landed in [VRTV-55](https://linear.app/vertivolatam/issue/VRTV-55).
The production Keycloak integration, server middleware, and Postgres
row-level security ship in follow-up sub-issues VRTV-55b / -55c / -55d.

## Why

LGA Art. 28–30 requires that each *auxiliar de función pública* is
identified and that their actions are attributable. Without RBAC + tenant
isolation we cannot prove:

> *"agent X acted on behalf of importer Y at time Z, and they held the
> required licence at that moment."*

Multi-tenancy is also the foundation of the revenue model — agencies,
freelance agents, and importer-led pymes all pay for tenant-scoped
workspaces. Cross-tenant data leakage is a revenue *and* compliance P0.

## Domain model

```
User 1 ──< N TenantMembership >── 1 Tenant
                 │
                 └── Role (level: int, code: string)
```

### Roles

Ordered by privilege (least → most privileged *within a tenant*):

| code | level | who | what they can do |
|---|---:|---|---|
| `fiscalizador` | 0 | DGA sandbox observer | read declarations + audit events |
| `importer` | 10 | pyme employee | prepare draft declarations; cannot sign |
| `agent` | 20 | licensed customs agent | prepare, sign, and submit DUAs |
| `supervisor` | 30 | agency supervisor | manage junior agents within the agency |
| `admin` | 40 | tenant owner | manage members + billing |

`Role.satisfies(minimum)` answers "is this role at least as privileged as
`minimum`?". An `admin` satisfies every role below them; an `importer`
satisfies only `importer` and `fiscalizador`.

### Tenant types

| type | example |
|---|---|
| `agency` | *"Agencia Aduanal Alfa S.A."* — multiple agents |
| `freelanceAgent` | a solo licensed agent |
| `importerLed` | a pyme using the importer-led mode |
| `educational` | a university using the training sandbox |

### TenantMembership

Links a user to a tenant with a **time window** and a role. The window
is `[since, expires)` — expired memberships are rejected even if the
JWT still carries them (defense in depth against stale tokens).

## Enforcement layers

Three layers defend against cross-tenant access:

1. **Application** — every handler calls
   `authorization.requireTenant(command.tenantId)` followed by
   `authorization.requireRole(Role.agent)` *before* touching state.
   Violations throw `AuthorizationException` which the boundary
   translates to HTTP 403.
2. **Infrastructure** — Postgres row-level security policies key every
   query on `tenant_id`. Ships in VRTV-55d.
3. **Audit** — every `AuditEvent` carries `tenantId` and the
   `actorRole` is stitched into the payload so forensics can reconstruct
   *"who acted, in what role, under what tenant"*.

## Mapping to use cases

| use case | requires | enforced by |
|---|---|---|
| `RecordClassification` | `agent`+ in command.tenantId | `RecordClassificationHandler` |
| `SubmitDeclaration` | `agent`+ in command.tenantId | `SubmitDeclarationHandler` |

An `importer` attempting classification or submission gets `role-denied`.
An agent from tenant A attempting to submit a declaration with
`tenantId: 'B'` gets `tenant-denied`.

## Postgres Row-Level Security (defense in depth)

Landed in VRTV-62. Every tenant-scoped table (today: `audit_events`;
future: declarations, classifications, attachments) is protected by
Postgres RLS policies that key on a session-local GUC:
`app.current_tenant_id`. The `PostgresAuditLogAdapter` sets this GUC
automatically on every `append()` (transaction-scoped); middleware-
owned sessions set it with a session-scoped call at request entry.

### Architecture

```
                              ┌──────────────────────────┐
   shelf request  ──▶ auth    │ 1. authMiddleware sets   │
                              │    app.current_tenant_id │
                              └─────────────┬────────────┘
                                            │
                              ┌─────────────▼────────────┐
                              │ 2. handler calls         │
                              │    AuditLogPort.append() │
                              └─────────────┬────────────┘
                                            │
                              ┌─────────────▼────────────┐
                              │ 3. Postgres RLS compares │
                              │    row tenant_id ==      │
                              │    current_app_tenant()  │
                              └──────────────────────────┘
```

### Helpers

The migration creates three PL/pgSQL functions:

- `set_app_tenant(p_tenant_id TEXT)` — writes `app.current_tenant_id`.
- `current_app_tenant()` — reads it (returns `NULL` when unset).
- `set_app_bypass_rls(p_flag TEXT)` — writes `app.bypass_rls`; set to
  `'admin'` for cross-tenant reads (fiscalizador export).

### Policies

| verb | policy | predicate |
|---|---|---|
| SELECT | `audit_events_tenant_select` | `tenant_id = current_app_tenant() OR app.bypass_rls = 'admin'` |
| INSERT | `audit_events_tenant_insert` | `tenant_id = current_app_tenant()` |
| UPDATE / DELETE | *(no policy — denied)* | — |

With `FORCE ROW LEVEL SECURITY` on, even the table owner honours the
policies. Postgres superusers (and any role with `BYPASSRLS`) still
bypass — in production, `aduanext_app` is a `NOBYPASSRLS` role created
by the migration; middleware connects as that role via
`SET ROLE aduanext_app` (or uses a login role that inherits from it).

### Admin bypass

Some endpoints (fiscalizador audit export, support tooling) need
cross-tenant reads. The adapter exposes `setSessionAdminBypass(true)`
which flips `app.bypass_rls = 'admin'`. Callers MUST:

1. Verify the actor holds `Role.admin` or `Role.fiscalizador` in
   the current tenant.
2. Audit-log the bypass itself BEFORE flipping the flag.
3. Clear the flag after the privileged read completes.

### Usage for custom adapters

Future tables (`declarations`, `classifications`, …) should copy the
same pattern:

```sql
ALTER TABLE declarations ENABLE ROW LEVEL SECURITY;
ALTER TABLE declarations FORCE ROW LEVEL SECURITY;

CREATE POLICY declarations_tenant_select ON declarations
  FOR SELECT USING (tenant_id = current_app_tenant());

CREATE POLICY declarations_tenant_insert ON declarations
  FOR INSERT WITH CHECK (tenant_id = current_app_tenant());

GRANT SELECT, INSERT ON TABLE declarations TO aduanext_app;
```

Adapters that call into these tables MUST call
`setSessionTenant(tenantId)` on every operation (the
`PostgresAuditLogAdapter` does this for you on `append`).

## Roadmap

| sub-issue | scope | status |
|---|---|---|
| VRTV-55 | domain model + `AuthorizationPort` + `InMemoryAuthorizationAdapter` + handler integration | Done |
| VRTV-60 | `KeycloakAuthorizationAdapter` — JWT verification + custom claim mapping | Done |
| VRTV-61 | `apps/server` middleware + role guards + route table | Done |
| VRTV-62 (this) | Postgres RLS on `audit_events` + `set_app_tenant()` | Done |

## Out of scope (separate issues)

- Self-service tenant creation
- User onboarding UI
- Agency invitation flow

All three depend on the RBAC contract landing first.
