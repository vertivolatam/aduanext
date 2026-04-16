import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/api/api_exception.dart';
import 'package:aduanext_mobile/shared/api/fake_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeApiClient.listDispatches', () {
    test('returns the default seed unfiltered', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
      final response = await client.listDispatches();

      expect(response.items, hasLength(3));
      expect(response.total, 3);
      expect(response.hasMore, isFalse);
    });

    test('filters by status code set', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
      final response = await client.listDispatches(
        statusCodes: {'REJECTED'},
      );

      expect(response.items, hasLength(1));
      expect(response.items.single.status, DeclarationStatus.rejected);
    });

    test('pagination honors offset + limit', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));

      final page1 = await client.listDispatches(limit: 2);
      final page2 = await client.listDispatches(offset: 2, limit: 2);

      expect(page1.items, hasLength(2));
      expect(page2.items, hasLength(1));
      expect(
        <String>{...page1.items.map((d) => d.declarationId),
          ...page2.items.map((d) => d.declarationId)}.length,
        3,
      );
    });

    test('riskScoreMin filter excludes dispatches below threshold', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
      final response = await client.listDispatches(riskScoreMin: 50);

      expect(response.items, hasLength(1));
      expect(response.items.single.riskScore, greaterThanOrEqualTo(50));
    });
  });

  group('FakeApiClient.getDispatch', () {
    test('returns a dispatch by id', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
      final dispatch = await client.getDispatch('DUA-2026-1201');

      expect(dispatch.status, DeclarationStatus.levante);
    });

    test('throws NotFoundApiException for unknown id', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));

      expect(
        () => client.getDispatch('DUA-2026-9999'),
        throwsA(isA<NotFoundApiException>()),
      );
    });
  });

  group('FakeApiClient.queueError', () {
    test('throws the queued exception on the next call only', () async {
      final client = FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
      client.queueError(const UnauthorizedApiException());

      await expectLater(
        client.listDispatches(),
        throwsA(isA<UnauthorizedApiException>()),
      );

      // Next call should succeed — the error was one-shot.
      final response = await client.listDispatches();
      expect(response.items, isNotEmpty);
    });
  });
}
