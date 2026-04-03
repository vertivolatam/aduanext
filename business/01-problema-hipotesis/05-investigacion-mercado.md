# Investigacion de Mercado — AduaNext
## Software de Cumplimiento Aduanero para America Latina

> Fecha: 2026-04-03 | Fuentes: INEC, PROCOMER, COMEX, DGA, SIECA, Webb Fontaine, CGR, Tico Times, informes de mercado

---

## 1. Dimensionamiento del Mercado Costa Rica

### 1.1 Agencias Aduanales Registradas

| Dato | Valor | Fuente |
|------|-------|--------|
| Agencias aduanales registradas (personas juridicas) | ~150-200 | Estimacion basada en directorio DGA + Asociacion de Agentes de Aduana CR |
| Agentes aduaneros (personas fisicas) autorizados | ~400-500 activos | Registro del Servicio Nacional de Aduanas (hacienda.go.cr) |
| Agencias asociadas (AAACR) | ~80-100 | Asociacion de Agentes de Aduana de Costa Rica |

**Notas:**
- La DGA mantiene un registro publico de agentes aduaneros activos ante el Servicio Nacional de Aduanas. El Ministerio de Hacienda publica este listado periodicamente.
- Requisitos para ser agente: licenciatura universitaria en Administracion Aduanera (o areas afines), examen de competencia DGA, caucion de $20,000 USD (Circular DGA-CIR-0020-2025).
- La Ley 7557 (Ley General de Aduanas) Art. 28 establece que solo un agente aduanero autorizado puede firmar DUAs.
- Estimacion de ~200 agencias se valida por: directorios en linea listan ~120-180 agencias visibles, mas agencias pequenas no listadas.

### 1.2 Importadores y Exportadores Activos

| Dato | Valor | Fuente |
|------|-------|--------|
| Empresas exportadoras activas | ~2,490 | PROCOMER (dato referenciado en multiples publicaciones) |
| Productos exportados | 4,426 | PROCOMER 2024 |
| Mercados destino | 169 paises | PROCOMER 2024 |
| Exportaciones totales 2024 | $19,894 millones USD | COMEX / PROCOMER |
| Exportaciones totales 2025 | $22,855 millones USD (record historico) | COMEX enero 2026 |
| Importaciones totales 2024 | ~$31,352 millones USD | INEC |
| Top 100 importadores (CIF 2024) | $19,214 millones USD (50% concentrado en top 10) | INEC / Hacienda |
| Crecimiento exportaciones 2025 vs 2024 | +14% | COMEX |
| Empresas importadoras activas (estimacion) | ~3,500-4,500 | Basado en DUAs unicos / ratio empresa-declaracion |

**Calculo de importadores activos:**
- 2,308,337 DUAs de importacion en 2024 / promedio ~500-650 DUAs por importador frecuente = ~3,500-4,600 importadores unicos.
- SIECA y datos de la region estiman ~4,000 importadores/exportadores activos en CR (cifra usada en GTM de AduaNext).
- El 50% del valor importado se concentra en 10 empresas (multinacionales de zona franca: Intel, Baxter, Abbott, etc.).
- El segmento pyme importador/exportador (target de AduaNext) es ~2,000-3,000 empresas.

### 1.3 Declaraciones Aduaneras por Anio

| Anio | DUAs Exportacion | DUAs Importacion | Total DUAs |
|------|-----------------|-----------------|------------|
| 2023 | 381,369 | 2,204,632 | **2,586,001** |
| 2024 | 387,311 | 2,308,337 | **2,695,648** |
| 2025 (estimado +5%) | ~406,000 | ~2,424,000 | **~2,830,000** |

**Fuente:** INEC - Estadisticas de Comercio Exterior 2023 y 2024, basadas en DUAs del sistema TICA con estatus ORI/ORD (confirmados).

