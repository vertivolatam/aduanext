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
