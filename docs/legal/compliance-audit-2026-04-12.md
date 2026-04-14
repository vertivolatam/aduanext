# Auditoría de Compliance Regulatorio — AduaNext

> **Fecha:** 2026-04-12
> **Auditor:** Claude Opus 4.6 + Andrés Peña
> **Marco legal:** Ley 7557 (LGA) · Decreto 25270 (RLGA) · Ley 8360 (CAUCA)
> **Sistema destino:** ATENA (Servicio Nacional de Aduanas, Ministerio de Hacienda CR)
> **Nota:** Esta auditoría NO referencia el sistema TICA (derogado). Toda integración es con ATENA.

---

## Resumen Ejecutivo

AduaNext tiene una **base arquitectónica sólida** (domain layer al 80%, gRPC sidecar al 85%, proto al 100%) pero **gaps críticos de compliance** que deben cerrarse antes de operar con DUAs reales. Los 5 bloqueadores principales son:

| # | Gap | Artículo(s) | Riesgo |
|---|-----|-------------|--------|
| 1 | Audit trail hash-chained NO implementado | LGA Art. 24, CAUCA Art. 24-25 | **CRÍTICO** — Sin prueba de actos, DGA puede desautorizar |
| 2 | Clasificación sin HITL vinculante | LGA Art. 33, 35.d | **CRÍTICO** — Agente personalmente responsable por clasificación |
| 3 | Capa de aplicación vacía (0 use cases) | LGA Art. 86 | **ALTO** — No hay lógica de negocio orquestada |
| 4 | Sin RBAC ni tenant isolation | LGA Art. 28-30, CAUCA Art. 22 | **ALTO** — Multi-tenancy requerido por modelo de negocio |
| 5 | Sin soporte PKCS#11 (tokens USB) | LGA Art. 86, CAUCA Art. 23 | **BLOQUEADOR** — Agentes usan SINPE tokens exclusivamente |

---

## 1. Auxiliares de Función Pública Aduanera (LGA Título III)

### 1.1 Registro y Autorización del Agente (Art. 28-29, 33-34)

| Requisito legal | Estado en AduaNext | Gap |
|----------------|-------------------|-----|
| Agente es persona natural autorizada por DGA (Art. 33) | No modelado | Falta entidad `Agent` con número de patente, estado DGA |
| Requisitos de ingreso: licenciatura, examen DGA, antecedentes (Art. 34) | No verificado | KYC del agente no implementado |
| Caución de 20,000 pesos centroamericanos (Art. 34) | No modelado | Falta tracking de vigencia de fianza |
| Inscripción en registro de auxiliares + Registro Tributario (Art. 29) | No modelado | Falta validación de estado DGA activo |
| Auxiliar que incumple requisito no puede operar (Art. 29 párr. 2) | No implementado | Debe bloquearse automáticamente |

**Veredicto: NO COMPLIANT** — No existe entidad `Agent` en domain ni validación de prerequisitos legales.

### 1.2 Obligaciones del Auxiliar (Art. 30, 35)

| Obligación | Estado | Gap |
|-----------|--------|-----|
| Llevar registros de actuaciones/operaciones (Art. 30.a) | Port definido (`AuditLogPort`) | Adapter NO implementado |
| Conservar documentos 5+ años (Art. 30.c / CAUCA Art. 14) | No implementado | Sin política de retención |
| Transmitir electrónicamente (Art. 30.e) | Implementado (gRPC sidecar) | OK |
| Mantener garantía vigente (Art. 30.g) | No monitoreado | Sin alerta de vencimiento |
| Clasificar conforme al SAC (Art. 35.d) | Parcial (HsCode VO existe) | Sin RIMM integration end-to-end |
| Declarar bajo fe de juramento (Art. 33 párr. 2) | No implementado | Falta confirmación explícita antes de firma |

### 1.3 Responsabilidad Solidaria (Art. 36)

