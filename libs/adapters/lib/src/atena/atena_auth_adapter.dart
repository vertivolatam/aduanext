/// Adapter: ATENA Auth — Implements [AuthProviderPort] via hacienda-sidecar gRPC.
///
/// Uses [HaciendaAuthClient] to authenticate with the Costa Rica Hacienda IDP
/// (Keycloak OIDC ROPC flow). The sidecar handles token caching and
/// auto-refresh transparently.
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'dart:developer' as developer;

import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';

import '../generated/hacienda.pbgrpc.dart';
import '../grpc/grpc_channel_manager.dart';

/// Implements [AuthProviderPort] by delegating to the hacienda-sidecar
/// [HaciendaAuthClient] gRPC service.
class AtenaAuthAdapter implements AuthProviderPort {
  final GrpcChannelManager _channelManager;
  final String? _defaultClientId;

  /// Stores the last-used credentials for token refresh.
  Credentials? _lastCredentials;

  /// Creates an adapter connected to the hacienda-sidecar.
  ///
  /// [channelManager] manages the gRPC channel lifecycle.
  /// [defaultClientId] is sent with requests if credentials don't specify one.
  AtenaAuthAdapter({
    required GrpcChannelManager channelManager,
    String? defaultClientId,
  })  : _channelManager = channelManager,
        _defaultClientId = defaultClientId;

  /// Returns a fresh gRPC stub backed by the current channel.
  ///
  /// Not cached — the channel lifecycle is managed externally and caching a
  /// stub risks leaking a closed channel reference across shutdown/terminate,
  /// which would surface cryptic gRPC errors instead of the clear [StateError]
  /// raised by [GrpcChannelManager].
  HaciendaAuthClient get _authClient =>
      HaciendaAuthClient(_channelManager.channel);

  @override
  Future<AuthToken> authenticate(Credentials credentials) async {
    try {
      final request = AuthenticateRequest(
        idType: credentials.idType,
        idNumber: credentials.idNumber,
        password: credentials.password,
        clientId: credentials.clientId ?? _defaultClientId,
      );

      final response = await _authClient.authenticate(request);

      if (!response.success) {
        throw AuthenticationException(
          response.message.isNotEmpty
              ? response.message
              : 'Authentication failed',
          vendorCode: response.errorCode.isNotEmpty ? response.errorCode : null,
        );
      }

      // After successful authenticate, fetch the actual token via getAccessToken.
      final tokenResponse = await _authClient.getAccessToken(
        GetAccessTokenRequest(
          clientId: credentials.clientId ?? _defaultClientId,
        ),
      );

      // Guard against an "authenticated" response that carries no usable
      // token — mirror the refreshToken() contract so a missing token is
      // surfaced as AuthenticationException and _lastCredentials is NOT
      // assigned (otherwise subsequent refresh/isAuthenticated/invalidate
      // calls would operate on unverified state).
      if (tokenResponse.token.isEmpty) {
        throw const AuthenticationException(
          'Authentication succeeded but sidecar returned an empty access '
          'token. Refusing to cache credentials.',
        );
      }

      // Store credentials only after successful authentication AND a valid
      // token has been obtained, so refreshToken/isAuthenticated/invalidate
      // only rely on verified state.
      _lastCredentials = credentials;

      return AuthToken(
        accessToken: tokenResponse.token,
        tokenType: tokenResponse.tokenType.isNotEmpty
            ? tokenResponse.tokenType
            : 'Bearer',
        expiresInSeconds: tokenResponse.expiresInSeconds.toInt(),
        issuedAt: DateTime.now(),
      );
    } on GrpcError catch (e) {
      throw AuthenticationException(
        e.message ?? 'gRPC communication error',
        vendorCode: e.codeName,
      );
    }
  }

  @override
  Future<AuthToken> refreshToken() async {
    try {
      // The sidecar auto-refreshes tokens 30s before expiry.
      // We call getAccessToken which returns the cached/refreshed token.
      final clientId = _lastCredentials?.clientId ?? _defaultClientId;

      final response = await _authClient.getAccessToken(
        GetAccessTokenRequest(clientId: clientId),
      );

      if (response.token.isEmpty) {
        throw const AuthenticationException(
          'No active session to refresh. Call authenticate() first.',
        );
      }

      return AuthToken(
        accessToken: response.token,
        tokenType: response.tokenType.isNotEmpty
            ? response.tokenType
            : 'Bearer',
        expiresInSeconds: response.expiresInSeconds.toInt(),
        issuedAt: DateTime.now(),
      );
    } on GrpcError catch (e) {
      throw AuthenticationException(
        e.message ?? 'gRPC communication error during token refresh',
        vendorCode: e.codeName,
      );
    }
  }

  @override
  Future<bool> get isAuthenticated async {
    try {
      final clientId = _lastCredentials?.clientId ?? _defaultClientId;

      final response = await _authClient.isAuthenticated(
        IsAuthenticatedRequest(clientId: clientId),
      );

      return response.authenticated;
    } on GrpcError catch (e, stackTrace) {
      // Connectivity or session failures are treated as "not authenticated"
      // but logged for observability so operators can diagnose sidecar
      // reachability issues in production.
      developer.log(
        'isAuthenticated check failed via hacienda-sidecar gRPC: '
        '${e.message ?? e.toString()} (code: ${e.codeName})',
        name: 'AtenaAuthAdapter',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> invalidate() async {
    try {
      final clientId = _lastCredentials?.clientId ?? _defaultClientId;

      await _authClient.invalidate(
        InvalidateRequest(clientId: clientId),
      );

      _lastCredentials = null;
    } on GrpcError catch (e) {
      throw AuthenticationException(
        e.message ?? 'gRPC communication error during session invalidation',
        vendorCode: e.codeName,
      );
    }
  }
}
