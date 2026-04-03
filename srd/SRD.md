# SRD — Synthetic Reality Development Framework
## AduaNext: Plataforma Multi-Hacienda de Cumplimiento Aduanero

> Generado: 2026-04-03 | Target: $50K MRR a 6 meses | Metodologia: SRD Quick Audit

---

## 1. Realidad de Exito

# Realidad de Éxito — AduaNext a $50K MRR

> "¿Cómo se ve AduaNext a los 6 meses con usuarios reales, transacciones reales y revenue real?"

## Instantánea a 6 meses (Octubre 2026)

| KPI | Meta |
|-----|------|
| MRR | $50,000 USD |
| ARR | $600,000 USD |
| Agencias activas (Standalone) | 15 |
| Agentes freelance activos | 40 |
| Pymes en modo Importer-Led | 120 |
| Estudiantes en Sandbox | 500 |
| DUAs procesadas/mes | 2,400 |
| Tasa de retención mensual | 94% |
| NPS | 55+ |
| CAC promedio | $180 USD |
| LTV promedio | $2,400 USD |
| LTV:CAC ratio | 13:1 |

## Desglose de Revenue

### Por segmento

| Segmento | Cuentas | ARPU/mes | MRR | % Revenue |
|----------|---------|----------|-----|-----------|
| Agencias Standalone | 15 | $1,200 | $18,000 | 36% |
| Agentes Freelance | 40 | $60 | $2,400 | 5% |
| Pymes Importer-Led | 120 | $120 | $14,400 | 29% |
| Revenue por despacho ($5/DUA) | 2,400 DUAs | $5 | $12,000 | 24% |
| Universidades (licencias) | 4 | $800 | $3,200 | 6% |
| **Total** | | | **$50,000** | **100%** |

### Por tipo de ingreso

| Tipo | MRR | % |
|------|-----|---|
| Suscripción mensual (SaaS) | $34,800 | 70% |
| Revenue transaccional (por DUA) | $12,000 | 24% |
| Licencias educativas | $3,200 | 6% |

## Atribución de Conversión

| Canal | % nuevos clientes |
|-------|-------------------|
| Referido agente → pyme | 35% |
| Convenio universitario | 20% |
| Content marketing (blog/YouTube aduanero) | 18% |
| Vertivo como caso de éxito público | 12% |
| Cámaras (CRECEX, AmCham) | 10% |
| Outbound directo a agencias | 5% |

## Volumen de Contenido / Operaciones a 6 meses

| Métrica | Volumen |
|---------|---------|
| DUAs de exportación procesadas | 14,400 (acumulado) |
| Clasificaciones arancelarias realizadas | 28,800 |
| Consultas RIMM exitosas | 86,400 |
| Certificados de origen generados | 2,100 |
| Alertas de riesgo pre-validación | 4,320 |
| Notificaciones Telegram/WhatsApp enviadas | 72,000 |
| Audit trail entries | 432,000 |

## Revenue Milestones

| Mes | MRR | Evento clave |
|-----|-----|-------------|
| Mes 1 (Abr 2026) | $0 | Spike técnico completado, arquitectura definida |
| Mes 2 (May) | $0 | MVP: auth + DUA mapping + sandbox + RIMM query |
| Mes 3 (Jun) | $2,500 | Beta privada: Vertivo (cliente zero) + 2 agencias piloto |
| Mes 4 (Jul) | $8,000 | Lanzamiento público: 5 agencias + 20 pymes + convenio UCR |
| Mes 5 (Ago) | $22,000 | Examen DGA agosto: graduados se onboardean como freelance |
| Mes 6 (Sep) | $35,000 | Marketplace vetted sourcers alpha + 2da universidad |
| Mes 7 (Oct) | $50,000 | Meta alcanzada: flywheel universidad→agente→pyme activo |

## Supuestos Clave

1. **ATENA sandbox disponible**: Sin acceso al ambiente dev-siaa.hacienda.go.cr, la beta se retrasa
2. **Caución del agente freelance**: $20K USD es barrera — modelo cooperativo (varios freelance, una caución) puede acelerarla
3. **Convenio universitario**: UCR o UTN firman en los primeros 3 meses — sin esto, el segmento educativo no arranca
4. **Vertivo como caso real**: La primera importación de luces LED desde Shenzhen se completa exitosamente en mes 3
5. **Regulación**: No hay cambios regulatorios que prohíban plataformas terceras de integrarse con ATENA

---

## 2. Personas Sinteticas

