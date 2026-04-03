# ADX-SPIKE-001 AduaNext Technical Spike — Consolidated Bilingual Brief

> **Type:** `Spike`

> **Size:** `XL`

> **Strategy:** `Team`

> **Components:** `Backend`, `Security`, `Infra`, `Database`, `Frontend`

> **Impact:** `Critical Path`, `Revenue`

> **Flags:** `Epic`

> **Branch:** `spike/adx-001-architecture-and-integration`

---

## HUMAN LAYER

### User Story

As a **customs agency owner in Costa Rica**, I want **a modern SaaS platform that integrates directly with ATENA, automates DUA preparation, classifies goods intelligently, manages multi-country declarations, and connects me with vetted importers** so that **I can reduce classification errors, protect my $20,000 USD bond, and scale my operations across Central America without manual portal navigation**.

### Background / Why

Costa Rica's customs ecosystem underwent a seismic shift with the deployment of ATENA (replacing TICA) and TRIBU-CR (replacing ATV). Every customs agency is now mandated to operate digitally via JSON/WCO Data Model v4.1, OpenID Connect + Firma Digital authentication, and electronic dossiers. The transition has created an urgent market gap: agencies need modern tooling that goes beyond the government portals.

AduaNext addresses this by providing two deployment modes: a **standalone SaaS** for agencies wanting to fully digitize, and a **Kubernetes sidecar** that plugs into existing agency systems. The platform is designed as "multi-hacienda" — not traditional multi-tenant (company A, company B), but multi-jurisdiction where each tenant is a **sovereign customs authority** with its own laws, schemas, and authentication systems.

The vetted sourcers marketplace adds a unique differentiator: pre-verified importers with classified product catalogs accelerate DUA preparation and automate origin certification generation — a capability no existing platform offers.

### Analogy

Think of AduaNext as **Stripe for customs declarations**: it abstracts away the complexity of government API integration (like Stripe abstracts payment processors), provides a clean developer experience, and handles compliance/security so the agency can focus on their clients. The sidecar mode is like Stripe's embedded components — it works alongside existing systems without replacing them.

### UX / Visual Reference

None provided. Recommended: Figma mockups for the declaration dashboard, classification workflow, and marketplace sourcer browser.

### Known Pitfalls & Gotchas

1. **ATENA API is undocumented** — No OpenAPI spec, no machine-readable JSON schema. Everything is inferred from PDF guides.
2. **RIMM API is a black box** — The tariff classification API has no public documentation.
3. **Firma Digital requires physical smart cards** — Cloud deployment needs a local signing gateway bridge.
4. **$20,000 USD bond at risk** — Any transmission error to ATENA can trigger fiscal penalties against the agency's bond.
5. **Human-in-the-loop is legally required** — Costa Rica's Ley 7557 assigns personal liability to the agente aduanero. Full automation of classification is legally impermissible.
6. **PDCC (Central American Digital Trade Platform) API is undocumented** — Cross-border DUCA-F/T integration is designed against assumptions.
7. **Data residency per country** — Unknown requirements that could force architectural changes.
8. **Monthly D-270 declarations** — TRIBU-CR's automated fiscalization means any inconsistency between billed honorarios and declared expenses is detected immediately.

---

## AGENT LAYER

### Objective

Produce a fully-architectured technical foundation for AduaNext: hexagonal architecture with ports & adapters, multi-tenant data layer, 4 spike deliverables (ATENA integration, classification engine, cross-border multi-hacienda, vetted sourcers marketplace), 8 Mermaid architecture diagrams, and a deployment strategy supporting both standalone SaaS and K8s sidecar modes.

### Context Files

- `spike_source.md` — Original mega-prompt with full Costa Rica regulatory context
- `spikes/spike-002-tariff-classification-rimm.md` — Spike 2 detailed brief
- `spikes/spike-003-cross-border-multi-hacienda-architecture.md` — Spike 3 detailed brief
- `architecture-diagrams.md` — 8 Mermaid diagrams (modular, hexagonal, sidecar, state machine, sequence, multi-tenant, ER, context)
- `AGENTS.md` — Boilerplate agent skills system and Linear taxonomy

