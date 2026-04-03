# Product Roadmap — AduaNext

## Roadmap derivado del SRD Gap Audit (T0 → T2)

```mermaid
gantt
    title AduaNext Roadmap — M1 a M12
    dateFormat YYYY-MM-DD
    axisFormat %b %Y

    section T0 Blockers
    gRPC sidecar (hacienda-cr)     :t0-1, 2026-04-07, 14d
    AtenaAuthAdapter + RIMM adapter :t0-2, after t0-1, 7d
    Serverpod endpoints (CRUD DUA)  :t0-3, after t0-1, 14d
    Signing adapter (gRPC)          :t0-5, after t0-1, 3d

    section T1 Revenue Enablers
    Declaration state machine       :t1-1, after t0-3, 7d
    Flutter Web (Material 3, tablet):t1-4, after t0-3, 14d
    Risk pre-validation (5 reglas)  :t1-3, after t0-2, 7d
    Telegram notifications          :t1-2, after t1-1, 3d
    Onboarding Importer-Led         :t1-5, after t1-4, 7d

    section Beta
    Reclutar 5 agentes freelance    :beta-1, 2026-05-05, 14d
    Beta Vertivo (importacion real) :crit, beta-2, 2026-05-19, 7d

    section T2 Differentiators
    agentic-core sidecar (AI class) :t2-1, 2026-06-02, 14d
    Sandbox educativo               :t2-2, after t2-1, 7d
    Vetted Sourcer CRUD + trust     :t2-3, 2026-06-16, 14d
    Origin cert generator           :t2-4, after t2-3, 7d
    Docker Compose + K8s            :t2-5, 2026-06-02, 7d

    section Scale
    Matching marketplace            :s-1, 2026-07-01, 14d
    Premium tier (exportadores)     :s-2, 2026-07-01, 7d
    Guatemala pilot (SAT-GT)        :s-3, 2026-09-01, 30d
```

## Versionamiento (Semver)

| Version | Sprint | Contenido | Gate |
|---------|--------|-----------|------|
| **v0.1.0** | S1-S4 | T0 complete: auth + DUA + RIMM + signing + sandbox transmission | "Puede transmitir 1 DUA a ATENA sandbox?" |
| **v0.2.0** | S5-S6 | T1 complete: state machine + Flutter Web + risk + notifications + onboarding | "Puede un agente y una pyme completar el flujo end-to-end?" |
| **v0.3.0** | S7-S8 | Beta: Vertivo importacion real + 5 agentes + 3 pymes | "Funciona con datos reales?" |
| **v0.4.0** | S9-S12 | T2: AI classification + sandbox edu + vetted sourcers + K8s | "Tiene diferenciadores vs. manual ATENA?" |
| **v0.5.0** | S13-S16 | Scale: marketplace + premium + expansion prep | "$50K MRR?" |
| **v1.0.0** | S17+ | Guatemala pilot + multi-pais + production hardening | "Funciona en 2 paises?" |

## 3 Sidecars Architecture (desde v0.4.0)

```mermaid
flowchart TB
    subgraph POD["K8s Pod: AduaNext"]
        SP[Serverpod<br>Dart<br>Main API + ORM]
        HS[hacienda-sidecar<br>TypeScript<br>Auth + Signing + ATENA]
        AC[agentic-core-sidecar<br>Python<br>AI Classification + RAG]
    end

    SP <-->|gRPC :50051| HS
    SP <-->|gRPC :50052| AC
    HS <-->|REST| ATENA[ATENA API]
    HS <-->|REST| RIMM[RIMM Server]
    AC <-->|Embeddings| VDB[(Vector DB)]

    FW[Flutter Web<br>Tablet-first] <-->|HTTP/WS| SP
    TG[Telegram Bot] <-->|API| SP
```