**Desglose relevante:**
- Crecimiento interanual DUAs: ~4.2% (2023-2024)
- Con la migracion a ATENA (iniciada Oct 2025 con modulo de exportacion), se espera que el volumen se mantenga o aumente.
- DUAs de exportacion incluyen DUCA-F (para destinos centroamericanos), que se transmiten automaticamente a SIECA despues del levante.

### 1.4 Costo Promedio de Agenciamiento Aduanal por Declaracion

| Concepto | Monto | Fuente |
|----------|-------|--------|
| Comision agenciamiento aduana (importacion) | Min $200 USD o 0.45% del CIF | Tarifario Grupo Alonso CR |
| Honorarios tipicos agencia mediana | $150-$350 USD por despacho | Cotizaciones de mercado |
| DUA de exportacion (tasa DGA) | $3 USD + impuestos (CORFOGA, Ley Caldera) | Manual Procedimientos ATENA Oct 2025 |
| DUCA-F (tasa SIECA) | $3 USD por DUCA-F | COMIECO, autorizado abril 2023 |
| Costo total promedio por despacho importacion (agencia + impuestos tramite) | $250-$500 USD | Estimacion basada en cotizaciones |
| Costo total promedio por despacho exportacion | $80-$200 USD | Estimacion basada en cotizaciones |

**Observaciones:**
- Las agencias grandes (SICSA, Samesa, GSR, Selconsa) cobran tarifas premium ($400-800/despacho para importaciones complejas).
- Los agentes freelance cobran menos ($100-250/despacho) pero con menor infraestructura tecnologica.
- El margen de oportunidad para AduaNext es reducir costos de gestion interna del agente/agencia, no reemplazar su rol (la ley lo impide).

---

## 2. Competidores

### 2.1 Integracion con ATENA

| Plataforma | Integra con ATENA? | Estado |
|------------|-------------------|--------|
| **Webb Fontaine / ATENA nativo** | Es el sistema mismo | ATENA ES Webb Fontaine (contrato $23.47M con consorcio PBS/WF) |
| **TICA (legacy)** | Era el sistema anterior | En proceso de reemplazo por ATENA |
| **AduaNext (en desarrollo)** | Objetivo primario | Integracion via API REST documentada (DUA + RIMM) |
| **CargoWise** | No | No tiene integracion con sistemas CR |
| **Descartes** | No | Enfocado en US/Canada/Mexico/EU |
| **Magaya** | No | Enfocado en US customs (ABI/ACE), expansion a Mexico |
| **Aduanasoft** | No | Enfocado exclusivamente en Mexico (SAT/pedimentos) |
| **SIGA** | No (es sistema de Rep. Dominicana) | Solo Republica Dominicana |

**Hallazgo critico:** Al 3 de abril de 2026, NO existe ninguna plataforma SaaS de terceros que se integre con ATENA. El ecosistema de ATENA esta completamente cerrado al consorcio PBS/Webb Fontaine. Los agentes aduaneros usan la interfaz web nativa de ATENA directamente, sin middleware ni herramientas de productividad de terceros.

### 2.2 Software Aduanero en Centroamerica

| Plataforma | Pais/Region | Tipo | Relevancia para AduaNext |
|-----------|------------|------|--------------------------|
| **ATENA** (Webb Fontaine) | Costa Rica | Sistema gubernamental | Es el sistema con el que AduaNext se integra |
| **ASYCUDA World** (UNCTAD) | ~100 paises, varios en CA | Sistema gubernamental | Estandar en muchos paises en desarrollo; potencial integracion futura |
| **SAT/VUPE Guatemala** | Guatemala | Sistema gubernamental | Mejor documentacion DUCA-F de la region |
| **SARAH Honduras** | Honduras | Sistema gubernamental | Aduana hondurena |
| **Aduanasoft** | Mexico | SaaS privado | Competidor indirecto; solo Mexico, desde 1996 |
| **Magaya** | US/LATAM | SaaS privado | Expansion a Mexico via alianza con Tsol; enfoque en freight forwarders |
| **CargoWise (WiseTech)** | Global | ERP logistico | Para grandes operadores; no atiende pymes ni agentes individuales |
| **Descartes** | US/Canada/EU | SaaS privado | Lider en compliance para US customs; sin presencia en CA |
| **OP CBS (SLAM)** | Mexico | SaaS privado | Software de gestion aduanal mexicano |
| **Bytemaster** | Espana | SaaS privado | Gestion aduanera digital, mercado europeo |
| **Xindus** | Global | Plataforma comercio | Marketplace para pymes; complementario, no competidor |

