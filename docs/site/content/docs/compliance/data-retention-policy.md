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

## Out of scope

- Per-provider cold storage adapters (S3 / GCS / MinIO) — separate
  issues, one per provider.
- Tenant UI for retention configuration — separate issue.
- Hot-path query optimisation for archived data (the live path simply
  does not see archived rows once purged).

## Acceptance criteria pinned by tests

- `purge_expired_records_handler_test.dart` covers archive + purge +
  tombstone, legal-hold skip, partial failure isolation, and the
  release-then-purge transition.
- `filesystem_archive_adapter_test.dart` covers blob + meta sidecar,
  idempotent write, refusal to overwrite different bytes, and `..` /
  absolute path rejection.
- `retention_worker_test.dart` covers `runNow` end-to-end and idempotent
  start / clean stop.
