/// Keycloak-backed [AuthorizationPort] adapter.
///
/// Responsibilities:
/// 1. Validate the JWT signature via Keycloak's JWKS endpoint (RS256).
/// 2. Enforce `exp` / `nbf` validity window.
/// 3. Enforce issuer + audience (protects against cross-realm token reuse).
/// 4. Extract AduaNext-specific claims into a [User] via
///    [KeycloakClaimsMapper].
/// 5. Expose [AuthorizationPort] semantics identical to the in-memory
///    adapter so handlers never branch on provider.
///
/// This adapter is pure Dart — it does NOT import shelf or any HTTP
/// framework. The request framing (extracting the Bearer token and the
/// selected tenant from an incoming request) is done by the server-side
/// middleware shipping in VRTV-61. This adapter is instantiated
/// per-request with the already-extracted token + tenant hint.
library;

import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'jwks_cache.dart';
import 'keycloak_claims.dart';

/// Factory that, given a raw JWT + optional tenant hint, returns a
/// ready-to-use [AuthorizationPort] for the current request.
///
/// The factory is long-lived (it owns the [JwksCache]); the port it
/// returns is request-scoped.
class KeycloakAuthorizationAdapterFactory {
  final JwksCache _jwks;
  final String expectedIssuer;
  final String expectedAudience;
  final KeycloakClaimsMapper _mapper;
  final DateTime Function() _now;

  KeycloakAuthorizationAdapterFactory({
    required JwksCache jwksCache,
    required this.expectedIssuer,
    required this.expectedAudience,
    KeycloakClaimsMapper? mapper,
    DateTime Function()? now,
  })  : _jwks = jwksCache,
        _mapper = mapper ?? const KeycloakClaimsMapper(),
        _now = now ?? DateTime.now;

  /// Build an [AuthorizationPort] for a request that presented [bearerToken].
  ///
  /// * [bearerToken] — the raw JWT (no `Bearer ` prefix).
  /// * [selectedTenantId] — tenant the caller is acting against, usually
  ///   carried in a header like `X-Tenant-Id`. Can be `null` for endpoints
  ///   that do not need tenant context (e.g. `/me`).
  ///
  /// Throws [AuthenticationException] when the JWT is missing / expired /
  /// signed by an unknown key / has an unexpected issuer or audience.
  /// Throws [MalformedTokenException] when the signature is valid but the
  /// AduaNext-specific claims are missing or malformed.
  Future<AuthorizationPort> forRequest({
    required String? bearerToken,
    required String? selectedTenantId,
  }) async {
    if (bearerToken == null || bearerToken.trim().isEmpty) {
      // Deliberately NOT an AuthorizationException — the request is not
      // "denied for lack of role"; it is unauthenticated. Callers can
      // tell the two apart by the thrown type.
      throw const AuthenticationException(
        'Missing bearer token',
        vendorCode: 'missing-token',
      );
    }

    final kid = _readKid(bearerToken);
    final JwksKey? key;
    try {
      key = await _jwks.keyForKid(kid);
    } on JwksFetchException catch (e) {
      throw AuthenticationException(
        'JWKS unavailable: ${e.message}',
        vendorCode: 'jwks-unavailable',
      );
    }
    if (key == null) {
      throw AuthenticationException(
        'JWT signed by unknown key "$kid"',
        vendorCode: 'unknown-kid',
      );
    }

    final JWT jwt;
    try {
      jwt = JWT.verify(
        bearerToken,
        RSAPublicKey.raw(key.rsaPublicKey),
        issuer: expectedIssuer,
        audience: Audience.one(expectedAudience),
      );
    } on JWTExpiredException {
      throw const AuthenticationException(
        'JWT is expired',
        vendorCode: 'expired',
      );
    } on JWTNotActiveException {
      throw const AuthenticationException(
        'JWT is not yet active (nbf in the future)',
        vendorCode: 'not-active',
      );
    } on JWTInvalidException catch (e) {
      throw AuthenticationException(
        'JWT invalid: ${e.message}',
        vendorCode: 'invalid',
      );
    } on JWTException catch (e) {
      throw AuthenticationException(
        'JWT verification failed: ${e.message}',
        vendorCode: 'verify-failed',
      );
    }

    final payload = jwt.payload;
    final Map<String, dynamic> claims;
    if (payload is Map<String, dynamic>) {
      claims = payload;
    } else if (payload is Map) {
      claims = Map<String, dynamic>.from(payload);
    } else {
      throw const AuthenticationException(
        'JWT payload is not a JSON object',
        vendorCode: 'bad-payload',
      );
    }

    final user = _mapper.toUser(claims);
    return _KeycloakAuthorizationPort(
      user: user,
      selectedTenantId: selectedTenantId,
      now: _now,
    );
  }

