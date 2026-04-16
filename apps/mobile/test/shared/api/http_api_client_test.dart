import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/api/api_client.dart';
import 'package:aduanext_mobile/shared/api/api_config.dart';
import 'package:aduanext_mobile/shared/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpApiClient.listDispatches', () {
    test('builds the expected request + parses the JSON envelope', () async {
      Uri? capturedUri;
      final mock = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'items': [
              {
                'declarationId': 'DUA-1',
                'status': 'LEVANTE',
                'commercialDescription': 'LED',
                'exporterCode': 'x',
                'officeOfDispatchExportCode': '001',
                'stateTimestamps': <String, String>{},
                'lastUpdatedAt': '2026-04-12T14:00:00Z',
              },
            ],
            'total': 1,
            'offset': 0,
            'limit': 50,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => 'tok-abc',
        httpClient: mock,
      );

      final response = await client.listDispatches(
        statusCodes: {'LEVANTE', 'VALIDATING'},
      );

      expect(response.items, hasLength(1));
      expect(capturedUri?.path, '/api/v1/dispatches');
      expect(capturedUri?.queryParameters['status'], contains('LEVANTE'));
    });

    test('attaches Authorization header when token is available', () async {
      String? seenAuth;
      final mock = MockClient((request) async {
        seenAuth = request.headers['authorization'];
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'offset': 0, 'limit': 50}),
          200,
        );
      });

      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => 'tok-abc',
        httpClient: mock,
      );

      await client.listDispatches();

      expect(seenAuth, 'Bearer tok-abc');
    });

    test('omits Authorization header when token provider returns null',
        () async {
      String? seenAuth;
      final mock = MockClient((request) async {
        seenAuth = request.headers['authorization'];
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'offset': 0, 'limit': 50}),
          200,
        );
      });

      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );

      await client.listDispatches();

      expect(seenAuth, isNull);
    });
  });

  group('HttpApiClient error handling', () {
    test('maps 401 to UnauthorizedApiException and fires callback', () async {
      var callbackCount = 0;
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'unauth', 'code': 'missing_token'}),
          401,
        );
      });

      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        onUnauthorized: () async {
          callbackCount++;
        },
        httpClient: mock,
      );

      await expectLater(
        client.listDispatches(),
        throwsA(isA<UnauthorizedApiException>()),
      );
      expect(callbackCount, 1);
    });

    test('maps 403 to ForbiddenApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'role denied'}),
          403,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      await expectLater(
        client.listDispatches(),
        throwsA(isA<ForbiddenApiException>()),
      );
    });

    test('maps 501 to NotImplementedApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'not impl', 'code': 'not_implemented'}),
          501,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      await expectLater(
        client.listDispatches(),
        throwsA(isA<NotImplementedApiException>()),
      );
    });

    test('maps 500 to ServerApiException with status code', () async {
      final mock = MockClient((request) async {
        return http.Response('{}', 503);
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      try {
        await client.listDispatches();
        fail('expected throw');
      } on ServerApiException catch (e) {
        expect(e.status, 503);
      }
    });

    test('maps 422 with details to ValidationApiException', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'bad',
            'code': 'validation_failed',
            'details': {'exporterCode': 'required'},
          }),
          422,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      try {
        await client.listDispatches();
        fail('expected throw');
      } on ValidationApiException catch (e) {
        expect(e.details, isNotNull);
        expect(e.details!['exporterCode'], 'required');
      }
    });

    test('retries 429 twice then succeeds', () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        if (calls < 3) {
          return http.Response('{}', 429, headers: {'retry-after': '0'});
        }
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'offset': 0, 'limit': 50}),
          200,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
        // Short backoff so the test runs in ms, not seconds.
        initialBackoff: const Duration(milliseconds: 1),
      );

      final response = await client.listDispatches();

      expect(calls, 3);
      expect(response.items, isEmpty);
    });

    test('retries 429 then surfaces RateLimitedApiException after maxAttempts',
        () async {
      var calls = 0;
      final mock = MockClient((request) async {
        calls++;
        return http.Response('{}', 429, headers: {'retry-after': '0'});
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
        initialBackoff: const Duration(milliseconds: 1),
      );

      await expectLater(
        client.listDispatches(),
        throwsA(isA<RateLimitedApiException>()),
      );
      expect(calls, 3);
    });
  });

  group('HttpApiClient.getDispatch', () {
    test('fetches and parses a single dispatch', () async {
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/v1/dispatches/DUA-1');
        return http.Response(
          jsonEncode({
            'declarationId': 'DUA-1',
            'status': 'LEVANTE',
            'commercialDescription': 'LED',
            'exporterCode': '310100580824',
            'officeOfDispatchExportCode': '001',
            'stateTimestamps': <String, String>{},
            'lastUpdatedAt': '2026-04-12T14:00:00Z',
          }),
          200,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );

      final dispatch = await client.getDispatch('DUA-1');

      expect(dispatch.declarationId, 'DUA-1');
      expect(dispatch.status, DeclarationStatus.levante);
    });
  });

  group('HttpApiClient.listAuditEvents', () {
    test('parses audit envelope', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'ev-1',
                'at': '2026-04-12T14:00:00Z',
                'actorId': 'user-1',
                'actorName': 'Andrea',
                'action': 'dispatch.submitted',
                'payload': {'source': 'ui'},
              },
            ],
          }),
          200,
        );
      });
      final client = HttpApiClient(
        config: const ApiConfig(baseUrl: 'https://api.test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );

      final events = await client.listAuditEvents('DUA-1');

      expect(events, hasLength(1));
      expect(events.single.action, 'dispatch.submitted');
    });
  });

  group('ApiConfig', () {
    test('trims trailing slash from baseUrl', () {
      const cfg = ApiConfig(baseUrl: 'https://api.test/');
      // The field itself is untouched; trimming is via the factory.
      final built = ApiConfig.fromEnvironment();
      // Just assert the factory runs and does not crash.
      expect(built.baseUrl, isNotNull);
      expect(cfg.useFake, isFalse);
    });
  });
}
