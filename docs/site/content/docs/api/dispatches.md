+++
title = "Dispatch REST API"
weight = 10
+++

# Dispatch REST API (`/api/v1/dispatches`)

Versioned endpoints that wire the North Star **SubmitDeclaration** use
case to Flutter Web (and any other HTTP client). Introduced in VRTV-79.

All endpoints are **authenticated** (Keycloak-issued JWT in
`Authorization: Bearer ...`) and **tenant-scoped** (`X-Tenant-Id`
header). See `docs/security/authentication.md` for the auth contract.

## Endpoints

| Method | Path                                    | Roles                     | Status        |
| ------ | --------------------------------------- | ------------------------- | ------------- |
| POST   | `/api/v1/dispatches/submit`             | agent, importer*          | Implemented   |
| POST   | `/api/v1/dispatches/{id}/rectify`       | agent, supervisor         | 501 (VRTV-48) |
| GET    | `/api/v1/dispatches/{id}`               | agent, importer, supervisor, admin | 501 (VRTV-45) |
| GET    | `/api/v1/dispatches`                    | agent, importer, supervisor, admin | 501 (VRTV-45) |

\* The submit handler additionally enforces `Role.agent` inside the use
case — an importer reaching the endpoint receives a 403
`INSUFFICIENT_ROLE`. Only licensed customs agents (LGA Art. 28) may
sign and transmit a DUA.

## `POST /api/v1/dispatches/submit`

Prepare, sign, and transmit a DUA to ATENA. Orchestrates the 4-step
ATENA flow behind a single request:

1. ATENA authentication (`authCredentials`)
2. Dry-run validation
3. Digital signature (software `.p12` OR hardware PKCS#11)
4. Submission (liquidation)

Every step writes to the tamper-evident audit chain (SRD rule 4).

### Request

```http
POST /api/v1/dispatches/submit HTTP/1.1
Authorization: Bearer <jwt>
X-Tenant-Id: <tenant-id>
Content-Type: application/json

{
  "declarationId": "uuid",
  "declaration": { ...ATENA DUA fields... },
  "credentials": {
    "type": "software",
    "atenaIdType": "02",
    "atenaIdNumber": "310100975830",
    "atenaPassword": "...",
    "atenaClientId": "atena-client",
    "p12Base64": "...",
    "p12Pin": "..."
  }
}
```

For hardware PKCS#11 tokens (BCCR Firma Digital USB keys) the
`credentials` block is:

```json
{
  "type": "hardware",
  "atenaIdType": "02",
  "atenaIdNumber": "310100975830",
  "atenaPassword": "...",
  "pkcs11ModulePath": "/usr/lib/x64-athena/ASEP11.so",
  "slotId": 0,
  "pin": "1234"
}
```

Size limit: **2 MiB**. Larger bodies → `413 PAYLOAD_TOO_LARGE`.

### Success response

```json
{
  "declarationId": "uuid",
  "status": "accepted",
  "customsRegistrationNumber": "CR-2026-001",
  "assessmentSerial": "...",
  "assessmentNumber": 1234,
  "assessmentDate": "2026-04-13"
}
```

### Error codes

| Failure                              | Status | `code`                    |
| ------------------------------------ | ------ | ------------------------- |
| Missing / empty required field       | 422    | `PRE_VALIDATION_FAILED`   |
| Invalid declaration structure        | 422    | `PRE_VALIDATION_FAILED`   |
| Pre-submission rule-engine error     | 422    | `PRE_VALIDATION_FAILED`   |
| ATENA rejected authentication        | 502    | `ATENA_AUTH_FAILED`       |
| ATENA rejected validation            | 422    | `ATENA_VALIDATION_FAILED` |
| Signing failure                      | 500    | `SIGNING_FAILED`          |
| ATENA rejected submission            | 502    | `ATENA_SUBMISSION_FAILED` |
| Hardware helper not configured       | 503    | `HARDWARE_UNAVAILABLE`    |
| Unknown JSON / bad request           | 400    | `MALFORMED_REQUEST`       |
| Body > 2 MiB                         | 413    | `PAYLOAD_TOO_LARGE`       |
| Rate limit exceeded                  | 429    | `RATE_LIMITED`            |
| Missing `Authorization`              | 401    | `MISSING_TOKEN`           |
| Expired / invalid JWT                | 401    | `EXPIRED_TOKEN` / `INVALID_TOKEN` |
| Caller not a member of target tenant | 403    | `WRONG_TENANT`            |
| Caller lacks required role           | 403    | `INSUFFICIENT_ROLE`       |

All error bodies share the shape:

```json
{
  "error": "validation_failed",
  "code": "ATENA_VALIDATION_FAILED",
  "message": "...",
  "request_id": "req_3b1c",
  "details": { ... optional ... }
}
```

`details` is populated for validation failures (ATENA-side errors +
warnings) and for pre-validation reports (one-line summary). It is
**never** populated with stack traces, adapter diagnostics, or
credentials.

### Rate limiting

- 10 submits / minute / tenant (token bucket, burst capacity 10).
- Per-tenant — NAT-shared agents are not bucketed together.
- Response headers on every pass-through:
  - `X-RateLimit-Limit: 10`
  - `X-RateLimit-Remaining: <n>`
- On 429: `Retry-After: <seconds>`.

### Security posture

- The PIN and p12 bytes are **never** logged.
- Infrastructure errors (gRPC timeout, Postgres disconnect) propagate
  as exceptions and surface as generic `500 INTERNAL_ERROR` — the
  specific failure is only in the server logs + audit trail.
- `requestId` is generated by the auth middleware (or propagated from
  an upstream `X-Request-Id`) and is echoed in every response body so
  clients can correlate with server logs.

## `POST /api/v1/dispatches/{id}/rectify`

Placeholder. Tracked as VRTV-48. Returns `501 NOT_IMPLEMENTED`.

## `GET /api/v1/dispatches/{id}` and `GET /api/v1/dispatches`

Placeholders. Tracked as VRTV-45 (dashboard + read model). Return `501
NOT_IMPLEMENTED`.

## Deprecated v0 paths

`/api/dispatches/*` is kept as a 501 shim for one release while clients
migrate to `/api/v1`. Remove by end of the current milestone.

## References

- Submit use case: `libs/application/lib/src/submission/submit_declaration_handler.dart`
- Error mapping: `apps/server/lib/src/http/error_mapping.dart`
- Rate limiter: `apps/server/lib/src/middleware/rate_limiter.dart`
- Request DTO: `apps/server/lib/src/http/dispatch_payload.dart`