```yaml
# Personas Sintéticas — AduaNext
# 7 personas que representan el 100% de usuarios y el 100% del revenue

personas:
  - id: P01
    nombre: "María Fernández"
    arquetipo: "Agente Aduanero Veterano"
    edad: 48
    ubicación: "Heredia, Costa Rica"
    rol: "Dueña de agencia aduanal con 15 años de experiencia"
    contexto: >
      Licenciada en Admin Aduanera de la UCR. Opera una agencia mediana (6 empleados).
      Usó TICA toda su carrera. ATENA la obligó a cambiar pero no tiene soporte técnico.
      Su equipo pierde 3 horas diarias transcribiendo datos entre sistemas.
    motivación: "Automatizar la transmisión a ATENA y reducir errores de clasificación"
    frustración: "ATENA no tiene soporte, Webb Fontaine no responde, DGA no capacita"
    dispositivos: ["Desktop Windows", "WhatsApp Business"]
    plan: "Standalone Agencia — $1,200/mes"
    wallet:
      ingreso_mensual: "$8,000 USD (honorarios agencia)"
      presupuesto_tech: "$1,500/mes"
      sensibilidad_precio: "Media — valora el ROI sobre el precio"
      costo_de_cambio: "Alto — tiene procesos establecidos"
    lifecycle:
      mes_1: "Trial gratuito. Prueba DUA sandbox con datos reales anonimizados"
      mes_2: "Convierte a plan pagado. Procesa primeras 10 DUAs reales vía AduaNext"
      mes_3: "Onboardea 2 asistentes. Reduce errores de clasificación 40%"
      mes_4: "Invita a 3 clientes pymes a monitorear sus DUAs en tiempo real"
      mes_5: "Refiere a otra agencia amiga. Adopta risk pre-validation"
      mes_6: "Renueva anual. Solicita módulo de importación"
    churn_risk:
      mes_2: "Si la integración ATENA falla en producción, cancela inmediatamente"
      mes_4: "Si el ROI no es visible (ahorro de tiempo medible), evalúa alternativas"
    scores:
      revenue: 9
      engagement: 8
      virality: 6
    porcentaje_usuarios: "8%"
    porcentaje_revenue: "36%"
    ltv: "$14,400"

  - id: P02
    nombre: "Carlos Jiménez"
    arquetipo: "Agente Freelance Recién Graduado"
    edad: 26
    ubicación: "San Carlos, Costa Rica"
    rol: "Recién licenciado en Admin Aduanera de la UTN, pasó el examen DGA agosto 2026"
    contexto: >
      Aprendió con AduaNext sandbox en la universidad. No tiene capital para abrir agencia.
      Su caución de $20K USD la financió con un préstamo bancario.
      Opera desde su casa atendiendo 3-5 pymes locales como freelance.
    motivación: "Tener una herramienta profesional sin invertir en infraestructura"
    frustración: "Las agencias grandes no lo contratan; debe generar sus propios clientes"
    dispositivos: ["Laptop Linux", "Android", "Telegram"]
    plan: "Agente Freelance — $60/mes"
    wallet:
      ingreso_mensual: "$1,500 USD (primeros meses)"
      presupuesto_tech: "$100/mes"
      sensibilidad_precio: "Alta — cada colón cuenta"
      costo_de_cambio: "Bajo — no tiene sistemas previos"
    lifecycle:
      mes_1: "Activa plan freelance. Ya conoce AduaNext del sandbox universitario"
      mes_2: "Procesa primera DUA real para un cliente pyme de San Carlos"
      mes_3: "Consigue 3 clientes fijos. Factura $800/mes en honorarios"
      mes_4: "Invita a compañeros de universidad. 2 se registran como freelance"
      mes_5: "Explora vetted sourcers para un cliente que importa desde Guatemala"
      mes_6: "Estable con 5 clientes. Empieza a considerar contratar asistente"
    churn_risk:
      mes_1: "Si no consigue su primer cliente en 30 días, abandona la plataforma"
      mes_3: "Si el costo mensual supera el 10% de sus ingresos, busca alternativa gratis"
    scores:
      revenue: 3
      engagement: 9
      virality: 9
    porcentaje_usuarios: "23%"
    porcentaje_revenue: "5%"
    ltv: "$720"

  - id: P03
    nombre: "Andrea Solano"
    arquetipo: "Pyme Importadora Tech"
    edad: 34
    ubicación: "Heredia, Costa Rica"
    rol: "Co-fundadora de startup hard-tech (micro-invernaderos verticales)"
    contexto: >
      Importa luces LED de horticultura desde Shenzhen y sensores de New York.
      Paga $1,200/despacho a una agencia que no le explica los costos.
      Quiere transparencia total: saber exactamente qué paga y por qué.
    motivación: "Controlar mi proceso de importación sin depender de la caja negra de la agencia"
    frustración: "Los códigos del desglose son secreto comercial. No tengo visibilidad."
    dispositivos: ["MacBook", "iPhone", "Slack", "Telegram"]
    plan: "Importer-Led — $120/mes + $5/DUA"
    wallet:
      ingreso_mensual: "$5,000 USD (startup early-stage)"
      presupuesto_tech: "$300/mes"
      sensibilidad_precio: "Media-alta — ROI debe ser claro vs. pagar agencia"
      costo_de_cambio: "Medio — debe encontrar agente freelance compatible"
    lifecycle:
      mes_1: "Se registra tras ver caso de éxito de Vertivo. Invita agente freelance"
      mes_2: "Primera importación: luces LED. Pre-clasifica con RIMM, agente firma"
      mes_3: "Ahorra $800 vs. tarifa de agencia anterior. Refiere a 2 startups amigas"
      mes_4: "Usa vetted sourcers para comparar proveedores chinos"
      mes_5: "Importa sensores desde NYC vía courier (régimen simplificado)"
      mes_6: "Cliente estable. Pide API para integrar con su ERP interno"
    churn_risk:
      mes_1: "Si no encuentra agente freelance disponible, no puede operar"
      mes_3: "Si la primera importación tiene problemas aduaneros, culpa a la plataforma"
    scores:
      revenue: 6
      engagement: 7
      virality: 8
    porcentaje_usuarios: "35%"
    porcentaje_revenue: "29%"
    ltv: "$2,040"

  - id: P04
    nombre: "Prof. Roberto Vargas"
    arquetipo: "Académico / Coordinador de Carrera"
    edad: 55
    ubicación: "San José, Costa Rica"
    rol: "Coordinador de Licenciatura en Admin Aduanera, UTN"
    contexto: >
      Lleva 20 años enseñando con TICA. ATENA lo dejó sin material de capacitación.
      Necesita herramientas prácticas para que sus estudiantes aprendan el sistema real.
      Le importa que sus graduados consigan empleo rápido.
    motivación: "Modernizar el currículo y que los estudiantes practiquen con ATENA real"
    frustración: "Hacienda no provee ambiente de práctica para universidades"
    dispositivos: ["Desktop Windows", "Proyector de aula"]
    plan: "Licencia Universitaria — $800/mes (cubre ~200 estudiantes)"
    wallet:
      ingreso_mensual: "Presupuesto departamental UCR/UTN"
      presupuesto_tech: "$2,000/semestre"
      sensibilidad_precio: "Alta — presupuesto público limitado"
      costo_de_cambio: "Muy bajo — no tiene herramienta actual"
    lifecycle:
      mes_1: "Piloto con 1 curso (30 estudiantes). AduaNext dona licencia"
      mes_2: "Estudiantes completan primera DUA en sandbox. Profesor reporta valor"
      mes_3: "Coordinación aprueba licencia para 3 cursos"
      mes_4: "200 estudiantes activos. AduaNext caso de estudio en clase"
      mes_5: "Prepara a estudiantes para examen DGA agosto con simulaciones"
      mes_6: "Primer cohorte gradúa con 'Certificado AduaNext'. 5 se registran freelance"
    churn_risk:
      mes_1: "Si el sandbox no funciona en el aula (red universitaria), pierde interés"
      mes_3: "Si el presupuesto no se aprueba para el segundo semestre, no renueva"
    scores:
      revenue: 4
      engagement: 5
      virality: 10
    porcentaje_usuarios: "15%"
    porcentaje_revenue: "6%"
    ltv: "$4,800"

  - id: P05
    nombre: "Diego Mora"
    arquetipo: "Exportador Habitual"
    edad: 42
    ubicación: "Limón, Costa Rica"
    rol: "Gerente de exportaciones de empresa bananera mediana"
    contexto: >
      Exporta 200+ contenedores/año a EE.UU. y Europa. Tiene agencia aduanal contratada
      pero quiere visibilidad de las DUAs en tiempo real. Usa DUCA-F para CA.
      La aduana le asigna revisión física frecuentemente por volumen.
    motivación: "Monitorear mis 50+ DUAs activas simultáneas sin llamar a la agencia"
    frustración: "Cada vez que necesito un dato, tengo que llamar al agente y esperar"
    dispositivos: ["Tablet Android (en planta)", "Desktop Windows"]
    plan: "Importer-Led Premium — $200/mes + $5/DUA"
    wallet:
      ingreso_mensual: "$15,000 USD (empresa establecida)"
      presupuesto_tech: "$500/mes"
      sensibilidad_precio: "Baja — busca eficiencia sobre precio"
      costo_de_cambio: "Alto — múltiples DUAs activas simultáneas"
    lifecycle:
      mes_1: "Demo con gerencia. Conecta AduaNext como visor de sus DUAs actuales"
      mes_2: "Monitorea 20 DUAs en tiempo real. Recibe alertas Telegram por levante"
      mes_3: "Integra pre-validación de riesgo. Reduce revisiones físicas 20%"
      mes_4: "Pide API para conectar con su sistema de logística interna"
      mes_5: "Exporta a Guatemala: AduaNext pre-llena datos para DUCA-F automática"
      mes_6: "Renueva anual. Solicita módulo de manifiesto marítimo"
    churn_risk:
      mes_2: "Si las notificaciones tienen latencia >5min vs. portal ATENA directo, no ve valor"
      mes_5: "Si la funcionalidad DUCA-F no agrega valor sobre lo que ATENA ya hace, cuestiona"
    scores:
      revenue: 7
      engagement: 6
      virality: 4
    porcentaje_usuarios: "7%"
    porcentaje_revenue: "14%"
    ltv: "$3,600"

  - id: P06
    nombre: "Lucía Chen"
    arquetipo: "Vetted Sourcer / Importador Directo"
    edad: 38
    ubicación: "Shenzhen, China → Heredia, CR"
    rol: "Representante de fabricante chino de LED hortícola con oficina en CR"
    contexto: >
      Maneja la relación comercial entre fábricas en Shenzhen y compradores en CA.
      Necesita que sus productos estén pre-clasificados con HS codes correctos
      para que las agencias y pymes los seleccionen fácilmente.
    motivación: "Que mis productos aparezcan como 'verified' para reducir fricción de venta"
    frustración: "Cada agencia me pide clasificar los mismos productos de forma diferente"
    dispositivos: ["iPhone", "WeChat", "WhatsApp", "Laptop Windows"]
    plan: "Sourcer Verified — $150/mes (marketplace listing)"
    wallet:
      ingreso_mensual: "$20,000 USD (comisiones comerciales)"
      presupuesto_tech: "$300/mes"
      sensibilidad_precio: "Baja — es costo de ventas"
      costo_de_cambio: "Medio — depende de que las agencias/pymes usen AduaNext"
    lifecycle:
      mes_1: "Registra catálogo de 50 productos LED con HS codes pre-validados"
      mes_2: "3 pymes la seleccionan como sourcer. Trust score: 45 (Basic)"
      mes_3: "Completa KYC. Trust score sube a 72 (Verified)"
      mes_4: "10 despachos exitosos. Certificados de origen auto-generados (TLC CR-CN)"
      mes_5: "Trust score: 88 (Trusted). Elegible para blanket certificates"
      mes_6: "30 clientes activos en AduaNext. Refiere a 2 fabricantes más"
    churn_risk:
      mes_2: "Si no hay suficientes compradores en la plataforma, no ve ROI del listing"
      mes_4: "Si la generación de certificados de origen no es aceptada por la DGA, pierde valor"
    scores:
      revenue: 5
      engagement: 6
      virality: 7
    porcentaje_usuarios: "5%"
    porcentaje_revenue: "6%"
    ltv: "$1,800"

  - id: P07
    nombre: "Estudiante Ana"
    arquetipo: "Estudiante de Admin Aduanera"
    edad: 22
    ubicación: "Cartago, Costa Rica"
    rol: "Estudiante de 3er año de Licenciatura en Admin Aduanera, UCR"
    contexto: >
      Nunca ha visto ATENA real. Aprendió con screenshots de TICA en clase.
      Usa AduaNext sandbox como parte del curso del Prof. Vargas.
      Su meta es pasar el examen DGA de agosto 2027 y abrir como freelance.
    motivación: "Practicar con datos reales para prepararme para el examen y el mercado"
    frustración: "La universidad solo enseña teoría. No hay práctica con sistemas reales"
    dispositivos: ["Laptop Chromebook", "Android", "WhatsApp"]
    plan: "Sandbox Educativo — Gratis (subsidiado por licencia universitaria)"
    wallet:
      ingreso_mensual: "$0 (estudiante)"
      presupuesto_tech: "$0"
      sensibilidad_precio: "Extrema — debe ser 100% gratis"
      costo_de_cambio: "Cero"
    lifecycle:
      mes_1: "Crea cuenta sandbox gratuita vía convenio universitario"
      mes_2: "Completa 5 DUAs de práctica en sandbox. Entiende clasificación arancelaria"
      mes_3: "Participa en simulación de importación desde China (caso Vertivo)"
      mes_4: "Completa módulo de risk pre-validation. Top 10% de su clase"
      mes_5: "Obtiene 'Certificado AduaNext Nivel 1'"
      mes_6: "Conecta con P03 (pyme) para práctica profesional. Primer ingreso real"
    churn_risk:
      mes_1: "Si el sandbox es complicado o lento, usa YouTube en vez de practicar"
      mes_5: "Si el certificado no tiene valor reconocido por empleadores, pierde interés"
    scores:
      revenue: 0
      engagement: 7
      virality: 8
    porcentaje_usuarios: "7%"
    porcentaje_revenue: "0%"
    ltv: "$0 (convierte a P02 al graduarse → $720 LTV futuro)"

# Validación:
# Usuarios: 8% + 23% + 35% + 15% + 7% + 5% + 7% = 100%
# Revenue: 36% + 5% + 29% + 6% + 14% + 6% + 0% = 96% (4% = revenue transaccional distribuido)
```