| Aspecto | Estado | Impacto |
|---------|--------|---------|
| Agente solidariamente responsable por obligaciones tributarias | No modelado | AduaNext debe advertir al agente del monto en riesgo |
| Subrogación por pagos realizados (Art. 39) | No modelado | Falta registro de pagos por cuenta del mandante |

---

## 2. Sistemas Informáticos (CAUCA Cap. III, Art. 22-25)

| Requisito | Artículo | Estado | Gap |
|-----------|----------|--------|-----|
| Cumplir medidas de seguridad del Servicio Aduanero | CAUCA 22 | Parcial | Auth OIDC OK; falta cert pinning, rate limiting |
| Firma electrónica = firma autógrafa | CAUCA 23 | Implementado | XAdES-EPES via gRPC sidecar |
| Registros del sistema = prueba de actos realizados | CAUCA 24 | **NO IMPLEMENTADO** | Audit trail hash-chained requerido |
| Información electrónica admisible como evidencia | CAUCA 25 | Parcial | Depende de que CAUCA 24 se implemente |
| Conservar información en medios digitales (LGA Art. 32) | No implementado | Sin persistence layer |

**Veredicto: PARCIALMENTE COMPLIANT** — La transmisión funciona pero la prueba/evidencia no se preserva.

---

## 3. Despacho Aduanero (CAUCA Título V, LGA Título V)

### 3.1 Declaración de Mercancías (CAUCA Art. 52-58)

| Requisito | Estado | Gap |
|-----------|--------|-----|
| Declaración expresa selección de régimen bajo juramento (CAUCA 52) | Parcial | `Declaration` entity existe; falta campo oath/juramento |
| Transmisión electrónica como procedimiento normal (CAUCA 53) | Implementado | gRPC → ATENA REST |
| Declaración anticipada (pre-arribo) soportada (CAUCA 55) | No implementado | Sin workflow pre-arribo |
| Declaración provisional soportada (CAUCA 56) | No implementado | Sin workflow provisional |
| Carácter definitivo; rectificación según Reglamento (CAUCA 57) | Parcial | Proto `RectifyDeclaration` definido |
| Aceptación = registro en sistema (CAUCA 58) | Implementado | `LiquidateDeclaration` retorna registrationKey |

### 3.2 Verificación (CAUCA Art. 59-62)

| Requisito | Estado | Gap |
|-----------|--------|-----|
| Selectividad aleatoria (canal verde/amarillo/rojo) (CAUCA 59) | Parcial | `DeclarationStatus` tiene estados pero no modela canales |
| Verificación posterior 4 años (CAUCA 62) | No soportado | Sin retención ni exportación de datos |
| Fiscalización post-despacho (CAUCA 61) | No soportado | Sin preparación para auditoría DGA |

### 3.3 Clasificación Arancelaria (LGA Art. 35.d, RLGA Art. 21)

| Requisito | Estado | Gap |
|-----------|--------|-----|
| Clasificar conforme al SAC vigente | Parcial | HsCode VO + RIMM port definidos |
| Criterios uniformes de DGA (RLGA Art. 21) | No implementado | Sin consumo de directrices DGA |
| Human-in-the-loop obligatorio | **NO IMPLEMENTADO** | BLOQUEADOR — agente es legalmente responsable |
| Decisión de clasificación inmutable | **NO IMPLEMENTADO** | Sin patrón append-only con firma |

---

## 4. Obligaciones Tributarias (CAUCA Título III)

| Requisito | Estado | Gap |
|-----------|--------|-----|
| Autodeterminación por declarante (CAUCA 32) | Parcial | Entity mapea campos pero sin cálculo |
| Base imponible = valor aduanero (CAUCA 30) | Parcial | IncoTerm VO existe; sin cálculo CIF |
| Garantías para regímenes suspensivos (CAUCA 28) | No implementado | Sin soporte de regímenes temporales |
| Prenda aduanera a favor del Fisco (CAUCA 33) | No modelado | Informativo — no requiere código |

---

## 5. Firma Digital (LGA Art. 86, CAUCA Art. 23)

