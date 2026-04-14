---
title: Procedimientos Operativos Estandar
description: 18 SOPs para el ciclo completo de despacho aduanero de exportacion en Costa Rica
---

# Procedimientos Operativos Estandar

**18 SOPs para el ciclo completo de despacho aduanero de exportacion en Costa Rica**

| Campo | Valor |
|---|---|
| Version | 1.0 |
| Fecha | 2026-04-12 |
| Jurisdiccion | Costa Rica |
| Sistema aduanero | ATENA (Sistema Nacional de Aduanas) |
| Plataforma | AduaNext |

---

## Marco Legal

Estos procedimientos se fundamentan en la legislacion aduanera vigente de Costa Rica y la normativa centroamericana:

| Sigla | Norma | Descripcion |
|---|---|---|
| **LGA** | Ley 7557 | Ley General de Aduanas de Costa Rica. Establece el regimen juridico de la actividad aduanera, los derechos y obligaciones de los auxiliares de la funcion publica aduanera, y los procedimientos de despacho. |
| **RLGA** | Decreto 25270 | Reglamento a la Ley General de Aduanas. Desarrolla y complementa los procedimientos establecidos en la LGA, incluyendo requisitos documentales, plazos y formalidades. |
| **CAUCA** | Ley 8360 | Codigo Aduanero Uniforme Centroamericano. Marco normativo regional que armoniza los procedimientos aduaneros entre los paises del SIECA (Guatemala, El Salvador, Honduras, Nicaragua, Costa Rica). |

!!! warning "Importante: Sistema ATENA"
    Todos los SOPs de este documento hacen referencia exclusivamente al sistema **ATENA** del Servicio Nacional de Aduanas (SNA) de Costa Rica. ATENA es el sistema informatico vigente para la gestion aduanera. Ninguno de estos procedimientos referencia sistemas anteriores o deprecados.

!!! info "Alcance"
    Estos SOPs cubren el ciclo completo de despacho aduanero de **exportacion** en Costa Rica, desde la autorizacion del agente aduanero hasta la confirmacion de embarque. El flujo incluye tanto pasos **digitales** (ejecutados en AduaNext y ATENA) como pasos **presenciales** (interacciones fisicas con inspectores DGA, depositarios, navieras y otros actores).

---

## Roles Participantes

| No. | Rol | Descripcion |
|---|---|---|
| 1 | **Agente Aduanero Freelance** | Persona natural autorizada por DGA, responsable solidario ante el fisco por las obligaciones tributarias aduaneras derivadas de las operaciones que gestiona (Art. 33 LGA). |
| 2 | **Exportador/Importador (Mandante)** | Dueno de la mercancia. Persona fisica o juridica que otorga mandato al agente aduanero para actuar en su nombre ante la aduana (Art. 36 LGA). |
| 3 | **Inspector de Aduanas (DGA)** | Funcionario del Servicio Nacional de Aduanas asignado por selectividad aleatoria para verificar el cumplimiento de las obligaciones aduaneras (Art. 19 LGA). |
| 4 | **Aforador (DGA)** | Funcionario tecnico de inspeccion fisica. Realiza el reconocimiento fisico de las mercancias cuando el semaforo de selectividad indica revision (Art. 93-94 LGA). |
| 5 | **Fiscalizador (DGA)** | Funcionario de la Direccion de Fiscalizacion. Ejecuta el control a posteriori sobre las operaciones aduaneras ya despachadas (Art. 24 LGA). |
| 6 | **Transportista Aduanero** | Auxiliar de la funcion publica aduanera que moviliza mercancia bajo regimen de transito aduanero T1 entre recintos habilitados (Art. 27 LGA). |
| 7 | **Depositario Aduanero** | Auxiliar que custodia mercancia en almacen fiscal o deposito aduanero bajo control del SNA (Art. 26 LGA). |
| 8 | **Naviera/Aerolinea** | Operador de transporte internacional que emite el conocimiento de embarque (B/L) o guia aerea (AWB) y confirma el embarque efectivo de la mercancia. |
| 9 | **Consolidador de Carga** | Auxiliar que agrupa mercancias de distintos exportadores en un solo contenedor o envio (carga LCL - Less than Container Load). |
| 10 | **AduaNext (Plataforma)** | Sistema que orquesta el flujo digital del despacho aduanero. Conecta al agente con ATENA, gestiona documentos, firma digital, clasificacion arancelaria y trazabilidad. |
| 11 | **ATENA (Sistema DGA)** | Sistema informatico del Servicio Nacional de Aduanas. Recibe las declaraciones (DUA), aplica selectividad, emite el levante y registra todas las operaciones aduaneras del pais. |
| 12 | **SINPE / Firma Digital** | Infraestructura de firma electronica del Banco Central de Costa Rica (BCCR). Token USB PKCS#11 que permite al agente firmar digitalmente las declaraciones antes de transmitirlas a ATENA. |