---

## 3. Jornadas Criticas

# Jornadas Críticas — AduaNext

> Cada jornada mapea un flujo end-to-end que conecta directamente con revenue.

---

## J01: Preparar y transmitir DUA de exportación a ATENA

**Persona primaria:** P01 (María, Agente Veterano) + P02 (Carlos, Freelance)
**Revenue tag:** $5/DUA transaccional + suscripción mensual
**Completitud actual:** 35%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Login → Dashboard agente | Pendiente | Auth via Serverpod, token Keycloak ATENA via gRPC sidecar |
| 2 | Crear nueva declaración (borrador) | Pendiente | Formulario con campos ATENA reales (Declaration entity existe) |
| 3 | Seleccionar exportador y consignatario | Pendiente | Buscar en RIMM `/declarant/search`, `/company/search` |
| 4 | Agregar items con clasificación arancelaria | Parcial | HsCode value object existe, RIMM `/commodity/search` definido |
| 5 | AI sugiere HS codes (top 3 con confidence) | Pendiente | RAG pipeline sobre catálogo RIMM cacheado |
| 6 | Agente confirma clasificación (human-in-the-loop) | Pendiente | Firma digital del agente captura identidad |
| 7 | Calcular CIF automáticamente | Pendiente | INCOTERM matrix + RIMM `/exchangeRate/search` |
| 8 | Risk pre-validation (score 0-100) | Pendiente | 25+ reglas definidas en spike, no implementadas |
| 9 | Revisar DUA completa antes de enviar | Pendiente | Vista preview del JSON ATENA |
| 10 | Firmar con Firma Digital (gRPC → sidecar) | Pendiente | Proto `HaciendaSigner.SignAndEncode` definido |
| 11 | Transmitir a ATENA (sandbox/producción) | Pendiente | Proto `HaciendaApi.ValidateDeclaration` + `LiquidateDeclaration` |
| 12 | Recibir respuesta ATENA (aceptada/rechazada) | Pendiente | Mapear status codes a DeclarationStatus enum |
| 13 | Notificación Telegram/WhatsApp al declarante | Pendiente | NotificationPort definido |

