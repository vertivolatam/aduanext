import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/api/dispatch_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DispatchSummary.fromJson', () {
    test('parses a minimal valid payload', () {
      final json = {
        'declarationId': 'DUA-2026-1',
        'status': 'LEVANTE',
        'commercialDescription': 'LED grow lights',
        'exporterCode': '310100580824',
        'officeOfDispatchExportCode': '001',
        'stateTimestamps': {
          'REGISTERED': '2026-04-10T12:00:00Z',
          'LEVANTE': '2026-04-12T12:00:00Z',
        },
        'lastUpdatedAt': '2026-04-12T14:00:00Z',
      };

      final summary = DispatchSummary.fromJson(json);

      expect(summary.declarationId, 'DUA-2026-1');
      expect(summary.status, DeclarationStatus.levante);
      expect(summary.stateTimestamps.length, 2);
      expect(summary.stateTimestamps['LEVANTE']!.isUtc, isTrue);
      expect(summary.atenaError, isNull);
    });

    test('parses atenaError block for rejected dispatches', () {
      final json = {
        'declarationId': 'DUA-2026-2',
        'status': 'REJECTED',
        'commercialDescription': 'LED Driver',
        'exporterCode': '310100580824',
        'officeOfDispatchExportCode': '001',
        'stateTimestamps': <String, String>{},
        'lastUpdatedAt': '2026-04-12T14:00:00Z',
        'atenaError': {
          'code': 'E-VAL-0042',
          'message': 'clasificacion arancelaria invalida',
        },
      };

      final summary = DispatchSummary.fromJson(json);

      expect(summary.status, DeclarationStatus.rejected);
      expect(summary.atenaError?.code, 'E-VAL-0042');
    });

    test('throws when required string field is missing', () {
      final json = {
        'status': 'LEVANTE',
        'commercialDescription': 'LED',
        'exporterCode': 'x',
        'officeOfDispatchExportCode': '001',
        'stateTimestamps': {},
        'lastUpdatedAt': '2026-04-12T14:00:00Z',
      };

      expect(() => DispatchSummary.fromJson(json), throwsFormatException);
    });

    test('throws when status code is not a known DeclarationStatus', () {
      final json = {
        'declarationId': 'DUA-2026-3',
        'status': 'MADE_UP',
        'commercialDescription': 'x',
        'exporterCode': 'x',
        'officeOfDispatchExportCode': '001',
        'stateTimestamps': {},
        'lastUpdatedAt': '2026-04-12T14:00:00Z',
      };

      expect(() => DispatchSummary.fromJson(json), throwsStateError);
    });
  });

  group('DispatchListResponse', () {
    test('parses paginated payload with explicit pagination metadata', () {
      final json = {
        'items': [
          {
            'declarationId': 'DUA-2026-1',
            'status': 'LEVANTE',
            'commercialDescription': 'LED',
            'exporterCode': 'x',
            'officeOfDispatchExportCode': '001',
            'stateTimestamps': <String, String>{},
            'lastUpdatedAt': '2026-04-12T14:00:00Z',
          },
        ],
        'total': 25,
        'offset': 0,
        'limit': 10,
      };

      final response = DispatchListResponse.fromJson(json);

      expect(response.items, hasLength(1));
      expect(response.total, 25);
      expect(response.hasMore, isTrue);
    });

    test('falls back to items.length when pagination metadata is absent', () {
      final json = {
        'items': [
          {
            'declarationId': 'DUA-2026-1',
            'status': 'LEVANTE',
            'commercialDescription': 'LED',
            'exporterCode': 'x',
            'officeOfDispatchExportCode': '001',
            'stateTimestamps': <String, String>{},
            'lastUpdatedAt': '2026-04-12T14:00:00Z',
          },
        ],
      };

      final response = DispatchListResponse.fromJson(json);

      expect(response.total, 1);
      expect(response.hasMore, isFalse);
    });

    test('throws when items is not an array', () {
      expect(
        () => DispatchListResponse.fromJson({'items': 'nope'}),
        throwsFormatException,
      );
    });
  });

  group('DispatchUpdate.fromJson', () {
    test('parses patch block into generic map', () {
      final json = {
        'declarationId': 'DUA-2026-1',
        'status': 'LEVANTE',
        'at': '2026-04-12T14:00:00Z',
        'patch': {'riskScore': 18},
      };

      final update = DispatchUpdate.fromJson(json);

      expect(update.status, DeclarationStatus.levante);
      expect(update.patch['riskScore'], 18);
      expect(update.at.isUtc, isTrue);
    });
  });
}
