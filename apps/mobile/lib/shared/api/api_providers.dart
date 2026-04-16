/// Riverpod wiring for the API layer.
///
/// Three providers:
///
///   1. [apiConfigProvider] — reads from Dart build-time env
///      (overridable in tests).
///   2. [bearerTokenProvider] — async bearer token supplier. Today
///      returns null (dev mode); VRTV-60/61 plug in real Keycloak.
///   3. [apiClientProvider] — chooses between [HttpApiClient] and
///      [FakeApiClient] based on `ApiConfig.useFake`.
///
/// Callers in VRTV-45c/45d/44/43 depend on `apiClientProvider` only.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_config.dart';
import 'fake_api_client.dart';

/// Read from `--dart-define` envs by default. Tests override with:
/// ```
/// ProviderScope(
///   overrides: [
///     apiConfigProvider.overrideWithValue(
///       const ApiConfig(baseUrl: 'http://test', useFake: true),
///     ),
///   ],
/// )
/// ```
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

/// Bearer-token supplier. Returns `null` today so unauthenticated
/// requests don't set the Authorization header (the backend's dev
/// mode accepts them). VRTV-60/61 will replace this with a provider
/// that reads from `flutter_secure_storage` and refreshes against
/// Keycloak.
final bearerTokenProvider = Provider<BearerTokenProvider>((ref) {
  return () async => null;
});

/// Callback for 401 responses. By default logs to the console; the
/// router overrides this to redirect to `/login`.
final unauthorizedCallbackProvider =
    Provider<UnauthorizedCallback?>((ref) => null);

/// The [ApiClient] the rest of the app consumes. Resolves to a
/// [FakeApiClient] when `ApiConfig.useFake` is true, otherwise a real
/// [HttpApiClient]. Disposed automatically with the provider scope.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.useFake) {
    final fake = FakeApiClient();
    ref.onDispose(fake.close);
    return fake;
  }
  final token = ref.watch(bearerTokenProvider);
  final unauthorized = ref.watch(unauthorizedCallbackProvider);
  final client = HttpApiClient(
    config: config,
    tokenProvider: token,
    onUnauthorized: unauthorized,
  );
  ref.onDispose(client.close);
  return client;
});
