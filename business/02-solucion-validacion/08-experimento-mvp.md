# Experimento MVP — Modelo Importer-Led

## Hipotesis a Validar

> "Vertivo puede completar una importacion real de luces LED desde Shenzhen usando AduaNext + un agente freelance contratado, con un costo total <$500/despacho (vs. $1,200 actual), en menos de 48 horas de preparacion."

## MVP Minimo Viable

### Lo que se construye (scope estricto):

| Componente | Incluido | Excluido |
|-----------|----------|----------|
| Auth ATENA via gRPC sidecar | SI | Multi-tenant (solo 1 tenant) |
| Formulario DUA de exportacion | SI (campos reales ATENA) | AI classification (manual) |
| RIMM /commodity/search | SI (busqueda basica) | Fuzzy search, sinonimos |
| Risk pre-validation | SI (5 reglas criticas) | Las 25 reglas completas |
| Firma digital via sidecar | SI | PKCS#11 hardware (solo .p12) |
| Transmision a ATENA sandbox | SI | Produccion (solo sandbox) |
| Estado de DUA (polling) | SI (manual refresh) | Real-time WebSocket |
| Notificacion Telegram | SI (1 canal) | WhatsApp, email, digest |
| Flutter app | NO | Solo backend + web basic |
| Marketplace agentes | NO | Matching manual |
| Vetted sourcers | NO | Fase posterior |
| Multi-pais | NO | Solo Costa Rica |

### Lo que NO se construye para el MVP:

- No Flutter mobile app — solo web dashboard basico (Serverpod endpoints + HTML simple)
- No AI classification — el agente clasifica manualmente con RIMM search
- No matching automatico — Vertivo contacta al agente freelance directamente
- No multi-tenant — hardcoded para Vertivo como unico tenant
- No produccion ATENA — solo ambiente sandbox (dev-siaa.hacienda.go.cr)

## Criterios de Exito del Experimento

| Criterio | Metrica | Threshold |
|----------|---------|-----------|
| DUA transmitida exitosamente | Response con customsRegistrationNumber | 1 DUA minimo |
| Tiempo de preparacion | Horas desde inicio hasta transmision | <4 horas (primera vez) |
| Costo total del despacho | Suscripcion + honorario agente + tasa DUA | <$500 total |
| Errores de clasificacion | DUAs rechazadas por ATENA | 0 rechazos por clasificacion |
| Agente freelance satisfecho | Encuesta post-firma | "Volveria a usar" = SI |
| Audit trail completo | Todos los pasos registrados con hash | 100% coverage |

## Timeline del Experimento

| Semana | Actividad | Entregable |
|--------|-----------|------------|
| S1 | gRPC sidecar + AtenaAuthAdapter | Auth funcional contra sandbox ATENA |
| S2 | RIMM adapter + Declaration CRUD | Busqueda de HS codes + crear DUA borrador |
| S3 | Signing adapter + transmision | Firmar y transmitir DUA a sandbox |
| S4 | Web dashboard + Telegram notif | Monitoreo basico + alerta de estado |
| S5 | Reclutar agente freelance | Agente con Firma Digital acepta participar |
| S6 | **EXPERIMENTO: importacion Vertivo** | DUA real de luces LED desde Shenzhen |

## Presupuesto del Experimento

| Item | Costo |
|------|-------|
| Hosting (6 semanas) | $50 |
| Claude Code (6 semanas) | $300 |
| Honorario agente freelance (1 despacho beta) | $150 |
| Tasa DUA exportacion ($3) | $3 |
| Costo real de importacion Vertivo (luces LED) | Variable (pagaria igual) |
| **Total presupuesto extra** | **~$503** |

## Riesgos del Experimento

| Riesgo | Probabilidad | Mitigacion |
|--------|-------------|------------|
| No conseguir agente freelance para beta | Media | Contactar 5+ agentes via CCECR. Ofrecer $150 por 1 despacho. |
| Sandbox ATENA no disponible/caido | Media | La auditoria CGR puede afectar disponibilidad. Tener mock server listo. |
| Error en firma digital | Baja | hacienda-cr ya implementa XAdES-EPES probado en produccion para facturacion |
| Clasificacion arancelaria incorrecta | Media | El agente freelance valida. Risk pre-validation las 5 reglas criticas. |
| Vertivo no tiene importacion pendiente | Baja | Programar compra de luces LED especificamente para el experimento |

## Post-Experimento: Decision Matrix

| Resultado | Accion |
|-----------|--------|
| DUA aceptada + costo <$500 + agente satisfecho | **GO** — Iniciar onboarding de 5 pymes + 3 agentes |
| DUA aceptada pero costo >$500 | **ITERATE** — Optimizar pricing, reducir friccion |
| DUA rechazada por clasificacion | **ITERATE** — Mejorar RIMM search + agregar mas reglas de validacion |
| DUA rechazada por error tecnico (auth/signing) | **FIX** — Debug integracion ATENA, probablemente config issue |
| No se consigue agente freelance | **PIVOT** — Considerar partnership con agencia existente en vez de freelance |
| Sandbox ATENA inaccesible | **WAIT** — Construir mock server completo, reintentar cuando sandbox estabilice |

## Gate 2: La solucion resuelve el problema?

Se evaluara despues del experimento. Criterios:

- [ ] Al menos 1 DUA de exportacion transmitida exitosamente a ATENA sandbox
- [ ] Costo total <$500 (vs. $1,200 con agencia actual)
- [ ] Tiempo de preparacion <4 horas
- [ ] Agente freelance confirma que "volveria a usar"
- [ ] 3 de 5 pymes entrevistadas dicen "lo usaria hoy" (de Phase 7)

**Gate 2 status:** PENDIENTE — requiere ejecutar el experimento.
