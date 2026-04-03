# SPIKE 003: Cross-Border Multi-Hacienda LATAM Architecture

## User Story

**As** the AduaNext platform operator,
**I want** a multi-tenant architecture where each tenant represents a country's customs authority ("hacienda"), with the ability to deploy as a standalone SaaS or as a Kubernetes sidecar alongside existing agency systems,
**So that** customs agencies across Central America and LATAM can operate on a single platform while respecting each country's unique regulatory framework, authentication systems, tariff schedules, and data formats -- starting with Costa Rica (ATENA) and expanding through PDCC integration.

---

## Technical Objective

Design and validate a multi-hacienda architecture that:

1. Isolates country-specific customs logic (auth, tariffs, risk models, data schemas) without forking the codebase.
2. Supports two deployment modes -- Standalone SaaS and Sidecar/Plugin -- from a single artifact.
3. Enables cross-border document exchange (DUCA-F, DUCA-T) through PDCC with minimal per-country adapter code.
4. Allows onboarding a new Central American country in under 2 weeks of engineering effort.

---

## Acceptance Criteria

- [ ] Multi-tenant data isolation strategy is selected and documented with migration path.
- [ ] A `CountryProfile` configuration schema exists that captures auth protocol, data format, tariff source, risk model parameters, and VUCE endpoint per country.
- [ ] DUCA-F and DUCA-T canonical data models are defined, with bidirectional mapping adapters for Costa Rica (ATENA format).
- [ ] Sidecar container spec is defined: container image, exposed gRPC/REST interfaces, sync protocol, health probes.
- [ ] Standalone and Sidecar modes share a single core library (`@aduanext/core`) with mode-specific entry points.
- [ ] Country onboarding checklist is documented and tested by adding a second country (Guatemala) as a dry-run.
- [ ] PDCC integration contract is defined: message format, transport (likely AS4/ebMS), error handling, retry semantics.
- [ ] Feature flag system supports country-scoped and agency-scoped toggles.
- [ ] Audit trail covers cross-border operations with immutable, append-only logging.
- [ ] Architecture decision records (ADRs) exist for each major choice.

---

## 1. Multi-Tenant Strategy Recommendation

### Recommendation: Shared-Schema with Row-Level Isolation + Country Configuration Modules

This is an opinionated choice. Here is the analysis:

### Option A: Schema-Per-Tenant (Database-per-country)

| Pros | Cons |
|------|------|
| Hard data isolation -- ideal for government compliance | Expensive operationally: N databases = N migration runs, N backup policies |
| Each country can have truly divergent schemas | Cross-border queries (DUCA-T transit tracking) become distributed joins |
| Simpler to reason about per-country data sovereignty | Connection pool explosion as countries scale |
| Easier to meet data residency laws per jurisdiction | Country onboarding = provision entire new DB + migrate |

### Option B: Shared-Schema with Row-Level Tenant Isolation (RECOMMENDED)

| Pros | Cons |
|------|------|
| Single migration path, single operational surface | Requires disciplined `country_id` / `tenant_id` on every query |
| Cross-border operations are simple JOINs | Data residency requires logical partitioning or row-level security |
| Connection pooling is straightforward | Risk of data leak if tenant filter is missed (mitigated by RLS) |
| Country onboarding = INSERT config rows, no DDL | Schema must accommodate country-specific fields via JSONB extension columns |

### Why Option B Wins

The defining use case is **cross-border transit (DUCA-T)**. A shipment originating in Costa Rica, transiting Honduras, and arriving in Guatemala needs to be tracked in a single query path. Schema-per-tenant makes this a distributed transaction nightmare. With shared-schema:

- PostgreSQL Row-Level Security (RLS) policies enforce `WHERE country_id = current_setting('app.current_country')` on every table.
- Country-specific extended fields live in a `JSONB metadata` column on core tables (`declarations`, `tariff_lines`, `risk_assessments`).
- A `country_configs` table drives all country-specific behavior: auth endpoints, format versions, VUCE URLs, risk thresholds.
- Cross-border operations use explicit multi-country queries that bypass RLS through a dedicated `cross_border_service` role with audited access.

