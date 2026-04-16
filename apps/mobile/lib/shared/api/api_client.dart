/// HTTP client for the AduaNext backend REST API.
///
/// The dashboard (VRTV-45), classifier (VRTV-44), and DUA form
/// (VRTV-43) all consume this one port. Keeping the concrete HTTP
/// library (`package:http`) behind the [ApiClient] interface means:
///
///   * Tests swap in [FakeApiClient] without mocking `http.Client`.
///   * The SSE stream (VRTV-86) can live in a sibling class without
///     polluting the request/response surface here.
///   * If we ever need to flip to `dio` or `web_socket_channel` we
///     touch one file.
///
/// Security / observability invariants:
///
///   * **Never** logs `Authorization` header values, PINs, p12 bytes,
///     or bearer tokens. The [_logRequest] helper redacts them.
///   * Surfaces 401 via an injected [onUnauthorized] callback so the
///     router can redirect to `/login` without every caller branching.
///   * Retries 429 transparently with exponential backoff (1s, 2s, 4s,
///     max 3 tries) respecting `Retry-After` when present.
///   * Maps every non-2xx response to an [ApiException] subtype — the
///     UI never handles raw [http.Response].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'dispatch_dto.dart';

/// Callback invoked when a request comes back 401 (Unauthorized).
/// The router wires this to `context.go('/login')`. Returning a
/// [Future] lets the callback `await` a token refresh before the
/// caller sees the exception.
typedef UnauthorizedCallback = Future<void> Function();

/// Provides the bearer token for the Authorization header. Returning
/// `null` lets the request proceed unauthenticated — useful for the
/// `/health` check and the onboarding bootstrap endpoint.
typedef BearerTokenProvider = Future<String?> Function();

/// Abstract API surface — every backend call lives here, grouped by
/// feature. Sub-issues (45c, 44, 43) extend this interface rather than
/// adding ad-hoc `http.get` calls inside widgets.
abstract class ApiClient {
  Future<DispatchListResponse> listDispatches({
    int offset = 0,
    int limit = 50,
    Set<String> statusCodes = const {},
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? riskScoreMin,
    int? riskScoreMax,
    String? exporterCode,
  });

  Future<DispatchSummary> getDispatch(String declarationId);

  Future<List<DispatchAuditEvent>> listAuditEvents(
    String declarationId, {
    int offset = 0,
    int limit = 100,
  });

  /// Close any pooled resources. Called from `ProviderScope.dispose`.
  Future<void> close();
}

/// Real HTTP implementation backed by `package:http`.
class HttpApiClient implements ApiClient {
  final ApiConfig _config;
  final http.Client _http;
  final BearerTokenProvider _tokenProvider;
  final UnauthorizedCallback? _onUnauthorized;

  /// Exposed for tests — lets a matrix override the backoff so
  /// retry-suite runs complete in milliseconds instead of seconds.
  @visibleForTesting
  final Duration initialBackoff;

  /// Clock override for tests — [DateTime.now] in production.
  @visibleForTesting
  final DateTime Function() now;

  HttpApiClient({
    required ApiConfig config,
    required BearerTokenProvider tokenProvider,
    UnauthorizedCallback? onUnauthorized,
    http.Client? httpClient,
    this.initialBackoff = const Duration(seconds: 1),
    DateTime Function()? now,
  })  : _config = config,
        _http = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized,
        now = now ?? DateTime.now;

  // ─── Public endpoints ───────────────────────────────────────────

