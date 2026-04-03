# Business Model Canvas — AduaNext Importer-Led

> Modelo enfocado: Pyme/startup importadora contrata agente aduanero freelance como firmante autorizado. La startup controla la plataforma.

---

## 1. Segmentos de Clientes (Customer Segments)

### Cliente primario: Pyme importadora hard-tech

- Startups y pymes en la GAM que importan componentes especializados
- 2-15 empleados, $50K-500K facturacion anual
- Importan 4-12 veces/ano desde China, EE.UU., Europa
- Fundadores ingenieros, tech-savvy, frustrados con opacidad aduanal
- **Tamano segmento:** ~2,000-3,000 empresas en Costa Rica

### Cliente secundario: Agente aduanero freelance

- Recien graduados de licenciatura en Admin Aduanera (UCR, UTN, Braulio Carrillo)
- 24-35 anos, examen DGA aprobado, caucion de $20K USD
- Operan independientemente con 3-10 clientes pyme
- Buscan clientes sin competir con agencias grandes
- **Tamano segmento:** ~100-200 agentes freelance potenciales en CR

### Canal de alimentacion: Estudiantes de Admin Aduanera

- 18 programas en 8 universidades, ~2,000 estudiantes/ano
- Usan AduaNext sandbox en la universidad
- Convierten a agentes freelance al graduarse
- **No son clientes directos** — son el growth engine del supply side

---

## 2. Propuesta de Valor (Value Proposition)

### Para la pyme importadora:

> **"Controla tu proceso de importacion. Prepara tus DUAs con transparencia total, contrata un agente freelance solo para firmar, y monitorea todo en tiempo real. Ahorra >60% vs. agencia tradicional."**

| Valor | Cuantificacion |
|-------|---------------|
| Transparencia | 100% de los campos de la DUA visibles (vs. caja negra) |
| Ahorro | De $1,200/despacho a <$500 (suscripcion + honorario agente + tasa DUA) |
| Control | Preparar la DUA tu mismo, el agente solo verifica y firma |
| Velocidad | Estado en tiempo real via Telegram vs. llamar a la agencia y esperar |
| Educacion | Entender tus aranceles, INCOTERMs, y clasificaciones |

### Para el agente freelance:

> **"Recibe DUAs pre-armadas y pre-validadas. Solo verifica, firma, y cobra. Reduce tu riesgo y multiplica tus clientes."**

| Valor | Cuantificacion |
|-------|---------------|
| Clientes listos | Las pymes ya prepararon la DUA, solo verificas y firmas |
| Riesgo reducido | Risk pre-validation (25 reglas) baja errores que comprometan tu caucion |
| Costo bajo | $60/mes — accesible para alguien facturando $1,500/mes |
| Escalabilidad | Atender 10+ clientes sin infraestructura propia |
| Profesionalismo | Dashboard con track record verificable |

---

## 3. Canales (Channels)

| Canal | Fase | Costo |
|-------|------|-------|
| **Referido startup-to-startup** | Adquisicion + activacion | $0 (organico) |
| **Vertivo como caso de exito publico** | Awareness | $0 (dogfooding) |
| **Convenio universitario** (UCR, UTN) | Supply side (agentes) | $0-500/semestre |
| **Content marketing aduanero** (blog + YouTube) | Awareness | $200/mes |
| **Camaras** (CRECEX, AmCham, Camara de Agentes) | Credibilidad | $500/ano afiliacion |
| **LinkedIn B2B** | Outbound a pymes | $100/mes |

### Funnel de conversion:

```
Awareness: Blog/YouTube + referidos + caso Vertivo
  → 1,000 visitas/mes

Interest: Landing page + demo sandbox
  → 15% registro trial (150/mes)

Trial: 14 dias gratis, primera DUA sandbox
  → 30% conversion (45/mes)

Activation: Primera DUA real transmitida a ATENA
  → 60% de trials (27/mes)

Revenue: Suscripcion + $5/DUA
  → $120/mes ARPU

Referral: Cada pyme refiere 0.3 pymes/mes
  → Viral coefficient: 0.3 (sub-viral pero compounding)
```

---

## 4. Relacion con Clientes (Customer Relationships)

| Tipo | Descripcion |
|------|-------------|
| **Self-service** | Onboarding automatizado <5 min. Sandbox sin asistencia humana. |
| **Matching automatico** | Algoritmo conecta pyme con agente freelance disponible por zona/especialidad |
| **Soporte chat** | WhatsApp Business para dudas de clasificacion arancelaria |
| **Comunidad** | Grupo Telegram de importadores usando AduaNext (peer support) |
| **Notificaciones proactivas** | Alertas de estado DUA, vencimientos LPCO, cambios de tipo de cambio |

