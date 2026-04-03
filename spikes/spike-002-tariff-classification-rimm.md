# SPIKE 002: Tariff Classification & RIMM Integration

**Status:** Draft
**Author:** Architecture Team
**Date:** 2026-04-03
**Estimated Size:** XL (8-13 weeks for full delivery; recommend phased rollout in 3 increments)

---

## User Story

**As a** licensed customs agent (agente aduanero) operating in the AduaNext platform,
**I want** an intelligent tariff classification workflow that queries RIMM catalogs, suggests HS/SAC codes via AI-assisted search, enforces human confirmation, and produces an immutable audit trail,
**so that** I can classify goods accurately before ATENA submission, avoid misclassification penalties (fines, suspension, criminal prosecution), and protect my agency's $20,000 USD bond.

---

## Technical Objective

Build a classification subsystem that:

1. Wraps ATENA's RIMM module behind a local query/cache layer with advanced search (fuzzy, synonyms, historical corrections).
2. Implements a deterministic, human-in-the-loop classification pipeline: commercial description intake, AI suggestion, RIMM validation, human confirmation, and submission lock.
3. Scores every declaration line for risk before ATENA transmission (CIF anomalies, generic descriptions, red-flag commodities).
4. Records every classification decision in an append-only, cryptographically chained audit log that satisfies Costa Rica's control-a-posteriori requirements (Ley 7557, Art. 24).
5. Operates in a sandboxed pre-submission environment so that no data reaches ATENA until all validations pass.

---

## Acceptance Criteria

### RIMM Query Skill (`rimm_query`)
- [ ] Agent can search RIMM tariff catalogs by commercial description, returning ranked HS/SAC heading candidates.
- [ ] Search supports fuzzy matching (Levenshtein distance <= 2), Spanish/English synonym expansion, and stemming.
- [ ] RIMM responses are cached locally with a TTL of 24 hours and a manual cache-bust trigger.
- [ ] Historical correction memory: if a human overrides an AI suggestion, that correction is stored and weighted in future searches for the same product family.
- [ ] Search latency p95 < 800ms for cached queries, < 3s for RIMM round-trips.
- [ ] Graceful degradation: if RIMM is unreachable, the system displays cached results with a staleness warning and blocks ATENA submission.

### Classification Flow
- [ ] User can input a free-text commercial description and receive at least 3 ranked HS/SAC code suggestions with confidence scores.
- [ ] Each suggestion includes: HS code, SAC-specific suffix, applicable duty rate, active technical notes (notas tecnicas), and any FTA preferential rate indicators.
- [ ] AI-suggested codes are clearly labeled as "SUGGESTION - REQUIRES CONFIRMATION" and cannot be auto-submitted.
- [ ] Human confirmation step captures the agent's identity (firma digital certificate DN), timestamp, and optional justification note.
- [ ] Once confirmed, the classification enters a "locked" state. Changes require a new classification event (no in-place mutation).
- [ ] The full classification chain (input description, AI suggestions, RIMM validation result, human decision, justification) is persisted as a single auditable unit.

### Risk Scoring
- [ ] Each declaration line receives a composite risk score (0-100) before ATENA submission.
- [ ] Risk score incorporates at least: CIF value deviation from historical median, description specificity index, commodity red-flag list match, origin-country risk profile, and importer KYC status.
- [ ] Lines scoring >= 70 ("High Risk") require supervisor sign-off before submission.
- [ ] Lines scoring >= 90 ("Critical Risk") are blocked from submission and generate an alert to the agency compliance officer.
- [ ] Risk model weights are configurable per tenant without code deployment.

### Audit Trail
- [ ] Every classification event is written to an append-only store (no UPDATE/DELETE operations on the audit table).
- [ ] Each record contains: event_id (UUIDv7), tenant_id, declaration_line_id, actor_id, actor_certificate_dn, event_type, timestamp (UTC), payload (before/after state), sha256_chain_hash (hash of previous record + current payload).
- [ ] Audit records are exportable in JSON and PDF formats for fiscal authority review.
- [ ] Audit log integrity can be verified via chain hash validation at any time.

