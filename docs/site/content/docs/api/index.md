# API REST

AduaNext expone una API REST versionada bajo `/api/v1/*` para clientes Flutter Web, integraciones de terceros (sourcers, universidades), y operadores internos.

## Documentos

| Endpoint group | Documento | Estado |
|---------------|-----------|--------|
| Dispatches (DUAs) | [Dispatch API](dispatches.md) | PRODUCTION (VRTV-79) |
| Classifications | *(pending)* | Backend done (VRTV-44), REST pendiente |
| Companies (exportadores/importadores) | *(pending)* | Stub inline, real endpoint pendiente |

## Autenticacion

**Todas las requests requieren `Authorization: Bearer <jwt>` con tokens emitidos por Keycloak del realm `aduanext`.**

```http
POST /api/v1/dispatches/submit HTTP/1.1
Host: api.aduanext.cr
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
Content-Type: application/json
```

El middleware (VRTV-61) valida el JWT contra JWKS de Keycloak y extrae:

- `sub` → user id
- `email`
- `aduanext_tenant_ids` (custom claim)
- `aduanext_roles` (custom claim, per-tenant)

Vease [seguridad/rbac](../security/rbac.md) para el modelo de autorizacion completo.

## Tenant Isolation

Cada request opera en el contexto del tenant del JWT. No existe header `X-Tenant-Id` — el tenant se deriva del token. Postgres RLS (VRTV-62) garantiza que la base de datos rechaza queries cross-tenant incluso si el middleware falla.

## Rate Limiting

Por defecto: **10 requests por minuto por tenant** (no por IP — evita starvation en agencias con NAT compartido).

Headers de respuesta:
- `X-RateLimit-Remaining`: requests restantes en la ventana
- `Retry-After`: segundos a esperar cuando recibes 429

## Error Response Format

Todos los errores siguen el mismo shape:

```json
{
  "error": "pre_validation_failed",
  "code": "PRE_VALIDATION_FAILED",
  "message": "Declaration failed 3 pre-validation rules",
  "details": {
    "errors": [...],
    "warnings": [...]
  },
  "requestId": "req_abc123"
}
```

Codigos estables (12):
- `MISSING_TOKEN` (401)
- `INVALID_TOKEN` (401)
- `EXPIRED_TOKEN` (401)
- `INSUFFICIENT_ROLE` (403)
- `WRONG_TENANT` (403)
- `USER_DISABLED` (403)
- `PRE_VALIDATION_FAILED` (422)
- `ATENA_VALIDATION_FAILED` (422)
- `ATENA_AUTH_FAILED` (502)
- `SIGNING_FAILED` (500)
- `ATENA_SUBMISSION_FAILED` (502)
- `INTERNAL_ERROR` (500)

## API Versioning

`/api/v1/*` es la API actual. Cambios breaking incrementan la version mayor (`/api/v2/*`), no se modifican endpoints v1 existentes.

**Legacy shims:** `/api/dispatches/*` (sin version) retornan 501 — unica razon de su existencia es backwards-compat temporal. Se eliminan tras deploy de clientes en v1.
