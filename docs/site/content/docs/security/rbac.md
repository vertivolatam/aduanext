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

## Roadmap

| sub-issue | scope |
|---|---|
| VRTV-55 (this) | domain model + `AuthorizationPort` + `InMemoryAuthorizationAdapter` + handler integration |
| VRTV-55b | `KeycloakAuthorizationAdapter` — JWT signature verification + custom claim mapping (`aduanext_tenant_ids`, `aduanext_roles`) |
| VRTV-55c | `apps/server` middleware wiring Keycloak + a route table |
| VRTV-55d | Postgres row-level security on `audit_events` + `set_app_tenant(uuid)` function |

## Out of scope (separate issues)

- Self-service tenant creation
- User onboarding UI
- Agency invitation flow

All three depend on the RBAC contract landing first.
