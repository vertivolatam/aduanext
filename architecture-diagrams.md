# AduaNext -- Architecture Diagrams

> Multi-tenant customs compliance platform for LATAM, starting with Costa Rica.
> Generated 2026-04-03 as part of the technical spike.

---

## Diagram 1: Modular Architecture (C4 Container Level)

This diagram shows AduaNext decomposed into its primary service containers and their relationships with external government systems. The architecture follows a modular monolith-ready design: each service can start as a module inside a single deployable and be extracted into an independent microservice when scale demands it.

Key decisions:
- **API Gateway** is the single entry point, enforcing rate limits, tenant resolution, and JWT validation before any request reaches an internal service.
- **Declaration Engine** is the heaviest module -- it owns the DUA lifecycle and orchestrates calls to Classification, Risk, and external adapters.
- **Marketplace Core** is intentionally decoupled from the declaration path so it can evolve on its own release cadence.
- External systems (ATENA, TRIBU-CR, VUCE 2.0, PDCC) are accessed exclusively through dedicated adapter services, never directly from business logic.

```mermaid
flowchart TB
    subgraph Users["Users & Channels"]
        CA["Customs Agent\n(Browser / Mobile)"]
        IMP["Importer\n(Portal)"]
        ADM["Admin\n(Back-office)"]
        BOT["Telegram / WhatsApp\nBot"]
    end

    subgraph AduaNext["AduaNext Platform"]
        GW["API Gateway\n(Kong / Envoy)\n- Tenant resolution\n- Rate limiting\n- JWT validation"]

        AUTH["Auth Service\n- OpenID Connect\n- Firma Digital handshake\n- Token refresh (atena_auth skill)"]

        DE["Declaration Engine\n- DUA lifecycle (CRUD)\n- Payload builder (OMA v4.1 JSON)\n- State machine orchestration"]

        CE["Classification Engine\n- RIMM query (rimm_query skill)\n- Tariff lookup & validation\n- HS code suggestion"]

        RE["Risk Engine\n- CIF value analysis\n- Description anomaly detection\n- Pre-validation scoring"]

        NS["Notification Service\n- Telegram dispatch\n- WhatsApp dispatch\n- Email / Webhook"]

        MC["Marketplace Core\n- Vetted sourcer registry\n- Product catalog\n- Origin certification"]

        AS["Audit Service\n- Immutable event log\n- Classification decision trail\n- Transmission record archive"]

        EB["Event Bus\n(NATS / RabbitMQ)"]
    end

    subgraph External["External Government Systems"]
        ATENA["ATENA\n(Customs - replaces TICA)\nREST + OpenID Connect"]
        TRIBU["TRIBU-CR\n(Tax platform)\nD-270 / IVA / Renta"]
        VUCE["VUCE 2.0\n(Trade single window)\nPermits & tech notes"]
        PDCC["PDCC\n(Central American trade)\nDUCA-F / DUCA-T"]
    end

    CA --> GW
    IMP --> GW
    ADM --> GW
    BOT --> GW

    GW --> AUTH
    GW --> DE
    GW --> CE
    GW --> RE
    GW --> MC

    DE --> CE
    DE --> RE
    DE --> AS
    DE --> EB

    CE --> AS
    RE --> AS

    EB --> NS

    DE -.->|"atena_auth + DUA submit"| ATENA
    CE -.->|"rimm_query"| ATENA
    DE -.->|"D-270 cross-ref"| TRIBU
    DE -.->|"Permit validation"| VUCE
    DE -.->|"cross_border_sync\nDUCA-F/T mapping"| PDCC

    style AduaNext fill:#1a1a2e,stroke:#e94560,color:#eee
    style External fill:#0f3460,stroke:#16213e,color:#eee
    style Users fill:#162447,stroke:#1b1b2f,color:#eee
```

---

## Diagram 2: Hexagonal Architecture (Ports and Adapters)

This diagram enforces the Dependency Rule: all arrows point inward. The domain core knows nothing about HTTP, gRPC, databases, or external APIs. Every interaction passes through a port (interface) that the domain defines and an adapter (implementation) that the infrastructure provides.

Key decisions:
- **Inbound ports** are defined as use-case interfaces (e.g., `SubmitDeclaration`, `ClassifyProduct`). REST controllers and gRPC handlers are adapters that call these ports.
- **Outbound ports** are repository and gateway interfaces. The domain says "I need to persist a declaration" or "I need to query ATENA" -- adapters decide how.
- The **Event Bus port** allows the domain to emit events without knowing whether NATS, RabbitMQ, or Kafka is underneath.
- This pattern makes the system testable: every adapter can be swapped for an in-memory stub during unit tests.

