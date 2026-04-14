# AduaNext

**Tu importacion, tu control.**

Plataforma multi-hacienda de cumplimiento aduanero para LATAM. Integra directamente con [ATENA](https://www.hacienda.go.cr/) (Costa Rica) para preparar, firmar, transmitir y monitorear Declaraciones Unicas Aduaneras (DUAs) en tiempo real.

[![License: BSL 1.1](https://img.shields.io/badge/License-BSL%201.1-blue.svg)](LICENSE.md)
[![Linear](https://img.shields.io/badge/Linear-AduaNext-blue)](https://linear.app/vertivolatam/project/aduanext-9392981cd39d)
[![Dart CI](https://github.com/vertivolatam/aduanext/actions/workflows/dart-ci.yml/badge.svg?branch=main)](https://github.com/vertivolatam/aduanext/actions/workflows/dart-ci.yml)

## El Problema

Las pymes que importan componentes especializados dependen de agencias aduanales opacas que no explican sus costos, no dan visibilidad del proceso, y cobran tarifas desproporcionadas. En Costa Rica se procesan **2.7 millones de DUAs al ano** y **ninguna plataforma SaaS se integra con ATENA**.

## La Solucion

AduaNext permite a importadores preparar sus propias DUAs con transparencia total, contratar un agente aduanero freelance solo para firmar, y monitorear el estado en tiempo real via Telegram/WhatsApp.

### Tres modos de operacion

| Modo | Para quien | Como funciona |
|------|-----------|---------------|
| **Importer-Led** | Pymes/startups | La pyme prepara la DUA, invita un agente freelance como firmante autorizado |
| **Standalone SaaS** | Agencias aduanales | La agencia usa AduaNext como su plataforma principal |
| **Sidecar K8s** | Agencias grandes | AduaNext se inyecta como contenedor junto a sistemas existentes |

## Arquitectura

> Basada en [Explicit Architecture](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/) (DDD/Hexagonal/Clean/CQRS) por Herberto Graca.

```
Flutter Web (Dart) <-> Serverpod (Dart) <-gRPC-> hacienda-sidecar (TS) <-REST-> ATENA/RIMM
                             |                          |
                        PostgreSQL              hacienda-cr (npm)
                             |
                    agentic-core (Python) -- AI Classification + RAG
```

**3 sidecars, 3 lenguajes, un Pod:**
- **Serverpod** (Dart) — API principal, ORM, multi-tenant
- **hacienda-sidecar** (TypeScript) — Auth OIDC, Firma Digital XAdES-EPES, ATENA proxy
- **agentic-core** (Python) — Clasificacion arancelaria con AI (RAG sobre RIMM)

### Estructura del Monorepo

```
aduanext/
├── apps/
│   ├── server/                    # Serverpod backend
│   ├── hacienda-sidecar/          # TypeScript gRPC sidecar
│   ├── mobile/                    # Flutter app (web + mobile)
│   └── widgetbook/                # Widget catalog
├── libs/
│   ├── domain/                    # DOMAIN LAYER (pure Dart, zero I/O)
│   │   ├── entities/              # Declaration, Item, Sourcer
│   │   ├── value_objects/         # HsCode, Incoterm, DeclarationStatus
│   │   ├── ports/                 # 6 interfaces (CustomsGateway, Auth, Signing...)
│   │   └── services/              # RiskScoring, TaxCalculator
│   ├── application/               # APPLICATION LAYER (use cases, CQRS)
│   ├── adapters/                  # SECONDARY ADAPTERS (ATENA, RIMM, signing)
│   └── proto/                     # Shared gRPC definitions (hacienda.proto)
├── srd/                           # Synthetic Reality Development framework
├── business/                      # Business model (21 phases)
├── spikes/                        # Technical spike briefs
├── issue-briefs/                  # Consolidated bilingual brief
├── docs/references/               # ATENA PDFs, DUCA transcripts, competitor manuals
├── infrastructure/                # Terraform, Helm, Docker
└── k8s/                           # Kubernetes manifests + ArgoCD
```

## Integraciones

| Sistema | Tipo | Endpoints | Status |
|---------|------|-----------|--------|
| ATENA (DUA API) | REST + OpenID Connect | 6 APIs (validate, liquidate, rectify, upload) | Documentado |
| RIMM (Tariff Catalog) | REST + OpenID Connect | 40+ endpoints (/commodity/search, /heading/search...) | Documentado |
| hacienda-cr SDK | npm dependency | Auth, XAdES-EPES signing, HTTP client | Implementado |
| TRIBU-CR | Futuro | Facturacion electronica, D-270 | Planificado |
| VUCE 2.0 | Futuro | Notas tecnicas / permisos | Planificado |
| PDCC/SIECA | Via ATENA | DUCA-F transmision automatica post-levante | No requiere integracion directa |

## Quick Start

```bash
# Clonar
git clone git@github.com:vertivolatam/aduanext.git
cd aduanext

# Domain layer (Dart)
cd libs/domain && dart pub get && dart test

# Proto compilation (requiere protoc)
protoc --dart_out=grpc:apps/server/lib/src/generated \
       --ts_proto_out=apps/hacienda-sidecar/src/generated \
       libs/proto/hacienda.proto
```

## Local Development

AduaNext usa `docker-compose` + `Makefile` para orquestar infra local. Mismo patron que los repos hermanos (`vertivolatam/monorepo`, `altrupets/monorepo`) pero con puertos desplazados para evitar conflictos cuando se corren todos a la vez.

### Servicios y puertos

| Servicio | Puerto (host) | Proposito |
|----------|--------------|-----------|
| `postgres` (dev) | `8190` | PostgreSQL 16 + pgvector — datos de desarrollo |
| `redis` (dev) | `8191` | Redis 6.2 — cache de desarrollo |
| `postgres_test` | `9190` | PostgreSQL 16 + pgvector — tests de integracion (tmpfs, efimero) |
| `redis_test` | `9191` | Redis 6.2 — tests de integracion (tmpfs, efimero) |

> pgvector, no postgres plano: las clasificaciones arancelarias usan RAG sobre embeddings de RIMM.

### Setup

```bash
# 1. Copiar template de variables de entorno
cp .env.example .env
# Editar .env con passwords fuertes: openssl rand -base64 32

# 2. Levantar servicios
make db-up

# 3. Verificar que pgvector esta disponible
make db-verify-pgvector

# 4. Abrir shell psql
make db-psql
```

### Targets del Makefile

Corre `make help` para la lista completa. Los mas usados:

| Target | Descripcion |
|--------|-------------|
| `make db-up` | Levanta postgres + redis (dev + test) |
| `make db-down` | Detiene servicios (preserva volumenes) |
| `make db-reset` | Destructivo: detiene + borra volumenes + recrea |
| `make db-psql` | Abre psql al DB de desarrollo |
| `make db-psql-test` | Abre psql al DB de test |
| `make test-dart` | Corre `dart test` en `libs/domain` + `libs/adapters` |

## K8s Local Cluster

Para pruebas mas cerca de produccion AduaNext usa Minikube + Helm umbrella chart que compone los subcharts de Bitnami (postgresql con `pgvector/pgvector:pg16` + redis).

### Requisitos

- `minikube` >= 1.38
- `kubectl` en el PATH
- `helm` >= 3.14
- Docker corriendo localmente (NO rootless — el Makefile fuerza `--rootless=false`)

### Setup

```bash
# 1. Levantar minikube (profile: aduanext, 4 CPU / 6GB RAM)
make minikube-up

# 2. Descargar dependencias del chart (bitnami/postgresql + redis)
make helm-deps

# 3. Lint del chart
make helm-lint

# 4. Instalar el release
make helm-install

# 5. Verificar
kubectl get pods -n aduanext
kubectl exec -n aduanext aduanext-postgresql-0 -- \
  env PGPASSWORD=changeme-aduanext psql -U aduanext -d aduanext \
  -c "SELECT extname, extversion FROM pg_extension WHERE extname='vector';"
# -> vector | 0.8.2
```

### Estructura

```
infrastructure/
|-- docker/                      # Placeholder Dockerfiles (server, web)
|-- k8s/base/                    # Base ConfigMap + Secret template
`-- helm-charts/aduanext/        # Umbrella chart
    |-- Chart.yaml               # Deps: bitnami/postgresql + redis
    |-- values.yaml              # Defaults (Minikube dev profile)
    `-- templates/               # server + web + configmap
```

Los Deployments `aduanext-server` y `aduanext-web` estan deshabilitados por defecto (`.enabled: false`) — las imagenes apuntan a `harbor.aduanext.local` que se provisiona en VRTV-58. Se activan cuando Harbor tiene las imagenes reales.

## Documentacion

| Documento | Descripcion |
|-----------|-------------|
| [SRD Framework](srd/SRD.md) | Personas, jornadas, gap audit, directiva Claude |
| [Business Model](business/README.md) | 21 fases del modelo de negocio (Importer-Led) |
| [Architecture Diagrams](architecture-diagrams.md) | 8 diagramas Mermaid |
| [Spike Brief](issue-briefs/ADX-SPIKE-001.md) | Brief bilingue consolidado |
| [ATENA DUA Guide](docs/references/SIAA-ATENA-DUA-GUIA-TECNICA.pdf) | 104 paginas, APIs reales |
| [RIMM Spec](docs/references/SIAA-ATENA-Especificacion-Tecnica-RIMM-Arancel.pdf) | 40+ endpoints |

## Licencia

[Business Source License 1.1](LICENSE.md) — Uso en produccion permitido excepto para competir con la version comercial. Convierte a Non-Profit OSL 3.0 despues de 5 anos.

(c) 2025 Luis Andres Pena Castillo