### 2.3 Startups Disrupting Customs Brokerage en LATAM

| Startup | Pais | Que hace | Estado |
|---------|------|----------|--------|
| **Aduanasoft** | Mexico | Plataforma integral de gestion aduanal (pedimentos, clasificacion, compliance) | Establecida (1996), no es startup |
| **OP CBS** | Mexico | Modulos SLAM para trafico aduanal y supply chain | Establecida, enfoque Mexico |
| **Boxful** | El Salvador | Logistica last-mile y fulfillment para e-commerce | Startup, pero no es customs compliance |
| **TagShelf** | Republica Dominicana | AI para procesamiento de documentos (facturas, documentos legales) | Startup, potencialmente aplicable a customs docs |
| **CustomsCity** | Global | Plataforma de customs clearance con AI | Emergente, enfoque global |
| **VAO** | Global | Top 10 customs clearance solutions | Enfoque en grandes operadores |

**Hallazgo:** No existe ninguna startup enfocada especificamente en customs compliance para Centroamerica. El nicho esta completamente vacio. AduaNext seria first-mover en este espacio.

---

## 3. Webb Fontaine — Analisis Detallado

### 3.1 Perfil de la Empresa

| Dato | Valor |
|------|-------|
| Fundacion | 2002 |
| Sede | Dubai, EAU (Office 712, Concord Tower Media City) |
| Presencia | Europa, Medio Oriente, Asia, Africa, America Latina |
| Referencias gubernamentales | 25+ en 4 continentes |
| Empleados | ~500-1,000 (estimacion basada en LinkedIn) |
| Producto estrella | TradeWorldManager (TWM) — sistema de automatizacion aduanera |
| Reconocimiento | Miembro del Private Sector Consultative Group (PSCG) de la WCO |

### 3.2 Paises con Implementaciones Confirmadas

| Region | Paises | Producto |
|--------|--------|----------|
| **America Latina** | **Panama** (Single Window - PORTCEL), **Costa Rica** (ATENA - Customs) | Webb Single Window, Webb Customs |
| **Africa Occidental** | Nigeria, Guinea, Benin, Costa de Marfil, Congo | Webb Customs, Webb Ports, Webb Single Window |
| **Africa Oriental** | Etiopia | Webb Customs |
| **Medio Oriente** | Bahrain, EAU | Webb Customs, Webb Single Window |
| **Asia** | Bangladesh, Filipinas, Nepal | Webb Single Window, Webb Customs, Webb Inspection |
| **Norte de Africa** | Egipto, Libia | Webb ACI, Webb Customs |

### 3.3 Ofrecen SaaS para Agentes Aduaneros?

**Respuesta: No directamente, pero si indirectamente.**

Webb Fontaine vende exclusivamente a gobiernos (B2G). Su modelo de negocio:
1. **Contrato con el gobierno** para implementar el sistema aduanero nacional (como ATENA en CR).
2. **Trade Point Manager**: Portal web incluido en el sistema para que traders, customs brokers, carriers y freight forwarders hagan sus declaraciones en linea.
3. **NO ofrecen un SaaS independiente** para agentes aduaneros. Los agentes usan la interfaz web del sistema gubernamental directamente.