**Criterios de aceptación:**
- [ ] Una DUA de exportación tipo "EX" se transmite exitosamente al sandbox de ATENA
- [ ] El response incluye `customsRegistrationNumber` y `assessmentSerial`
- [ ] El audit trail registra cada paso con SHA-256 hash chain
- [ ] El tiempo total de preparación es <15 minutos para un agente experimentado

---

## J02: Clasificar producto con RIMM y asistencia AI

**Persona primaria:** P01 (María) + P03 (Andrea, Pyme)
**Revenue tag:** Diferenciador clave para retención
**Completitud actual:** 20%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Ingresar descripción comercial del producto | Pendiente | Campo `commercialDescription` en DeclarationItem |
| 2 | Sistema busca en RIMM con FULL_TEXT | Parcial | Endpoint `/commodity/search` documentado, adapter pendiente |
| 3 | AI genera 3+ sugerencias de HS code con confidence | Pendiente | RAG sobre catálogo RIMM (11,422 commodities) |
| 4 | Mostrar: código, descripción, tarifa, notas técnicas | Pendiente | Commodity response schema conocido del PDF RIMM |
| 5 | Agente selecciona y confirma (locked classification) | Pendiente | Patrón append-only, no in-place mutation |
| 6 | Verificar si requiere nota técnica (LPCO) | Pendiente | RIMM `/nationalNote/search` |
| 7 | Guardar corrección manual si el agente cambia la sugerencia | Pendiente | Pesa en futuras búsquedas |