  /// Parse the JWT header (first base64url segment) and extract the `kid`.
  static String _readKid(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const AuthenticationException(
        'JWT does not have three segments',
        vendorCode: 'malformed',
      );
    }
    try {
      final padded = parts[0].padRight(
        parts[0].length + ((4 - parts[0].length % 4) % 4),
        '=',
      );
      final raw = utf8.decode(base64Url.decode(padded));
      final header = jsonDecode(raw);
      if (header is! Map) {
        throw const AuthenticationException(
          'JWT header is not a JSON object',
          vendorCode: 'bad-header',
        );
      }
      final kid = header['kid'];
      if (kid is! String || kid.isEmpty) {
        throw const AuthenticationException(
          'JWT header is missing `kid`',
          vendorCode: 'missing-kid',
        );
      }
      return kid;
    } on AuthenticationException {
      rethrow;
    } catch (e) {
      throw AuthenticationException(
        'JWT header unreadable: $e',
        vendorCode: 'bad-header',
      );
    }
  }
}

/// Thin pass-through implementation of [AuthorizationPort] that mirrors
/// the in-memory adapter's semantics but is initialised from a
/// validated JWT.
class _KeycloakAuthorizationPort implements AuthorizationPort {
  final User _user;
  final String? _selectedTenantId;
  final DateTime Function() _now;

  _KeycloakAuthorizationPort({
    required User user,
    required String? selectedTenantId,
    required DateTime Function() now,
  })  : _user = user,
        _selectedTenantId = selectedTenantId,
        _now = now;

  @override
  User currentUser() => _user;

  @override
  String currentTenantId() {
    final t = _selectedTenantId;
    if (t == null || t.isEmpty) {
      throw const AuthorizationException(
        code: 'tenant-not-selected',
        message: 'No tenant has been selected for this request.',
      );
    }
    return t;
  }

  @override
  TenantMembership? currentMembership() {
    final t = _selectedTenantId;
    if (t == null) return null;
    for (final m in _user.memberships) {
      if (m.tenantId == t && m.isActiveAt(_now())) return m;
    }
    return null;
  }

  @override
  bool hasRole(Role role) {
    final m = currentMembership();
    return m != null && m.role.satisfies(role);
  }

  @override
  bool canActFor(String tenantId) {
    for (final m in _user.memberships) {
      if (m.tenantId == tenantId && m.isActiveAt(_now())) return true;
    }
    return false;
  }

  @override
  void requireRole(Role role) {
    currentTenantId(); // may throw tenant-not-selected
    if (!hasRole(role)) {
      throw AuthorizationException(
        code: 'role-denied',
        message:
            'Current user does not hold at least role "${role.code}" '
            'in tenant "${_selectedTenantId ?? ""}".',
        tenantId: _selectedTenantId,
        requiredRole: role,
      );
    }
  }

  @override
  void requireTenant(String tenantId) {
    if (!canActFor(tenantId)) {
      throw AuthorizationException(
        code: 'tenant-denied',
        message:
            'Current user is not an active member of tenant "$tenantId".',
        tenantId: tenantId,
      );
    }
  }
}
