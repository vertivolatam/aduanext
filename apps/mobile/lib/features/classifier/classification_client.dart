/// RIMM classification service client.
///
/// Abstract [ClassificationClient] + two implementations:
///   * [HttpClassificationClient] — hits the backend once it's live.
///   * [FakeClassificationClient] — in-memory seed that mirrors the
///     `07-rimm-classifier.html` mockup, used in offline dev + widget
///     tests.
///
/// The interface returns futures rather than streams — a single
/// search emits one response (top-N suggestions) and callers
/// display the whole list at once.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../shared/api/api_client.dart' show BearerTokenProvider;
import '../../shared/api/api_config.dart';
import '../../shared/api/api_exception.dart';
import 'classification_dto.dart';

abstract class ClassificationClient {
  /// Search RIMM for classification suggestions matching [description].
  /// The [mode] hints which RIMM endpoint to use (full text / AI /
  /// by HS code). Returns at most [limit] suggestions, ranked by
  /// confidence descending.
  Future<ClassificationSuggestResponse> suggest(
    String description, {
    ClassificationSearchMode mode = ClassificationSearchMode.aiSuggestion,
    int limit = 5,
  });

  Future<void> close();
}

/// HTTP-backed client. Hits `POST /api/v1/classifications/suggest`
/// once the backend ships it; today the endpoint returns 501 and the
/// drawer surfaces a NotImplementedApiException which the UI handles
/// gracefully.
class HttpClassificationClient implements ClassificationClient {
  final ApiConfig _config;
  final http.Client _http;
  final BearerTokenProvider _tokenProvider;

  HttpClassificationClient({
    required ApiConfig config,
    required BearerTokenProvider tokenProvider,
    http.Client? httpClient,
  })  : _config = config,
        _http = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  @override
  Future<ClassificationSuggestResponse> suggest(
    String description, {
    ClassificationSearchMode mode = ClassificationSearchMode.aiSuggestion,
    int limit = 5,
  }) async {
    final uri =
        Uri.parse('${_config.baseUrl}/api/v1/classifications/suggest');
    final token = await _tokenProvider();
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
    };
    final response = await _http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'description': description,
            'mode': mode.code,
            'limit': limit,
          }),
        )
        .timeout(_config.requestTimeout);

    switch (response.statusCode) {
      case 200:
        final decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        return ClassificationSuggestResponse.fromJson(decoded);
      case 401:
        throw const UnauthorizedApiException();
      case 501:
        throw const NotImplementedApiException(
          'El clasificador RIMM estará disponible próximamente.',
        );
      default:
        throw ServerApiException(
          response.statusCode,
          message: 'No se pudieron cargar sugerencias (${response.statusCode}).',
        );
    }
  }

  @override
  Future<void> close() async => _http.close();
}

/// In-memory fake matching the mockup.
class FakeClassificationClient implements ClassificationClient {
  final Duration artificialLatency;

  FakeClassificationClient({this.artificialLatency = Duration.zero});

  @override
  Future<ClassificationSuggestResponse> suggest(
    String description, {
    ClassificationSearchMode mode = ClassificationSearchMode.aiSuggestion,
    int limit = 5,
  }) async {
    if (artificialLatency > Duration.zero) {
      await Future<void>.delayed(artificialLatency);
    }
    // Seed data matches the RIMM classifier mockup
    // (07-rimm-classifier.html).
    const seeds = [
      ClassificationSuggestion(
        hsCode: '8539.50.0000',
        description:
            'Luminarias y aparatos de alumbrado, de diodos emisores de luz (LED)',
        confidence: 92,
        nationalNote:
            'Incluye reflectores, difusores y componentes ópticos para '
            'luminarias LED cuando se importan como parte de un sistema de '
            'iluminación.',
        rates: TariffRates(dai: 0, iva: 13, isc: 1),
      ),
      ClassificationSuggestion(
        hsCode: '7616.99.0000',
        description:
            'Las demás manufacturas de aluminio — artículos de uso técnico',
        confidence: 67,
        rates: TariffRates(dai: 5, iva: 13, isc: 0),
      ),
      ClassificationSuggestion(
        hsCode: '9405.99.0000',
        description:
            'Partes de aparatos de alumbrado no expresados ni comprendidos '
            'en otra parte',
        confidence: 54,
        rates: TariffRates(dai: 5, iva: 13, isc: 0),
      ),
    ];

    final truncated = seeds.take(limit).toList(growable: false);
    return ClassificationSuggestResponse(suggestions: truncated);
  }

  @override
  Future<void> close() async {}
}