---

## Flujo General del Despacho de Exportacion

El siguiente diagrama muestra el flujo macro que cubre el conjunto de los 18 SOPs:

```mermaid
graph LR
    A[MANDATO] --> B[CLASIFICACION]
    B --> C[VALORACION]
    C --> D[PREPARACION DUA]
    D --> E[FIRMA DIGITAL]
    E --> F[TRANSMISION ATENA]
    F --> G[SELECTIVIDAD]
    G --> H[LEVANTE]
    H --> I[T1 MOVILIZACION]
    I --> J[EMBARQUE]
    J --> K[CONFIRMACION]

    style A fill:#1a1a2e,stroke:#e94560,color:#fff
    style B fill:#1a1a2e,stroke:#e94560,color:#fff
    style C fill:#1a1a2e,stroke:#e94560,color:#fff
    style D fill:#1a1a2e,stroke:#e94560,color:#fff
    style E fill:#1a1a2e,stroke:#0f3460,color:#fff
    style F fill:#1a1a2e,stroke:#0f3460,color:#fff
    style G fill:#1a1a2e,stroke:#16213e,color:#fff
    style H fill:#1a1a2e,stroke:#16213e,color:#fff
    style I fill:#1a1a2e,stroke:#533483,color:#fff
    style J fill:#1a1a2e,stroke:#533483,color:#fff
    style K fill:#1a1a2e,stroke:#533483,color:#fff
```

---

## Catalogo de SOPs

### Categoria A: Ciclo del Agente

Procedimientos relacionados con el ciclo de vida del agente aduanero freelance como auxiliar de la funcion publica aduanera.