  @override
  Future<DispatchListResponse> listDispatches({
    int offset = 0,
    int limit = 50,
    Set<String> statusCodes = const {},
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? riskScoreMin,
    int? riskScoreMax,
    String? exporterCode,
  }) async {
    final qs = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      if (statusCodes.isNotEmpty) 'status': statusCodes.join(','),
      if (createdAfter != null)
        'createdAfter': createdAfter.toUtc().toIso8601String(),
      if (createdBefore != null)
        'createdBefore': createdBefore.toUtc().toIso8601String(),
      if (riskScoreMin != null) 'riskScoreMin': '$riskScoreMin',
      if (riskScoreMax != null) 'riskScoreMax': '$riskScoreMax',
      if (exporterCode != null && exporterCode.isNotEmpty)
        'exporterCode': exporterCode,
    };
    final json = await _getJson('/api/v1/dispatches', query: qs);
    return DispatchListResponse.fromJson(json);
  }

  @override
  Future<DispatchSummary> getDispatch(String declarationId) async {
    final json = await _getJson('/api/v1/dispatches/$declarationId');
    return DispatchSummary.fromJson(json);
  }

  @override
  Future<List<DispatchAuditEvent>> listAuditEvents(
    String declarationId, {
    int offset = 0,
    int limit = 100,
  }) async {
    final json = await _getJson(
      '/api/v1/dispatches/$declarationId/audit',
      query: {'offset': '$offset', 'limit': '$limit'},
    );
    final items = json['items'];
    if (items is! List) {
      throw const ValidationApiException(
        'Respuesta invalida del servidor (audit.items)',
      );
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(DispatchAuditEvent.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> close() async {
    _http.close();
  }

  // ─── Request pipeline ───────────────────────────────────────────

  /// GET the path and decode the response as a JSON object. Surfaces
  /// 501 as [NotImplementedApiException] so the dashboard can hide
  /// not-yet-built features instead of showing a scary red error.
  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String> query = const {},
  }) async {
    final response = await _send('GET', path, query: query);
    return _decodeJsonObject(response);
  }

  /// Thin wrapper around [_sendRaw] that enforces the retry / 401 /
  /// exception-mapping contract.
  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String> query = const {},
    Object? body,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      final http.Response response;
      try {
        response = await _sendRaw(method, path, query: query, body: body);
      } on TimeoutException {
        throw const TimeoutApiException();
      } on SocketException catch (e) {
        throw NetworkApiException('Sin conexión: ${e.osError?.message ?? e.message}');
      } on http.ClientException catch (e) {
        // `package:http` wraps platform-specific errors in ClientException
        // — we mirror them as network failures.
        throw NetworkApiException('Sin conexión: ${e.message}');
      }

      // ── Happy path
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      // ── 401 → fire callback, then surface
      if (response.statusCode == 401) {
        final cb = _onUnauthorized;
        if (cb != null) {
          // Swallow callback errors — the login redirect is best-effort;
          // the caller still needs its exception.
          try {
            await cb();
          } catch (_) {}
        }
        throw const UnauthorizedApiException();
      }

      // ── 429 → retry with backoff, respecting Retry-After
      if (response.statusCode == 429 && attempt < 3) {
        final retryAfter = _parseRetryAfter(response.headers['retry-after']);
        final delay = retryAfter ??
            initialBackoff * math.pow(2, attempt - 1).toInt();
        await Future<void>.delayed(delay);
        continue;
      }

      _mapErrorResponse(response);
    }
  }

  /// Emit a single HTTP request. Extracted so tests can inject a
  /// `MockClient` via the constructor and assert the URL / headers /
  /// body shape.
  Future<http.Response> _sendRaw(
    String method,
    String path, {
    Map<String, String> query = const {},
    Object? body,
  }) async {
    final uri = Uri.parse(_config.baseUrl + path).replace(
      queryParameters: query.isEmpty ? null : query,
    );
    final headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
    };
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      headers['authorization'] = 'Bearer $token';
    }

    _logRequest(method, uri);

    final encoded = body == null ? null : jsonEncode(body);

    final Future<http.Response> future = switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' =>
        _http.post(uri, headers: headers, body: encoded),
      'PATCH' =>
        _http.patch(uri, headers: headers, body: encoded),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported HTTP method: $method'),
    };
    return future.timeout(_config.requestTimeout);
  }

  /// Parse a JSON object response. 204 (No Content) returns `{}` so
  /// callers can uniformly `await` without a null-branch.
  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return const <String, dynamic>{};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw ValidationApiException(
        'El servidor devolvió JSON inválido: ${e.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ValidationApiException(
        'El servidor devolvió una respuesta en un formato inesperado.',
      );
    }
    return decoded;
  }

  /// Translate a non-2xx [http.Response] into the right [ApiException]
  /// subtype. Always throws — returning would be a lie about control
  /// flow.
  Never _mapErrorResponse(http.Response response) {
    Map<String, dynamic> envelope;
    try {
      envelope = response.body.isEmpty
          ? const {}
          : (jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      envelope = const {};
    }
    final code = envelope['code'] as String?;
    final message = envelope['message'] as String?;
    final details =
        (envelope['details'] as Map?)?.cast<String, dynamic>();

    switch (response.statusCode) {
      case 403:
        throw ForbiddenApiException(
          message ?? 'No tienes permisos para esta acción.',
        );
      case 404:
        throw NotFoundApiException(
          message ?? 'El recurso solicitado no existe.',
        );
      case 422:
        throw ValidationApiException(
          message ?? 'El servidor rechazó los datos enviados.',
          code: code,
          details: details,
        );
      case 429:
        throw const RateLimitedApiException();
      case 501:
        throw NotImplementedApiException(
          message ??
              'Esta función aún no está disponible. Estamos trabajando en ella.',
        );
    }
    if (response.statusCode >= 500) {
      throw ServerApiException(
        response.statusCode,
        message: message ??
            'Error del servidor (${response.statusCode}). Intenta de nuevo en unos minutos.',
        code: code,
      );
    }
    // Everything else (400, 409, 410, ...) → validation-style surface.
    throw ValidationApiException(
      message ?? 'Solicitud inválida (${response.statusCode})',
      code: code,
      details: details,
    );
  }

  /// `Retry-After` can be either delta-seconds or an HTTP-date. We
  /// only support delta-seconds — the backend never emits the date
  /// form (and browsers re-compute dates inconsistently anyway).
  Duration? _parseRetryAfter(String? header) {
    if (header == null) return null;
    final seconds = int.tryParse(header.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds);
  }

  /// Structured log at the request boundary. Redacts `authorization`
  /// at the source (never logged) and emits a stable prefix
  /// (`api.request`) so log greps work the same on web (browser
  /// console) and server (stdout when run under Dart CLI).
  void _logRequest(String method, Uri uri) {
    if (!kDebugMode) return;
    // Strip the query string before the log — it's useful for us but
    // may contain exporterCode / tenantId we'd rather not pin into
    // browser devtools history.
    final safeUrl = '${uri.scheme}://${uri.authority}${uri.path}';
    debugPrint('api.request $method $safeUrl');
  }
}