```mermaid
flowchart TB
    subgraph InboundAdapters["INBOUND ADAPTERS (Driving)"]
        REST["REST API Controller\n(Express / Fastify)"]
        GRPC["gRPC Server\n(inter-service calls)"]
        EBIN["Event Bus Consumer\n(NATS / RabbitMQ)"]
        CLI["CLI / Agent Runner\n(Hermes / NemoClaw)"]
    end

    subgraph InboundPorts["INBOUND PORTS (Use Cases)"]
        IP1["SubmitDeclaration"]
        IP2["ClassifyProduct"]
        IP3["EvaluateRisk"]
        IP4["RegisterSourcer"]
        IP5["QueryDeclarationStatus"]
    end

    subgraph Domain["DOMAIN CORE"]
        direction TB
        DEC["Declarations\n- DUA aggregate\n- State machine\n- Validation rules"]
        CLASS["Classification\n- HS code resolution\n- Tariff note matching\n- Trade agreement lookup"]
        RISK["Risk Assessment\n- CIF anomaly model\n- Description scoring\n- Historical pattern check"]
        MARKET["Marketplace\n- Sourcer vetting\n- Origin cert verification"]
        EVENTS["Domain Events\n- DeclarationSubmitted\n- ClassificationCompleted\n- RiskFlagged\n- LevanteConceded"]
    end

    subgraph OutboundPorts["OUTBOUND PORTS (Interfaces)"]
        OP1["DeclarationRepository"]
        OP2["TariffCatalogGateway"]
        OP3["CustomsAuthorityGateway"]
        OP4["TaxPlatformGateway"]
        OP5["TradeWindowGateway"]
        OP6["CrossBorderGateway"]
        OP7["NotificationGateway"]
        OP8["AuditLogWriter"]
        OP9["EventPublisher"]
    end

    subgraph OutboundAdapters["OUTBOUND ADAPTERS (Driven)"]
        PG["PostgreSQL Adapter\n(Prisma / Drizzle)"]
        RIMM_A["RIMM Adapter\n(rimm_query skill)"]
        ATENA_A["ATENA Adapter\n(atena_auth skill + REST)"]
        TRIBU_A["TRIBU-CR Adapter\n(REST / SOAP bridge)"]
        VUCE_A["VUCE 2.0 Adapter\n(REST + firma digital)"]
        PDCC_A["PDCC Adapter\n(cross_border_sync skill)"]
        NOTIF_A["Notification Adapter\n(Telegram / WhatsApp API)"]
        AUDIT_A["Audit Log Adapter\n(Append-only store)"]
        EVPUB_A["Event Bus Publisher\n(NATS / RabbitMQ)"]
    end

    REST --> IP1
    REST --> IP2
    REST --> IP5
    GRPC --> IP1
    GRPC --> IP3
    EBIN --> IP3
    EBIN --> IP4
    CLI --> IP1
    CLI --> IP2

    IP1 --> DEC
    IP2 --> CLASS
    IP3 --> RISK
    IP4 --> MARKET
    IP5 --> DEC

    DEC --> OP1
    DEC --> OP3
    DEC --> OP8
    DEC --> OP9
    CLASS --> OP2
    CLASS --> OP8
    RISK --> OP3
    RISK --> OP8
    MARKET --> OP5
    EVENTS --> OP7
    EVENTS --> OP9

    OP1 --> PG
    OP2 --> RIMM_A
    OP3 --> ATENA_A
    OP4 --> TRIBU_A
    OP5 --> VUCE_A
    OP6 --> PDCC_A
    OP7 --> NOTIF_A
    OP8 --> AUDIT_A
    OP9 --> EVPUB_A

    style Domain fill:#1b4332,stroke:#52b788,color:#d8f3dc
    style InboundPorts fill:#2d6a4f,stroke:#40916c,color:#d8f3dc
    style OutboundPorts fill:#2d6a4f,stroke:#40916c,color:#d8f3dc
    style InboundAdapters fill:#081c15,stroke:#1b4332,color:#b7e4c7
    style OutboundAdapters fill:#081c15,stroke:#1b4332,color:#b7e4c7
```

---

## Diagram 3: Kubernetes Sidecar Pattern

