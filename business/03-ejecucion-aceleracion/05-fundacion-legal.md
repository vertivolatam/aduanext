# Fundación Legal (Legal Foundation) — AduaNext

## Entidad Legal

| Aspecto | Estado | Acción |
|---------|--------|--------|
| Constituida? | NO — opera bajo persona física del fundador | Constituir SRL o SA antes de M4 |
| Jurisdicción | Costa Rica (Heredia) | Registro en RNPJ + DGT + CCSS |
| Tipo recomendado | SRL (Sociedad de Responsabilidad Limitada) | Más simple que SA, suficiente para SaaS |
| Cédula jurídica | Pendiente | Trámite ~2-4 semanas |
| Patente municipal | Requerida en Heredia | Licencia comercial + uso de suelo |

## Cofundadores

| Aspecto | Estado |
|---------|--------|
| Cofundadores? | NO — fundador único (Andrés Peña) |
| Equity split | 100% fundador |
| Vesting | N/A (fundador único) |
| SAFE/convertible notes | No emitidos. Considerar para pre-seed cuando haya traction. |

## Propiedad Intelectual

| IP | Protección | Estado |
|----|-----------|--------|
| Código fuente AduaNext | BSL 1.1 (Business Source License) | Implementado en repo |
| Código fuente hacienda-cr | MIT (open source) | Dependencia npm, no fork |
| Marca "AduaNext" | Registro de marca CR | Pendiente (RNPI) |
| Dominio aduanext.com | Registro de dominio | Pendiente |
| Documentación ATENA/RIMM | Documentos públicos del gobierno | No requiere protección |

## Acuerdos Legales Necesarios

| Acuerdo | Para quién | Estado | Prioridad |
|---------|-----------|--------|-----------|
| Términos de Servicio (ToS) | Usuarios de la plataforma | Pendiente | M4 |
| Política de Privacidad | Usuarios (LGPD CR / Ley 8968) | Pendiente | M4 |
| Contrato de mandato (Art. 33 Ley 7557) | Pyme ↔ Agente freelance | Template pendiente | M3 |
| NDA (Acuerdo de Confidencialidad) | Agentes freelance (datos de pymes) | Pendiente | M3 |
| FAST (Founder Advisor Standard Template) | Futuros advisors | No necesario aún | M6+ |
| Data Processing Agreement (DPA) | Para compliance Ley 8968 | Pendiente | M4 |

## Cumplimiento Regulatorio Específico

### Como plataforma tecnológica (AduaNext NO es agencia aduanal):

| Regulación | Aplica? | Notas |
|-----------|---------|-------|
| Ley 7557 (Ley General de Aduanas) | Indirecto | AduaNext no es auxiliar de función pública. Los agentes freelance sí. |
| Caución de $20K USD | NO | La caución la rinde el agente freelance, no la plataforma |
| Registro ante DGA | NO | AduaNext es herramienta tecnológica, no agente aduanero |
| Colegiatura CCECR | NO | Solo aplica a personas físicas que firman DUAs |
| Ley 8968 (Protección de Datos) | SI | Procesamos datos de importadores + exportadores |
| TRIBU-CR (obligaciones fiscales) | SI | D-270 mensual, IVA, renta |
| Firma Digital (BCCR) | Indirecto | Los agentes usan su propia firma. AduaNext solo la transmite vía gRPC. |
| Facturación electrónica (hacienda-cr) | SI | Para cobrar suscripciones a pymes y agentes |

### Riesgo legal principal:

> AduaNext **no asume responsabilidad** por errores en clasificación arancelaria o transmisión de DUAs. La responsabilidad legal recae en el agente aduanero que firma (Art. 28, Ley 7557). AduaNext provee herramientas de pre-validación pero el human-in-the-loop del agente es la barrera legal.

El ToS debe incluir cláusula explícita:
> "AduaNext es una herramienta tecnológica de asistencia. No sustituye el juicio profesional del agente aduanero. La persona declarante asume responsabilidad plena por la información consignada en la DUA."

## Gate 3: Base financiera y legal sólida?

| Criterio | Status |
|----------|--------|
| Economía unitaria viable (LTV > 3x CAC)? | SI — LTV:CAC = 18.7:1 |
| Modelo financiero con camino a rentabilidad? | SI — breakeven M4, $851 déficit total |
| Marca e identidad definidas? | PARCIAL — nombre y posicionamiento sí, visual pendiente |
| Fundación legal establecida? | NO — SRL pendiente de constituir |
| Acuerdos legales redactados? | NO — ToS, privacidad, mandato pendientes |

**Gate 3: CONDICIONALMENTE APROBADO** — Los números son sólidos. La constitución legal y acuerdos son tareas paralelas que no bloquean el desarrollo técnico del MVP. Deben completarse antes de M4 (primer cobro a clientes).