### Metricas de relacion:

| Metrica | Target |
|---------|--------|
| NPS | 55+ |
| Churn mensual | <6% |
| Time-to-first-DUA | <48 horas desde registro |
| Tickets de soporte/mes/cliente | <2 |

---

## 5. Fuentes de Ingresos (Revenue Streams)

| Fuente | Modelo | Precio | % Revenue estimado |
|--------|--------|--------|-------------------|
| **Suscripcion pyme** | MRR recurrente | $120/mes | 40% |
| **Revenue transaccional** | Por DUA procesada | $5/DUA | 25% |
| **Suscripcion agente freelance** | MRR recurrente | $60/mes | 8% |
| **Matching fee** | Por conexion pyme↔agente | $25 one-time | 5% |
| **Suscripcion premium** (exportadores grandes) | MRR recurrente | $200/mes | 15% |
| **Licencia universitaria** | Semestral | $800/mes | 7% |

### Proyeccion a 6 meses (meta $50K MRR):

| Mes | Pymes | Agentes | Univ | DUAs/mes | MRR |
|-----|-------|---------|------|----------|-----|
| M3 | 10 | 5 | 0 | 40 | $2,100 |
| M4 | 30 | 12 | 1 | 150 | $6,350 |
| M5 | 65 | 25 | 2 | 400 | $15,200 |
| M6 | 120 | 40 | 4 | 800 | $29,600 |
| M7 | 180 | 55 | 4 | 1,400 | $42,100 |
| M8 | 240 | 70 | 5 | 2,400 | $50,000+ |

---

## 6. Recursos Clave (Key Resources)

| Recurso | Tipo | Estado |
|---------|------|--------|
| **Integracion ATENA** (6 DUA APIs + 40 RIMM endpoints) | Tecnico | Documentado, no implementado |
| **hacienda-cr SDK** (auth + signing + HTTP client) | Tecnico | Implementado (npm) |
| **Domain Layer** (Declaration entity + 6 Ports) | Tecnico | Implementado (Dart) |
| **Proto definitions** (4 gRPC services) | Tecnico | Implementado |
| **Documentacion ATENA** (3 PDFs + manual DGA) | Conocimiento | Descargado y analizado |
| **Vertivo como cliente zero** | Market | Disponible |
| **Supply de agentes freelance** | Market | Dependiente de convenio universitario |
| **Firma Digital** (certificados BCCR) | Legal | Requiere agente con certificado activo |

---

## 7. Actividades Clave (Key Activities)

| Actividad | Prioridad | Sprint |
|-----------|-----------|--------|
| Implementar gRPC sidecar (hacienda-cr wrapper) | T0 | Sprint 1 |
| Implementar AtenaAuthAdapter + RIMM adapter | T0 | Sprint 1 |
| Serverpod endpoints para CRUD Declaration | T0 | Sprint 2 |
| Flutter app: onboarding pyme + invitacion agente | T1 | Sprint 3 |
| Risk pre-validation engine (25 reglas) | T1 | Sprint 3 |
| Notificaciones Telegram | T1 | Sprint 4 |
| Beta con Vertivo (primera importacion real) | Validacion | Sprint 4 |
| Matching pyme↔agente | T1 | Sprint 5 |
| Convenio con UCR o UTN | GTM | Paralelo |

---

## 8. Socios Clave (Key Partners)

| Socio | Tipo | Valor que aporta | Estado |
|-------|------|------------------|--------|
| **Agentes aduaneros freelance** | Supply side | Firma Digital + responsabilidad legal | Pendiente (reclutar 5 iniciales) |
| **UCR / UTN** | Canal | Supply de agentes + validacion academica | Pendiente (iniciar conversacion) |
| **CRECEX** | Credibilidad | Red de importadores/exportadores | Afiliacion disponible |
| **Colegio de Ciencias Economicas (CCECR)** | Regulatorio | Registro de agentes colegiados | Relacion institucional |
| **hacienda-cr (open source)** | Tecnico | SDK de auth/signing mantenido | Disponible (npm) |
| **Webb Fontaine / DGA** | Infraestructura | ATENA funcione correctamente | Indirecto (no partner formal) |

### Socios criticos para lanzamiento:

1. **3-5 agentes freelance** dispuestos a participar en beta — sin ellos, las pymes no pueden operar
2. **1 universidad** para convenio sandbox — sin esto, no hay flywheel de agentes
3. **Vertivo** como cliente zero — sin dogfooding, no hay validacion real

