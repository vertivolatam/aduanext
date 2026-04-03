---
marp: true
theme: default
paginate: true
---

# AduaNext
## Tu importacion, tu control.

Plataforma multi-hacienda de cumplimiento aduanero para LATAM.

**Andres Pena** — Fundador
Abril 2026

---

# El Problema

> "Los codigos que componen el desglose suelen ser **secreto comercial** y la agencia aduanal **no le explica** al comprador."
> — Vertivo LATAM (importador real)

- Las pymes pagan **$1,200/despacho** a agencias opacas
- **Cero visibilidad** del proceso de importacion
- **2.7 millones de DUAs/ano** en Costa Rica (INEC 2024)
- ATENA (nuevo sistema aduanero) lanzo Oct 2025 — **nadie se ha integrado**

---

# La Oportunidad

| Dato | Valor |
|------|-------|
| DUAs/ano en Costa Rica | 2,695,648 |
| Costo promedio agenciamiento | $250-500/despacho |
| Agencias registradas | ~200 |
| Pymes importadoras | ~3,000 |
| Competidores integrados con ATENA | **0** |
| TAM (LATAM customs software) | $320M |
| SAM (CR + Centroamerica) | $80M |

**AduaNext es first-mover en un mercado sin competencia directa.**

---

# La Solucion

**AduaNext permite a pymes preparar sus propias DUAs, contratar un agente freelance solo para firmar, y monitorear todo en tiempo real.**

3 modos de operacion:
1. **Importer-Led** — Pyme controla, agente freelance firma
2. **Standalone SaaS** — Agencia compra la plataforma
3. **Sidecar K8s** — Se inyecta junto a sistemas existentes

---

# Demo: Como funciona

```
Pyme importa LED lights desde Shenzhen:

1. Pyme entra a AduaNext (Flutter Web, tablet)
2. Crea DUA borrador → RIMM busca HS code automaticamente
3. AI sugiere 3 clasificaciones con confidence score
4. Risk pre-validation: score 0-100 antes de enviar
5. Invita a agente freelance → agente verifica y firma
6. AduaNext transmite a ATENA via gRPC sidecar
7. Pyme monitorea estado en Telegram: "Levante autorizado"

Costo total: $120/mes + $5/DUA + $150 honorario agente = ~$275
vs. agencia tradicional: $1,200
Ahorro: 77%
```

---

# Tecnologia

**Explicit Architecture** (Herberto Graca) — 3 sidecars, 3 lenguajes:

| Sidecar | Lenguaje | Funcion |
|---------|----------|---------|
| Serverpod | Dart | API principal, ORM, multi-tenant |
| hacienda-sidecar | TypeScript | Auth OIDC, Firma Digital XAdES, ATENA proxy |
| agentic-core | Python | AI classification, RAG sobre RIMM |

- **6 APIs de DUA** + **40+ endpoints RIMM** documentados (Webb Fontaine)
- **hacienda-cr SDK** open-source: auth + signing ya implementados
- Domain layer con zero dependencias I/O — multi-pais via Adapter/Factory

---

# Modelo de Negocio

| Fuente | Precio | % Revenue |
|--------|--------|-----------|
| Suscripcion pyme | $120/mes (standard) | 40% |
| Por DUA procesada | $5/DUA | 25% |
| Agente freelance | $20/mes + 10% rev share | 13% |
| Exportadores premium | $200/mes | 15% |
| Universidades sandbox | $800/mes | 7% |

**Early adopter pricing:** $60/mes + $3/DUA (50% off permanente, primeros 50)

---

# Unit Economics

| Metrica | Valor |
|---------|-------|
| CAC | $116 |
| LTV (pyme) | $2,171 |
| LTV:CAC | **18.7:1** |
| Payback | 0.9 meses |
| Gross margin | 87% |
| Burn rate pre-revenue | $302/mes |
| Breakeven | **Mes 4** |

---

# Traccion y Roadmap

| Milestone | Fecha | Status |
|-----------|-------|--------|
| Spike tecnico completo | Abr 2026 | DONE |
| Domain Layer + Proto definitions | Abr 2026 | DONE |
| SRD Framework (7 personas, 7 jornadas) | Abr 2026 | DONE |
| gRPC sidecar + ATENA auth | May 2026 | Planned |
| Beta: Vertivo importa LED desde Shenzhen | Jun 2026 | Planned |
| Early adopter launch (50 pymes) | Jul 2026 | Planned |
| Convenio UCR/UTN sandbox | Jul 2026 | Planned |
| $50K MRR | Oct 2026 | Target |

---

# Growth Flywheel

```
Universidades capacitan estudiantes con AduaNext sandbox
    → Graduados pasan examen DGA y se registran como freelance
        → Agentes freelance sirven a pymes en AduaNext
            → Pymes satisfechas refieren a otras pymes
                → Mas demanda de agentes → Universidades capacitan mas
```

**8 universidades, 18 programas, ~2,000 estudiantes/ano**

Modelo Autodesk/Figma: gratis para estudiantes → pago al graduarse.
Lock-in generacional que toma 2-3 anos en replicar.

---

# Competencia

| | AduanApp (MX) | Aduanasoft (MX) | AduaNext |
|---|---|---|---|
| Mercado | Mexico | Mexico | CR → CA → LATAM |
| Tipo | AI classifier | Desktop legacy (1996) | Plataforma end-to-end |
| Genera DUAs? | No | Via WinSAAI | Si (ATENA directo) |
| Transmite? | No | Via WinSAAI | Si (gRPC sidecar) |
| Cloud/SaaS | Parcial | No | Si (K8s native) |
| AI Classification | Si (tokens) | No | Si (RAG + HITL) |
| Multi-pais | No | No | Si (Adapter/Factory) |

**AduaNext es operator, no advisor.** Nadie mas transmite DUAs a ATENA.

---

# El Equipo

**Andres Pena** — Fundador
- Arquitecto de software (Explicit Architecture, K8s, gRPC)
- Fundador de Vertivo LATAM (micro-invernaderos autonomos)
- Autor de hacienda-cr SDK (auth + firma digital para Hacienda CR)
- Cliente zero: Vertivo importa componentes desde China y EE.UU.

**AI Co-developer:** Claude Code (Opus 4.6, 1M context)
- Spike tecnico completo en 1 sesion
- 7 sub-agentes paralelos, 15 archivos de memoria persistente

---

# El Ask

**Ahora:** No necesitamos capital. Burn rate $302/mes. Bootstrap con Vertivo.

**Pre-seed ($100K) en M8 si:**
- $10K MRR validado
- 50+ clientes activos
- Beta exitosa con importacion real

**Uso de fondos:**
- 60% — Equipo (Customer Success + Flutter Dev)
- 20% — Marketing (content + eventos)
- 10% — Infra (produccion K8s)
- 10% — Legal (SRL + contratos + marca)

---

# Contacto

**AduaNext** — Tu importacion, tu control.

- Repo: github.com/vertivolatam/aduanext (privado)
- Linear: linear.app/vertivolatam/project/aduanext
- Email: andres@vertivolatam.com
- LinkedIn: linkedin.com/in/lapc506

*Licencia: BSL 1.1 — Business Source License*