**Implicacion para AduaNext:** Webb Fontaine no es un competidor directo. Ellos construyen la infraestructura gubernamental; AduaNext construye herramientas de productividad para los USUARIOS de esa infraestructura. Es la diferencia entre construir una carretera (Webb Fontaine) vs. construir los autos que circulan por ella (AduaNext).

### 3.4 ATENA en Crisis — Oportunidad para AduaNext

Segun The Tico Times (15 feb 2026) y CRHoy:
- **Auditoria de la CGR** iniciada por denuncia ciudadana el 23 de diciembre de 2025.
- **Sindicato Sindhac** pidio intervencion de la Contraloria el 27 de noviembre de 2025.
- **Problemas detectados:**
  - Perfiles de usuario con seguridad deficiente
  - Matriz de roles incompleta (no alineada con TICA existente)
  - Pruebas piloto incompletas con codigo sin terminar
  - Migracion parcial de datos desde TICA
  - Errores en carga de aranceles
  - Pruebas de interoperabilidad pendientes
- **Valor del contrato:** $23,471,680.95 USD (consorcio PBS CR + Webb Fontaine, firmado 4 oct 2023)
- **Estado actual:** Modulo de exportaciones desplegado parcialmente desde Oct 2025 (inicio Puerto Caldera). Modulos de importacion y transito para 2026.

**Oportunidad:** La inestabilidad de ATENA crea demanda de herramientas que pre-validen datos ANTES de enviarlos al sistema. AduaNext como "capa de seguridad" entre el usuario y ATENA reduce riesgos de errores y rechazos.

---

## 4. TAM / SAM / SOM para AduaNext

### 4.1 TAM — Total Addressable Market (Todo el software aduanero en LATAM)

| Metrica | Valor | Fuente |
|---------|-------|--------|
| Mercado global de customs software 2024 | $1,465-1,920 millones USD | Valuates Reports / Growth Market Reports |
| CAGR global 2025-2031 | 8.5-11.3% | Multiples informes |
| Mercado LATAM customs compliance software 2024 | **$320 millones USD** | Growth Market Reports |
| Mercado LATAM proyectado 2026 | ~$370-400 millones USD | Estimacion con CAGR regional ~10% |
| Proyeccion LATAM 2031 | ~$600-700 millones USD | Estimacion con CAGR |

**TAM de AduaNext = $320-400M USD** (todo el software de compliance aduanero en LATAM).

### 4.2 SAM — Serviceable Available Market (Costa Rica + Centroamerica)

**Costa Rica:**

| Componente | Calculo | Valor anual |
|-----------|---------|-------------|
| Agencias aduanales (150-200) x licencia SaaS ($800-1,200/mes) | 175 x $1,000 x 12 | **$2.1M** |
| Agentes freelance (400-500) x licencia ($30-80/mes) | 450 x $55 x 12 | **$297K** |
| Pymes importadoras/exportadoras (3,000) x suscripcion ($50-150/mes) | 3,000 x $100 x 12 | **$3.6M** |
| Revenue transaccional: 2.8M DUAs x ~$2-5/DUA (asistencia) | 2,800,000 x $3 | **$8.4M** |
| Universidades (8 programas) x licencia ($5K-15K/semestre) | 8 x $10K x 2 | **$160K** |
| **Total Costa Rica** | | **~$14.6M/anio** |

**Centroamerica (6 paises SICA: GT, SV, HN, NI, PA + CR):**

| Pais | Multiplicador vs CR (por volumen comercio) | SAM estimado |
|------|-------------------------------------------|-------------|
| Costa Rica | 1.0x | $14.6M |
| Guatemala | 1.5x (mayor economia CA) | $21.9M |
| Panama | 1.2x (hub logistico) | $17.5M |
| Honduras | 0.7x | $10.2M |
| El Salvador | 0.6x | $8.8M |
| Nicaragua | 0.4x | $5.8M |
| **Total Centroamerica** | | **~$78.8M/anio** |

**SAM de AduaNext = ~$80M USD/anio** (Costa Rica + Centroamerica, todos los segmentos).

