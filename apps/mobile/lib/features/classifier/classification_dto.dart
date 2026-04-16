/// Wire DTOs for the RIMM classifier.
///
/// The backend endpoint (`POST /api/v1/classifications/suggest`) isn't
/// yet wired — the FakeRimmClassificationClient below returns seeded
/// data matching the mockup (`07-rimm-classifier.html`). When the
/// real endpoint lands (tracked separately), only the client
/// implementation changes.
library;

/// Search mode toggled by the three filter chips in the drawer
/// (FULL_TEXT / AI_SUGGESTION / HS_CODE).
///
/// * fullText   — RIMM `/hsCode/search?q=...` direct.
/// * aiSuggestion — RAG + confidence via the AI service.
/// * hsCode     — exact lookup (useful when the agent already knows
///   the code and just wants tariffs).
enum ClassificationSearchMode {
  fullText('FULL_TEXT', 'Texto completo'),
  aiSuggestion('AI_SUGGESTION', 'AI Sugerencia'),
  hsCode('HS_CODE', 'Por HS Code');

  final String code;
  final String displayName;
  const ClassificationSearchMode(this.code, this.displayName);
}

/// Per-suggestion tariff rates. Displayed in the card footer grid
/// (DAI / IVA / ISC) per the mockup.
class TariffRates {
  /// Derechos Arancelarios a la Importación — percentage (0–100).
  final double dai;

  /// Impuesto al Valor Agregado — percentage.
  final double iva;

  /// Impuesto Selectivo de Consumo — percentage.
  final double isc;

  const TariffRates({
    required this.dai,
    required this.iva,
    required this.isc,
  });

  factory TariffRates.fromJson(Map<String, dynamic> json) => TariffRates(
        dai: (json['dai'] as num?)?.toDouble() ?? 0,
        iva: (json['iva'] as num?)?.toDouble() ?? 0,
        isc: (json['isc'] as num?)?.toDouble() ?? 0,
      );
}

/// A single classification suggestion from the RIMM service.
class ClassificationSuggestion {
  /// The HS code formatted as emitted by RIMM (e.g. `8539.50.0000`).
  final String hsCode;

  /// Short commodity description (Spanish).
  final String description;

  /// Optional "nota nacional" — country-specific note that explains
  /// when the heading applies. Null for suggestions that don't
  /// carry a national scope.
  final String? nationalNote;

  /// AI confidence, 0-100. The card coloring follows the same bands
  /// as the risk badge atom (>=85 verde, 60-84 amber, <60 rojo).
  final int confidence;

  /// Tariff rates for the classification.
  final TariffRates rates;

  const ClassificationSuggestion({
    required this.hsCode,
    required this.description,
    required this.confidence,
    required this.rates,
    this.nationalNote,
  });

  factory ClassificationSuggestion.fromJson(Map<String, dynamic> json) =>
      ClassificationSuggestion(
        hsCode: json['hsCode'] as String,
        description: json['description'] as String,
        nationalNote: json['nationalNote'] as String?,
        confidence: (json['confidence'] as num).toInt(),
        rates: TariffRates.fromJson(
          (json['rates'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
}

/// Response from the `suggest` endpoint.
class ClassificationSuggestResponse {
  final List<ClassificationSuggestion> suggestions;

  const ClassificationSuggestResponse({required this.suggestions});

  factory ClassificationSuggestResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['suggestions'];
    if (raw is! List) {
      throw const FormatException(
        '"suggestions" must be a JSON array',
      );
    }
    return ClassificationSuggestResponse(
      suggestions: raw
          .whereType<Map<String, dynamic>>()
          .map(ClassificationSuggestion.fromJson)
          .toList(growable: false),
    );
  }
}