| SOP | Titulo | Descripcion | Referencia Legal |
|---|---|---|---|
| [SOP-A01](categoria-a-ciclo-agente.md#sop-a01-registro-y-autorizacion-del-agente-freelance) | Registro y Autorizacion del Agente Freelance | Alta del agente en DGA y AduaNext, desde el examen hasta la operacion activa | LGA Art. 28-29, 33-34; CAUCA Art. 11-14 |
| [SOP-A02](categoria-a-ciclo-agente.md#sop-a02-gestion-de-caucion-y-garantias) | Gestion de Caucion y Garantias | Control de la caucion obligatoria, renovacion, alertas y bloqueo por vencimiento | LGA Art. 34, 65-66; CAUCA Art. 71 |
| [SOP-A03](categoria-a-ciclo-agente.md#sop-a03-control-permanente-del-auxiliar) | Control Permanente del Auxiliar | Respuesta a requerimientos de fiscalizacion y control a posteriori de DGA | LGA Art. 24, 30; CAUCA Art. 14 |

### Categoria B: Despacho de Exportacion (Core)

Procedimientos del flujo principal de despacho aduanero de exportacion, desde la recepcion del mandato hasta la transmision de la DUA.

| SOP | Titulo | Descripcion | Referencia Legal |
|---|---|---|---|
| SOP-B01 | Recepcion y Validacion del Mandato | Formalizacion de la relacion agente-mandante, verificacion de documentos y poder | LGA Art. 36-37; RLGA Art. 253 |
| SOP-B02 | Clasificacion Arancelaria | Determinacion de la partida SAC/HS con HITL (Human-in-the-Loop) obligatorio | LGA Art. 89; CAUCA Art. 46 |
| SOP-B03 | Valoracion Aduanera | Calculo del valor en aduanas segun metodos OMC/GATT | LGA Art. 89-90; CAUCA Art. 47-50 |
| SOP-B04 | Preparacion de la DUA de Exportacion | Llenado de los campos ATENA de la Declaracion Unica Aduanera | LGA Art. 86-87; RLGA Art. 245-248 |
| SOP-B05 | Firma Digital de la DUA | Firma electronica avanzada con token PKCS#11 via Firma Digital BCCR | LGA Art. 86; Ley 8454 Art. 9 |
| SOP-B06 | Transmision de la DUA a ATENA | Envio electronico de la declaracion al sistema ATENA del SNA | LGA Art. 86; RLGA Art. 249 |
| SOP-B07 | Proceso de Selectividad | Manejo del semaforo de selectividad aleatoria (verde, amarillo, rojo) | LGA Art. 93-94; RLGA Art. 250-252 |
| SOP-B08 | Obtencion del Levante | Autorizacion de salida de la mercancia del recinto aduanero | LGA Art. 100-101; RLGA Art. 260 |

### Categoria C: Post-Despacho

Procedimientos posteriores a la obtencion del levante, incluyendo movilizacion, embarque y cierre de la operacion.

| SOP | Titulo | Descripcion | Referencia Legal |
|---|---|---|---|
| SOP-C01 | Transito Aduanero T1 | Movilizacion de mercancia entre recintos bajo control aduanero | LGA Art. 104-105; RLGA Art. 270-275 |
| SOP-C02 | Embarque y Confirmacion de Salida | Verificacion del embarque efectivo y registro en ATENA | LGA Art. 106; RLGA Art. 276 |
| SOP-C03 | Archivo y Custodia Documental | Organizacion y conservacion del expediente de despacho | LGA Art. 30; RLGA Art. 280 |
| SOP-C04 | Liquidacion y Facturacion al Mandante | Cierre financiero de la operacion con el exportador | LGA Art. 33; Codigo de Comercio |

### Categoria D: Compliance Continuo

Procedimientos transversales de cumplimiento normativo que aplican durante todo el ciclo de vida del agente.

| SOP | Titulo | Descripcion | Referencia Legal |
|---|---|---|---|
| SOP-D01 | Auditoria Interna y Trazabilidad | Cadena SHA-256 de auditoria, verificacion de integridad de registros | LGA Art. 30; RLGA Art. 280 |
| SOP-D02 | Actualizacion Normativa | Monitoreo de cambios en legislacion, aranceles y procedimientos DGA | LGA Art. 30; CAUCA Art. 14 |
| SOP-D03 | Gestion de Incidentes y Sanciones | Respuesta a multas, suspensiones, procedimientos sancionatorios | LGA Art. 230-245; CAUCA Art. 100-105 |

---

## Modelo de Ingreso AduaNext

Los SOPs estan disenados para soportar el modelo de negocio de AduaNext. Cada SOP genera valor que se refleja en los siguientes flujos de ingreso:

| Plan | Precio | Descripcion | SOPs Principales |
|---|---|---|---|
| **Suscripcion Agente Freelance** | $60 - $150/mes | Acceso a la plataforma, firma digital, transmision ATENA, dashboard de compliance | A01-A03, B01-B08, D01-D03 |
| **Suscripcion Agencia** | $300 - $1,200/mes | Multi-agente, reportes avanzados, API, soporte prioritario | Todos |
| **Costo por DUA** | $5/DUA | Cargo por cada declaracion transmitida exitosamente a ATENA | B04-B06 |
| **Suscripcion Pyme (Importador-Led)** | $120/mes | Monitoreo en tiempo real, co-pilot de clasificacion, trazabilidad | B02, B07, C01-C02, D01 |

---

## Resumen de Tiempos por Fase

Estimacion de tiempos para un despacho de exportacion estandar (mercancia general, sin incidencias):

| Fase | SOP(s) | Tiempo Estimado | Digital / Presencial |
|---|---|---|---|
| Mandato y documentos | B01 | 1-2 horas | Digital |
| Clasificacion arancelaria | B02 | 30 min - 2 horas | Digital (con HITL) |
| Valoracion aduanera | B03 | 15-30 min | Digital |
| Preparacion DUA | B04 | 20-45 min | Digital |
| Firma digital | B05 | 2-5 min | Digital (token fisico) |
| Transmision a ATENA | B06 | 1-3 min | Digital |
| Selectividad | B07 | Inmediato - 4 horas | Digital + Presencial |
| Levante | B08 | 15 min - 2 horas | Digital + Presencial |
| Transito T1 | C01 | 2-8 horas | Presencial |
| Embarque y confirmacion | C02 | 1-4 horas | Presencial + Digital |
| Archivo documental | C03 | 15-30 min | Digital |
| Liquidacion al mandante | C04 | 30 min - 1 hora | Digital |
| **Total estimado** | | **6-24 horas** | |

!!! note "Variabilidad"
    Los tiempos varian significativamente segun el tipo de mercancia, la aduana de despacho, la carga de trabajo de DGA, y si la selectividad resulta en semaforo verde (sin revision), amarillo (revision documental) o rojo (reconocimiento fisico).

---

## Apendice: Articulos Legales Clave por SOP

Mapeo de los articulos legales mas relevantes a cada grupo de SOPs para referencia rapida:

| Articulo | Ley | Tema | SOPs Relacionados |
|---|---|---|---|
| Art. 19 LGA | Ley 7557 | Facultades del SNA, selectividad aleatoria | B07 |
| Art. 24 LGA | Ley 7557 | Control y fiscalizacion a posteriori | A03, D01 |
| Art. 26 LGA | Ley 7557 | Depositarios aduaneros | B08, C01 |
| Art. 27 LGA | Ley 7557 | Transportistas aduaneros | C01 |
| Art. 28-29 LGA | Ley 7557 | Agentes aduaneros, requisitos de autorizacion | A01 |
| Art. 30 LGA | Ley 7557 | Obligaciones de los auxiliares, registros 5 anos | A03, C03, D01 |
| Art. 33-34 LGA | Ley 7557 | Responsabilidad solidaria, caucion obligatoria | A01, A02 |
| Art. 36-37 LGA | Ley 7557 | Mandato aduanero, poder de representacion | B01 |
| Art. 65-66 LGA | Ley 7557 | Garantias aduaneras, tipos y montos | A02 |
| Art. 86-87 LGA | Ley 7557 | Declaracion aduanera, forma y contenido | B04, B05, B06 |
| Art. 89-90 LGA | Ley 7557 | Clasificacion arancelaria y valoracion | B02, B03 |
| Art. 93-94 LGA | Ley 7557 | Verificacion y reconocimiento de mercancias | B07 |
| Art. 100-101 LGA | Ley 7557 | Levante de mercancias | B08 |
| Art. 104-105 LGA | Ley 7557 | Transito aduanero | C01 |
| Art. 106 LGA | Ley 7557 | Embarque y salida de mercancias | C02 |
| Art. 230-245 LGA | Ley 7557 | Regimen sancionatorio, infracciones y multas | D03 |
| Art. 11-14 CAUCA | Ley 8360 | Auxiliares de la funcion publica aduanera | A01 |
| Art. 46-50 CAUCA | Ley 8360 | Clasificacion y valoracion aduanera | B02, B03 |
| Art. 71 CAUCA | Ley 8360 | Garantias aduaneras | A02 |
| Art. 100-105 CAUCA | Ley 8360 | Infracciones aduaneras | D03 |
| Art. 9 Ley 8454 | Ley 8454 | Valor juridico de la firma digital | B05 |
| Art. 245-252 RLGA | Decreto 25270 | Procedimiento de declaracion y despacho | B04, B06, B07 |
| Art. 253 RLGA | Decreto 25270 | Mandato aduanero, requisitos formales | B01 |
| Art. 260 RLGA | Decreto 25270 | Levante y retiro de mercancias | B08 |
| Art. 270-276 RLGA | Decreto 25270 | Transito y embarque | C01, C02 |
| Art. 280 RLGA | Decreto 25270 | Conservacion de documentos y registros | C03, D01 |
