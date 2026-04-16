/// API endpoint configuration.
///
/// `baseUrl` is read from the Dart build-time environment so a single
/// web bundle can be pointed at staging (`https://api.staging.aduanext.io`),
/// production (`https://api.aduanext.io`), or localhost during dev
/// without rebuilding.
///
/// Example:
/// ```
/// flutter run -d chrome \
///   --dart-define=API_BASE_URL=https://api.staging.aduanext.io
/// ```
library;

/// Immutable API configuration. A single instance is injected at the
/// root of the Riverpod container so tests can override the base URL
/// without touching `String.fromEnvironment` defaults.
class ApiConfig {
  /// The root URL for backend REST endpoints. Must NOT include a
  /// trailing slash — [ApiClient] appends the path segment directly.
  final String baseUrl;

  /// Whether to use [FakeApiClient] instead of the live HTTP client.
  /// Toggled via `--dart-define=API_FAKE=true` for offline dev or
  /// widget/integration tests that don't spin up the full server.
  final bool useFake;

  /// Default per-request timeout. The real client wraps every call
  /// with this so a hung backend surfaces as a user-visible error
  /// rather than a spinner that never resolves.
  final Duration requestTimeout;

  const ApiConfig({
    required this.baseUrl,
    this.useFake = false,
    this.requestTimeout = const Duration(seconds: 15),
  });

  /// Build the default config from Dart build-time environment variables.
  ///
  /// - `API_BASE_URL` — backend root (default: `http://localhost:8080`
  ///   which matches the Serverpod dev server port).
  /// - `API_FAKE` — when `"true"`, skip HTTP and use the in-memory fake.
  factory ApiConfig.fromEnvironment() {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    const fake = String.fromEnvironment('API_FAKE', defaultValue: 'false');
    return ApiConfig(
      baseUrl: _trimTrailingSlash(url),
      useFake: fake.toLowerCase() == 'true',
    );
  }

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
