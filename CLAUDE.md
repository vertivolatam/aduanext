# CLAUDE.md — AduaNext

## Project Overview

AduaNext is a multi-tenant customs compliance platform for LATAM, starting with Costa Rica (ATENA integration). Hybrid stack: Serverpod (Dart) + hacienda-cr gRPC sidecar (TypeScript) + agentic-core (Python). Architecture: Explicit Architecture (Herberto Graca).

## Commands

```bash
# Domain layer
cd libs/domain && dart pub get && dart test

# Proto compilation
protoc --dart_out=grpc:apps/server/lib/src/generated libs/proto/hacienda.proto

# Sidecar
cd apps/hacienda-sidecar && npm install && npm run build && npm test
```

## Architecture

- `libs/domain/` — Pure Dart, ZERO I/O dependencies. Entities, Value Objects, Ports, Domain Services.
- `libs/application/` — Use Cases, Commands, Queries, CountryAdapterFactory. Depends only on domain.
- `libs/adapters/` — ATENA, RIMM, signing, notifications, persistence. Implements domain Ports.
- `apps/server/` — Serverpod. Primary adapters (REST endpoints). Wires everything via DI.
- `apps/hacienda-sidecar/` — TypeScript gRPC. Auth (OIDC), XAdES signing, ATENA proxy.
- `libs/proto/hacienda.proto` — 4 gRPC services: HaciendaAuth, HaciendaSigner, HaciendaApi, HaciendaOrchestrator.

**Dependency flow:** apps/server -> libs/application -> libs/domain <- libs/adapters

## SRD Priority Rules

1. Never work on J05 (Sandbox Edu) or J06 (Vetted Sourcer) before J01 (DUA Export) and J07 (Auth) are at 100%.
2. Every implementation must use Port/Adapter pattern. Never import ATENA, RIMM, or hacienda-cr from domain or application layer.
3. Human-in-the-loop for tariff classification is NOT negotiable. Never auto-submit an HS code without explicit agent confirmation.
4. Every classification, signing, and transmission decision must be logged in the audit trail with SHA-256 hash chain.
5. The gRPC sidecar (hacienda-cr) is imported as npm dependency, NEVER forked.
6. Prioritize P03 (Andrea, pyme) over P01 (Maria, agency) in UX decisions.
7. Always use exact ATENA API field names in the domain model (camelCase, same names). Do not rename or translate.

## SRD Anti-Patterns

- Do NOT implement marketplace features (J06) before core customs flow (J01) works.
- Do NOT hardcode ATENA URLs in code — use CountryAdapterFactory + environment config.
- Do NOT bypass the sandbox proxy for direct ATENA production calls.
- Do NOT add I/O dependencies to libs/domain/ (check pubspec.yaml).
- Do NOT mutate classifications — use append-only pattern (new event per change).

## North Star

"Can a freelance agent prepare, sign, and transmit a complete DUA to ATENA using AduaNext, and can a pyme monitor the status in real-time?"

Current answer: No.

## Key References

- ATENA DUA API: docs/references/SIAA-ATENA-DUA-GUIA-TECNICA.pdf (104 pages)
- RIMM API: docs/references/SIAA-ATENA-Especificacion-Tecnica-RIMM-Arancel.pdf (26 pages)
- Export Procedures: docs/references/Procedimientos-Exportacion-ATENA.pdf (64 pages)
- SRD: srd/SRD.md | Business Model: business/README.md
- hacienda-cr SDK: github.com/DojoCodingLabs/hacienda-cr (npm: @dojocoding/hacienda-sdk)

## Application Layer Conventions

- CQRS: every write is a `Command<TResult>` handled by a `CommandHandler<TCmd, TResult>`. Queries follow the same shape in separate files.
- Hybrid error model: `Result<T>` (sealed `Ok`/`Err`) for expected business errors (validation, rule violations, business "not found"). Typed exceptions for infrastructure failures (DB down, port unavailable) — the boundary (Serverpod endpoint) catches those.
- Vertical slice layout under `libs/application/lib/src/<feature>/`: command, handler, failure, and (future) queries live together. Shared primitives (`Command`, `Result`, `Failure`) live under `src/shared/`.
- Handlers take Ports (from `libs/domain`) by constructor injection. Tests use `InMemoryAuditLogAdapter` from `aduanext_adapters` (dev dep) to exercise the contract without I/O.
- Every classification/signing/transmission decision MUST log to `AuditLogPort` with a snapshot payload (SRD priority rule #4). Audit append failures propagate as exceptions — never swallow.

## Conventions

- Dart: snake_case files, PascalCase classes, camelCase functions
- TypeScript: kebab-case files, PascalCase classes, camelCase functions
- Proto: snake_case fields, PascalCase messages, PascalCase services
- Commits: conventional commits (feat/fix/chore/docs)
- Language: Code in English, docs/business in Spanish