**Partition strategy**: Range-partition the `declarations` table by `country_id` for query performance and to enable future physical data separation if a country demands it.

> **WARNING: Assumed** -- That no Central American country currently mandates that customs data must reside on servers physically located within its borders. If this assumption is wrong, we need a federated model with per-country Postgres instances connected via Foreign Data Wrappers, which changes the cost calculus significantly.

### Country Configuration Module

```
country_configs/
  costa_rica/
    auth.yaml          # OpenID Connect + Firma Digital config for ATENA
    data_format.yaml   # OMA v4.1 JSON mapping rules
    tariff_source.yaml # RIMM endpoint, SAC 2022 edition, local amendments
    risk_model.yaml    # Thresholds, CIF validation rules, red-flag keywords
    vuce.yaml          # VUCE 2.0 endpoint, SINPE payment integration
    notifications.yaml # Telegram/WhatsApp trigger config
  guatemala/
    auth.yaml          # SAT Guatemala auth (different OAuth provider)
    data_format.yaml   # Guatemala DUA format deviations
    ...
```

Each YAML file is validated against a strict JSON Schema at boot time. Missing or invalid config = hard failure, no silent defaults.

### Feature Flags

Use a two-axis feature flag system:

- **Country axis**: `country:CR:atena_v2_risk_model = true`
- **Agency axis**: `agency:AG-0042:beta_duca_t_support = true`

Implementation: a lightweight in-memory flag store (loaded from DB on startup, refreshable via admin API) rather than a third-party service. Customs systems cannot depend on external SaaS for feature evaluation -- latency and availability requirements are too strict.

---

## 2. DUCA Mapping Architecture

### Canonical Data Model

Define an internal canonical DUCA model that is a superset of all country-specific fields:

```
CanonicalDUCA {
  header: {
    type: "DUCA-F" | "DUCA-T" | "DUCA-D"
    origin_country: ISO3166Alpha2
    destination_country: ISO3166Alpha2
    transit_countries: ISO3166Alpha2[]
    declarant: DeclarantInfo
    consignee: ConsigneeInfo
    regime: CustomsRegimeCode     // CAUCA IV regime codes
    timestamps: { created, submitted, accepted, liquidated, released }
  }
  goods_lines: [{
    line_number: int
    sac_code: string              // SAC (Central American Tariff System) code
    description: string
    origin: ISO3166Alpha2
    cif_value: { amount: decimal, currency: ISO4217 }
    weight: { net_kg: decimal, gross_kg: decimal }
    quantity: { amount: decimal, unit: UNECECode }
    country_extensions: JSONB     // Country-specific fields
  }]
  transport: {
    mode: TransportModeCode
    carrier: CarrierInfo
    vehicle_id: string
    seal_numbers: string[]
    route: BorderCrossingPoint[]  // For DUCA-T
  }
  documents: [{
    type: DocumentTypeCode
    reference: string
    digital_hash: string          // SHA-256 of attached document
  }]
  risk_assessment: {
    score: decimal
    flags: RiskFlag[]
    channel: "GREEN" | "YELLOW" | "RED"
  }
}
```

### Country Adapters (Mapper Pattern)

```
                  +-----------------+
 ATENA JSON  <--> | CR Adapter      | <--> CanonicalDUCA
                  +-----------------+
 SAT XML    <--> | GT Adapter      | <--> CanonicalDUCA
                  +-----------------+
 PDCC ebXML <--> | PDCC Adapter    | <--> CanonicalDUCA
                  +-----------------+
```

Each adapter implements a `CountryDUCAMapper` interface:

```typescript
interface CountryDUCAMapper {
  countryCode: ISO3166Alpha2;
  toCanonical(raw: unknown, format: string): CanonicalDUCA;
  fromCanonical(duca: CanonicalDUCA): unknown;
  validate(duca: CanonicalDUCA): ValidationResult;
}
```