**Criterios de aceptación:**
- [ ] Una búsqueda por "café verde sin tostar" retorna HS 0901.11 como top resultado
- [ ] El agente DEBE confirmar antes de que el código se pueda usar en una DUA
- [ ] Correcciones manuales se registran en audit trail y pesan en futuras sugerencias

---

## J03: Monitorear estado de DUA en tiempo real

**Persona primaria:** P03 (Andrea, Pyme) + P05 (Diego, Exportador)
**Revenue tag:** Retención — si no hay visibilidad, cancela
**Completitud actual:** 15%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Dashboard con lista de DUAs activas | Pendiente | Filtrar por tenant (multi-tenant RLS) |
| 2 | Estado actual con semáforo visual | Parcial | DeclarationStatus enum con 15+ estados definido |
| 3 | Timeline de transiciones de estado | Pendiente | Audit trail por declaration |
| 4 | Alerta automática por cambio de estado | Pendiente | NotificationPort → Telegram/WhatsApp |
| 5 | Alerta de stuck (DUA en mismo estado >threshold) | Pendiente | Escalation timer configurable |
| 6 | Ver detalles de rechazo (códigos de error ATENA) | Pendiente | Parsear response errors |
| 7 | Iniciar rectificación desde la misma pantalla | Pendiente | API #4 + #5 (Validate + Rectify) |

