# Data Retention Policy

**Status:** Approved (VRTV-57)
**Last reviewed:** 2026-04-13
**Legal basis:** LGA Art. 30.b (Ley 7557, Costa Rica) — auxiliares de
funcion publica must preserve operational records for at least 5 years,
longer if any administrative or judicial proceeding is pending.

## Why this policy exists

Without a written, code-enforced retention policy AduaNext cannot:

- Respond to a DGA fiscalizacion request that reaches back ≥5 years.
- Bound tenant-side storage costs at scale.
- Prove to a tenant that we will neither delete data prematurely nor
  retain it beyond what regulation requires.

This policy is the source of truth. The retention worker
(`apps/server/lib/src/workers/retention_worker.dart`) and its
underlying `PurgeExpiredRecordsHandler` enforce it daily.

## Retention table

| category                    | legal minimum | platform default | tenant override allowed | rationale |
|-----------------------------|---------------|------------------|-------------------------|-----------|
| `auditEvent`                | 5 years       | **7 years**      | extend only             | LGA Art. 30.b plus a 2-year buffer |
| `duaSubmission`             | 5 years       | **7 years**      | extend only             | matches audit chain so chain integrity survives |
| `classificationDecision`    | 5 years       | 5 years          | extend only             | tied to DUA |
| `userSessionLog`            | 90 days       | 90 days          | extend only             | non-compliance — debugging only |
| `validationOutcome`         | 1 year        | 1 year           | extend only             | non-compliance — debugging only |
| `notificationReceipt`       | 1 year        | 1 year           | extend only             | proof-of-delivery for SLAs |

Tenants may NEVER reduce a category below its `legal minimum`. Attempting
to do so via `RetentionPolicy.withTenantOverride` raises
`ArgumentError`.

## Lifecycle

```
┌──────────┐  created_at + window  ┌────────────┐
│  active  │ ────────────────────▶ │  expired   │
└──────────┘                       └─────┬──────┘
                                         │
                                         ▼
                          ┌──────────────────────────────┐
                          │ legal_holds.is_active(...)?  │
                          └──┬────────────────────────┬──┘
                       NO ─┘                          └─ YES
                          ▼                              ▼
                ┌──────────────────┐          ┌────────────────┐
                │ archive to       │          │ skip — record  │
                │ StorageBackend   │          │ stays live     │
                └────────┬─────────┘          └────────────────┘
                         ▼
                ┌──────────────────┐
                │ purge from live  │
                │ store            │
                └────────┬─────────┘
                         ▼
                ┌──────────────────┐
                │ tombstone audit  │
                │ event appended   │
                └──────────────────┘
```

## Legal holds

A `LegalHold` pauses purges for a specific `(tenantId, entityType,
entityId)` triple. Use cases:

- DGA opens a fiscalizacion case touching a particular DUA → admin
  places a hold on `('Declaration', 'DUA-2026-NNN')`.
- A tenant disputes an HS classification at TICA → hold the
  classification decision and any related declarations.

Holds are tenant-scoped — a hold in tenant A never affects tenant B.
Releasing a hold does NOT reset `created_at`; the next worker pass
re-evaluates the original retention window (so a record held for 2 years
during a 7-year window has 5 years of remaining live storage).

Setting and releasing a hold is itself an audit event.

## Worker

- Schedule: daily at **03:00 UTC** (per VRTV-57 acceptance).
- Implementation: `Timer.periodic(60s)` checking the wall clock.
  Concurrency: only one run in flight; subsequent ticks skip until the
  in-flight run completes.
- Errors: per-record failures are caught and counted; the worker NEVER
  aborts the whole run on one bad record.
- Manual trigger: `RetentionWorker.runNow()` — used by ops tooling and
  tests.

## Archive layout

`FilesystemArchiveAdapter` (placeholder for S3 / GCS / MinIO) writes:

```
{rootPath}/{category}/{tenantId}/{year}/{entityType}/{entityId}.json
{rootPath}/{...same path...}.meta.json    ← contentType + metadata + archivedAt
```

The path layout deliberately puts `tenantId` second so a future
multi-bucket sharding (one bucket per tenant) is a path-prefix swap.

## Restore from archive

Out of scope for VRTV-57. Tracked separately under audit-export work
(VRTV-67/68). The archive layout + metadata sidecars give that future
adapter everything it needs to reconstruct the audit chain context.

## Runtime configuration (VRTV-74)

The retention worker is wired in `apps/server` and reads its knobs
from environment variables. It stays OFF by default — operators must
opt in explicitly.

| Variable | Default | Description |
| --- | --- | --- |
| `ADUANEXT_RETENTION_ENABLED` | `false` | Master switch. `true` wires the worker into `AppContainer`. |
| `ADUANEXT_RETENTION_AUDIT_YEARS` | `7` | Audit-event retention window. Rejected at boot if < 5 (LGA floor). |
| `ADUANEXT_RETENTION_DUA_YEARS` | `7` | DUA submission retention. Same 5-year floor. |
| `ADUANEXT_RETENTION_SESSION_DAYS` | `90` | Session log retention (no legal floor). |
| `ADUANEXT_RETENTION_RUN_AT_UTC` | `03:00` | Daily run time in UTC, `HH:MM`. |
| `ADUANEXT_ARCHIVE_PATH` | `/var/aduanext/archive` | Filesystem archive root (placeholder until S3/GCS adapters land). |