This diagram shows the "Sidecar / Plugin" deployment mode. Many customs agencies already run their own ERP or legacy dispatch system. Instead of replacing that system, AduaNext deploys as a sidecar container inside the same Kubernetes Pod. The sidecar intercepts outbound customs calls, enriches them with risk pre-validation and classification, and proxies them to ATENA.

Key decisions:
- **Shared volume** (`/shared/declarations`) allows the agency system to drop JSON declaration files that the sidecar picks up, enriches, and transmits.
- **Envoy proxy sidecar** handles mTLS termination and traffic splitting so the agency system does not need to implement firma digital directly.
- **Init container** bootstraps tenant configuration and pulls the latest tariff catalog on pod startup.
- The sidecar exposes a local-only API on `localhost:9090` so the agency system can call AduaNext features without any network hop.

```mermaid
flowchart TB
    subgraph K8sCluster["Kubernetes Cluster"]
        subgraph Node1["Worker Node"]
            subgraph Pod["Pod: agency-dispatch-pod"]
                direction LR

                subgraph InitContainer["Init Container"]
                    INIT["aduanext-init\n- Pull tenant config\n- Sync tariff catalog\n- Verify firma digital cert"]
                end

                subgraph MainContainer["Main Container"]
                    AGENCY["Agency Legacy System\n(ERP / Dispatch App)\n- Generates DUA drafts\n- Writes to shared volume\n- Calls localhost:9090"]
                end

                subgraph SidecarContainer["Sidecar Container"]
                    ADUA["AduaNext Sidecar\n- REST API on :9090\n- File watcher on /shared\n- Risk pre-validation\n- Classification enrichment\n- ATENA submission proxy"]
                end

                subgraph ProxyContainer["Envoy Proxy Sidecar"]
                    ENVOY["Envoy Proxy\n- mTLS termination\n- Firma Digital injection\n- Traffic routing\n- Retry / circuit-breaker"]
                end

                VOL[("Shared Volume\n/shared/declarations\n- draft/*.json\n- enriched/*.json\n- submitted/*.json\n- responses/*.json")]

                AGENCY -->|"localhost:9090\n(enrichment API)"| ADUA
                AGENCY -->|"write draft JSON"| VOL
                ADUA -->|"read draft,\nwrite enriched"| VOL
                ADUA -->|"outbound HTTPS\nvia proxy"| ENVOY
            end

            subgraph PodSupport["Pod-Level Resources"]
                SA["ServiceAccount\n(RBAC for secrets)"]
                SEC["Secrets\n- ATENA credentials\n- Firma Digital cert\n- Tenant API key"]
                CM["ConfigMap\n- Tenant config\n- Feature flags\n- RIMM endpoint"]
            end
        end

        subgraph Services["Cluster Services"]
            SVC_ADUA["Service: aduanext-sidecar\n(ClusterIP, port 9090)"]
            SVC_METRICS["Service: metrics\n(ClusterIP, port 9091)"]
        end
    end

    subgraph ExternalSystems["External Systems"]
        ATENA_EXT["ATENA API Gateway\n(api.hacienda.go.cr)"]
        RIMM_EXT["RIMM Catalog\n(rimm.hacienda.go.cr)"]
        NOTIF_EXT["Notification APIs\n(Telegram / WhatsApp)"]
    end

    ENVOY -->|"mTLS + JWT"| ATENA_EXT
    ENVOY -->|"HTTPS"| RIMM_EXT
    ADUA -->|"webhook"| NOTIF_EXT

    SA -.-> Pod
    SEC -.-> Pod
    CM -.-> Pod

    InitContainer -->|"runs before\nmain containers"| MainContainer
    InitContainer -->|"runs before\nmain containers"| SidecarContainer

    style Pod fill:#1a1a2e,stroke:#e94560,color:#eee
    style K8sCluster fill:#0d1117,stroke:#30363d,color:#c9d1d9
    style ExternalSystems fill:#0f3460,stroke:#16213e,color:#eee
```

---

## Diagram 4: Declaration Lifecycle State Machine

This state machine models the full lifecycle of a DUA (Declaracion Unica Aduanera) in ATENA. Each transition triggers audit logging and, where indicated, notifications to the customs agent via Telegram/WhatsApp.

Key decisions:
- **Draft** is the only state where edits are unrestricted. Once submitted, the declaration is immutable from the agent's perspective.
- **Risk Pre-Validation** is an AduaNext-internal step that runs before the official ATENA validation, catching CIF anomalies and description issues early.
- **Manual Review** is a holding state entered when the risk score exceeds a threshold or ATENA flags the declaration.
- **Rejected** is not terminal -- the agent can correct and resubmit, creating a new version linked to the original.
- **Levante (Released)** is the terminal success state, meaning the goods are cleared for release.

