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

/// Port: Auth Provider — country-agnostic authentication interface.
abstract class AuthProviderPort {
  /// Authenticate with the customs authority.
  Future<AuthToken> authenticate(Credentials credentials);

  /// Refresh an existing token (if supported by the provider).
  Future<AuthToken> refreshToken();

  /// Check if there is a valid, non-expired session.
  Future<bool> get isAuthenticated;

  /// Invalidate the current session.
  Future<void> invalidate();
}