**Criterios de aceptación:**
- [ ] Pyme ve el estado actualizado <60 segundos después del cambio en ATENA
- [ ] Recibe notificación Telegram cuando DUA pasa a "Levante autorizado"
- [ ] Puede ver la razón exacta si la DUA fue rechazada

---

## J04: Onboarding pyme en modo Importer-Led

**Persona primaria:** P03 (Andrea, Pyme)
**Revenue tag:** $120/mes + $5/DUA — 29% del revenue total
**Completitud actual:** 0%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Registro como importador (cédula jurídica + SINPE) | Pendiente | Validar contra RIMM `/company/search` |
| 2 | Crear workspace del importador | Pendiente | Multi-tenant: TenantType.importerLed |
| 3 | Invitar agente aduanero freelance al workspace | Pendiente | Patrón invitación con rol "authorized_signer" |
| 4 | Agente acepta invitación y conecta su Firma Digital | Pendiente | gRPC sidecar vincula certificado al tenant |
| 5 | Pyme crea primera DUA borrador | Pendiente | Formulario simplificado para importadores |
| 6 | Agente revisa, corrige, firma y transmite | Pendiente | J01 pasos 6-13 |
| 7 | Pyme monitorea estado en tiempo real | Pendiente | J03 |
| 8 | Facturación automática: suscripción + por DUA | Pendiente | Stripe/payment integration |

**Criterios de aceptación:**
- [ ] Una pyme se registra en <5 minutos con su cédula jurídica
- [ ] Invita a un agente freelance que acepta en <24 horas
- [ ] La primera DUA se transmite exitosamente a ATENA
- [ ] La pyme puede ver el costo total (aranceles + honorarios + AduaNext) antes de enviar

---

## J05: Sandbox educativo para estudiantes

**Persona primaria:** P04 (Prof. Vargas) + P07 (Ana, Estudiante)
**Revenue tag:** $800/mes licencia + flywheel futuro
**Completitud actual:** 0%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Profesor crea aula virtual con código de acceso | Pendiente | Tenant tipo "educational" |
| 2 | Estudiante se registra con correo universitario | Pendiente | Dominio @ucr.ac.cr, @utn.ac.cr verificado |
| 3 | Estudiante accede al sandbox (dev-siaa.hacienda.go.cr) | Pendiente | Ambiente ATENA dev con datos de prueba |
| 4 | Completar ejercicio: DUA de exportación café a EE.UU. | Pendiente | Caso de estudio pre-armado |
| 5 | Clasificar con RIMM sandbox | Pendiente | Misma UX que producción, datos reales |
| 6 | Risk pre-validation muestra errores intencionales | Pendiente | Ejercicio pedagógico |
| 7 | Profesor revisa trabajos y califica | Pendiente | Dashboard académico |
| 8 | Emitir certificado "AduaNext Nivel 1" | Pendiente | PDF firmado + badge digital |

**Criterios de aceptación:**
- [ ] 30 estudiantes simultáneos sin degradación de performance
- [ ] Datos sandbox NO tocan producción en ningún momento
- [ ] Profesor puede ver métricas por estudiante (completitud, errores, tiempo)

---

## J06: Registrar y verificar Vetted Sourcer