**DUCA-F** (Free Trade): Maps between the country's DUA export format and the CAUCA IV DUCA-F schema. Key challenge: each country's local DUA has fields that do not exist in the DUCA-F standard. The adapter must know which fields to drop and which to promote.

**DUCA-T** (Transit): Must maintain a chain of custody across border crossings. Each country's border checkpoint appends a `transit_leg` to the DUCA-T with timestamps, seal verifications, and inspection results. This is an append-only document -- no country can modify another country's leg.

> **WARNING: Assumed** -- That PDCC uses an AS4/ebMS transport based on the EU's e-CODEX precedent. The actual PDCC protocol specification must be obtained from SIECA. If PDCC uses a different transport (e.g., proprietary REST API), the adapter layer handles this without impacting the canonical model.

---

## 3. Sidecar Pattern

### Problem

Many customs agencies in Central America already have operational systems (ERPs, custom-built declaration tools, Excel-based workflows). They will not rip-and-replace. AduaNext must plug in alongside these systems.

### Solution: Kubernetes Sidecar Container

```
+--------------------------------------------------+
|  Kubernetes Pod                                    |
|                                                    |
|  +--------------------+    +--------------------+  |
|  | Agency's Existing  |    | AduaNext Sidecar   |  |
|  | System (main       |<-->| Container          |  |
|  | container)         |    |                    |  |
|  +--------------------+    +--------------------+  |
|         |                         |                 |
|    localhost:8080           localhost:9090           |
|    (agency UI/API)         (AduaNext APIs)          |
+--------------------------------------------------+
          |                         |
     Agency's DB             AduaNext State
                             (embedded SQLite
                              or remote PG)
```

### What the Sidecar Exposes