### AI-Assisted Classification
- [ ] LLM-based classification uses a Retrieval-Augmented Generation (RAG) pipeline grounded in the official SAC nomenclature and Costa Rica's explanatory notes.
- [ ] The LLM never communicates directly with ATENA; it only produces suggestions consumed by the deterministic pipeline.
- [ ] Model outputs include citation references to the specific SAC chapter/heading/subheading notes that support the suggestion.
- [ ] A/B testing infrastructure exists to evaluate classification accuracy against a labeled validation set of >= 500 historical declarations.
- [ ] Model performance dashboard tracks: suggestion acceptance rate, override rate, top-10 overridden codes, and average confidence delta between accepted and rejected suggestions.

### Penalty Avoidance / Bond Protection
- [ ] All ATENA API calls execute through a sandboxed gateway that enforces pre-submission validation.
- [ ] No transmission to ATENA can occur without: (a) all declaration lines classified and human-confirmed, (b) risk score below critical threshold or supervisor override, (c) KYC check passed for the importer.
- [ ] A "dry-run" mode exists that validates the full payload against ATENA's schema and business rules without transmitting.
- [ ] Financial exposure dashboard shows estimated duties/taxes per declaration and cumulative exposure against the $20,000 bond.

---

## Classification Flow (Step-by-Step)

### Phase 1: Intake

1. **Commercial description entry.** The agent enters (or imports from the commercial invoice) the product's commercial description, country of origin, and declared CIF value. The system normalizes the text: lowercasing, removing extraneous whitespace, expanding known abbreviations (e.g., "S/S" -> "stainless steel", "PVC" -> "polyvinyl chloride").

2. **KYC gate.** Before proceeding, the system verifies that the importer/exporter has passed KYC due diligence. If KYC is expired or missing, the flow is halted with a prompt to complete the `kyc_check` skill. This satisfies the 2026 mandate that agents act as extensions of fiscal control (source spike_source.md, ref. 44).

### Phase 2: AI-Assisted Suggestion

3. **RAG retrieval.** The normalized description is embedded and queried against a vector index built from: (a) the SAC nomenclature (2,500+ 10-digit tariff lines for Costa Rica), (b) official explanatory notes, (c) RIMM technical notes, (d) the tenant's historical classification corrections. The top-k (k=20) document chunks are retrieved.