**Persona primaria:** P06 (Lucía, Sourcer China)
**Revenue tag:** $150/mes listing + origina DUAs para pymes
**Completitud actual:** 0%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Sourcer se registra con datos de empresa extranjera | Pendiente | KYC: tax ID origen, documentos, representante |
| 2 | Subir catálogo de productos con HS codes propuestos | Pendiente | CSV/Excel import + validación RIMM |
| 3 | AduaNext valida HS codes contra RIMM | Pendiente | `/commodity/search` + batch validation |
| 4 | Sourcer recibe trust score inicial (Unverified → Basic) | Pendiente | 7 señales ponderadas |
| 5 | Completar KYC documental (auditor verifica) | Pendiente | Workflow de aprobación |
| 6 | Pymes pueden buscar y seleccionar sourcer | Pendiente | Marketplace search by category/origin/trust |
| 7 | Generar certificado de origen automático | Pendiente | Template por TLC (CAFTA-DR, CR-CN, EU-CA) |

**Criterios de aceptación:**
- [ ] Un catálogo de 50 productos se valida contra RIMM en <30 segundos
- [ ] Trust score se calcula con las 7 señales definidas en Spike 004
- [ ] El certificado de origen generado cumple con formato del TLC aplicable

---

## J07: Autenticarse con ATENA via gRPC sidecar

**Persona primaria:** Todas (sistema)
**Revenue tag:** Bloqueador — sin auth, nada funciona
**Completitud actual:** 40%

### Pasos

| # | Pantalla/Acción | Estado | Notas |
|---|-----------------|--------|-------|
| 1 | Serverpod envía credenciales al sidecar gRPC | Parcial | Proto `HaciendaAuth.Authenticate` definido |
| 2 | Sidecar obtiene token OIDC de Keycloak ATENA | Parcial | hacienda-cr `TokenManager` reutilizable |
| 3 | Token cacheado en sidecar, auto-refresh a 80% TTL | Parcial | hacienda-cr ya implementa esto |
| 4 | Serverpod solicita `GetAccessToken` para cada request | Parcial | Proto definido |
| 5 | Si token expirado, refresh automático transparente | Parcial | hacienda-cr ya implementa |
| 6 | Si refresh falla, alerta al administrador | Pendiente | NotificationPort |

**Criterios de aceptación:**
- [ ] Auth completa en <2 segundos
- [ ] Token refresh es transparente (usuario no percibe interrupción)
- [ ] Credenciales nunca se loguean en plaintext

---

## 4. Auditoria de Brechas

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

---

## 5. Directiva Claude