```mermaid
stateDiagram-v2
    [*] --> Draft: Agent creates declaration

    Draft --> Submitted: Agent submits\n[payload validated locally]
    Draft --> Cancelled: Agent cancels

    Submitted --> RiskPreValidation: AduaNext internal check\n>> Notification: "DUA submitted"

    RiskPreValidation --> Stored: Risk score OK\n(score < threshold)
    RiskPreValidation --> ManualReview: Risk score HIGH\n(CIF anomaly / generic desc)\n>> Notification: "Risk flag - review needed"

    ManualReview --> Stored: Agent corrects & resubmits\n[new version created]
    ManualReview --> Rejected: Agent cannot resolve\n>> Notification: "DUA rejected after review"

    Stored --> ATENAValidation: Transmitted to ATENA\n>> Notification: "DUA stored in ATENA"

    ATENAValidation --> Validated: ATENA accepts\n[no discrepancies]
    ATENAValidation --> ATENARejected: ATENA rejects\n(format / rule violation)\n>> Notification: "ATENA rejection"

    ATENARejected --> ManualReview: Agent reviews\nATENA error codes

    Validated --> Liquidated: Taxes calculated\n(DAI + IVA + selective)\n>> Notification: "Liquidation ready"

    Liquidated --> PaymentPending: Awaiting tax payment

    PaymentPending --> PaymentConfirmed: Payment received\n(SINPE / bank)\n>> Notification: "Payment confirmed"
    PaymentPending --> PaymentFailed: Payment timeout / failure\n>> Notification: "Payment failed"

    PaymentFailed --> PaymentPending: Retry payment

    PaymentConfirmed --> PhysicalInspection: Random or risk-based\nATENA selects for inspection
    PaymentConfirmed --> Released: No inspection required\n(green channel)

    PhysicalInspection --> Released: Inspection passed\n>> Notification: "Goods cleared"
    PhysicalInspection --> Held: Discrepancy found\n>> Notification: "Goods held at customs"

    Held --> ManualReview: Requires correction\nor additional docs

    Released --> [*]: LEVANTE conceded\n>> Notification: "Levante! Goods released"

    Cancelled --> [*]: Terminal

    Rejected --> Draft: Agent creates\ncorrected version

    note right of RiskPreValidation
        AduaNext pre-validation step.
        Runs BEFORE ATENA submission.
        Catches CIF anomalies,
        generic descriptions, and
        missing trade agreement refs.
    end note

    note right of Released
        "Levante" = final customs
        release authorization.
        Goods can leave the
        bonded warehouse.
    end note
```

---

## Diagram 5: Sequence Diagram -- Agent to Gateway to ATENA

This sequence diagram traces the full lifecycle of a DUA submission, from the customs agent's browser through AduaNext's internal services to ATENA and back. It shows the auth handshake, risk pre-validation, ATENA transmission, and notification dispatch.

Key decisions:
- Authentication happens once and tokens are cached; the `atena_auth` skill handles refresh transparently.
- Risk pre-validation runs in parallel with classification enrichment to minimize latency.
- All interactions are logged to the Audit Service for regulatory compliance.
- Notifications are dispatched asynchronously via the Event Bus so they never block the main flow.