### Acceptance Criteria

#### Spike 1: ATENA Integration & DUA Mapping
- [ ] Commercial invoice to DUA Export JSON mapping engine (WCO v4.1, 40+ field transformations)
- [ ] OpenID Connect + Firma Digital dual-layer auth (PKCE flow, PKCS#11 hardware token support)
- [ ] Declaration lifecycle state machine (13 states: Draft through Levante)
- [ ] Docker-sandboxed API proxy (SANDBOX/ARMED/ATENA_SANDBOX modes)
- [ ] Risk pre-validation engine (25+ rules, composite risk score 0-100)
- [ ] Telegram/WhatsApp notifications per state transition
- [ ] CIF auto-calculation with BCCR exchange rate integration
- [ ] Immutable audit trail for every transformation and decision

#### Spike 2: Tariff Classification & RIMM
- [ ] RIMM query skill with fuzzy matching (Levenshtein <= 2), synonym expansion, stemming
- [ ] AI-assisted classification pipeline (RAG over fine-tuning, 3+ suggestions with confidence scores)
- [ ] Human-in-the-loop confirmation (legally required, firma digital identity capture)
- [ ] Locked classification pattern (no in-place mutation, new event per change)
- [ ] Risk scoring per line item (CIF deviation, description specificity, red-flag commodity match)
- [ ] Historical correction memory (human overrides weighted in future searches)
- [ ] Cache with 24h TTL and manual cache-bust; graceful degradation when RIMM unreachable

#### Spike 3: Cross-Border Multi-Hacienda
- [ ] Shared-schema multi-tenant with PostgreSQL RLS (not schema-per-tenant)
- [ ] Country-specific JSONB extension columns for divergent fields
- [ ] DUCA-F (free trade) and DUCA-T (transit) cross-border declaration mapping
- [ ] Hexagonal core (`@aduanext/core`) consumed by both Standalone and Sidecar shells
- [ ] Sidecar: K8s container on localhost:9090, SQLite for offline resilience, eventually-consistent sync
- [ ] Country onboarding in 10 working days (YAML config + CountryDUCAMapper adapter + CustomsGatewayPort)
- [ ] VUCE 2.0 integration for technical notes/permits

#### Spike 4: Vetted Sourcers Marketplace
- [ ] VettedSourcer entity with KYC, trade agreement eligibility, INCOTERM preferences
- [ ] All 11 INCOTERM 2020 codes modeled with full responsibility matrices
- [ ] Product catalog with pre-classified HS codes (6-10 digit SAC/NAUCA)
- [ ] Origin certification draft generation per trade agreement (CAFTA-DR, EU-CA AA, SICA)
- [ ] Trust/reputation scoring (7 weighted signals, 4 tiers: Unverified/Basic/Verified/Trusted)
- [ ] Multi-tenant isolation (Agency A cannot see Agency B's sourcer shortlists)
- [ ] Kept as in-repo domain module (NOT separate marketplace-core repo)

### Technical Constraints

- **Hexagonal Architecture**: Domain core has zero I/O dependencies. All government APIs behind port/adapter interfaces.
- **WCO Data Model v4.1**: All declaration payloads must conform to WCO standards with SAC 10-digit extensions.
- **Firma Digital**: RSA 2048-bit X.509 v3 certificates via BCCR-authorized CAs. PKCS#11 for hardware, PKCS#12 for software certs.
- **PostgreSQL**: Primary database with JSONB for country-specific extensions, RLS for tenant isolation, append-only audit tables.
- **TypeScript/Node.js**: Inferred backend stack (JSON-native for WCO, ecosystem alignment with K8s tooling).
- **No ML in Phase 1**: Rule-based risk scoring and classification. RAG for AI suggestions. ML deferred to Phase 2.
- **Audit immutability**: Append-only PostgreSQL with SHA-256 hash chaining. Periodic S3 Object Lock snapshots.

### Verification Commands

```bash
# Tests
npm run test -- --coverage

# Lint
npm run lint

# Build
npm run build

# Type check
npx tsc --noEmit

# Schema validation
npm run validate:schema -- spikes/spike-001-atena-dua-export.json

# Docker sandbox
docker compose -f docker-compose.sandbox.yml up --build
```

### Agent Strategy

**Mode:** `Team`

**Lead role:** Coordinator — assigns tasks, reviews, synthesizes. No direct file edits.

**Teammates:**
- Teammate 1: **ATENA Integration Engineer** → owns `src/modules/declarations/`, `src/adapters/atena/`, `src/adapters/bccr/`
- Teammate 2: **Classification & Risk Engineer** → owns `src/modules/classification/`, `src/modules/risk/`, `src/adapters/rimm/`
- Teammate 3: **Multi-Hacienda & Sidecar Architect** → owns `src/core/`, `src/tenancy/`, `k8s/sidecar/`, `infrastructure/`
- Teammate 4: **Marketplace & Origin Cert Engineer** → owns `src/modules/marketplace/`, `src/modules/certifications/`

**Display mode:** `split`
**Plan approval required:** yes
**File ownership:** Explicit mapping above to avoid write conflicts.

---

## PARALLELIZATION RECOMMENDATION

**Recommended mechanism:** `Agent Teams` (4 teammates) + `Git Worktrees` for experimental sidecar work

**Reasoning:**

This is an **XL Epic** with 4 distinct spikes touching different architectural layers. The spikes have clear module boundaries but share core infrastructure (auth, audit, tenant isolation).

- **Agent Teams (4 teammates)**: Each spike is owned by a dedicated engineer. The coordinator ensures shared interfaces (ports/adapters) are defined before parallel implementation begins.
- **Git Worktrees for Sidecar**: The K8s sidecar pattern (Spike 3) is experimental and risky. Isolate it in a worktree to avoid destabilizing the main development line.
- **Subagents for Research**: Each teammate can spawn subagents for targeted research (e.g., fetching BCCR exchange rates, parsing RIMM specs).

**Size -> Mechanism mapping:**
- Spike 1 (ATENA): L → Agent Teams teammate
- Spike 2 (RIMM): XL → Agent Teams teammate (phased delivery)
- Spike 3 (Multi-Hacienda): XL → Agent Teams teammate + Worktree for sidecar
- Spike 4 (Marketplace): L → Agent Teams teammate

**Cost estimate:** ~4x base token cost

---

## Synthesis Additional Comments

### MECE Logical Validation

**Mutually Exclusive:** Each spike owns a distinct domain boundary:
- Spike 1: Declaration submission pipeline (ATENA I/O)
- Spike 2: Classification intelligence (RIMM I/O)
- Spike 3: Multi-tenant infrastructure (cross-cutting)
- Spike 4: Sourcer marketplace (business domain)

No overlap in primary responsibility. Shared concerns (auth, audit, tenant isolation) are abstracted into `src/core/` owned by the Multi-Hacienda architect.

**Collectively Exhaustive:** The four spikes cover 100% of the user's stated requirements:
- ATENA integration (Spike 1)
- Tariff classification with AI assistance (Spike 2)
- Multi-country expansion with two deployment modes (Spike 3)
- Vetted sourcers with origin certs and INCOTERMs (Spike 4)

Missing from the spikes but needed: Frontend/mobile app design, CI/CD pipeline setup, monitoring/observability. These are "Phase 2" concerns that depend on the architectural decisions made here.

### Executive Synthesis (Minto Pyramid)

**1. Lead with the Answer:** AduaNext is technically feasible as a hexagonal-architecture platform with shared-schema multi-tenancy, dual deployment modes (SaaS + sidecar), and 4 domain modules — but execution is blocked by 3 critical government API documentation gaps (ATENA schema, RIMM API, PDCC protocol) that must be resolved through a Hacienda Digital liaison before Sprint 1.

**2. Supporting Arguments:**
- **Architecture Viability**: Hexagonal + ports/adapters pattern de-risks the undocumented government APIs by isolating all external dependencies behind swappable adapters. If ATENA changes its API, only the adapter changes.
- **Multi-tenant Scalability**: Shared-schema with RLS scales to 100+ country tenants without operational complexity. JSONB extension columns handle per-country divergence without schema migrations.
- **Marketplace Differentiation**: The vetted sourcers module is the competitive moat. No existing customs platform offers pre-classified product catalogs with automated origin certification. Keep it in-repo (not separate repo) until the domain boundaries prove stable.
- **Compliance Safety**: Docker sandbox proxy, immutable audit trails with hash chaining, and mandatory human-in-the-loop classification satisfy both Ley 7557 requirements and protect the $20K bond.

**3. Data & Evidence:**
- 50-81 story points across 4 spikes (XL aggregate)
- 25+ pre-validation rules in the risk engine
- 13-state declaration lifecycle state machine
- 9+ trade agreements for origin certification
- 11 INCOTERM 2020 codes fully modeled
- 10-day target for country onboarding

### Pareto 80/20 Efficiency Review

**80% business value from 20% code complexity:**
- **Phase A (highest value, lowest complexity):** DUA mapping engine + sandbox proxy + audit trail + basic classification with human confirmation. This gives agencies a working declaration submission pipeline with compliance safety.
- **Phase B (high value, moderate complexity):** AI-assisted classification + risk scoring + Telegram notifications. Differentiating features that reduce agent workload.
- **Phase C (moderate value, high complexity):** Multi-country expansion + sidecar mode + DUCA cross-border mapping. Only needed when the first Costa Rica agencies are onboarded.
- **Phase D (strategic value, highest complexity):** Vetted sourcers marketplace + origin certification automation. The competitive moat, but depends on having active agencies and sourcers.

**Over-engineered components flagged:**
- The INCOTERM responsibility matrix model (Spike 4) is more detailed than needed for MVP. A simple JSONB seed table with the 11 codes suffices. The full obligation matrix can be Phase 2.
- The trust/reputation scoring system (7 weighted signals, batch computation) is premature — start with simple KYC verified/unverified binary. Add scoring when there's enough data to make it meaningful.

### Second-Order Thinking & Risk Assessment

**Scalability (10x/100x data volume):**
- PostgreSQL RLS performs well at 10x. At 100x (thousands of agencies across LATAM), consider: read replicas per region, RIMM cache as a distributed Redis cluster, and potentially moving the audit log to a dedicated time-series store.
- The sidecar pattern scales horizontally by design — each agency pod is independent.

**Downstream Effects:**
- The hexagonal architecture means future developers can add new country adapters without understanding the core domain. This is the intended design — low coupling.
- The "locked classification" pattern (no in-place mutation) will generate high write volume in the audit table. Plan for partitioning by month + archival strategy.
- If ATENA changes its API (likely in the first 2 years post-launch), only the ATENA adapter needs updating. The port interface absorbs the change.

**Hidden Dependencies / Architectural Traps:**
- **Firma Digital certificate lifecycle**: Certificates expire and require physical renewal at BCCR-authorized CAs. If the system doesn't proactively alert (30 days advance), an expired cert silently blocks ALL submissions.
- **BCCR exchange rate single point of failure**: If the BCCR API goes down and the local cache is stale, CIF calculations may be inaccurate. Mitigation: daily cache at 06:00 CST with a 48-hour staleness tolerance.
- **Government API versioning**: ATENA is new. Expect breaking changes in the first 12-18 months. The adapter pattern is essential.
- **Regulatory changes**: The monthly D-270 requirement (TRIBU-CR) and KYC obligations are evolving. The system must be auditable enough to survive a control-a-posteriori audit that could happen years after a declaration.
