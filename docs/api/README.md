# AduaNext — API Reference (Stoplight Elements)

Visor interactivo de la especificación OpenAPI de AduaNext, renderizado con
[Stoplight Elements](https://docs.stoplight.io/docs/elements/d6a8ba3f3c186-stoplight-elements).

## Ver localmente

Desde la raíz del repo, levanta un servidor estático sobre `docs/api/`:

```bash
# Opción A — Python
python3 -m http.server -d docs/api 8080

# Opción B — Node (sin instalación si ya tienes npx)
npx serve docs/api
```

Luego abre `http://localhost:8080/` (o la URL que imprima `serve`).

## Archivos

- `index.html` — Página de entrada. Carga Stoplight Elements desde unpkg (CDN,
  sin dependencias npm) y apunta a `./openapi.yaml`.
- `openapi.yaml` — **Placeholder** OpenAPI 3.1 con un único endpoint `/health`.
  Reemplazar cuando aterricen los primeros endpoints REST de DUA export
  (VRTV-38 y siguientes) en `apps/server`.
- `README.md` — Este archivo.

## Regeneración del spec (futuro)

AduaNext tiene dos fuentes potenciales para el OpenAPI real:

1. **apps/server (shelf, Dart):** los handlers CQRS en `libs/application/` se
   expondrán vía endpoints REST en `apps/server`. El spec debería generarse
   desde ahí — idealmente con un plugin OpenAPI del server o un script de
   introspección sobre los `CommandHandler` / query handlers.
2. **libs/proto/hacienda.proto (gRPC):** los 4 servicios gRPC
   (`HaciendaAuth`, `HaciendaSigner`, `HaciendaApi`, `HaciendaOrchestrator`)
   pueden exportarse a OpenAPI con `buf` + `protoc-gen-openapi`, si en algún
   momento se quiere documentar el contrato gRPC ↔ REST del sidecar
   hacienda-cr.

La ruta recomendada es (1) para la API pública de AduaNext, manteniendo (2)
como spec separado (o fusionado) si el sidecar llega a exponerse al exterior.

## Publicación online (opcional, futuro)

`docs/api/` es una página estática autocontenida; se puede publicar como
artefacto adicional de GitHub Pages, independiente del sitio MkDocs que vive
en `docs/site/`. Si se quiere enlazar desde el sitio MkDocs, agregar una
entrada a `docs/site/mkdocs.yml` bajo la sección `nav.API:` — fuera del
alcance de esta integración inicial.

## Referencias

- Docs oficiales de Stoplight Elements: <https://docs.stoplight.io/docs/elements/d6a8ba3f3c186-stoplight-elements>
- Repositorio: <https://github.com/stoplightio/elements>