### 4.3 SOM — Serviceable Obtainable Market (6 meses, solo Costa Rica)

Basado en las metas del SRD (Success Reality a Oct 2026):

| Segmento | Cuentas objetivo | ARPU/mes | MRR a 6 meses | ARR equivalente |
|----------|-----------------|----------|---------------|-----------------|
| Agencias standalone | 15 | $1,200 | $18,000 | $216,000 |
| Agentes freelance | 40 | $60 | $2,400 | $28,800 |
| Pymes importer-led | 120 | $120 | $14,400 | $172,800 |
| Revenue por despacho | 2,400 DUAs/mes | $5/DUA | $12,000 | $144,000 |
| Universidades | 4 | $800 | $3,200 | $38,400 |
| **Total SOM** | | | **$50,000 MRR** | **$600,000 ARR** |

**SOM de AduaNext = $600K ARR** (0.75% del SAM Costa Rica, 0.19% del TAM LATAM).

### 4.4 Resumen TAM/SAM/SOM

```
TAM: $320-400M USD    (Software de compliance aduanero en toda LATAM)
 |
 +-- SAM: ~$80M USD   (Costa Rica + Centroamerica, todos los segmentos)
      |
      +-- SOM: $600K   (Meta 6 meses: pymes + freelance + agencias piloto en CR)
```

**Ratio de penetracion SOM/SAM = 0.75%** — extremadamente conservador y alcanzable.

---

## 5. Datos Clave por Fuente

### PROCOMER
- 2,490 empresas exportadoras activas
- 4,426 productos exportados a 169 destinos
- Exportaciones 2024: $19,894M USD (+9%)
- Exportaciones 2025: $22,855M USD (+14%, record historico)
- Q1 2025: $5,186M USD (+12% vs Q1 2024)
- 55 nuevos proyectos IED en 2025

