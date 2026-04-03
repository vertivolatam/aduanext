# Modelo Financiero (Financial Model) — AduaNext Importer-Led

## Costos Fijos Mensuales

### Pre-revenue (M1-M3):

| Concepto | Monto/mes | Notas |
|----------|-----------|-------|
| Infraestructura cloud (dev/staging) | $100 | DigitalOcean droplet + managed Postgres |
| Claude Code (AI co-developer) | $200 | Opus 4.6, herramienta critica de desarrollo |
| Dominio (aduanext.com) | $2 | ~$20/ano |
| GitHub private repo | $0 | Plan personal suficiente |
| Linear (issue tracking) | $0 | Plan gratuito |
| Figma (diseno) | $0 | Plan gratuito |
| Tiempo del fundador | $0 | Financiado por Vertivo (sin salario AduaNext) |
| **Total pre-revenue** | **$302/mes** | |

### Post-revenue (M4-M9):

| Concepto | M4 | M6 | M9 | Notas |
|----------|-----|-----|-----|-------|
| Cloud (produccion) | $200 | $400 | $800 | Escala con usuarios |
| Claude Code | $200 | $200 | $200 | Fijo |
| Dominio + SSL | $2 | $2 | $2 | |
| Stripe fees (2.9% + $0.30) | $65 | $430 | $1,680 | Variable con revenue |
| Soporte (part-time) | $0 | $500 | $1,000 | 1 persona part-time desde M6 |
| Content marketing | $0 | $200 | $400 | Blog + videos |
| Legal (contador) | $100 | $150 | $200 | Contabilidad + TRIBU-CR |
| Miscelaneos | $50 | $100 | $200 | |
| **Total post-revenue** | **$617** | **$1,982** | **$4,482** | |

## Costos Variables por Unidad

| Costo | Monto | Trigger |
|-------|-------|---------|
| Hosting incremental por cliente | ~$1.50/mes/cliente | Por cada nuevo tenant |
| Stripe fee por transaccion | 2.9% + $0.30 | Por cada cobro |
| ATENA API calls (gratuito) | $0 | API gubernamental sin costo |
| Telegram Bot API | $0 | Gratuito |
| Costo por DUA procesada | ~$0.10 | Compute + storage por DUA |

## Runway — Cuanto tiempo sin ingresos?

| Concepto | Valor |
|----------|-------|
| Burn rate pre-revenue | $302/mes |
| Ahorros disponibles para AduaNext | $0 (bootstrap con Vertivo) |
| Ingreso alternativo del fundador | Vertivo LATAM (operacion existente) |
| **Runway sin ingresos** | **Indefinido** — el costo es tan bajo que Vertivo lo absorbe |

**Ventaja critica:** El burn rate de $302/mes es posiblemente el mas bajo para un SaaS B2B en LATAM. Claude Code reemplaza a un equipo de 2-3 developers. No hay salario del fundador. No hay oficina. No hay ventas outbound.

## Necesidad de Capital

**Respuesta: NO se necesita capital externo para el MVP.**

| Opcion | Monto | Estado |
|--------|-------|--------|
| Autofinanciamiento (Bootstrapping) | $1,800 (6 meses × $302) | **SELECCIONADO** |
| Pre-seed / angel | $50K-100K | No necesario ahora |
| VC | N/A | Prematuro |
| Grant (MICITT/PROCOMER) | $10K-50K | Investigar despues de beta |

### Cuando levantariamos capital?

| Trigger | Monto | Para que |
|---------|-------|---------|
| $10K MRR validado + 50 clientes | $100K pre-seed | Contratar 1 dev + 1 customer success |
| $30K MRR + expansion a Guatemala | $500K seed | Equipo de 5 + multi-pais |
| $100K MRR + 3 paises | $2M Series A | Expansion LATAM + enterprise |

## Proyeccion P&L Mensual

| Concepto | M3 | M4 | M5 | M6 | M7 | M8 | M9 |
|----------|-----|-----|-----|-----|-----|-----|-----|
| **Revenue** | $55 | $2,130 | $6,310 | $14,250 | $27,100 | $44,200 | $56,100 |
| COGS (hosting + Stripe) | $52 | $267 | $590 | $1,130 | $1,950 | $3,050 | $3,880 |
| **Gross Profit** | $3 | $1,863 | $5,720 | $13,120 | $25,150 | $41,150 | $52,220 |
| Gross Margin | 5% | 87% | 91% | 92% | 93% | 93% | 93% |
| OpEx (team + marketing) | $302 | $350 | $500 | $850 | $1,200 | $1,600 | $2,000 |
| **EBITDA** | -$299 | $1,513 | $5,220 | $12,270 | $23,950 | $39,550 | $50,220 |
| EBITDA Margin | — | 71% | 83% | 86% | 88% | 89% | 90% |

### Breakeven: **Mes 4** ($2,130 revenue > $617 costos)

### Cashflow acumulado:

| Mes | Cashflow mensual | Acumulado |
|-----|-----------------|-----------|
| M1 | -$302 | -$302 |
| M2 | -$302 | -$604 |
| M3 | -$247 | -$851 |
| M4 | +$1,513 | +$662 |
| M5 | +$5,220 | +$5,882 |
| M6 | +$12,270 | +$18,152 |

**El proyecto es cashflow positivo acumulado desde M4.** El deficit total pre-breakeven es solo $851.

## Escenario Pesimista (50% de proyecciones)

| Concepto | M6 | M9 |
|----------|-----|-----|
| Revenue | $7,125 | $28,050 |
| Costos | $1,200 | $3,000 |
| EBITDA | $5,925 | $25,050 |
| Breakeven | M5 (un mes despues) | |

Incluso al 50% de las proyecciones, AduaNext es rentable desde M5 y alcanza $28K MRR en M9. El modelo es extremadamente resiliente gracias al burn rate ultra-bajo.
