/// Port: Auth Provider — abstracts authentication with any country's system.
///
/// Each country's customs authority has different auth:
///   - Costa Rica ATENA: OpenID Connect ROPC via Keycloak
///   - Guatemala SAT: OAuth2 + certificate (different flow)
///   - Honduras SARAH: Basic Auth + SOAP (legacy)
///
/// The domain never knows which auth mechanism is used.
library;

/// Credentials for authenticating with a customs authority.
class Credentials {
  final String idType;
  final String idNumber;
  final String password;
  final String? clientId;

  const Credentials({
    required this.idType,
    required this.idNumber,
    required this.password,
    this.clientId,
  });
}

/// Token returned by the auth provider.
class AuthToken {
  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;
  final String? refreshToken;
  final DateTime issuedAt;

  const AuthToken({
    required this.accessToken,
    this.tokenType = 'Bearer',
    required this.expiresInSeconds,
    this.refreshToken,
    required this.issuedAt,
  });

  bool get isExpired =>
      DateTime.now().isAfter(issuedAt.add(Duration(seconds: expiresInSeconds)));
}

/// Domain-level exception raised by [AuthProviderPort] implementations
/// when the customs authority rejects the authentication attempt, OR
/// when the adapter cannot complete the handshake (expired token,
/// transport error, etc.).
///
/// Kept in the domain — not in the adapter — so use cases in the
/// application layer can catch a single stable type without depending
/// on country-specific adapter packages. Adapters extend this class
/// with country-specific context (gRPC status code, HTTP status, IDP
/// vendor error code).
class AuthenticationException implements Exception {
  /// Human-readable message. Already translated from any underlying
  /// transport error by the adapter.
  final String message;

  /// Optional vendor / transport error code surfaced by the adapter
  /// (e.g. gRPC status name, IDP `INVALID_GRANT`).
  final String? vendorCode;

  const AuthenticationException(this.message, {this.vendorCode});

  @override
  String toString() => 'AuthenticationException: $message'
      '${vendorCode != null ? ' (vendor: $vendorCode)' : ''}';
}

/// Port: Auth Provider — country-agnostic authentication interface.
abstract class AuthProviderPort {
  /// Authenticate with the customs authority.
  ///
  /// Implementations MUST throw [AuthenticationException] when the
  /// authority rejects the credentials or when the transport fails in a
  /// way the caller should treat as "cannot authenticate right now".
  Future<AuthToken> authenticate(Credentials credentials);

  /// Refresh an existing token (if supported by the provider).
  ///
  /// Same error contract as [authenticate].
  Future<AuthToken> refreshToken();

  /// Check if there is a valid, non-expired session.
  Future<bool> get isAuthenticated;

  /// Invalidate the current session. Same error contract as
  /// [authenticate] on failure.
  Future<void> invalidate();
}