```mermaid
sequenceDiagram
    actor Agent as Customs Agent
    participant GW as API Gateway
    participant AUTH as Auth Service<br/>(atena_auth)
    participant DE as Declaration Engine
    participant CE as Classification Engine<br/>(rimm_query)
    participant RE as Risk Engine
    participant AS as Audit Service
    participant ATENA as ATENA API<br/>(Hacienda)
    participant EB as Event Bus
    participant NS as Notification Service

    Note over Agent, NS: Phase 1 -- Authentication Handshake

    Agent->>GW: POST /auth/login (firma digital cert)
    GW->>AUTH: Validate firma digital + OpenID Connect
    AUTH->>ATENA: OpenID Connect token request (client_credentials)
    ATENA-->>AUTH: JWT access_token + refresh_token
    AUTH->>AUTH: Cache tokens, set expiry timer
    AUTH-->>GW: Session token + ATENA bearer
    GW-->>Agent: 200 OK (session established)

    Note over Agent, NS: Phase 2 -- DUA Submission

    Agent->>GW: POST /declarations (DUA payload, OMA v4.1 JSON)
    GW->>GW: Resolve tenant, validate JWT
    GW->>DE: Forward declaration request

    DE->>AS: Log: "Declaration received" (draft)
    DE->>DE: Schema validation (OMA v4.1)

    Note over DE, RE: Phase 3 -- Parallel Enrichment & Risk Check

    par Classification Enrichment
        DE->>CE: Classify items (HS codes, descriptions)
        CE->>ATENA: GET /rimm/tariff-lookup (rimm_query skill)
        ATENA-->>CE: Tariff data + applicable notes
        CE->>CE: Validate HS codes, suggest corrections
        CE-->>DE: Enriched classification result
        CE->>AS: Log: classification decision trail
    and Risk Pre-Validation
        DE->>RE: Evaluate risk (CIF values, descriptions, origin)
        RE->>RE: Run anomaly models
        RE->>RE: Check historical patterns
        RE-->>DE: Risk score + flags
        RE->>AS: Log: risk assessment result
    end

    alt Risk Score HIGH (above threshold)
        DE->>AS: Log: "Manual review required"
        DE->>EB: Emit: RiskFlagged event
        EB->>NS: Consume RiskFlagged
        NS->>Agent: Telegram: "DUA requires manual review - risk flag"
        DE-->>GW: 202 Accepted (status: manual_review)
        GW-->>Agent: 202 - Review required
    else Risk Score OK
        Note over DE, ATENA: Phase 4 -- ATENA Transmission

        DE->>AUTH: Get fresh ATENA bearer token
        AUTH-->>DE: Bearer token (refreshed if needed)

        DE->>ATENA: POST /dua/submit (enriched payload + bearer)
        DE->>AS: Log: "Transmitted to ATENA"

        alt ATENA Accepts
            ATENA-->>DE: 200 OK (DUA stored, liquidation data)
            DE->>DE: Update state: Stored -> Validated -> Liquidated
            DE->>AS: Log: "ATENA accepted, liquidation calculated"
            DE->>EB: Emit: DeclarationValidated event
            EB->>NS: Consume DeclarationValidated
            NS->>Agent: Telegram: "DUA accepted! Taxes: $X DAI + $Y IVA"
            DE-->>GW: 200 OK (declaration validated)
            GW-->>Agent: 200 - Declaration processed
        else ATENA Rejects
            ATENA-->>DE: 422 Error (error codes + details)
            DE->>DE: Update state: ATENARejected
            DE->>AS: Log: "ATENA rejected" + error codes
            DE->>EB: Emit: DeclarationRejected event
            EB->>NS: Consume DeclarationRejected
            NS->>Agent: Telegram: "ATENA rejected DUA - errors: [codes]"
            DE-->>GW: 422 Unprocessable (ATENA errors)
            GW-->>Agent: 422 - Correction needed
        end
    end
```

---

## Diagram 6: Multi-Tenant Data Architecture

This diagram shows how AduaNext isolates tenant data while sharing infrastructure. The hybrid approach uses a shared database with schema-per-tenant for strong isolation of sensitive customs data, plus a shared schema with tenant discriminator for cross-cutting concerns like the tariff catalog.

Key decisions:
- **Tenant Registry** is the single source of truth for tenant metadata. It lives in a shared schema and maps each tenant to its country, hacienda, auth configuration, and feature flags.
- **Schema-per-tenant** is used for declarations, audit logs, and financial data because Costa Rican law requires strict data isolation between agencies (the caution bond of $20,000 USD means one agency's error must never leak into another's records).
- **Shared schema with discriminator** is used for reference data (tariff catalog, trade agreements, HS codes) because this data is country-specific but not agency-specific.
- **Country configuration** is a first-class concept: when AduaNext expands to Guatemala or Panama, a new country config is added without code changes.

