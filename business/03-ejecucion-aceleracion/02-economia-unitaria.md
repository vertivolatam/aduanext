# Economia Unitaria (Unit Economics) — AduaNext Importer-Led

## CAC — Costo de Adquisicion de Cliente (Customer Acquisition Cost)

### Por canal:

| Canal | CAC | % clientes | CAC ponderado |
|-------|-----|-----------|---------------|
| Referido startup-to-startup | $0 | 35% | $0 |
| Caso de exito Vertivo (organico) | $0 | 12% | $0 |
| Convenio universitario (graduados → agentes → pymes) | $50 | 20% | $10 |
| Content marketing (blog + YouTube aduanero) | $200 | 18% | $36 |
| Camaras (CRECEX, AmCham) | $400 | 10% | $40 |
| LinkedIn outbound | $600 | 5% | $30 |
| **CAC promedio ponderado** | | **100%** | **$116** |

### Desglose del CAC por componente:

| Componente | Costo/cliente |
|-----------|---------------|
| Marketing directo (ads, contenido) | $40 |
| Tiempo de onboarding (self-service, ~15 min) | $5 |
| Soporte primer mes (1-2 tickets) | $15 |
| Matching con agente freelance | $10 |
| Infraestructura trial (14 dias sandbox) | $6 |
| Overhead (Stripe fees en primer cobro) | $4 |
| **Total CAC** | **$80-150** (promedio $116) |

## LTV — Valor de Vida del Cliente (Lifetime Value)

### Pyme importadora (cliente primario):

| Metrica | Valor | Fuente |
|---------|-------|--------|
| ARPU mensual (Standard) | $120 suscripcion + $25 transaccional (5 DUAs × $5) | Pricing ladder |
| ARPU mensual (Early Adopter) | $60 + $15 (5 DUAs × $3) | Pricing ladder |
| **ARPU promedio ponderado** | **$130/mes** | 60% standard + 40% early |
| Churn mensual | 6% | Estimacion conservadora para SMB SaaS |
| Vida promedio del cliente | 1 / 0.06 = **16.7 meses** | Inverso del churn |
| **LTV pyme** | $130 × 16.7 = **$2,171** | ARPU × vida |

### Agente freelance (cliente secundario):

| Metrica | Valor |
|---------|-------|
| Base mensual | $20 |
| Revenue share promedio | $15/DUA × 8 DUAs/mes = $120 |
| ARPU agente | $140/mes |
| Churn mensual | 4% (mas sticky que pymes — su negocio depende de la plataforma) |
| Vida promedio | 25 meses |
| **LTV agente** | $140 × 25 = **$3,500** |

### Universidad:

| Metrica | Valor |
|---------|-------|
| Licencia mensual | $800 |
| Duracion promedio convenio | 4 semestres (24 meses) |
| Churn semestral | 10% |
| **LTV universidad** | $800 × 20 = **$16,000** |

## Ratios Clave

| Ratio | Valor | Benchmark SaaS | Status |
|-------|-------|----------------|--------|
| **LTV:CAC (pyme)** | $2,171 / $116 = **18.7:1** | >3:1 es saludable | Excelente |
| **LTV:CAC (agente)** | $3,500 / $50 = **70:1** | >3:1 | Excepcional (CAC casi cero) |
| **Payback period (pyme)** | $116 / $130 = **0.9 meses** | <12 meses | Excelente |
| **Gross margin** | ~**87%** | >70% para SaaS | Saludable |
| **Revenue per employee** | $50K MRR / 1 = **$600K ARR/emp** | >$200K/emp | Excepcional (equipo de 1) |

## Canales de Adquisicion — Conversion por Etapa

```mermaid
funnel
    title Funnel de Conversion AduaNext
    Visitantes web : 1000
    Registros trial : 150
    Primera DUA sandbox : 90
    Match con agente : 45
    Primera DUA real : 32
    Cliente pagando : 22
```

| Etapa | Tasa | Acumulado |
|-------|------|-----------|
| Visita → Trial | 15% | 15% |
| Trial → DUA sandbox | 60% | 9% |
| DUA sandbox → Match agente | 50% | 4.5% |
| Match → DUA real | 70% | 3.2% |
| DUA real → Pago | 70% | **2.2%** |

**Nota:** El funnel real es mas largo que el estimado en el revenue model (4.7% vs 2.2%) porque incluimos el match con agente como paso adicional. El cuello de botella es el supply de agentes, no la demanda de pymes.

## Metricas de Salud Unitaria

| Metrica | Target M6 | Alerta si |
|---------|-----------|-----------|
| Monthly churn (pymes) | <6% | >10% |
| Monthly churn (agentes) | <4% | >8% |
| NPS | >55 | <30 |
| Time to first DUA | <48h | >7 dias |
| DUAs por pyme/mes | >4 | <2 |
| Agentes por pyme | >1 | 0 (no matched) |
| Revenue share collected | >$15/DUA | <$10/DUA |
| Support tickets/cliente/mes | <2 | >5 |

## Sensibilidad: Que pasa si...

| Escenario | Impacto en LTV:CAC | Accion |
|-----------|-------------------|--------|
| Churn sube a 10% | LTV cae a $1,300. Ratio baja a 11:1. | Aun saludable. Investigar causa. |
| Churn sube a 15% | LTV cae a $867. Ratio baja a 7.5:1. | Preocupante. Pivot a retention. |
| CAC sube a $300 | Ratio baja a 7.2:1. | Aun viable. Reducir paid channels. |
| ARPU baja a $80 (todos early) | LTV cae a $1,336. Ratio = 11.5:1. | Viable. Subir precio standard. |
| Revenue share baja a 5% | Agente LTV cae a $2,100. | Aun 42:1. Mantener. |