**Inbound APIs (consumed by the agency's system):**

| Endpoint | Purpose |
|----------|---------|
| `POST /declarations/validate` | Pre-validate a declaration against ATENA/country rules before submission |
| `POST /declarations/submit` | Submit declaration to the customs authority via the sidecar |
| `GET /declarations/{id}/status` | Poll declaration lifecycle status |
| `GET /tariffs/classify?description=...&sac=...` | Query RIMM/tariff classification |
| `POST /risk/assess` | Run pre-submission risk assessment |
| `GET /duca/map` | Convert agency's format to DUCA-F/DUCA-T |
| `GET /health` | Kubernetes liveness/readiness probe |
| `GET /metrics` | Prometheus metrics for observability |

**Outbound Connections (from sidecar to external):**

| Target | Protocol | Purpose |
|--------|----------|---------|
| ATENA Gateway | HTTPS + mTLS + JWT | Declaration submission, status polling |
| VUCE 2.0 | HTTPS + Firma Digital | Technical notes, permits |
| PDCC | AS4/ebMS (TBD) | Cross-border DUCA exchange |
| AduaNext Central | gRPC + mTLS | Telemetry, config sync, license validation |

### Sync Protocol

The sidecar operates in an **eventually-consistent** model:

1. **Config Sync**: On startup and every 5 minutes, pulls country config, tariff updates, and feature flags from AduaNext Central.
2. **Declaration Sync**: Declarations submitted through the sidecar are stored locally (embedded SQLite for resilience) and asynchronously replicated to AduaNext Central for cross-border visibility.
3. **Offline Mode**: If connectivity to AduaNext Central is lost, the sidecar continues operating against the customs authority directly. It queues telemetry and syncs when connectivity resumes. This is critical -- agencies cannot stop operating because our cloud is down.

### Sidecar Container Spec

```yaml
# aduanext-sidecar.yaml
apiVersion: v1
kind: Pod
metadata:
  name: agency-pod
  labels:
    aduanext.io/sidecar: enabled
spec:
  containers:
  - name: agency-app
    image: agency/their-system:latest
    ports:
    - containerPort: 8080
  - name: aduanext-sidecar
    image: aduanext/sidecar:1.0.0
    ports:
    - containerPort: 9090     # API
    - containerPort: 9091     # Metrics
    env:
    - name: ADUANEXT_COUNTRY
      value: "CR"
    - name: ADUANEXT_AGENCY_ID
      value: "AG-0042"
    - name: ADUANEXT_CENTRAL_URL
      value: "grpcs://central.aduanext.io:443"
    - name: ADUANEXT_AUTH_MODE
      value: "firma_digital"  # or "oauth2", "api_key"
    volumeMounts:
    - name: firma-digital-cert
      mountPath: /etc/aduanext/certs
      readOnly: true
    - name: local-state
      mountPath: /var/lib/aduanext
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 512Mi
    livenessProbe:
      httpGet:
        path: /health
        port: 9090
      initialDelaySeconds: 10
      periodSeconds: 30
    readinessProbe:
      httpGet:
        path: /health
        port: 9090
      initialDelaySeconds: 5
      periodSeconds: 10
  volumes:
  - name: firma-digital-cert
    secret:
      secretName: agency-firma-digital
  - name: local-state
    emptyDir:
      sizeLimit: 1Gi
```

For agencies not running Kubernetes, provide an alternative: a standalone Docker container with the same image, configured via `docker-compose.yaml`. Same APIs, same behavior, no K8s dependency.

> **WARNING: Assumed** -- That agencies running legacy systems have at least Docker capability. If some agencies are running bare-metal Windows servers with no containerization, we need a native Windows service distribution path. This would significantly increase packaging complexity.

---

## 4. Standalone vs Plugin: Unified Architecture

### Core Principle: Hexagonal Architecture with Mode-Specific Shells

```
+---------------------------------------------------------------+
|                     Deployment Shells                          |
|                                                                |
|  +------------------+              +------------------------+  |
|  | Standalone Shell |              | Sidecar Shell          |  |
|  | - Next.js UI     |              | - REST/gRPC API only   |  |
|  | - Full Auth      |              | - Delegated Auth       |  |
|  | - Multi-agency   |              | - Single-agency        |  |
|  | - Cloud DB (PG)  |              | - Local state (SQLite) |  |
|  | - Admin console  |              | - Config from Central  |  |
|  +--------+---------+              +-----------+------------+  |
|           |                                    |               |
|  +--------+------------------------------------+------------+  |
|  |                  @aduanext/core                           |  |
|  |                                                           |  |
|  |  - CanonicalDUCA model                                    |  |
|  |  - Country adapters (CR, GT, HN, SV, PA, NI)            |  |
|  |  - Risk assessment engine                                 |  |
|  |  - Tariff classification logic                            |  |
|  |  - Declaration lifecycle state machine                    |  |
|  |  - PDCC client                                            |  |
|  |  - Audit logger                                           |  |
|  |  - DUCA-F / DUCA-T mappers                               |  |
|  +-----------------------------------------------------------+  |
|                                                                |
|  +-----------------------------------------------------------+  |
|  |                  @aduanext/ports                           |  |
|  |  - DatabasePort (PG implementation, SQLite implementation)|  |
|  |  - AuthPort (OpenID impl, API Key impl, Firma Digital)   |  |
|  |  - NotificationPort (Telegram, WhatsApp, Email, Webhook) |  |
|  |  - CustomsGatewayPort (ATENA, SAT-GT, etc.)             |  |
|  |  - VUCEPort (VUCE 2.0 CR, VUCE GT, etc.)               |  |
|  +-----------------------------------------------------------+  |
+---------------------------------------------------------------+
```

### Package Structure

```
packages/
  core/                    # Pure business logic, zero I/O dependencies
    src/
      duca/               # DUCA models, mappers, validators
      tariff/             # SAC classification, RIMM queries
      risk/               # Risk assessment engine
      lifecycle/          # Declaration state machine
      audit/              # Immutable audit log generation
  ports/                   # Port interfaces + implementations
    src/
      database/           # DatabasePort + PG adapter + SQLite adapter
      auth/               # AuthPort + OpenID + FirmaDigital + APIKey
      customs-gateway/    # GatewayPort + ATENA + SAT-GT adapters
      vuce/               # VUCEPort + VUCE 2.0 adapter
      notifications/      # NotificationPort + Telegram/WhatsApp
      pdcc/               # PDCCPort + AS4 client
  country-configs/         # YAML configs per country
  standalone/              # Next.js full SaaS application
    src/
      app/                # UI routes, dashboards, admin
      api/                # API routes (uses core + ports)
  sidecar/                 # Minimal REST/gRPC server
    src/
      server.ts           # Express/Fastify server (no UI)
      grpc/               # gRPC service definitions
      sync/               # Config sync, declaration replication
```

### What Prevents Code Duplication

- `@aduanext/core` is a pure TypeScript library with **zero** framework dependencies. It does not import Express, Next.js, Prisma, or any I/O library.
- Both `standalone` and `sidecar` import `@aduanext/core` and `@aduanext/ports`, wiring them together with different port implementations.
- Standalone uses `PostgresDatabase`, `OpenIDAuth`, `NextNotification`.
- Sidecar uses `SQLiteDatabase`, `APIKeyAuth`, `WebhookNotification`.
- The **same** DUCA mapper, risk engine, and tariff logic runs in both modes.

---

## 5. Country Onboarding Process

### Onboarding a New Country: Step-by-Step

**Target: 10 working days for a Central American country, 15 for a non-CA LATAM country.**

#### Phase 1: Regulatory Analysis (Days 1-3)

- [ ] Obtain the country's customs authority API documentation (equivalent of ATENA technical guide).
- [ ] Map the country's DUA format to the CanonicalDUCA model. Document field-by-field mapping.
- [ ] Identify authentication requirements (OAuth2, certificates, national digital signature).
- [ ] Obtain the country's SAC edition and local tariff amendments.
- [ ] Identify VUCE equivalent (if any) and its integration protocol.
- [ ] Document regulatory differences from CAUCA IV baseline.

#### Phase 2: Configuration (Days 4-6)

- [ ] Create `country_configs/{country_code}/` directory with all YAML files.
- [ ] Implement `CountryDUCAMapper` adapter for the country's format.
- [ ] Implement `CustomsGatewayPort` adapter for the country's API.
- [ ] Implement `AuthPort` adapter for the country's authentication.
- [ ] Add country-specific RLS policy and seed `country_configs` table.
- [ ] Configure feature flags for phased rollout.

#### Phase 3: Validation (Days 7-8)

- [ ] Run CanonicalDUCA round-trip tests: Country Format -> Canonical -> Country Format (lossless for required fields).
- [ ] Submit test declarations to the country's sandbox/test environment.
- [ ] Validate DUCA-F cross-border mapping with Costa Rica as counterparty.
- [ ] Run risk model with country-specific thresholds against sample declarations.
- [ ] Pen-test the auth adapter.

#### Phase 4: Go-Live (Days 9-10)

- [ ] Deploy country config to production (feature-flagged, agency allow-list).
- [ ] Onboard a pilot agency in the country.
- [ ] Monitor for 48 hours.
- [ ] Remove feature flag restrictions for general availability.

### What Makes This Fast

- No database migrations needed (shared-schema, JSONB extensions).
- No new services to deploy (same binary, different config).
- Country adapter is the only new code -- typically 500-1000 lines of TypeScript.
- Everything else (risk engine, lifecycle, audit, UI) works from config.

---

## 6. PDCC Integration

### Architecture

```
+------------+        +----------------+        +-------------+
| AduaNext   | AS4/   | PDCC Gateway   | AS4/   | Destination |
| (Origin    |------->| (SIECA)        |------->| Country's   |
|  Country)  | ebMS   |                | ebMS   | System      |
+------------+        +----------------+        +-------------+
      |                      |                        |
      |<--- Acknowledgment --|--- Acknowledgment ---->|
      |                      |                        |
      |<-- Status Updates ---|--- Status Updates ---->|
```

### Integration Points

1. **DUCA-F Submission**: When a free-trade declaration involves goods moving between CA countries, AduaNext submits the DUCA-F to PDCC, which routes it to the destination country's system.

2. **DUCA-T Transit Tracking**: For goods in transit, AduaNext updates the DUCA-T at each border crossing. PDCC provides the "single truth" view of the transit document.

3. **Tariff Harmonization**: PDCC maintains the SAC (Sistema Arancelario Centroamericano) baseline. AduaNext syncs this periodically and overlays country-specific amendments.

4. **Risk Intelligence Sharing**: PDCC allows participating countries to share risk flags (e.g., "this shipper was flagged in Honduras"). AduaNext consumes these signals in its risk model.

### PDCC Client Implementation

```typescript
interface PDCCClient {
  // Submit DUCA-F for cross-border trade
  submitDUCAF(duca: CanonicalDUCA): Promise<PDCCSubmissionReceipt>;

  // Update DUCA-T transit leg at border crossing
  appendTransitLeg(ducaId: string, leg: TransitLeg): Promise<void>;

  // Query DUCA-T status across all transit countries
  getTransitStatus(ducaId: string): Promise<TransitStatus>;

  // Sync SAC tariff baseline
  syncTariffBaseline(): Promise<TariffUpdate>;

  // Receive risk intelligence feed
  subscribeRiskFeed(callback: (alert: RiskAlert) => void): Subscription;
}
```

> **WARNING: Assumed** -- That PDCC is operational and has a documented API. As of 2026, PDCC may still be in pilot phase. If PDCC is not yet available, AduaNext should implement bilateral country-to-country DUCA exchange as a fallback, with PDCC support added when available.

---

## Key Constraints

| # | Constraint | Impact |
|---|-----------|--------|
| 1 | **Firma Digital is mandatory** in Costa Rica. No declaration is valid without it. | Auth adapter must integrate with BCCR-authorized CA hierarchy. Cannot use generic TLS certs. |
| 2 | **$20,000 USD caution bond** is at risk per agency per submission error. | The sandbox/validation layer is not optional. Every declaration MUST pass pre-validation before touching ATENA. |
| 3 | **CAUCA IV / RECAUCA** are the supranational legal framework. | Country adapters cannot contradict CAUCA IV. Local deviations must be flagged in the audit trail. |
| 4 | **D-270 monthly reporting** means TRIBU-CR cross-references in real-time. | AduaNext's invoicing/billing module must produce D-270-compatible output or risk triggering fiscal audits. |
| 5 | **Expediente Electronico** is mandatory in ATENA. | All supporting documents (invoices, transport docs, certificates of origin) must be digitally attached to declarations. No physical fallback. |
| 6 | **Offline resilience** for sidecar deployments. | Sidecar must operate during network partitions. Local SQLite + queue-and-sync is non-negotiable. |
| 7 | **Multi-language SAC codes**. | Tariff descriptions exist in Spanish but goods descriptions from shippers may be in English, Portuguese. Classification engine needs multilingual support. |

---

## Gaps and Risks

### Critical Gaps

| # | Gap | Severity | Mitigation |
|---|-----|----------|------------|
| G1 | **PDCC API specification not publicly available.** We are designing against assumed AS4/ebMS protocol. | HIGH | Engage SIECA directly. Design the PDCCPort interface so the transport is pluggable. Build bilateral REST fallback first. |
| G2 | **ATENA technical guide may not cover all edge cases.** The system replaced TICA recently and documentation lags. | HIGH | Establish direct relationship with Hacienda Digital technical team. Budget for discovery spikes against ATENA sandbox. |
| G3 | **Data residency requirements per country are unknown.** Some countries may mandate in-country data storage. | MEDIUM | Architecture supports future migration to schema-per-tenant with Foreign Data Wrappers if legally required. Decision deferred until legal review per country. |
| G4 | **VUCE 2.0 integration surface is unclear.** PROCOMER's API documentation for VUCE 2.0 is sparse. | MEDIUM | VUCE 2.0 is operational at vuce20.procomer.go.cr. Reverse-engineer the API from the web app or obtain docs from PROCOMER directly. |
| G5 | **Sidecar networking assumes pod-level localhost access.** Not all agency environments support this. | MEDIUM | Provide Docker Compose alternative. For bare-metal, provide a systemd service distribution. |

### Risks

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| R1 | A country mandates a fundamentally different customs process that cannot be modeled by CanonicalDUCA. | LOW | HIGH | CanonicalDUCA includes `country_extensions: JSONB` escape hatch. If a country truly diverges, we extend the canonical model -- it is a superset by design. |
| R2 | ATENA changes its API without notice. | MEDIUM | HIGH | Version the ATENA adapter. Run nightly smoke tests against ATENA sandbox. Alert on schema drift. |
| R3 | Firma Digital certificate management is operationally complex for small agencies. | HIGH | MEDIUM | Build a certificate lifecycle manager into the sidecar: expiry warnings, renewal prompts, automatic token refresh. |
| R4 | Cross-border DUCA-T breaks when one country's system is down. | MEDIUM | HIGH | DUCA-T is an append-only document. If a country's checkpoint is offline, the sidecar queues the transit leg locally and retries. The physical goods do not wait -- the digital record catches up. |
| R5 | Feature flag sprawl creates untestable country/flag combinations. | MEDIUM | MEDIUM | Enforce a flag naming convention. Require each flag to have an expiry date. Automated test matrix covers all active flag combinations per country. |

---

## Size Estimate

**XL (Extra Large)**

### Justification

| Component | Effort |
|-----------|--------|
| Core canonical model + DUCA mappers | L |
| Multi-tenant DB schema with RLS + migrations | M |
| Country config system + validation | M |
| Sidecar container + sync protocol + offline mode | L |
| ATENA gateway adapter (first country) | L |
| PDCC integration (with protocol uncertainty) | L |
| Hexagonal architecture packaging (standalone + sidecar) | M |
| Feature flag system | S |
| Audit trail (immutable, cross-border) | M |
| Country onboarding framework + Guatemala dry-run | M |
| VUCE 2.0 integration | M |

This spike encompasses the foundational architecture of the entire platform. It is not a single feature -- it is the skeleton upon which all other spikes build. Estimate: **10-14 weeks** for a team of 3-4 senior engineers to deliver the architecture with Costa Rica fully operational and Guatemala as a validated dry-run.

### Suggested Decomposition for Execution

If XL is too large for a single sprint cycle, decompose into:

1. **Spike 3a**: Core canonical model + hexagonal packaging + country config system (3 weeks)
2. **Spike 3b**: Multi-tenant DB + RLS + ATENA adapter + Costa Rica end-to-end (3 weeks)
3. **Spike 3c**: Sidecar container + sync protocol + offline mode (3 weeks)
4. **Spike 3d**: DUCA-F/DUCA-T mappers + PDCC integration + Guatemala dry-run (3 weeks)
5. **Spike 3e**: VUCE 2.0 + feature flags + audit trail hardening (2 weeks)

---

## Appendix: Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Multi-tenant model | Shared-schema + RLS | Cross-border queries are first-class; DUCA-T transit tracking demands it |
| Country-specific logic | Configuration-driven (YAML) + Adapter pattern | Minimizes code per country; config changes do not require deployments |
| Sidecar communication | REST (primary) + gRPC (internal sync) | REST for agency compatibility; gRPC for efficient Central sync |
| Sidecar local state | SQLite (embedded) | Zero-ops for agencies; survives container restarts via volume mount |
| Canonical model approach | Superset with JSONB extensions | Avoids lowest-common-denominator; countries can use full expressiveness |
| PDCC transport | AS4/ebMS (assumed, pluggable) | Aligned with international e-customs standards; fallback to REST bilateral |
| Feature flags | In-process, DB-backed | No external SaaS dependency; customs systems need deterministic behavior |