The worker also requires `ADUANEXT_POSTGRES_URL` — without a
Postgres audit log there is nothing to purge. With the flag off the
server still exposes `LegalHoldPort` via the in-memory adapter so
SubmitDeclarationHandler's hold-aware paths keep functioning.

### Lifecycle

1. `bin/server.dart` builds [`AppContainer`]; if the retention flag
   is set it constructs a [`RetentionWorker`] backed by a
   [`PostgresAuditRetentionAdapter`], [`FilesystemArchiveAdapter`] and
   the [`PostgresLegalHoldAdapter`].
2. After HTTP boot the worker is `start()`-ed. It runs once per day
   at the configured UTC time; missed runs catch up on the next tick.
3. On SIGINT/SIGTERM the worker is `stop()`-ed (awaits in-flight) and
   the Postgres connections close cleanly.

### Chain integrity

Per SPIKE-002 the worker uses the **cold-archive + tombstone** model:

1. Dump the entity's full audit chain as canonical JSON via
   `serializeForArchive`.
2. `putBytes` to the archive with the metadata sidecar.
3. DELETE every row for the entity from `audit_events`.
4. Append a fresh `RetentionPurge` event at `sequence_number = 0`
   with payload `{archivedCount, cutoffDate, category,
   originalCreatedAt, originalNewestAt}`. The tombstone's
   `previous_hash` is the genesis hash for the `(entity_type,
   entity_id)` chain, so `verifyChainIntegrity` reports the new
   single-event chain as valid.

## Out of scope

- Per-provider cold storage adapters (S3 / GCS / MinIO) — separate
  issues, one per provider.
- Tenant UI for retention configuration — separate issue.
- Hot-path query optimisation for archived data (the live path simply
  does not see archived rows once purged).

## Production deployment — dedicated Postgres role (VRTV-75)

The RetentionWorker runs with a **narrow, dedicated** Postgres role
(`aduanext_retention_worker`) in production. It cannot `DROP TABLE`,
cannot `INSERT INTO audit_events` (that path goes through the normal
`AuditLogPort` with the chain hasher), and cannot bypass Row-Level
Security invisibly.

### Bootstrap (one-time, per environment)

The role + grants are installed by the embedded migration
`retention_worker_role_migration.dart` (SQL source:
`libs/adapters/lib/src/retention/migrations/0002_retention_worker_role.sql`).
`AppContainer.boot()` applies it automatically against the privileged
container connection before opening the worker's narrow connection.

Privileges granted:

| Table          | Grants                        |
| -------------- | ----------------------------- |
| `audit_events` | `SELECT`, `DELETE`            |
| `legal_holds`  | `SELECT`, `INSERT`, `UPDATE`  |
| (functions)    | `set_app_bypass_rls`, `set_app_tenant`, `current_app_tenant` |

Privileges NOT granted (enforced by absent grants + NOBYPASSRLS):

- No `INSERT` / `UPDATE` / `TRUNCATE` on `audit_events`.
- No `DELETE` on `legal_holds` (append-only with `released_at`).
- No `BYPASSRLS` — cross-tenant iteration happens via the audited
  `app.bypass_rls='admin'` GUC (VRTV-62).

### Connection string

Set `ADUANEXT_RETENTION_DB_URL` to a URL authenticating as the role:

```
ADUANEXT_RETENTION_DB_URL=postgres://aduanext_retention_worker:<password>@db:5432/aduanext
```

The boot sequence logs a warning if the variable is unset and
falls back to the main `DATABASE_URL` — acceptable for dev,
**not acceptable in production**.

### Password management

Rotate the role's password via `setRetentionWorkerRolePassword(conn,
password:)` called from your deployment orchestration (helm post-install
hook / ArgoCD job). The Dart helper validates the password shape
(rejects empty / control-char values) and issues an idempotent
`ALTER ROLE ... PASSWORD '...'`.

In Kubernetes, store the password in a `Secret` referenced by the
server Deployment env var `ADUANEXT_RETENTION_DB_URL`:

```yaml
env:
  - name: ADUANEXT_RETENTION_DB_URL
    valueFrom:
      secretKeyRef:
        name: aduanext-retention-db
        key: url
```

### Audit attribution

Every action taken by the worker is attributed in the tombstone
payload with `actor = "system.retention_worker"` so DGA auditors can
distinguish automated purges from manual admin bypasses.

## Acceptance criteria pinned by tests

- `purge_expired_records_handler_test.dart` covers archive + purge +
  tombstone, legal-hold skip, partial failure isolation, the
  release-then-purge transition, AND the cutoff-plumbing contract
  (VRTV-76).
- `filesystem_archive_adapter_test.dart` covers blob + meta sidecar,
  idempotent write, refusal to overwrite different bytes, and `..` /
  absolute path rejection.
- `retention_worker_test.dart` covers `runNow` end-to-end and idempotent
  start / clean stop.
- `retention_worker_role_migration_test.dart` (VRTV-75) locks the
  grant table: NOBYPASSRLS, NOINHERIT, SELECT+DELETE on
  `audit_events`, SELECT+INSERT+UPDATE on `legal_holds`, no DELETE on
  `legal_holds`, idempotent CREATE/ALTER.