---

## 9. Estructura de Costos (Cost Structure)

### Costos fijos mensuales (pre-revenue):

| Costo | Monto | Notas |
|-------|-------|-------|
| Infraestructura cloud (AWS/DO) | $50-150/mes | Dev/staging. Prod escala con clientes |
| Dominio + SSL | $15/mes | aduanext.com |
| GitHub (privado) | $0 | Incluido en plan personal |
| Linear (issue tracking) | $0 | Plan gratis para <10 users |
| Tiempo del fundador | $0 (bootstrap) | Financiado por Vertivo |
| Claude Code (AI co-developer) | $200/mes | Opus 4.6 |

**Burn rate pre-revenue: ~$265/mes** — extremadamente lean.

### Costos variables (post-revenue):

| Costo | Monto | Trigger |
|-------|-------|---------|
| Serverpod hosting (prod) | $200-500/mes | >50 usuarios activos |
| Telegram Bot API | $0 | Gratis |
| Stripe payment processing | 2.9% + $0.30/tx | Por cobro |
| Soporte (part-time) | $500/mes | >100 clientes |
| Marketing content | $200/mes | Desde M4 |

### Unit economics target:

| Metrica | Valor |
|---------|-------|
| CAC (pyme) | $180 |
| LTV (pyme, 17 meses promedio) | $2,040 |
| LTV:CAC | 11.3:1 |
| Payback period | 1.5 meses |
| Gross margin | 85%+ |

---

## 10. Ventaja Injusta (Unfair Advantage)

La ventaja que **no se puede copiar ni comprar**:

1. **Primer integrador con ATENA** — Tenemos la documentacion tecnica (104 + 26 + 64 paginas) que solo esta disponible para integradores del consorcio PBS/WF. La analizamos completa.

2. **hacienda-cr SDK** — Open source pero con BSL 1.1 license. Nadie mas tiene auth + XAdES-EPES signing para Hacienda CR implementado en TypeScript.

3. **Cliente zero (Vertivo)** — Dogfooding real con importaciones reales de componentes hard-tech. Los competidores tendrian que construir Y encontrar clientes simultaneamente.

4. **Flywheel universitario** — Si UCR/UTN adoptan AduaNext como herramienta de capacitacion, cada generacion de graduados ya sabe usar la plataforma. Esto toma 2-3 anos en construir; nadie puede replicarlo rapido.

5. **ATENA en crisis** — La auditoria de la CGR crea urgencia. Las agencias necesitan herramientas YA. Quien se posicione primero durante la crisis captura el mercado.

---

## Resumen Visual del Canvas

```
+-------------------+-------------------+-------------------+
|                   |                   |                   |
| 8. SOCIOS CLAVE   | 7. ACTIVIDADES    | 2. PROPUESTA      |
|                   |    CLAVE          |    DE VALOR        |
| - Agentes free-   |                   |                   |
|   lance (supply)  | - gRPC sidecar    | PYME:             |
| - UCR/UTN         | - ATENA adapters  | "Controla tu      |
|   (flywheel)      | - Flutter app     |  importacion.     |
| - CRECEX          | - Beta Vertivo    |  60% mas barato." |
|   (credibilidad)  | - Convenio univ.  |                   |
| - hacienda-cr     |                   | AGENTE:           |
|   (SDK)           | 6. RECURSOS CLAVE | "DUAs pre-armadas.|
|                   |                   |  Solo firma."     |
|                   | - ATENA API docs  |                   |
|                   | - hacienda-cr SDK |                   |
|                   | - Vertivo (client |                   |
|                   |   zero)           |                   |
|                   | - Supply agentes  |                   |
+-------------------+-------------------+-------------------+
|                                       |                   |
| 9. ESTRUCTURA DE COSTOS               | 5. FUENTES DE     |
|                                       |    INGRESOS        |
| Fijos: $265/mes (pre-revenue)         |                   |
| Variables: hosting + Stripe 2.9%      | - Suscripcion pyme |
| Burn rate: <$500/mes                  |   $120/mes (40%)  |
| Gross margin: 85%+                    | - Por DUA $5 (25%)|
| CAC: $180 | LTV: $2,040 | 11.3:1     | - Suscripcion     |
|                                       |   agente $60 (8%) |
|                                       | - Matching $25    |
|                                       | - Premium $200    |
|                                       | - Univ $800 (7%)  |
+---------------------------------------+-------------------+
```

---

Phase 6/21 complete — Business Model Canvas del Importer-Led.
