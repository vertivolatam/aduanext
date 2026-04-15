# Keycloak realm — `aduanext`

This directory holds the Keycloak realm export that the `keycloak`
service in `docker-compose.yaml` imports on first boot, plus the
documentation for the custom claim mapper that
`KeycloakAuthorizationAdapterFactory` (libs/adapters) depends on.

## Realm settings

| Setting                  | Value                                              |
|--------------------------|----------------------------------------------------|
| Realm                    | `aduanext`                                         |
| Access token lifespan    | 1 hour (tunable per tenant plan — see notes)       |
| Refresh token lifespan   | 8 hours                                            |
| Signature algorithm      | RS256                                              |
| Token type issued        | `access` (backend APIs MUST NOT trust `id_token`)  |
| Issuer claim             | `https://keycloak.<env>.aduanext.cr/realms/aduanext` |

## Client: `aduanext-server`

- **Client type:** confidential (not public — requires a client secret
  for token exchange).
- **Authentication:** `client_id` + `client_secret`.
- **Valid Redirect URIs:** set per environment (dev:
  `http://localhost:8080/*`, prod: `https://app.aduanext.cr/*`).
- **Web Origins:** matches the above.
- **Service accounts:** disabled (we do not call Keycloak as a machine
  user from this client).

## Custom claim mappers

The `KeycloakAuthorizationAdapter` in `libs/adapters` requires the
following claims to be present in the access token. Each is produced
by a dedicated User Attribute → Token Claim mapper in the
`aduanext-server` client, with **Access Token** checked and **ID Token**
unchecked.

| Attribute on user          | Token claim                   | Type              |
|----------------------------|-------------------------------|-------------------|
| `aduanext_tenant_ids`      | `aduanext_tenant_ids`         | `JSON array of String` |
| `aduanext_roles`           | `aduanext_roles`              | `JSON object` (tenantId → array of role codes) |
| `aduanext_membership_since`| `aduanext_membership_since`   | `JSON object` (tenantId → ISO-8601) |
| `aduanext_membership_exp`  | `aduanext_membership_exp`     | `JSON object` (tenantId → ISO-8601) — optional per tenant |

Standard claims consumed:

| Claim  | Mapped to                     |
|--------|-------------------------------|
| `sub`  | `User.id`                     |
| `email`| `User.email`                  |
| `iss`  | Validated against expected issuer |
| `aud`  | Validated against `aduanext-server` |
| `exp`  | JWT expiry (RFC 7519)         |
| `iat`  | JWT issued-at                 |
| `nbf`  | JWT not-before (optional)     |

### Role codes

The `aduanext_roles` claim carries role codes exactly as defined in
`libs/domain/lib/src/authorization/role.dart`. Known codes:

- `fiscalizador`
- `importer`
- `agent`
- `supervisor`
- `admin`

Unknown codes are silently ignored as long as AT LEAST one known code
remains; a tenant mapping with zero recognised roles makes the adapter
throw `MalformedTokenException`.

### Example payload

```json
{
  "sub": "9f23-...-user",
  "email": "andrea@pyme.cr",
  "aduanext_tenant_ids": ["t-pyme-andrea", "t-agency-maria"],
  "aduanext_roles": {
    "t-pyme-andrea": ["importer"],
    "t-agency-maria": ["agent"]
  },
  "aduanext_membership_since": {
    "t-pyme-andrea": "2026-01-10T00:00:00Z",
    "t-agency-maria": "2026-03-01T00:00:00Z"
  },
  "aduanext_membership_exp": {
    "t-agency-maria": "2026-12-31T23:59:59Z"
  },
  "iss": "https://keycloak.aduanext.cr/realms/aduanext",
  "aud": "aduanext-server",
  "exp": 1713196800,
  "iat": 1713193200
}
```

## Provisioning

Users, tenants, and memberships are created via the Keycloak admin API
by the onboarding UI (VRTV-59). There is no self-service signup in the
MVP — an admin or an invited supervisor creates accounts.

## Production deployment

The `infrastructure/helm-charts/aduanext` umbrella chart pulls in
`bitnami/keycloak` as a subchart; see `values.yaml` for the realm import
configuration and ingress host (`keycloak.aduanext.local` in Minikube,
`keycloak.<env>.aduanext.cr` in managed clusters).

## Rotating signing keys

Keycloak rotates the RS256 signing key under the realm's **Keys**
section. The adapter's `JwksCache` honours rotation transparently:

1. When a JWT arrives with an unknown `kid`, the cache force-refetches
   the JWKS from the well-known endpoint
   (`/realms/aduanext/protocol/openid-connect/certs`).
2. During a brief JWKS outage, a grace period (default 30 min beyond
   the 15 min TTL) keeps the server serving requests signed with the
   last-known keys. Beyond grace, the adapter fails closed with
   `AuthenticationException(jwks-unavailable)`.