```yaml
# Directiva Claude — AduaNext
# Machine-readable priorities for AI agents and engineers
# Generated: 2026-04-03
# Target: $50K MRR at 6 months

north_star:
  question: "Puede un agente aduanero freelance (P02) preparar, firmar y transmitir una DUA de exportacion completa a ATENA usando AduaNext, y que una pyme (P03) monitoree el estado en tiempo real?"
  current_answer: "No. La arquitectura esta definida pero cero flujo end-to-end funciona."
  blocking_items:
    - "T0-1: gRPC sidecar no implementado"
    - "T0-3: Serverpod endpoints no existen"
    - "T0-4: RIMM adapter no implementado"

priority_rules:
  - id: PR-01
    rule: "Nunca trabajes en J05 (Sandbox Edu) o J06 (Vetted Sourcer) antes de que J01 (DUA Export) y J07 (Auth) esten al 100%"
    why: "J01+J07 representan el 60% del revenue. J05+J06 son 12% y dependen de que el core funcione."

  - id: PR-02
    rule: "Toda implementacion debe pasar por el Port/Adapter pattern. Nunca importes ATENA, RIMM, o hacienda-cr directamente desde el domain o application layer."
    why: "Explicit Architecture. El domain tiene ZERO dependencias I/O. Cuando agreguemos Guatemala (SAT-GT), solo se crean nuevos adapters."

  - id: PR-03
    rule: "El human-in-the-loop de clasificacion arancelaria NO es negociable. Nunca auto-submitas un HS code sin confirmacion explicita del agente."
    why: "Ley 7557 asigna responsabilidad personal al agente aduanero. Full automation de clasificacion es legalmente impermisible."

  - id: PR-04
    rule: "Toda decision de clasificacion, firma, y transmision se registra en el audit trail con SHA-256 hash chain. Sin excepciones."
    why: "Control a-posteriori de la DGA puede ocurrir anos despues del despacho. La cadena de decisiones debe ser inmutable."

  - id: PR-05
    rule: "El gRPC sidecar (hacienda-cr) se importa como dependencia npm, NUNCA se forkea. Las adaptaciones para ATENA van en la config, no en el codigo del SDK."
    why: "hacienda-cr tiene su propio ciclo de releases. Fork diverge y no recibe security patches."

  - id: PR-06
    rule: "Prioriza a P03 (Andrea, Pyme) sobre P01 (Maria, Agencia) en decisiones de UX. La pyme necesita simplicidad; la agencia tolera complejidad."
    why: "P03 representa 29% del revenue y es el segmento con mayor viral loop (startup-to-startup referrals)."

  - id: PR-07
    rule: "Siempre usa los field names exactos de la API ATENA en el domain model (camelCase, mismos nombres). No renombres ni traduzcas."
    why: "El JSON que entra y sale de ATENA debe ser 1:1 con nuestro modelo. Renombrar introduce bugs de mapping silenciosos."

anti_patterns:
  - id: AP-01
    pattern: "Implementar features del marketplace (J06) antes de que el core customs flow (J01) funcione"
    detection: "PRs que tocan libs/adapters/marketplace/ cuando libs/adapters/atena/ esta incompleto"
    fix: "Redirect al backlog T0/T1"

  - id: AP-02
    pattern: "Hardcodear URLs de ATENA en el codigo"
    detection: "Strings como 'dev-siaa.hacienda.go.cr' fuera de archivos de config"
    fix: "Usar CountryAdapterFactory + environment config YAML"

  - id: AP-03
    pattern: "Bypasear el sandbox proxy para llamadas directas a ATENA produccion"
    detection: "HTTP calls a ATENA sin pasar por el gRPC sidecar"
    fix: "Toda comunicacion ATENA pasa por HaciendaApi gRPC service"

  - id: AP-04
    pattern: "Agregar dependencias I/O al domain layer (libs/domain/)"
    detection: "pubspec.yaml de libs/domain con deps como http, grpc, postgres"
    fix: "Mover a libs/adapters/. El domain solo depende de 'meta' (annotations)"

  - id: AP-05
    pattern: "Mutar clasificaciones en lugar de crear nuevo evento"
    detection: "UPDATE en tabla de clasificaciones en vez de INSERT"
    fix: "Patron append-only. Cambios = nuevo evento con referencia al anterior"

  - id: AP-06
    pattern: "Notificaciones sin opt-out por tipo"
    detection: "NotificationPort.send() sin verificar preferencias del usuario"
    fix: "Cada tenant configura que estados disparan notificacion y por que canal"

persona_quick_ref:
  P01_maria: "Agencia veterana, 36% revenue, necesita J01+J02+J07. Churn risk: integracion ATENA falla."
  P02_carlos: "Freelance recien graduado, 5% revenue pero 23% usuarios. Viral loop alto. Sensible a precio."
  P03_andrea: "Pyme importadora, 29% revenue. QUIERE transparencia. Pain: 'los codigos son secreto comercial'."
  P04_vargas: "Profesor UTN, 6% revenue. Gateway al flywheel educativo. Necesita sandbox funcional."
  P05_diego: "Exportador grande, 14% revenue. Necesita monitoreo real-time de 50+ DUAs simultaneas."
  P06_lucia: "Sourcer China, 6% revenue. Solo viable cuando hay compradores en la plataforma."
  P07_ana: "Estudiante, 0% revenue hoy. Convierte a P02 al graduarse. Long-term flywheel."

journey_acceptance:
  J01_dua_export:
    must: "DUA EX transmitida a ATENA sandbox con customsRegistrationNumber en response"
    must_not: "DUA transmitida sin firma digital del agente"
    metric: "Tiempo de preparacion <15 min para agente experimentado"

  J02_clasificacion:
    must: "3+ sugerencias de HS code con confidence score por busqueda"
    must_not: "HS code auto-asignado sin confirmacion humana"
    metric: "Clasificacion correcta al primer intento >85%"

  J03_monitoreo:
    must: "Estado actualizado <60 segundos despues del cambio en ATENA"
    must_not: "Estado stale por >5 minutos sin alerta"
    metric: "Notificacion Telegram entregada <30 segundos post-cambio"

  J04_importer_led:
    must: "Pyme registrada + agente invitado + primera DUA transmitida en <48 horas"
    must_not: "Pyme vea informacion financiera de otros clientes del agente"
    metric: "Onboarding completo en <5 minutos (registro pyme)"

  J07_auth:
    must: "Token ATENA obtenido via gRPC sidecar en <2 segundos"
    must_not: "Credenciales logueadas en plaintext en ningun log"
    metric: "Token refresh transparente (zero downtime percibido)"
```
