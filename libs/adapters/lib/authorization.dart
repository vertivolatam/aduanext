/// Authorization adapters implementing [AuthorizationPort].
///
/// * [InMemoryAuthorizationAdapter] — for tests and local-dev runs.
/// * [KeycloakAuthorizationAdapterFactory] — production adapter that
///   validates Keycloak-issued JWTs (RS256) against a cached JWKS.
library;

export 'src/authorization/in_memory_authorization_adapter.dart';
export 'src/authorization/jwks_cache.dart'
    show JwksCache, JwksKey, JwksFetchException;
export 'src/authorization/keycloak_authorization_adapter.dart'
    show KeycloakAuthorizationAdapterFactory;
export 'src/authorization/keycloak_claims.dart'
    show KeycloakClaimsMapper, MalformedTokenException;