```mermaid
flowchart TB
    subgraph AppLayer["Application Layer"]
        TM["Tenant Middleware\n- Extracts tenant_id from JWT\n- Sets schema search_path\n- Injects country config"]
    end

    subgraph TenantRegistry["Tenant Registry (Shared Schema: public)"]
        TR[("tenants\n- id (UUID)\n- name\n- country_code (CR, GT, PA...)\n- hacienda_id\n- schema_name\n- subscription_tier\n- is_active")]

        CC[("country_configs\n- country_code (PK)\n- customs_api_base_url\n- tax_platform_url\n- auth_provider_config (JSONB)\n- tariff_version\n- currency_code")]

        FF[("feature_flags\n- tenant_id (FK)\n- flag_name\n- enabled\n- config_json")]

        TR --- CC
        TR --- FF
    end

    subgraph SharedRef["Shared Reference Data (Schema: reference)"]
        TA[("tariff_catalog\n- hs_code (PK)\n- country_code\n- description\n- duty_rate_dai\n- duty_rate_selective\n- iva_rate\n- trade_notes\n- effective_date")]

        TRADE[("trade_agreements\n- id\n- agreement_code\n- origin_country\n- dest_country\n- preferential_rate\n- rules_of_origin")]

        INCO[("incoterms\n- code (PK)\n- name\n- responsibilities_json")]
    end

    subgraph TenantSchemas["Isolated Tenant Schemas"]
        subgraph SchemaA["Schema: tenant_agencia_alpha"]
            DA[("declarations\n- id, tenant_id\n- dua_number\n- status (state machine)\n- payload_json (OMA v4.1)\n- risk_score\n- atena_response")]

            AUDA[("audit_logs\n- id, timestamp\n- action, actor\n- entity_type, entity_id\n- before_state, after_state\n- ip_address")]

            FINA[("financial_records\n- declaration_id\n- dai_amount\n- iva_amount\n- selective_amount\n- payment_status\n- payment_ref")]
        end

        subgraph SchemaB["Schema: tenant_aduanas_beta"]
            DB[("declarations\n(same structure,\nfully isolated)")]

            AUDB[("audit_logs\n(same structure,\nfully isolated)")]

            FINB[("financial_records\n(same structure,\nfully isolated)")]
        end

        subgraph SchemaN["Schema: tenant_..._N"]
            DN["..."]
        end
    end

    subgraph MigrationLayer["Migration & Provisioning"]
        PROV["Tenant Provisioner\n- CREATE SCHEMA tenant_xxx\n- Run migrations\n- Seed country defaults\n- Configure auth keys"]

        MIG["Schema Migrator\n- Shared migrations (reference)\n- Per-tenant migrations\n- Version tracking per schema"]
    end

    TM -->|"SET search_path = tenant_xxx"| SchemaA
    TM -->|"SET search_path = tenant_xxx"| SchemaB
    TM -->|"Always accessible"| SharedRef
    TM -->|"Lookup tenant"| TenantRegistry

    PROV --> SchemaA
    PROV --> SchemaB
    PROV --> SchemaN
    MIG --> SharedRef
    MIG --> SchemaA
    MIG --> SchemaB

    style TenantRegistry fill:#1a1a2e,stroke:#e94560,color:#eee
    style SharedRef fill:#16213e,stroke:#0f3460,color:#eee
    style TenantSchemas fill:#0f3460,stroke:#1a1a2e,color:#eee
    style MigrationLayer fill:#162447,stroke:#1b1b2f,color:#eee
```

---

## Diagram 7: Vetted Sourcers Marketplace -- Entity Relationship

This ER diagram models the marketplace where pre-vetted international suppliers (sourcers) offer products to customs agencies and importers. The marketplace is integrated into the declaration flow: when an importer selects a sourcer's product, the origin certification and trade agreement data auto-populate the DUA.

Key decisions:
- **Sourcer** has a vetting status that must be APPROVED before products are visible in the marketplace. Vetting includes document verification, trade reference checks, and compliance screening.
- **OriginCertification** is a first-class entity because proof of origin determines preferential tariff rates under trade agreements like DR-CAFTA or the EU-Central America Association Agreement.
- **INCOTERMProfile** is attached to the Sourcer-Product relationship because the same sourcer may offer different INCOTERM conditions for different products or destinations.
- **Declaration** links back to products, creating a traceable chain from supplier to customs release.

