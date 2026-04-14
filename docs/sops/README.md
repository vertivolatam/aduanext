# SOPs — Procedimientos Operativos Estándar de AduaNext

> Procedimientos Operativos Estándar para el ciclo completo de despacho aduanero de exportación en Costa Rica, desde el mandato del cliente hasta la confirmación de embarque, incluyendo pasos digitales, presenciales e interacciones con inspectores de la DGA.

**Versión:** 1.0

**Fecha:** 2026-04-12

**Marco legal:**
- Ley 7557 — Ley General de Aduanas (LGA)
- Decreto 25270 — Reglamento a la LGA (RLGA, Títulos II y III vigentes)
- Ley 8360 — Código Aduanero Uniforme Centroamericano (CAUCA)
- Decreto 44051 — Nuevo Reglamento LGA (2023, procedimientos ATENA)

**Sistema de destino:** ATENA (Servicio Nacional de Aduanas, Ministerio de Hacienda)

**NOTA:** Estos SOPs NO referencian el sistema TICA (derogado). Toda integración es con ATENA.

**Referencias:**
- [Auditoría de Compliance](../legal/compliance-audit-2026-04-12.md)
- [ATENA DUA API](../references/SIAA-ATENA-DUA-GUIA-TECNICA.pdf)
- [RIMM API](../references/SIAA-ATENA-Especificacion-Tecnica-RIMM-Arancel.pdf)
- [Procedimientos de Exportación DGA](../references/Procedimientos-Exportacion-ATENA.pdf)
- [SRD Journeys](../../srd/journeys.md)
- [Cadena de Valor (North Star)](../../srd/SRD.md)

---

## Roles

| Rol | Descripción | Tipo | Acciones principales |
|-----|-------------|------|---------------------|
| **Agente Aduanero Freelance** | Persona natural autorizada por DGA (patente vigente). Representa al mandante ante el SNA. Responsable solidario por obligaciones tributarias. | Humano | Clasifica, prepara DUA, firma con Firma Digital, acompaña aforo, transmite a ATENA |
| **Exportador/Importador (Mandante)** | Persona física o jurídica dueña de la mercancía. Otorga mandato al agente. | Humano | Provee datos comerciales, facturas, docs de soporte. Monitorea estado de DUA |
| **Inspector de Aduanas (DGA)** | Funcionario del Servicio Nacional de Aduanas asignado por selectividad aleatoria (Art. 19 LGA). | Humano | Revisa documentos (canal amarillo), inspecciona físicamente (canal rojo), autoriza levante |
| **Aforador (DGA)** | Funcionario técnico especializado en inspección física de mercancías. | Humano | Abre bultos, verifica cantidad/naturaleza, compara contra declaración, toma muestras |
| **Fiscalizador (DGA)** | Funcionario de la Dirección de Fiscalización. Actúa en control a posteriori. | Humano | Audita registros, solicita documentación, determina ajustes tributarios (hasta 4 años) |
| **Transportista Aduanero** | Auxiliar autorizado que moviliza mercancía bajo control aduanero (T1). | Humano | Presenta vehículo, instala precintos electrónicos, transporta por ruta legal |
| **Depositario Aduanero** | Persona que custodia mercancías en almacén fiscal autorizado. | Humano | Recibe, almacena, libera mercancía solo con autorización de levante |
| **Naviera/Aerolínea** | Operador de transporte internacional que emite conocimiento de embarque. | Externo | Emite B/L o AWB, confirma embarque, transmite manifiesto de carga |
| **Consolidador de Carga** | Agrupa mercancías de varios consignatarios (LCL). | Externo | Emite HBL, transmite manifiesto consolidado, desconsolida en destino |
| **AduaNext (Plataforma)** | Sistema que orquesta el flujo digital del despacho. | Software | Guía pasos, calcula riesgo, conecta con ATENA vía gRPC, genera audit trail |
| **ATENA (Sistema DGA)** | Sistema informático del SNA para gestión de declaraciones y RIMM. | Software | Recibe DUA, valida, asigna canal, registra, emite liquidación |
| **SINPE / Firma Digital** | Infraestructura de firma electrónica del BCCR. Token USB PKCS#11. | Hardware | Firma XAdES-EPES con certificado BCCR. Equivale a firma autógrafa (CAUCA Art. 23) |

---

## Flujo General del Despacho de Exportación