4. **LLM classification.** The retrieved context plus the commercial description are passed to the classification LLM (fine-tuned or prompted with few-shot examples from the tenant's validated history). The model returns up to 5 candidate HS/SAC codes, each with:
   - The 10-digit SAC code.
   - A confidence score (0.0 to 1.0).
   - A plain-language justification citing specific nomenclature rules (e.g., "GRI 1: heading text explicitly covers this product").
   - Applicable general duty rate and any FTA preferential rates.

5. **Duplicate/conflict detection.** The system checks if the suggested codes conflict with each other (e.g., two suggestions from mutually exclusive chapters) and flags the conflict for the agent.

### Phase 3: RIMM Validation

6. **RIMM round-trip.** The top candidate code(s) selected by the agent are validated against RIMM via `rimm_query`. The query confirms: (a) the code exists and is active in the current SAC version, (b) any applicable technical notes or import restrictions (e.g., VUCE permits required), (c) the duty rate matches the locally cached rate.

7. **Technical note resolution.** If RIMM returns active technical notes for the selected heading, these are displayed prominently. The agent must acknowledge each note before proceeding. Notes that indicate a VUCE permit requirement trigger an automatic cross-check against VUCE 2.0 to verify permit status.

8. **Rate discrepancy check.** If the RIMM-returned duty rate differs from the locally cached rate, the system updates the cache and alerts the agent. This prevents stale-rate submissions.

### Phase 4: Human Confirmation

9. **Decision screen.** The agent sees a consolidated view: the original description, all AI suggestions with scores, the RIMM validation result, applicable technical notes, and the risk score (computed in parallel -- see Risk Scoring below). The agent selects the final code and optionally adds a justification note.

10. **Digital signature.** The agent confirms the classification by authenticating with their firma digital certificate. The system captures the certificate DN, timestamp, and the full decision payload.

11. **Lock.** The classification is now immutable. If the agent later disagrees, they must create a *new* classification event that references the prior event_id, producing a visible correction chain. The old record is never deleted or modified.

### Phase 5: Pre-Submission Risk Gate

12. **Composite risk scoring.** The finalized declaration line passes through the risk scoring engine (see model below). If the score is >= 70, the flow halts for supervisor review. If >= 90, it is blocked entirely pending compliance officer intervention.

13. **Dry-run validation.** Before live transmission, the complete DUA payload (all lines) is validated in dry-run mode against ATENA's JSON schema (OMA v4.1) and known business rules. Schema violations are reported with field-level detail.

14. **Sandbox transmission.** Only after all lines pass risk scoring and dry-run validation does the system allow transmission through the sandboxed ATENA gateway. The gateway logs the raw request/response pair to the audit trail.

---

## Risk Scoring Model Proposal

### Architecture

The risk engine is a rule-based scoring system (not ML -- deliberate choice for auditability and regulatory explainability). Each factor produces a sub-score that is multiplied by a configurable weight. The composite score is the weighted sum, capped at 100.

### Factors

| # | Factor | Signal | Sub-Score Range | Default Weight |
|---|--------|--------|-----------------|----------------|
| 1 | **CIF Value Deviation** | Declared CIF vs. historical median CIF for same HS code + origin country (last 12 months, tenant-scoped). Deviation > 2 standard deviations scores high. | 0-25 | 0.25 |
| 2 | **Description Specificity** | Token count and information density of the commercial description. Descriptions with < 5 tokens or matching a "generic phrases" blocklist (e.g., "general merchandise", "spare parts", "miscellaneous") score high. | 0-20 | 0.20 |
| 3 | **Red-Flag Commodity** | HS code appears on a configurable watchlist (e.g., precursor chemicals Ch.29, weapons Ch.93, textiles with origin-fraud history). | 0 or 20 (binary) | 0.20 |
| 4 | **Origin Country Risk** | Country of origin mapped against a risk tier list (Tier 1 = low, Tier 2 = medium, Tier 3 = high). Tier list sourced from WCO and Costa Rica's own ATENA risk profiles. | 0-15 | 0.15 |
| 5 | **Importer KYC Score** | Composite of: time since last KYC refresh, number of prior corrections/penalties, declared vs. actual import volume. | 0-10 | 0.10 |
| 6 | **Classification Override** | Agent overrode the AI's top suggestion. Manual overrides are not inherently risky but signal the classification deserves a second look. | 0 or 10 (binary) | 0.10 |

### Thresholds

| Composite Score | Risk Level | Action |
|----------------|------------|--------|
| 0-39 | Low | Auto-proceed to submission. |
| 40-69 | Medium | Proceed with warning banner. Log in risk report. |
| 70-89 | High | Halt. Require supervisor digital signature to proceed. |
| 90-100 | Critical | Block. Compliance officer must review. Cannot be overridden by supervisor alone. |

### Calibration

- Initial weights are set from domain expert judgment (the table above).
- After 90 days of production data, a quarterly calibration review compares risk scores against actual ATENA rejections, post-clearance audits, and penalty events.
- Weight adjustments require a configuration change with audit trail entry (who changed what, when, why).

---

## Key Constraints

1. **RIMM API availability is not guaranteed.** ATENA/RIMM is a government system with maintenance windows and potential instability. The architecture MUST degrade gracefully. Local caching and offline-capable classification are non-negotiable.

2. **Firma digital is mandatory.** Every confirmation step must cryptographically bind to the agent's SINPE/BCCR digital certificate. The system cannot substitute username/password for the signature step on classification decisions. This is a legal requirement under Ley 7557 and ATENA's OpenID Connect + digital signature protocol.

3. **Multi-tenancy isolation.** Classification histories, risk model weights, correction memories, and audit logs are strictly tenant-scoped. No cross-tenant data leakage is acceptable. Tenant = customs agency. This is critical because competing agencies share the platform.

4. **SAC versioning.** The Central American Tariff System is updated periodically (HS revisions every 5 years, with CARICOM/SIECA amendments in between). The vector index and RIMM cache must be version-aware. A classification made under SAC v2022 must be retrievable as such, even after SAC v2027 is published.

5. **LLM isolation.** The classification LLM must never receive PII, bond details, or financial data. It receives only the commercial description, origin country, and SAC nomenclature context. No declaration-level data flows to the model. If using a cloud LLM, a data processing agreement (DPA) must cover Costa Rica's data protection law (Ley 8968).

6. **Regulatory ceiling on automation.** Costa Rica's Ley General de Aduanas assigns personal liability to the agente aduanero. Full automation of classification is legally impermissible. The human-in-the-loop step is not a "nice to have" -- it is a legal requirement. The system must make it *impossible* to bypass human confirmation.

7. **Append-only audit integrity.** The audit store must prevent retroactive tampering. Preferred implementation: PostgreSQL with row-level security, no DELETE/UPDATE grants on the audit table, and a sha256 hash chain. For higher assurance, periodic snapshots to an immutable object store (S3 with Object Lock or equivalent).

---

## Gaps / Risks Detected

### Critical

- **GAP-001: RIMM API specification is undocumented publicly.** The ATENA technical guide (SIAA-ATENA-DUA-GUIA-TECNICA.pdf) describes RIMM conceptually but does not publish a REST API contract. We need Hacienda Digital to provide or confirm: endpoint URLs, authentication flow, rate limits, response schemas, and error codes. Without this, the `rimm_query` skill is designed against assumptions.
  - Mitigation: Build against a mock RIMM API; isolate the integration behind a port/adapter so the real client can be swapped in.
  - **Risk level: BLOCKER for Phase 3 (RIMM Validation).**

- **GAP-002: No public SAC machine-readable dataset.** The full 10-digit SAC nomenclature with explanatory notes is not available as a structured dataset (JSON/CSV). It exists in PDF and fragmented HTML on SIECA's site. Building the RAG vector index requires a structured corpus.
  - Mitigation: Budget a dedicated data-engineering task to parse and structure the SAC from SIECA sources. Alternatively, negotiate data access with DGA or CRECEX.
  - **Risk level: BLOCKER for Phase 2 (AI Suggestion).**

- **GAP-003: ATENA sandbox/dry-run capability is unconfirmed.** The spike source mentions a Docker sandbox for transmission, but it is unclear whether ATENA itself provides a test/staging environment or dry-run endpoint. If not, the "dry-run" must be a client-side schema validation only, which cannot catch server-side business rule violations.
  - Mitigation: Request ATENA sandbox credentials from DGA. Design the dry-run as two layers: local schema validation (always available) + remote dry-run (if ATENA supports it).

### High

- **GAP-004: Historical classification data for CIF deviation model.** The risk scoring factor #1 (CIF Value Deviation) requires historical CIF data per HS code + origin. For a new platform, this data does not exist. Cold-start problem.
  - Mitigation: Phase 1 uses global reference prices from WCO or SIECA databases (if available). Phase 2 switches to tenant-scoped history once >= 50 observations per HS code are accumulated. Flag to users that CIF deviation scoring is in "learning mode" for the first 6 months.

- **GAP-005: LLM classification accuracy is unvalidated.** No labeled dataset of Costa Rica-specific classification decisions exists for benchmarking. Accuracy claims are aspirational until validated.
  - Mitigation: Before production launch, assemble a validation set of >= 500 classification decisions from partner agencies. Require >= 80% top-3 accuracy (the correct code appears in the top 3 suggestions) before enabling AI suggestions for production declarations. Below this threshold, disable AI suggestions and fall back to RIMM keyword search only.

- **GAP-006: Firma digital integration complexity.** The BCCR digital signature ecosystem uses PKCS#11 hardware tokens. Browser-based signing (WebCrypto + PKCS#11 bridge) is notoriously fragile across OS/browser combinations. This is a cross-cutting concern that affects all ATENA interactions, not just classification.
  - Mitigation: Evaluate existing middleware (e.g., Signer from Hacienda Digital, or third-party solutions like Bit4id). Budget dedicated testing across Windows/macOS/Linux with the SINPE token.

### Medium

- **GAP-007: VUCE 2.0 cross-check integration.** Step 7 of the classification flow references automatic VUCE permit verification. VUCE 2.0 API availability and authentication model are not confirmed.
  - Mitigation: Make VUCE cross-check optional in Phase 1; display a manual checklist reminder instead.

- **GAP-008: Multi-language synonym dictionary.** Costa Rica trade uses a mix of Spanish technical terms, English commercial names, and colloquial abbreviations. A production-grade synonym dictionary does not exist off-the-shelf for customs nomenclature.
  - Mitigation: Seed from WCO's HS nomenclature (available in EN/ES/FR). Extend with tenant-contributed synonyms. Budget ongoing curation effort.

---

## Architecture Opinions (Opinionated Decisions)

1. **Rule-based risk scoring over ML.** For a regulated domain where every score must be explainable to a fiscal auditor, a transparent rule engine with configurable weights is superior to a black-box ML model. ML can be layered on later for anomaly detection, but the primary scoring must be deterministic and auditable.

2. **RAG over fine-tuning for classification.** Fine-tuning an LLM on customs data is expensive, hard to update, and creates vendor lock-in. RAG with a well-curated vector index of SAC nomenclature is cheaper to maintain, easier to update when the SAC changes, and provides explicit citation grounding. Fine-tuning can be explored as an optimization in Phase 3.

3. **PostgreSQL append-only over blockchain/distributed ledger.** The audit trail does not need decentralized consensus. It needs tamper-evidence and query performance. A PostgreSQL table with no DELETE/UPDATE grants, row-level security, and sha256 hash chaining provides both. Periodic snapshots to immutable object storage (S3 Object Lock) provide the external tamper-evidence guarantee. Blockchain adds operational complexity for zero marginal benefit in a single-operator context.

4. **Port/Adapter pattern for all government integrations.** RIMM, ATENA, VUCE, and TRIBU-CR should each be behind a port (interface) with adapter implementations that can be swapped between mock, sandbox, and production. This is non-negotiable given GAP-001 and GAP-003.

5. **Tenant-scoped vector indexes.** Each tenant's historical corrections and synonym extensions live in a tenant-scoped vector namespace. The base SAC nomenclature is shared (global namespace). This prevents one agency's classification biases from leaking into another's suggestions while avoiding redundant storage of the common nomenclature.

---

## Assumptions Register

- Assumed: RIMM exposes a REST API with JSON responses following OMA v4.1 data model conventions. No public documentation confirms this.
- Assumed: ATENA's OpenID Connect flow allows service-to-service tokens for RIMM queries (not only interactive user tokens). If RIMM requires interactive authentication, the query skill needs a different design.
- Assumed: The $20,000 bond is per-agency, not per-declaration. The financial exposure dashboard aggregates across all pending declarations.
- Assumed: Costa Rica's data protection law (Ley 8968) permits processing commercial descriptions (non-PII) through a cloud LLM provider with a DPA. If regulators classify tariff data as sensitive, an on-premise model deployment becomes mandatory.
- Assumed: ATENA maintenance windows are predictable and published. If not, the cache TTL and degradation strategy need more aggressive tuning.
- Assumed: The existing `atena_auth` skill (Spike 001) handles token refresh and firma digital handshake. This spike depends on that skill being operational.
- Assumed: KYC/due diligence data is collected and stored by a separate subsystem. This spike consumes KYC status but does not implement KYC collection.

---

## Size Estimate: XL

### Breakdown by Phase

| Phase | Scope | Estimate |
|-------|-------|----------|
| **Phase A: Foundation** | RIMM port/adapter + mock, audit trail table + hash chain, classification data model, basic keyword search against cached SAC data | M (3-4 weeks) |
| **Phase B: AI Pipeline** | SAC corpus structuring, vector index build, RAG pipeline, LLM integration, suggestion UI, A/B testing infra | L (4-5 weeks) |
| **Phase C: Risk & Compliance** | Risk scoring engine, configurable weights, KYC gate integration, supervisor/compliance officer approval flows, financial exposure dashboard | M (3-4 weeks) |
| **Phase D: RIMM Live Integration** | Replace mock adapter with real RIMM client (blocked on GAP-001 resolution), VUCE cross-check, production hardening | S (2-3 weeks, assumes API spec is available) |

**Total: 12-16 weeks** for full delivery across all phases, with Phase A and Phase B partially parallelizable.

**Recommendation:** Ship Phase A first. It provides the audit trail, human confirmation flow, and basic RIMM search -- the minimum required for legal compliance. Phase B (AI suggestions) and Phase C (risk scoring) can follow as enhancements. Phase D is blocked on external dependency resolution.

---

## Dependencies on Other Spikes

| Dependency | Spike | Status |
|-----------|-------|--------|
| `atena_auth` skill (OpenID Connect + firma digital) | Spike 001 | Required before any RIMM or ATENA integration |
| DUA data model and JSON schema | Spike 001 | Required for dry-run validation |
| KYC/due diligence subsystem | TBD (not yet spiked) | Required for risk factor #5 and classification flow step 2 |
| Notification triggers (Telegram/WhatsApp) | Spike 003 | Optional: alert compliance officer on critical risk scores |
| DUCA-F/DUCA-T cross-border sync | Spike 004 | Required if classification must be consistent across PDCC submissions |
