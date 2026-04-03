# Auditoría de Brechas — AduaNext

## Matriz Persona x Jornada

| | J01 DUA Export | J02 Clasificación | J03 Monitoreo | J04 Importer-Led | J05 Sandbox Edu | J06 Vetted Sourcer | J07 Auth gRPC |
|---|---|---|---|---|---|---|---|
| **P01 María (Agencia)** | CRITICO | CRITICO | Alto | Medio | Bajo | Bajo | CRITICO |
| **P02 Carlos (Freelance)** | CRITICO | CRITICO | Alto | Medio | N/A | Bajo | CRITICO |
| **P03 Andrea (Pyme)** | Alto | Alto | CRITICO | CRITICO | Bajo | Alto | Alto |
| **P04 Prof. Vargas (Univ)** | Bajo | Medio | Bajo | N/A | CRITICO | N/A | Medio |
| **P05 Diego (Exportador)** | Alto | Medio | CRITICO | Alto | N/A | Medio | Alto |
| **P06 Lucía (Sourcer)** | Bajo | Alto | Bajo | Medio | N/A | CRITICO | Bajo |
| **P07 Ana (Estudiante)** | N/A | Medio | N/A | N/A | CRITICO | N/A | Medio |

## Revenue en Riesgo por Jornada Rota

| Jornada | Score | Revenue mensual en riesgo | Personas afectadas |
|---------|-------|--------------------------|-------------------|
| J01 DUA Export | 35% | **$30,000/mes** (60% MRR) | P01, P02, P03, P05 |
| J07 Auth gRPC | 40% | **$50,000/mes** (100% — bloqueador) | Todas |
| J02 Clasificación | 20% | **$22,000/mes** (44%) | P01, P02, P03, P06 |
| J04 Importer-Led | 0% | **$14,400/mes** (29%) | P03, P05 |
| J03 Monitoreo | 15% | **$12,000/mes** (24%) | P03, P05 |
| J06 Vetted Sourcer | 0% | **$3,000/mes** (6%) | P06 |
| J05 Sandbox Edu | 0% | **$3,200/mes** (6%) | P04, P07 |

## Viabilidad de Personas

| Persona | Jornadas críticas completadas | Viable? | Bloqueador principal |
|---------|-------------------------------|---------|---------------------|
| P01 María (36% revenue) | 0 de 3 | NO | J07 Auth + J01 DUA Export |
| P02 Carlos (5% revenue) | 0 de 3 | NO | J07 Auth + J01 DUA Export |
| P03 Andrea (29% revenue) | 0 de 4 | NO | J04 Onboarding Importer-Led |
| P04 Prof. Vargas (6% revenue) | 0 de 1 | NO | J05 Sandbox Edu |
| P05 Diego (14% revenue) | 0 de 3 | NO | J03 Monitoreo + J07 Auth |
| P06 Lucía (6% revenue) | 0 de 1 | NO | J06 Vetted Sourcer |
| P07 Ana (0% revenue) | 0 de 1 | NO | J05 Sandbox Edu |

**Ninguna persona es viable hoy.** El codebase tiene la arquitectura definida (Ports, Entities, Protos, Value Objects) pero cero implementación de UI, endpoints, o adapters.

## Lista de Fixes por Tier

### T0 — Bloqueadores (sin estos, $0 revenue)

| # | Fix | Revenue en riesgo | Jornada | Esfuerzo |
|---|-----|-------------------|---------|----------|
| T0-1 | **Implementar gRPC sidecar con hacienda-cr** | $50K (100%) | J07 | L — 2 semanas |
| T0-2 | **Implementar AtenaAuthAdapter** (Dart gRPC client) | $50K (100%) | J07 | M — 1 semana |
| T0-3 | **Serverpod endpoints básicos** (CRUD Declaration) | $30K (60%) | J01 | L — 2 semanas |
| T0-4 | **RimmTariffCatalogAdapter** (/commodity/search) | $22K (44%) | J02 | M — 1 semana |
| T0-5 | **HaciendaSigningAdapter** (gRPC sign flow) | $30K (60%) | J01 | S — 3 días |

**T0 total:** Sin estas 5 piezas, AduaNext no puede procesar una sola DUA.
**Dependencia:** T0-1 debe completarse primero (todo depende del sidecar gRPC).

### T1 — Revenue Enablers (habilitan los primeros clientes pagos)

| # | Fix | Revenue habilitado | Jornada | Esfuerzo |
|---|-----|-------------------|---------|----------|
| T1-1 | **Declaration state machine** (15+ estados) | $30K | J03 | M — 1 semana |
| T1-2 | **Notificaciones Telegram** | $12K | J03 | S — 3 días |
| T1-3 | **Risk pre-validation engine** (25 reglas) | $22K | J01 | M — 1 semana |
| T1-4 | **Flutter mobile dashboard** (lista DUAs + estado) | $14K | J03, J04 | L — 2 semanas |
| T1-5 | **Onboarding Importer-Led** (registro + invitación agente) | $14K | J04 | M — 1 semana |

### T2 — Diferenciadores (expanden mercado y retención)

| # | Fix | Revenue habilitado | Jornada | Esfuerzo |
|---|-----|-------------------|---------|----------|
| T2-1 | AI classification pipeline (RAG sobre RIMM) | — | J02 | L — 2 semanas |
| T2-2 | Sandbox educativo (tenant tipo educational) | $3.2K | J05 | M — 1 semana |
| T2-3 | Vetted Sourcer marketplace (CRUD + trust score) | $3K | J06 | L — 2 semanas |
| T2-4 | Origin certification generator (templates por TLC) | — | J06 | M — 1 semana |
| T2-5 | Docker Compose + K8s sidecar deployment | — | Infra | M — 1 semana |

### Quick Wins (existentes en el codebase)

| Item | Estado | Acción |
|------|--------|--------|
| Declaration entity (exact ATENA JSON match) | Implementado | Usar directamente |
| 6 Domain Ports (interfaces) | Implementado | Implementar adapters |
| hacienda.proto (4 gRPC services) | Implementado | Compilar con protoc |
| DeclarationStatus (15+ estados) | Implementado | Wiring con state machine |
| Incoterm (11 códigos + responsibility matrix) | Implementado | Usar en CIF calc |
| HsCode (chapter/heading/subheading parsing) | Implementado | Conectar con RIMM |
| CountryAdapterFactory pattern | Definido | Implementar para CR |
