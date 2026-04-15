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

## Tests

```bash
dart test
```

Unit tests use fake `Port` implementations — no Postgres or gRPC required.
Integration tests against the real stack live with their use cases (see
`libs/application/test/` and the end-to-end harness in `apps/hacienda-sidecar`).