```mermaid
erDiagram
    CUSTOMS_AGENCY {
        uuid id PK
        string name
        string hacienda_license_number
        string country_code
        decimal caution_bond_usd
        string status "ACTIVE | SUSPENDED"
        timestamp created_at
    }

    CUSTOMS_AGENT {
        uuid id PK
        uuid agency_id FK
        string full_name
        string license_number
        string firma_digital_serial
        string role "AGENT | ASSISTANT"
    }

    SOURCER {
        uuid id PK
        string company_name
        string country_of_origin
        string tax_id
        string vetting_status "PENDING | APPROVED | REJECTED | SUSPENDED"
        date vetting_expiry
        decimal compliance_score
        jsonb contact_info
        timestamp onboarded_at
    }

    PRODUCT {
        uuid id PK
        uuid sourcer_id FK
        string hs_code
        string commercial_description
        string technical_description
        string unit_of_measure
        decimal unit_price_usd
        string currency
        boolean is_active
    }

    ORIGIN_CERTIFICATION {
        uuid id PK
        uuid product_id FK
        uuid sourcer_id FK
        string certificate_number
        string issuing_authority
        string origin_country
        date issue_date
        date expiry_date
        string status "VALID | EXPIRED | REVOKED"
        string document_url
    }

    TRADE_AGREEMENT {
        uuid id PK
        string agreement_code "DR-CAFTA | EU-CA | CPTPP"
        string agreement_name
        string origin_country
        string destination_country
        decimal preferential_rate_pct
        jsonb rules_of_origin
        date effective_from
        date effective_until
    }

    INCOTERM_PROFILE {
        uuid id PK
        uuid sourcer_id FK
        uuid product_id FK
        string incoterm_code "FOB | CIF | EXW | DDP"
        string port_of_origin
        string port_of_destination
        decimal estimated_freight_usd
        decimal estimated_insurance_usd
    }

    DECLARATION {
        uuid id PK
        uuid agency_id FK
        uuid agent_id FK
        string dua_number
        string declaration_type "IMPORT | EXPORT | TRANSIT"
        string status "DRAFT | SUBMITTED | VALIDATED | RELEASED"
        jsonb payload_oma_v41
        decimal total_cif_usd
        decimal total_taxes
        timestamp submitted_at
        timestamp released_at
    }

    DECLARATION_ITEM {
        uuid id PK
        uuid declaration_id FK
        uuid product_id FK
        uuid origin_cert_id FK
        uuid trade_agreement_id FK
        integer line_number
        string hs_code
        decimal quantity
        decimal unit_value_usd
        decimal cif_value_usd
        decimal dai_amount
        decimal iva_amount
    }

    CUSTOMS_AGENCY ||--o{ CUSTOMS_AGENT : "employs"
    CUSTOMS_AGENCY ||--o{ DECLARATION : "files"
    CUSTOMS_AGENT ||--o{ DECLARATION : "signs"

    SOURCER ||--o{ PRODUCT : "offers"
    SOURCER ||--o{ ORIGIN_CERTIFICATION : "provides"
    SOURCER ||--o{ INCOTERM_PROFILE : "defines terms"

    PRODUCT ||--o{ ORIGIN_CERTIFICATION : "certified by"
    PRODUCT ||--o{ INCOTERM_PROFILE : "shipped under"
    PRODUCT ||--o{ DECLARATION_ITEM : "referenced in"

    DECLARATION ||--o{ DECLARATION_ITEM : "contains"

    DECLARATION_ITEM }o--|| ORIGIN_CERTIFICATION : "backed by"
    DECLARATION_ITEM }o--o| TRADE_AGREEMENT : "applies"

    TRADE_AGREEMENT }o--o{ PRODUCT : "covers (via HS code match)"
```

---

## Diagram 8: System Context (C4 Level 1)

This is the highest-level view of AduaNext. It shows who uses the system, what it does at the boundary level, and which external systems it depends on. This diagram is intended for stakeholders who need to understand scope without implementation details.

Key decisions:
- **Three user personas** reflect the Costa Rican customs ecosystem: the Customs Agent (primary power user), the Importer (limited self-service portal), and the Admin (platform operator for multi-tenant management).
- **Messaging channels** (Telegram/WhatsApp) are shown as external systems because AduaNext does not own them -- it integrates via their APIs for notification dispatch.
- **ATENA** is the most critical external dependency. AduaNext cannot function without it because ATENA is the system of record for all customs declarations in Costa Rica.
- **PDCC** enables the cross-border expansion strategy: once AduaNext supports DUCA-F/T through PDCC, it can handle transit declarations across all Central American countries.

