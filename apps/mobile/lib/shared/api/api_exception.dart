/// Typed API failures surfaced to the UI layer.
///
/// The dashboard, classifier, and DUA form all consume [ApiClient] via
/// Riverpod. Rather than every caller catching the same zoo of
/// [http.Response] / [TimeoutException] / [SocketException] shapes,
/// [ApiClient] translates them once into a small, exhaustive set of
/// [ApiException] subtypes that widgets can render with friendly
/// Spanish messages.
///
/// Categories follow the ATENA / backend dispatch error vocabulary in
/// `apps/server/lib/src/http/error_responses.dart` so log grep-ability
/// stays consistent end-to-end.
library;

/// Base for all API-layer failures.
sealed class ApiException implements Exception {
  /// Short, user-safe message in Spanish. Safe to render in SnackBars,
  /// dialogs, and banners — never contains tokens or PINs.
  final String message;

  /// Optional backend error code (matches `code` field on the JSON
  /// error envelope) so downstream handlers can branch on specific
  /// failures without string-matching [message].
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => 'ApiException($runtimeType): $message'
      '${code == null ? '' : ' [code=$code]'}';
}

/// The request never reached the server — DNS/TLS/socket-level error.
/// Presented to users as "Sin conexión. Verifica tu red."
class NetworkApiException extends ApiException {
  const NetworkApiException([
    super.message = 'Sin conexión. Verifica tu red.',
  ]);
}

/// The server answered but didn't complete within the configured
/// timeout. Distinguished from network failures so the UI can suggest
/// "El servidor esta lento" vs "Sin conexion".
class TimeoutApiException extends ApiException {
  const TimeoutApiException([
    super.message = 'El servidor tardó demasiado en responder.',
  ]);
}

/// 401 — the JWT is missing/invalid/expired. Widgets should redirect
/// to the login flow; the [ApiClient] emits a callback for the router
/// to react without every page handling this directly.
class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException([
    super.message = 'Tu sesion expiró. Inicia sesion nuevamente.',
  ]) : super(code: 'unauthorized');
}

/// 403 — the caller lacks the required role or tenant scope.
class ForbiddenApiException extends ApiException {
  const ForbiddenApiException([
    super.message = 'No tienes permisos para esta accion.',
  ]) : super(code: 'forbidden');
}

/// 404 — resource not found.
class NotFoundApiException extends ApiException {
  const NotFoundApiException([
    super.message = 'El recurso solicitado no existe.',
  ]) : super(code: 'not_found');
}

/// 422 — backend validation failed. Carries the backend's structured
/// `details` so the form layer can highlight specific fields.
class ValidationApiException extends ApiException {
  /// Per-field errors emitted by the backend. Matches the `details`
  /// field on the JSON error envelope.
  final Map<String, dynamic>? details;

  const ValidationApiException(
    super.message, {
    super.code,
    this.details,
  });
}

/// 429 — rate-limited. [ApiClient] retries transparently before
/// giving up and throwing this.
class RateLimitedApiException extends ApiException {
  const RateLimitedApiException([
    super.message = 'Muchas solicitudes. Esperá unos segundos.',
  ]) : super(code: 'rate_limited');
}

/// 5xx — the backend misbehaved. Caller should surface a generic
/// "Error del servidor" and retry later.
class ServerApiException extends ApiException {
  /// HTTP status code (5xx).
  final int status;

  const ServerApiException(
    this.status, {
    String message =
        'Error del servidor. Intenta de nuevo en unos minutos.',
    String? code,
  }) : super(message, code: code);
}

/// 501 — the endpoint exists but isn't implemented yet (e.g. the
/// dispatch list/get placeholders in VRTV-79). Distinguished from 5xx
/// so the UI can surface a "coming soon" message instead of a scary
/// server-error banner.
class NotImplementedApiException extends ApiException {
  const NotImplementedApiException([
    super.message =
        'Esta función aún no está disponible. Estamos trabajando en ella.',
  ]) : super(code: 'not_implemented');
}
