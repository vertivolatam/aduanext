import 'package:aduanext_mobile/features/classifier/classification_client.dart';
import 'package:aduanext_mobile/features/classifier/classification_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeClassificationClient', () {
    test('returns seeded suggestions sorted by confidence descending',
        () async {
      final client = FakeClassificationClient();
      final response = await client.suggest('LED grow lights');

      expect(response.suggestions, hasLength(3));
      expect(response.suggestions.first.hsCode, '8539.50.0000');
      expect(response.suggestions.first.confidence, 92);
      // Descending by confidence.
      expect(
        response.suggestions.map((s) => s.confidence).toList(),
        [92, 67, 54],
      );
    });

    test('honors the `limit` arg', () async {
      final client = FakeClassificationClient();
      final response = await client.suggest('x', limit: 1);

      expect(response.suggestions, hasLength(1));
    });

    test('emits national note for the recommended suggestion', () async {
      final client = FakeClassificationClient();
      final response = await client.suggest('x');

      expect(
        response.suggestions.first.nationalNote,
        contains('reflectores'),
      );
      // Non-recommended suggestions omit the note.
      expect(response.suggestions[1].nationalNote, isNull);
    });

    test('honors search mode (does not crash on any enum value)',
        () async {
      final client = FakeClassificationClient();
      for (final mode in ClassificationSearchMode.values) {
        final response = await client.suggest('x', mode: mode);
        expect(response.suggestions, isNotEmpty);
      }
    });
  });

  group('ClassificationSuggestion.fromJson', () {
    test('parses a minimal valid payload', () {
      final json = {
        'hsCode': '8539.50.0000',
        'description': 'LED luminaires',
        'confidence': 92,
        'rates': {'dai': 0, 'iva': 13, 'isc': 1},
      };
      final s = ClassificationSuggestion.fromJson(json);
      expect(s.hsCode, '8539.50.0000');
      expect(s.confidence, 92);
      expect(s.rates.dai, 0);
      expect(s.rates.iva, 13);
      expect(s.rates.isc, 1);
    });

    test('ClassificationSuggestResponse.fromJson parses a list', () {
      final json = {
        'suggestions': [
          {
            'hsCode': '8539.50.0000',
            'description': 'LED',
            'confidence': 92,
            'rates': <String, dynamic>{},
          },
        ],
      };
      final r = ClassificationSuggestResponse.fromJson(json);
      expect(r.suggestions, hasLength(1));
    });

    test('throws when suggestions is not an array', () {
      expect(
        () => ClassificationSuggestResponse.fromJson({'suggestions': 'x'}),
        throwsFormatException,
      );
    });
  });
}
