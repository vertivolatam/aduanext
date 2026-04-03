# Validacion del Problema — Modelo Importer-Led

## Problema Central

> Las pymes y startups hard-tech que importan componentes especializados dependen completamente de agencias aduanales opacas que no explican sus costos, no dan visibilidad del proceso, y cobran tarifas desproporcionadas al servicio que proveen.

## Evidencia del Problema

### Fuente 1: Experiencia directa (Vertivo LATAM)

Extraido del Notion de Vertivo (`Logistica y Comercio Internacional`):

> *"Los codigos que componen el desglose suelen ser secreto comercial y la agencia aduanal no le explica al comprador o importador con lujo de detalles que significan."*

> *"Estos procesos NO son responsabilidad de nuestra empresa directamente, a menos que alguna agencia aduanal nos lo solicite."*

**Costo actual de Vertivo por importacion:**
- Luces LED desde Shenzhen, China: ~$1,200 USD/despacho (agencia aduanal)
- Sensores desde New York, EE.UU.: ~$400 USD/despacho (courier)
- Total anual estimado (6 importaciones): ~$7,200 USD

### Fuente 2: Marco regulatorio (Ley 7557)

- Art. 28: Solo un agente aduanero colegiado puede firmar DUAs
- Art. 33: El importador otorga mandato al agente. Puede sustituirlo en cualquier momento.
- **Implicacion:** El importador NO puede ser autonomo, pero SI puede elegir a su agente y controlar el proceso.

### Fuente 3: Transformacion digital forzada (ATENA 2025)

- ATENA reemplazo a TICA en Oct 2025 — transicion incompleta
- Las agencias estan luchando con el nuevo sistema
- No hay herramientas terceras integradas con ATENA
- **Oportunidad:** Quien se integre primero captura el mercado

### Fuente 4: Mercado de agentes freelance

- El examen DGA se aplica cada agosto
- 18 programas universitarios en 8 universidades producen ~2,000 graduados/ano
- Muchos no consiguen empleo en agencias grandes
- La caucion de $20K USD es la unica barrera real para operar como freelance

## Cinco Porques (5 Whys)

1. **Por que Vertivo paga $1,200/despacho?** Porque la agencia cobra por el servicio completo: clasificacion + DUA + transmision + monitoreo.
2. **Por que no puede hacer parte del trabajo ella misma?** Porque la ley exige un agente aduanero para firmar la DUA.
3. **Por que no contrata solo un firmante?** Porque no existe una plataforma que separe la preparacion de la firma.
4. **Por que no existe esa plataforma?** Porque TICA (sistema anterior) era cerrado. ATENA apenas se lanzo y nadie ha construido integraciones terceras.
5. **Por que nadie ha construido integraciones?** Porque la documentacion de ATENA recien se publico (Feb 2025) y requiere conocimiento especializado de firma digital + Keycloak SSO.

**Root cause:** La barrera tecnica de integrarse con ATENA ha protegido el monopolio de las agencias. AduaNext rompe esa barrera.

## Hipotesis del Problema

> "Las pymes importadoras en Costa Rica pagarian un 60% menos por despacho si pudieran preparar sus propias DUAs y contratar un agente freelance solo para la firma y transmision."

### Metricas de validacion

| Metrica | Criterio de exito | Estado |
|---------|-------------------|--------|
| Costo actual vs. propuesto | Ahorro >50% por despacho | Pendiente (estimar con datos reales) |
| Disposicion a pagar | 5+ pymes confirman que pagarian $120/mes + $5/DUA | Pendiente |
| Disponibilidad de agentes freelance | 3+ agentes disponibles en GAM para firmar | Pendiente |
| Vertivo completa importacion real con modelo | 1 importacion exitosa desde Shenzhen | Pendiente |

## Segmento Early Adopter

**Pymes hard-tech en la GAM (Gran Area Metropolitana) que importan componentes especializados desde Asia o EE.UU.**

Caracteristicas:
- Facturan $50K-500K USD/ano
- Importan 4-12 veces al ano
- El costo de importacion es un % significativo de su COGS
- Son tech-savvy (fundadores ingenieros)
- Estan frustradas con la opacidad de la agencia actual
- Se recomiendan entre si (comunidad startup CR es pequena)

Ejemplos ademas de Vertivo:
- Startups de IoT/agtech importando sensores
- Empresas de iluminacion LED importando desde Shenzhen
- Fabricantes de drones importando partes desde EE.UU.
- Emprendimientos de e-commerce importando productos de Alibaba