**Fuentes:**
- [PROCOMER - Exportaciones 2024](https://procomer.com/costa-rica-cierra-el-2024-con-un-crecimiento-de-9-en-las-exportaciones-de-bienes/)
- [COMEX - Records 2025](https://www.comex.go.cr/sala-de-prensa/comunicados/2026/enero/cp-3198-costa-rica-alcanza-r%C3%A9cords-en-exportaciones-de-bienes-e-inversi%C3%B3n-extranjera-fuera-de-la-gam-en-2025/)

### INEC
- DUAs exportacion 2024: 387,311
- DUAs importacion 2024: 2,308,337
- Total DUAs 2024: 2,695,648
- Importaciones 2024: $28,407M USD (Valor FOB) / ~$31,352M (CIF)
- Crecimiento importaciones 2024: +8%

**Fuentes:**
- [INEC - Comercio Exterior 2024](https://sistemas.inec.cr/nada5.4/index.php/catalog/375)
- [INEC - Valor importaciones y exportaciones 2024](https://inec.cr/noticias/valor-importaciones-exportaciones-costa-rica-crecio-2024)

### DGA / Ministerio de Hacienda
- Sistema ATENA: Reemplaza TICA, basado en microservicios + REST APIs
- Modelo de datos WCO v4.1
- Autenticacion: OpenID Connect + JWT + Firma Digital
- Contrato ATENA: $23.47M USD (PBS CR + Webb Fontaine, Oct 2023)
- Auditoria CGR en curso desde dic 2025

**Fuentes:**
- [ATENA DUA Guia Tecnica](https://www.hacienda.go.cr/docs/SIAA-ATENA-DUA-GUIA-TECNICA.pdf)
- [BLP Legal - ATENA Modernization](https://blplegal.com/atena-system-a-step-forward-in-costa-ricas-customs-modernization/)
- [Tico Times - Hidden Flaws in ATENA](https://ticotimes.net/2026/02/15/hidden-flaws-in-costa-ricas-customs-overhaul-leads-to-audit)

### SIECA
- DUCA-F costo: $3 USD por declaracion
- Plataforma PDCC: Liferay + Keycloak SSO, AWS ca-central-1
- Portales operativos (cr.ducaf.sieca.int etc.) restringidos por IP (403)
- DUCA-F CR->PA electronica habilitada desde Feb 2025

**Fuentes:**
- [SIECA DUCA-F Instructivos](https://www.sieca.int/wp-content/uploads/2025/02/manual-pasos-registro-DUCA-F-14022025.pdf)
- [SICA - DUCA](https://www.sica.int/iniciativas/duca)

### CRECEX
- Camara de Comercio Exterior de Costa Rica, fundada 1951
- Directorio de empresas de comercio exterior
- Sin datos publicos de numero de afiliados

**Fuente:**
- [CRECEX](https://crecex.com/)

### Mercado Global
- Customs software market global 2024: $1.5-1.9B USD
- LATAM 2024: $320M USD
- CAGR global: 8.5-11.3%
- AI-driven classification reduce errores hasta 80%

**Fuentes:**
- [Valuates Reports - Customs Software Market](https://reports.valuates.com/market-reports/QYRE-Auto-13K19861/global-customs-software)
- [Growth Market Reports - Customs Compliance Software 2033](https://growthmarketreports.com/report/customs-compliance-software-market)

### Webb Fontaine
- 25+ referencias gubernamentales en 4 continentes
- En LATAM: Panama (PORTCEL/Single Window, 2019) y Costa Rica (ATENA, 2023)
- Producto B2G exclusivamente; no ofrecen SaaS para agentes/brokers
- TRACIT Summit Rio de Janeiro abril 2026: presentando AI para customs LATAM

**Fuentes:**
- [Webb Fontaine - Costa Rica Expansion](https://webbfontaine.com/news/2023/webb-fontaine-expands-central-american-footprint-with-costa-rican-customs-project/)
- [Webb Fontaine - Panama Success Story](https://webbfontaine.com/success-stories-panama-single-window)
- [Webb Fontaine - TRACIT Summit LATAM](https://www.prnewswire.co.uk/news-releases/webb-fontaine-to-showcase-agentic-ai-solutions-for-latam-customs-at-tracit-summit-302732740.html)

---

## 6. Ventaja Competitiva de AduaNext

| Factor | AduaNext | Competencia |
|--------|----------|-------------|
| Integracion ATENA nativa | Si (APIs documentadas) | Nadie mas |
| Multi-hacienda (multi-pais) | Arquitectura desde dia 1 | No existe |
| Segmento pyme + freelance | Pricing accesible ($30-150/mes) | Competidores sirven solo agencias grandes |
| Sandbox educativo | Convenios universitarios | No existe |
| DUCA-F awareness | Preparacion automatica | No existe en software tercero |
| Firma Digital integrada | Reutiliza patron de hacienda-cr | Manual en competidores |
| AI clasificacion arancelaria | RIMM API + AI layer | Solo Webb Fontaine (B2G) |
| First mover Centroamerica | Si | Campo completamente vacio |

---

## 7. Riesgos Identificados

1. **ATENA inestable:** La auditoria de la CGR y problemas reportados podrian retrasar la disponibilidad del sandbox de desarrollo. Sin sandbox, no hay beta.
2. **Webb Fontaine como gatekeeper:** Si WF decide ofrecer un portal mejorado para agentes (poco probable dado su modelo B2G), podria cooptar el mercado.
3. **Regulatorio:** Un cambio en la Ley 7557 que restrinja integraciones de terceros con ATENA seria existencial.
4. **Concentracion de mercado:** El 50% del valor importado esta en 10 empresas grandes que tienen sistemas internos; el mercado real son las pymes.
5. **Adopcion tecnologica:** Muchos agentes aduaneros son tradicionalistas y podrian resistir herramientas nuevas.
6. **Caucion de $20K USD:** Barrera de entrada para agentes freelance; puede limitar el segmento 2.