```mermaid
flowchart TB
    subgraph Users["People"]
        AGENT["Customs Agent\n[Person]\n\nPrimary user. Files DUA\ndeclarations, classifies\ngoods, tracks shipments."]

        IMPORTER["Importer / Exporter\n[Person]\n\nViews declaration status,\nuploads commercial docs,\nselects vetted sourcers."]

        ADMIN["Platform Admin\n[Person]\n\nManages tenants, monitors\nsystem health, configures\ncountry rules."]
    end

    subgraph System["AduaNext"]
        AN["AduaNext\n[Software System]\n\nMulti-tenant customs compliance\nplatform. Manages DUA lifecycle,\ntariff classification, risk\npre-validation, and cross-border\ntrade for LATAM agencies.\n\nDeployment: Standalone SaaS\nor Kubernetes Sidecar."]
    end

    subgraph GovSystems["Government Systems"]
        ATENA_SYS["ATENA\n[External System]\n\nCosta Rica integrated customs\nmanagement. Replaces TICA.\nOpenID Connect + REST.\nDUA storage, validation,\nliquidation, levante."]

        TRIBU_SYS["TRIBU-CR\n[External System]\n\nCosta Rica unified tax platform.\nReplaces ATV. Manages IVA,\nRenta, D-270 monthly\ninformative declarations."]

        VUCE_SYS["VUCE 2.0\n[External System]\n\nSingle window for foreign trade.\nManages import/export permits,\ntechnical notes, phytosanitary\ncertificates via PROCOMER."]

        PDCC_SYS["PDCC\n[External System]\n\nCentral American Digital\nTrade Platform. Handles\nDUCA-F (invoice) and\nDUCA-T (transit) for\ncross-border operations."]
    end

    subgraph Messaging["Messaging Channels"]
        TG["Telegram Bot API\n[External System]\n\nReal-time notifications\nfor declaration status\nchanges and alerts."]

        WA["WhatsApp Business API\n[External System]\n\nNotifications for agents\nwho prefer WhatsApp.\nTemplate-based messages."]
    end

    subgraph DigitalID["Identity Providers"]
        FD["Firma Digital (BCCR)\n[External System]\n\nCosta Rica national digital\nsignature infrastructure.\nRequired for all customs\ntransmissions."]
    end

    AGENT -->|"Files declarations,\nclassifies goods,\nmonitors status"| AN
    IMPORTER -->|"Views status,\nuploads documents,\nbrowses marketplace"| AN
    ADMIN -->|"Manages tenants,\nconfigures rules,\nmonitors health"| AN

    AN -->|"Submit DUA, query RIMM,\nreceive levante\n[REST + OpenID Connect]"| ATENA_SYS
    AN -->|"Cross-reference tax data,\nD-270 validation\n[REST]"| TRIBU_SYS
    AN -->|"Validate permits,\nrequest technical notes\n[REST + firma digital]"| VUCE_SYS
    AN -->|"DUCA-F/T submission,\ncross-border sync\n[REST + XML/JSON]"| PDCC_SYS

    AN -->|"Send status\nnotifications"| TG
    AN -->|"Send status\nnotifications"| WA

    AN -->|"Authenticate\ntransmissions"| FD

    style AN fill:#e94560,stroke:#1a1a2e,color:#fff
    style Users fill:#162447,stroke:#1b1b2f,color:#eee
    style GovSystems fill:#0f3460,stroke:#16213e,color:#eee
    style Messaging fill:#1a1a2e,stroke:#e94560,color:#eee
    style DigitalID fill:#16213e,stroke:#0f3460,color:#eee
```

---

## Summary of Architectural Decisions

| Decision | Rationale |
|---|---|
| Hexagonal (Ports & Adapters) core | Isolates domain logic from infrastructure. Enables testing without ATENA connectivity. Adapters can be swapped per deployment mode (SaaS vs Sidecar). |
| Schema-per-tenant for sensitive data | Costa Rican law requires strict isolation between customs agencies. The $20,000 USD caution bond creates legal liability that cannot tolerate data leakage. |
| Shared schema for reference data | Tariff catalogs, trade agreements, and INCOTERM definitions are country-level, not agency-level. Sharing avoids duplication and ensures consistency. |
| Kubernetes Sidecar deployment option | Many agencies already have dispatch systems. The sidecar pattern lets AduaNext add value without requiring a full system replacement, reducing adoption friction. |
| Risk pre-validation before ATENA | Catching CIF anomalies and generic descriptions before transmission prevents ATENA rejections, which are costly (time, reputation, potential fines). |
| Event-driven notifications | Decouples the critical declaration path from notification delivery. If Telegram is down, declarations still process. |
| Agent skills as named capabilities | `atena_auth`, `rimm_query`, and `cross_border_sync` are reusable skills that can be invoked by both the SaaS platform and the sidecar runtime. |
| Immutable audit log | Regulatory requirement under Costa Rican customs law. Every classification decision and transmission must be traceable for post-clearance audits. |
