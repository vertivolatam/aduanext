/// Unit tests for [RimmTariffCatalogAdapter].
///
/// Coverage focus:
/// - Happy-path JSON decoding into [CommodityEntry].
/// - C8 regression: FormatException / TypeError wrapped in
///   [TariffCatalogException] (no silent failure).
/// - C9 regression: [CommodityEntry.validFromDate] parsing throws on
///   null/invalid values — no `DateTime.now()` fallback that would poison
///   downstream tariff filtering.
/// - Search param serialization (operator, validityDate, text vs hsCode).
/// - Exchange-rate / delivery-terms / customs-office branches.
library;

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_adapters/src/generated/hacienda.pb.dart';
import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

import '../helpers/fake_services.dart';
import '../helpers/in_process_grpc_server.dart';

void main() {
  group('RimmTariffCatalogAdapter', () {
    late FakeApiService fake;
    late InProcessGrpcTestHarness harness;
    late RimmTariffCatalogAdapter adapter;

    setUp(() async {
      fake = FakeApiService();
      harness = await InProcessGrpcTestHarness.start([fake]);
      adapter = RimmTariffCatalogAdapter(
        channelManager: harness.channelManager,
      );
    });

    tearDown(() async {
      await harness.stop();
    });

    // -------------------------------------------------------------------------
    // searchCommodities
    // -------------------------------------------------------------------------
    group('searchCommodities', () {
      test('maps text-query params to RimmRestriction', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: [
                '{"code":"48191000","hsCode":"481910",'
                    '"description":"boxes","validFromDate":"2024-01-01"}',
              ],
            );
        final result = await adapter.searchCommodities(
          const TariffSearchParams(
            textQuery: 'boxes',
            operator: 'FULL_TEXT',
            maxResults: 25,
            offset: 5,
          ),
        );
        expect(result, hasLength(1));
        expect(result.single.code, '48191000');
        final req = fake.lastRimmSearch!;
        expect(req.endpoint, 'commodity/search');
        expect(req.max, 25);
        expect(req.offset, 5);
        expect(req.restrictions, hasLength(1));
        expect(req.restrictions.first.value, 'boxes');
        expect(req.restrictions.first.operator, 'FULL_TEXT');
        expect(req.restrictions.first.field_3, 'description');
      });

      test('adds hsCode restriction when provided', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(resultList: const []);
        await adapter.searchCommodities(
          TariffSearchParams(
            hsCode: HsCode('481910'),
            validityDate: DateTime.utc(2026, 4, 13),
          ),
        );
        final req = fake.lastRimmSearch!;
        expect(req.restrictions, hasLength(1));
        expect(req.restrictions.first.field_3, 'code');
        expect(req.restrictions.first.operator, 'STARTS_WITH');
        expect(req.meta.validityDate, '2026-04-13');
      });

      test('response.error yields TariffCatalogException', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(error: 'rimm down');
        await expectLater(
          adapter.searchCommodities(const TariffSearchParams(textQuery: 'x')),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test(
        'C8 regression: malformed result payload wraps as '
        'TariffCatalogException (not silent failure)',
        () async {
          fake.onRimmSearch = (_) =>
              RimmSearchResponse(resultList: const ['not-json']);
          await expectLater(
            adapter.searchCommodities(
              const TariffSearchParams(textQuery: 'x'),
            ),
            throwsA(
              isA<TariffCatalogException>().having(
                (e) => e.message,
                'message',
                contains('Failed to decode commodity search payload'),
              ),
            ),
          );
        },
      );

      test(
        'C9 regression: missing validFromDate throws explicit exception '
        '(NO DateTime.now fallback)',
        () async {
          fake.onRimmSearch = (_) => RimmSearchResponse(
                resultList: const [
                  '{"code":"C1","hsCode":"HS","description":"d"}',
                ],
              );
          await expectLater(
            adapter.searchCommodities(
              const TariffSearchParams(textQuery: 'x'),
            ),
            throwsA(
              isA<TariffCatalogException>().having(
                (e) => e.message,
                'message',
                contains('missing validFromDate'),
              ),
            ),
          );
        },
      );

      test(
        'C9 regression: unparseable validFromDate throws explicit exception',
        () async {
          fake.onRimmSearch = (_) => RimmSearchResponse(
                resultList: const [
                  '{"code":"C1","hsCode":"HS","description":"d",'
                      '"validFromDate":"garbage-date"}',
                ],
              );
          await expectLater(
            adapter.searchCommodities(
              const TariffSearchParams(textQuery: 'x'),
            ),
            throwsA(
              isA<TariffCatalogException>().having(
                (e) => e.message,
                'message',
                contains('unparseable validFromDate'),
              ),
            ),
          );
        },
      );

      test('C9 regression: unparseable validToDate throws explicit exception',
          () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const [
                '{"code":"C1","hsCode":"HS","description":"d",'
                    '"validFromDate":"2024-01-01",'
                    '"validToDate":"not-a-date"}',
              ],
            );
        await expectLater(
          adapter.searchCommodities(
            const TariffSearchParams(textQuery: 'x'),
          ),
          throwsA(
            isA<TariffCatalogException>().having(
              (e) => e.message,
              'message',
              contains('unparseable validToDate'),
            ),
          ),
        );
      });

      test('accepts valid validToDate', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const [
                '{"code":"C1","hsCode":"HS","description":"d",'
                    '"validFromDate":"2024-01-01",'
                    '"validToDate":"2030-12-31"}',
              ],
            );
        final res = await adapter.searchCommodities(
          const TariffSearchParams(textQuery: 'x'),
        );
        expect(res.single.validToDate, DateTime.parse('2030-12-31'));
      });

      test('maps taxes and tolerates non-numeric tax values silently',
          () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const [
                '{"code":"C1","hsCode":"HS","description":"d",'
                    '"validFromDate":"2024-01-01",'
                    '"taxes":{"IVA":13,"DAI":"not-a-number"}}',
              ],
            );
        final res = await adapter.searchCommodities(
          const TariffSearchParams(textQuery: 'x'),
        );
        // Only the numeric rate survives; non-numeric is filtered out.
        expect(res.single.taxRates, {'IVA': 13.0});
      });

      test('wraps GrpcError with code', () async {
        fake.onRimmSearch = (_) =>
            throw GrpcError.resourceExhausted('quota');
        await expectLater(
          adapter.searchCommodities(const TariffSearchParams(textQuery: 'x')),
          throwsA(
            isA<TariffCatalogException>()
                .having((e) => e.vendorCode, "vendorCode", 'RESOURCE_EXHAUSTED'),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getCommodityByCode
    // -------------------------------------------------------------------------
    group('getCommodityByCode', () {
      test('returns null when no results', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(resultList: const []);
        final res = await adapter.getCommodityByCode('481910');
        expect(res, isNull);
      });

      test('returns the first parsed entry when results exist', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const [
                '{"code":"C","hsCode":"H","description":"d",'
                    '"validFromDate":"2024-01-01"}',
              ],
            );
        final res = await adapter.getCommodityByCode('C');
        expect(res, isNotNull);
        expect(res!.code, 'C');
      });

      test('response.error throws TariffCatalogException', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(error: 'not authorized');
        await expectLater(
          adapter.getCommodityByCode('X'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('wraps GrpcError', () async {
        fake.onRimmSearch = (_) =>
            throw GrpcError.internal('boom');
        await expectLater(
          adapter.getCommodityByCode('X'),
          throwsA(isA<TariffCatalogException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getExchangeRate
    // -------------------------------------------------------------------------
    group('getExchangeRate', () {
      test('returns parsed rate from exchangeRate field', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['{"exchangeRate":520.5}'],
            );
        final r = await adapter.getExchangeRate(
          'USD',
          DateTime.utc(2026, 4, 13),
        );
        expect(r, 520.5);
        expect(fake.lastRimmSearch?.endpoint, 'exchangeRate/search');
        expect(fake.lastRimmSearch?.meta.validityDate, '2026-04-13');
      });

      test('falls back to rate then value key', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['{"rate":"501.25"}'],
            );
        final r = await adapter.getExchangeRate(
          'USD',
          DateTime.utc(2026, 4, 13),
        );
        expect(r, 501.25);
      });

      test('throws when result list is empty', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(resultList: const []);
        await expectLater(
          adapter.getExchangeRate('JPY', DateTime.utc(2026, 4, 13)),
          throwsA(
            isA<TariffCatalogException>().having(
              (e) => e.message,
              'message',
              contains('No exchange rate found'),
            ),
          ),
        );
      });

      test('throws when rate field is missing', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['{"somethingElse":"x"}'],
            );
        await expectLater(
          adapter.getExchangeRate('USD', DateTime.utc(2026, 4, 13)),
          throwsA(
            isA<TariffCatalogException>().having(
              (e) => e.message,
              'message',
              contains('missing rate field'),
            ),
          ),
        );
      });

      test('wraps malformed JSON payload', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['not-json'],
            );
        await expectLater(
          adapter.getExchangeRate('USD', DateTime.utc(2026, 4, 13)),
          throwsA(
            isA<TariffCatalogException>().having(
              (e) => e.message,
              'message',
              contains('Failed to decode exchange rate payload'),
            ),
          ),
        );
      });

      test('wraps GrpcError', () async {
        fake.onRimmSearch = (_) =>
            throw GrpcError.unavailable('down');
        await expectLater(
          adapter.getExchangeRate('USD', DateTime.utc(2026, 4, 13)),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('response.error bubbles up', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(error: 'rate server broken');
        await expectLater(
          adapter.getExchangeRate('USD', DateTime.utc(2026, 4, 13)),
          throwsA(
            isA<TariffCatalogException>().having(
              (e) => e.message,
              'message',
              contains('rate server broken'),
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getDeliveryTerms
    // -------------------------------------------------------------------------
    group('getDeliveryTerms', () {
      test('returns JSON map on success', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['{"code":"FOB","description":"free"}'],
            );
        final m = await adapter.getDeliveryTerms('FOB');
        expect(m['code'], 'FOB');
        expect(fake.lastRimmSearch?.endpoint, 'deliveryTerms/search');
      });

      test('throws when empty', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(resultList: const []);
        await expectLater(
          adapter.getDeliveryTerms('ZZZ'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('malformed JSON wrapped', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['not-json'],
            );
        await expectLater(
          adapter.getDeliveryTerms('FOB'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('response.error wrapped', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(error: 'boom');
        await expectLater(
          adapter.getDeliveryTerms('FOB'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('GrpcError wrapped', () async {
        fake.onRimmSearch = (_) =>
            throw GrpcError.unavailable('x');
        await expectLater(
          adapter.getDeliveryTerms('FOB'),
          throwsA(isA<TariffCatalogException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getCustomsOffice
    // -------------------------------------------------------------------------
    group('getCustomsOffice', () {
      test('returns JSON map on success', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['{"code":"001","name":"Caldera"}'],
            );
        final m = await adapter.getCustomsOffice('001');
        expect(m['code'], '001');
        expect(fake.lastRimmSearch?.endpoint, 'customsOffice/search');
      });

      test('throws when empty', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(resultList: const []);
        await expectLater(
          adapter.getCustomsOffice('999'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('malformed JSON wrapped', () async {
        fake.onRimmSearch = (_) => RimmSearchResponse(
              resultList: const ['not-json'],
            );
        await expectLater(
          adapter.getCustomsOffice('001'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('response.error wrapped', () async {
        fake.onRimmSearch = (_) =>
            RimmSearchResponse(error: 'unauth');
        await expectLater(
          adapter.getCustomsOffice('001'),
          throwsA(isA<TariffCatalogException>()),
        );
      });

      test('GrpcError wrapped', () async {
        fake.onRimmSearch = (_) =>
            throw GrpcError.unknown('mystery');
        await expectLater(
          adapter.getCustomsOffice('001'),
          throwsA(isA<TariffCatalogException>()),
        );
      });
    });
  });
}