```
MANDATO → CLASIFICACIÓN → VALORACIÓN → PREPARACIÓN DUA → FIRMA DIGITAL → TRANSMISIÓN ATENA
    → SELECTIVIDAD (canal verde/amarillo/rojo) → LEVANTE → T1 MOVILIZACIÓN → EMBARQUE → CONFIRMACIÓN
```

**Post-despacho:**
```
RECTIFICACIÓN (si errores) ← → PAGO DE DIFERENCIAS ← → FISCALIZACIÓN (hasta 4 años)
```

---

## Catálogo de SOPs

### Categoría A: Ciclo de Vida del Agente

| SOP | Título | Base Legal | Archivo |
|-----|--------|-----------|---------|
| A01 | Registro y Autorización del Agente Freelance | LGA Art. 28-29, 33-34 | [categoria-a-ciclo-agente.md](categoria-a-ciclo-agente.md#sop-a01) |
| A02 | Gestión de Caución y Garantías | LGA Art. 34, 65-66 | [categoria-a-ciclo-agente.md](categoria-a-ciclo-agente.md#sop-a02) |
| A03 | Control Permanente del Auxiliar | LGA Art. 24, 30 | [categoria-a-ciclo-agente.md](categoria-a-ciclo-agente.md#sop-a03) |

### Categoría B: Flujo de Despacho — Exportación (core, mapea a J01)

| SOP | Título | Base Legal | Archivo |
|-----|--------|-----------|---------|
| B01 | Intake del Despacho (KYC + Mandato) | LGA Art. 33, 37-38 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b01) |
| B02 | Clasificación Arancelaria con HITL | LGA Art. 35.d; RLGA Art. 21 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b02) |
| B03 | Valoración Aduanera (CIF/FOB) | LGA Art. 57; RLGA Art. 22-23 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b03) |
| B04 | Preparación de la DUA de Exportación | LGA Art. 86; CAUCA Art. 52-54 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b04) |
| B05 | Firma Digital y Transmisión a ATENA | CAUCA Art. 23, 53 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b05) |
| B06 | Verificación y Aforo (Selectividad) | LGA Art. 22-23; CAUCA Art. 59-60 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b06) |
| B07 | Levante y Autorización de Salida | LGA Art. 48.e; CAUCA Art. 51 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b07) |
| B08 | Movilización con Documento T1 | LGA Art. 40-43; CAUCA Art. 70-72 | [categoria-b-despacho-exportacion.md](categoria-b-despacho-exportacion.md#sop-b08) |

### Categoría C: Ciclo Post-Despacho

| SOP | Título | Base Legal | Archivo |
|-----|--------|-----------|---------|
| C01 | Confirmación de Embarque | Procedimientos Exportación Cap. 6 | [categoria-c-post-despacho.md](categoria-c-post-despacho.md#sop-c01) |
| C02 | Rectificación (Contra-escritura) | CAUCA Art. 57; LGA Art. 59 | [categoria-c-post-despacho.md](categoria-c-post-despacho.md#sop-c02) |
| C03 | Pago de Tributos y Diferencias | LGA Art. 53-61; CAUCA Art. 26-35 | [categoria-c-post-despacho.md](categoria-c-post-despacho.md#sop-c03) |
| C04 | Cancelación y Anulación de DUA | LGA Art. 56; CAUCA Art. 94 | [categoria-c-post-despacho.md](categoria-c-post-despacho.md#sop-c04) |

### Categoría D: Compliance Continuo

| SOP | Título | Base Legal | Archivo |
|-----|--------|-----------|---------|
| D01 | Control A Posteriori (Fiscalización) | LGA Art. 24, 59; CAUCA Art. 61-62 | [categoria-d-compliance.md](categoria-d-compliance.md#sop-d01) |
| D02 | Gestión de Documentos de Soporte | LGA Art. 30, 32, 35.g; CAUCA Art. 54 | [categoria-d-compliance.md](categoria-d-compliance.md#sop-d02) |
| D03 | Respuesta a Infracciones y Recursos | LGA Art. 24-25; CAUCA Art. 97-105 | [categoria-d-compliance.md](categoria-d-compliance.md#sop-d03) |

---

## Modelo de Ingresos en el Flujo

AduaNext genera ingresos en tres momentos del ciclo de despacho:

| Momento | Quién paga | Monto | Frecuencia |
|---------|-----------|-------|------------|
| **Suscripción del agente/agencia** (SOP-A01) | Agente/Agencia | $60-$1,200/mes según plan | Mensual |
| **Revenue por DUA transmitida** (SOP-B05) | Agente o Pyme | $5/DUA | Por despacho |
| **Suscripción pyme importer-led** (SOP-B01) | Pyme | $120/mes | Mensual |

---

## Mapeo SOP → Journey SRD → Use Case

| SOP | Journey | Use Case (libs/application/) | Domain Entity |
|-----|---------|------------------------------|---------------|
| A01 | J07 | `RegisterAgentUseCase` | `Agent` (nuevo) |
| B01 | J04 | `CreateDispatchUseCase` | `Dispatch` (nuevo) |
| B02 | J02 | `ClassifyTariffUseCase` | `HsCode`, `CommodityEntry` |
| B03 | J01.7 | `CalculateValuationUseCase` | `Incoterm`, `Declaration` |
| B04 | J01.2-9 | `PrepareDeclarationUseCase` | `Declaration` |
| B05 | J01.10-11 | `SignAndTransmitUseCase` | `Declaration`, `SigningResult` |
| B06 | J01.12 | `HandleVerificationUseCase` | `DeclarationStatus` |
| B07 | J01.12 | `AuthorizeReleaseUseCase` | `DeclarationStatus` |
| B08 | J01.12 | `MobilizeT1UseCase` | `Transit` (nuevo) |
| C01 | J03 | `ConfirmShipmentUseCase` | `DeclarationStatus` |
| C02 | J03.7 | `RectifyDeclarationUseCase` | `Declaration` |
| D01 | — | `RespondAuditUseCase` | `AuditEvent` |
| D02 | — | `ManageDocumentsUseCase` | `AttachedDocument` |

---

## Resumen de Tiempos

| SOP | Duración estimada | SLA en AduaNext |
|-----|-------------------|-----------------|
| A01 | 30-90 días (examen DGA + trámite) | Onboarding digital <1 día; trámite DGA es externo |
| B01 | 1-2 horas (primera vez por cliente) | Mandato firmado en <30 min vía plataforma |
| B02 | 5-30 min por línea arancelaria | AI sugiere en <5 seg; agente confirma en <2 min |
| B03 | 5-15 min | Cálculo automático; revisión manual |
| B04 | 15-45 min por DUA completa | Formulario guiado; pre-validación instantánea |
| B05 | 1-3 min | Firma + transmisión <30 seg si token conectado |
| B06 | 0 min (verde) / 1h (amarillo) / 2-8h (rojo) | Notificación instantánea del canal asignado |
| B07 | 5-30 min | Notificación cuando ATENA autoriza |
| B08 | 2-48 horas (según distancia) | Tracking de precintos en tiempo real |
| C01 | 1-5 días (ventana de confirmación) | Alerta automática antes de vencimiento |
| C02 | 30-60 min | Formulario de corrección + re-firma |
| C03 | Variable (plazos legales) | Calculadora de intereses automática |
| D01 | 1-30 días (según alcance de auditoría) | Exportación de evidencia en 1 clic |

**Tiempo total de intake a embarque confirmado: 2-5 días** (vs. 5-15 días del proceso manual tradicional)

---

## Apéndice: Artículos Clave por SOP

| Artículo | Ley | Tema | SOPs donde aplica |
|----------|-----|------|-------------------|
| Art. 28-29 | LGA | Concepto y requisitos de auxiliares | A01, A03 |
| Art. 30 | LGA | Obligaciones básicas de auxiliares | A03, D01, D02 |
| Art. 33-34 | LGA | Agente aduanero: concepto y requisitos | A01, B01 |
| Art. 35 | LGA | Obligaciones específicas del agente | B02, B04, D02 |
| Art. 36 | LGA | Responsabilidad solidaria | B04, C03 |
| Art. 37 | LGA | Intervención obligatoria/opcional del agente | B01 |
| Art. 38-39 | LGA | Mandato y subrogación | B01, C03 |
| Art. 40-43 | LGA | Transportista aduanero | B08 |
| Art. 48 | LGA | Obligaciones del depositario | B07 |
| Art. 53-61 | LGA | Obligaciones tributarias y pago | C03 |
| Art. 65-66 | LGA | Garantías y ejecución | A02 |
| Art. 22-25 | CAUCA | Sistemas informáticos y firma electrónica | B05, D02 |
| Art. 26-35 | CAUCA | Obligaciones aduaneras | C03 |
| Art. 51-62 | CAUCA | Despacho aduanero | B04, B05, B06, B07 |
| Art. 70-72 | CAUCA | Tránsito aduanero | B08 |
| Art. 94-96 | CAUCA | Abandono y subasta | C04 |
| Art. 97-105 | CAUCA | Infracciones y recursos | D03 |