| Requisito | Estado | Gap |
|-----------|--------|-----|
| XAdES-EPES con certificado BCCR | Implementado | gRPC `HaciendaSigner` |
| Equivalencia legal firma autógrafa | Implementado | CAUCA Art. 23 cubierto |
| Verificación criptográfica de firma | **INCOMPLETO** | Solo check estructural, no criptográfico |
| Cadena de certificados BCCR | No implementado | Sin validación de CA root |
| OCSP / revocación de certificado | No implementado | Certificado revocado podría firmar |
| Soporte PKCS#11 (tokens USB SINPE) | **NO IMPLEMENTADO** | BLOQUEADOR para producción |

---

## 6. Regímenes Aduaneros (CAUCA Título VI)

| Régimen | Soportado | Prioridad |
|---------|-----------|-----------|
| Exportación definitiva (CAUCA 69) | Parcial (J01) | **P0** — North Star |
| Importación definitiva (CAUCA 68) | No | P1 — Post-MVP |
| Tránsito aduanero (CAUCA 70) | Parcial (T1 en DeclarationStatus) | P0 — Parte del flujo export |
| Importación temporal (CAUCA 73) | No | P2 |
| Admisión temporal perfeccionamiento activo (CAUCA 74) | No | P2 |
| Depósito aduanero (CAUCA 75) | No | P2 |
| Zonas francas (CAUCA 77) | No | P3 |
| Reexportación (CAUCA 83) | No | P3 |

---

## 7. Infracciones y Sanciones (CAUCA Título VIII)

| Tipo | Relevancia para AduaNext | Gap |
|------|-------------------------|-----|
| Administrativa (CAUCA 98) | AduaNext debe prevenir infracciones por errores | Sin validación pre-envío exhaustiva |
| Tributaria (CAUCA 99) | Perjuicio fiscal = responsabilidad solidaria agente | Sin cálculo de exposición de riesgo |
| Penal (CAUCA 100) | Contrabando, defraudación | AduaNext no debe facilitar evasión |

---

## 8. Matriz de Compliance por Componente

| Componente | LGA | CAUCA | RLGA | Score |
|-----------|-----|-------|------|-------|
| Domain entities | ◐ | ◐ | ○ | 40% |
| gRPC sidecar (auth) | ● | ● | ◐ | 75% |
| gRPC sidecar (signing) | ◐ | ● | ○ | 60% |
| gRPC sidecar (API) | ● | ● | ◐ | 80% |
| Audit trail | ○ | ○ | ○ | 5% |
| Classification HITL | ○ | ○ | ○ | 5% |
| Application layer | ○ | ○ | ○ | 0% |
| RBAC / multi-tenant | ○ | ○ | ○ | 0% |
| Data retention | ○ | ○ | ○ | 0% |
| Risk pre-validation | ○ | ○ | ○ | 0% |

**Leyenda:** ● Compliant · ◐ Parcial · ○ No implementado

---

## 9. Plan de Remediación (Priorizado)

### P0 — Bloqueadores (antes de beta)

1. **Implementar audit trail hash-chained** — PostgreSQL append-only + SHA-256 chain
2. **Implementar clasificación HITL** — UI + firma digital del agente por decisión
3. **Integrar PKCS#11** — Bridge para tokens USB SINPE
4. **Crear application layer** — Use cases que orquesten domain + adapters

### P1 — Críticos (antes de producción)

5. **RBAC + tenant isolation** — Roles: agent, supervisor, importer, admin
6. **Data retention policy** — 5 años mínimo (LGA Art. 30.c)
7. **Pre-validation rules engine** — Antes de transmitir a ATENA
8. **Verificación criptográfica de firma** — Cadena BCCR + OCSP

### P2 — Importantes (primeros 3 meses post-launch)

9. **Soporte regímenes suspensivos** — Importación temporal, depósito
10. **Exportación de evidencia para fiscalización** — JSON + PDF
11. **Cálculo automático de obligación tributaria**
12. **Alertas de vencimiento de caución y certificados**

---

*Próxima revisión recomendada: cuando se complete el audit trail (P0.1)*
