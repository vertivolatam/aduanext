# apps/server — AduaNext primary server

Shelf-based HTTP server that wires the domain `Port`s to concrete adapters
from `libs/adapters`. This is the Explicit-Architecture **primary adapter**:
all inbound traffic enters here and is dispatched to use cases in
`libs/application`.

Today the surface is intentionally small — only health probes — so the
subsequent use-case issues (VRTV-38 submit declaration, VRTV-42
pre-validation, VRTV-55 RBAC, ...) can land incrementally without churn.

## Why `shelf` and not full Serverpod?

Serverpod ships its own ORM, code generator, and scaffolding. The re-scoped
[VRTV-37](https://linear.app/vertivolatam/issue/VRTV-37) calls for just a
skeleton + DI + health endpoint + smoke test, so a hand-wired `shelf`
server is ~1/10 the footprint and keeps the dependency flow obvious. If we
later decide we want Serverpod's ORM / realtime / module ecosystem, the
public REST contract is identical — migration is mechanical.

## Running locally

```bash
# 1. Start Postgres + redis (port 8190 / 8191 for dev).
make db-up

# 2. Start the hacienda-sidecar gRPC server (port 50051).
cd apps/hacienda-sidecar && npm run dev

# 3. Run the server.
cd apps/server
dart pub get
ADUANEXT_POSTGRES_URL=postgres://postgres:$POSTGRES_PASSWORD@localhost:8190/aduanext \
  dart run bin/server.dart
```

Then:

```bash
curl http://localhost:8180/livez   # -> {"status":"alive"}
curl -i http://localhost:8180/readyz  # -> 200 if all deps are up, 503 otherwise
```

## Environment variables

| var | default | purpose |
|---|---|---|
| `ADUANEXT_HTTP_HOST` | `0.0.0.0` | bind address |
| `ADUANEXT_HTTP_PORT` | `8180` | HTTP port |
| `HACIENDA_SIDECAR_HOST` | `localhost` | gRPC sidecar host |
| `HACIENDA_SIDECAR_PORT` | `50051` | gRPC sidecar port |
| `HACIENDA_DEFAULT_CLIENT_ID` | *(none)* | Optional OIDC client id |
| `HACIENDA_P12_PATH` | *(none)* | Path to PKCS#12 cert — enables `SigningPort` |
| `HACIENDA_P12_PIN` | *(none)* | PIN for the cert above |
| `ADUANEXT_POSTGRES_URL` | *(none)* | `postgres://user:pass@host:port/db` — enables `PostgresAuditLogAdapter`; falls back to in-memory |
| `KEYCLOAK_JWKS_URI` | *(none)* | Keycloak JWKS URL, e.g. `https://keycloak.aduanext.cr/realms/aduanext/protocol/openid-connect/certs`. Required for protected routes — when unset, every protected route returns 503 (fail-closed). |
| `KEYCLOAK_ISSUER` | *(none)* | Expected `iss` claim, e.g. `https://keycloak.aduanext.cr/realms/aduanext` |
| `KEYCLOAK_AUDIENCE` | *(none)* | Expected `aud` claim — the Keycloak client id (typically `aduanext-server`) |

## Authentication & authorization

Every protected route flows through two layers:

1. **`authMiddleware`** — extracts `Authorization: Bearer <jwt>` and
   `X-Tenant-Id`, validates the JWT against Keycloak's JWKS (RS256, exp /
   nbf / issuer / audience), and attaches a `RequestContext` to the
   shelf `Request`. On failure it short-circuits with the standardized
   error JSON below.
2. **`roleGuard(Set<Role>)`** — enforces tenant membership and the
   per-route role allow-list. Honours role hierarchy:
   `fiscalizador < importer < agent < supervisor < admin`.

Public routes (`/livez`, `/readyz`) bypass both layers.

### Route table

The canonical table lives in `lib/src/http/routes.dart`. Each entry
declares the HTTP verb, the path, the allowed roles, and the handler.
Until the per-use-case handlers land (VRTV-38 etc.), each route returns
`501 Not Implemented` once the auth + role checks pass.

| route | required roles |
|---|---|
| `POST /api/dispatches/submit` | `agent` or `importer` |
| `POST /api/classifications/confirm` | `agent` or `supervisor` |
| `GET /api/dispatches/<id>` | `agent`, `importer`, `supervisor`, `admin` |
| `POST /api/dispatches/<id>/rectify` | `agent` or `supervisor` |
| `GET /api/audit/export` | `admin` or `fiscalizador` |

### Standardized error JSON

The frontend depends on the field names and the `code` enum — do not
rename without coordinating a client release.

```json
{
  "error": "authorization_failed",
  "code": "INSUFFICIENT_ROLE",
  "message": "This action requires one of: agent, supervisor",
  "request_id": "req_8c91..."
}
```

| HTTP | code | meaning |
|---|---|---|
| 401 | `MISSING_TOKEN` | No (or malformed) Authorization header |
| 401 | `INVALID_TOKEN` | Signature / claims invalid; or Keycloak rejected the token |
| 401 | `EXPIRED_TOKEN` | `exp` in the past |
| 400 | `WRONG_TENANT` | Missing `X-Tenant-Id` header |
| 403 | `WRONG_TENANT` | User has no active membership in the requested tenant |
| 403 | `INSUFFICIENT_ROLE` | User lacks any of the route's allowed roles |
| 503 | `AUTH_NOT_CONFIGURED` | Server has no `KEYCLOAK_*` env vars; fail-closed |

## Tests

```bash
dart test
```

Unit tests use fake `Port` implementations — no Postgres or gRPC required.
Integration tests against the real stack live with their use cases (see
`libs/application/test/` and the end-to-end harness in `apps/hacienda-sidecar`).
