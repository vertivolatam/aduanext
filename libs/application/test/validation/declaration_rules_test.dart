/// Unit tests for the 9 pre-submission rules (VRTV-42).
///
/// Each rule gets at least one pass + one fail case. Rules that touch
/// [TariffCatalogPort] (5, 9) use a tiny fake; the others are pure.
library;

import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 4, 14, 12);
  DateTime clock() => now;

  // ── Rule 1: RequiredFieldsRule ─────────────────────────────────────
  group('RequiredFieldsRule', () {
    final rule = RequiredFieldsRule();

    test('passes a complete minimal declaration', () async {
      final result = await rule.evaluate(_buildMinimal());
      expect(result, isA<Pass>());
    });

    test('reports every missing field in the message', () async {
      final d = _buildMinimal(
        exporterCode: '',
        declarantCode: '',
      );
      final result = await rule.evaluate(d);
      final fail = result as Fail;
      expect(fail.severity, RuleSeverity.error);
      expect(fail.message, contains('exporterCode'));
      expect(fail.message, contains('declarantCode'));
    });
  });

  // ── Rule 2: IncotermConsistencyRule ────────────────────────────────
  group('IncotermConsistencyRule', () {
    final rule = IncotermConsistencyRule();

    test('passes when FOB + mode=sea (1)', () async {
      final d = _buildMinimal(
        deliveryTermsCode: 'FOB',
        modeOfTransportAtBorderCode: '1',
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails when FOB + mode=road (3)', () async {
      final d = _buildMinimal(
        deliveryTermsCode: 'FOB',
        modeOfTransportAtBorderCode: '3',
      );
      expect((await rule.evaluate(d) as Fail).message,
          contains('implies sea transport'));
    });

    test('passes FOB with multimodal (9)', () async {
      final d = _buildMinimal(
        deliveryTermsCode: 'FOB',
        modeOfTransportAtBorderCode: '9',
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails when CPT (land) + mode=sea (1)', () async {
      final d = _buildMinimal(
        deliveryTermsCode: 'CPT',
        modeOfTransportAtBorderCode: '1',
      );
      expect((await rule.evaluate(d) as Fail).message,
          contains('implies road transport'));
    });
  });

  // ── Rule 3: HsCodeFormatRule ───────────────────────────────────────
  group('HsCodeFormatRule', () {
    final rule = HsCodeFormatRule();

    test('passes a 10-digit commodity code', () async {
      final d = _buildMinimal(commodityCode: '8541100000');
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails a 5-digit code', () async {
      final d = _buildMinimal(commodityCode: '85411');
      expect((await rule.evaluate(d) as Fail).message,
          contains('6-12 digits'));
    });

    test('fails on generic description "goods"', () async {
      final d = _buildMinimal(
        commodityCode: '8541100000',
        description: 'goods',
      );
      expect((await rule.evaluate(d) as Fail).message,
          contains('too generic'));
    });
  });

  // ── Rule 4: WeightConsistencyRule ──────────────────────────────────
  group('WeightConsistencyRule', () {
    final rule = WeightConsistencyRule();

    test('passes net <= gross with both > 0', () async {
      final d = _buildMinimal(netMass: 9.0, grossMass: 10.5);
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails net > gross', () async {
      final d = _buildMinimal(netMass: 10.5, grossMass: 9.0);
      expect((await rule.evaluate(d) as Fail).message, contains('cannot exceed'));
    });

    test('fails zero weight', () async {
      final d = _buildMinimal(netMass: 0, grossMass: 1);
      expect((await rule.evaluate(d) as Fail).message, contains('must be > 0'));
    });

    test('skips silently when weights are null', () async {
      final d = _buildMinimal();
      expect(await rule.evaluate(d), isA<Pass>());
    });
  });

  // ── Rule 5: CurrencyExchangeRateRule ───────────────────────────────
  group('CurrencyExchangeRateRule', () {
    test('passes when declared rate is within ±10% of the reference', () async {
      final catalog = _FakeTariff(rate: 520.0);
      final rule =
          CurrencyExchangeRateRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(
        invoiceCurrency: 'USD',
        invoiceExchangeRate: 525.0,
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails when declared rate is 20% off', () async {
      final catalog = _FakeTariff(rate: 500.0);
      final rule =
          CurrencyExchangeRateRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(
        invoiceCurrency: 'USD',
        invoiceExchangeRate: 620.0,
      );
      final fail = await rule.evaluate(d) as Fail;
      expect(fail.severity, RuleSeverity.error);
      expect(fail.message, contains('exceeds'));
    });

    test('degrades to warning when RIMM is unreachable', () async {
      final catalog = _FakeTariff(throws: true);
      final rule =
          CurrencyExchangeRateRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(
        invoiceCurrency: 'USD',
        invoiceExchangeRate: 620.0,
      );
      final fail = await rule.evaluate(d) as Fail;
      expect(fail.severity, RuleSeverity.warning);
      expect(fail.message, contains('Unable to verify FX rate'));
    });
  });

  // ── Rule 6: DocumentAttachmentRule ─────────────────────────────────
  group('DocumentAttachmentRule', () {
    test('passes when commercial invoice (380) is attached', () async {
      final rule = DocumentAttachmentRule();
      final d = _buildMinimal(docCodes: ['380']);
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails when 380 is missing', () async {
      final rule = DocumentAttachmentRule();
      final d = _buildMinimal(docCodes: []);
      expect(
        (await rule.evaluate(d) as Fail).message,
        contains('380'),
      );
    });

    test('requires extra codes when configured', () async {
      final rule = DocumentAttachmentRule(extraRequiredCodes: {'705'});
      final d = _buildMinimal(docCodes: ['380']);
      expect(
        (await rule.evaluate(d) as Fail).message,
        contains('705'),
      );
    });
  });

  // ── Rule 7: ValueDeclarationRule ──────────────────────────────────
  group('ValueDeclarationRule', () {
    final rule = ValueDeclarationRule(
      baseline: {'854110': (mean: 5.0, stdDev: 1.0)},
    );

    test('passes within 2σ', () async {
      final d = _buildMinimal(
        commodityCode: '8541100000',
        cif: 50.0, // 5.0 USD/kg at 10kg
        netMass: 10.0,
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('warns outside 2σ', () async {
      final d = _buildMinimal(
        commodityCode: '8541100000',
        cif: 200.0, // 20.0 USD/kg — way outside band [3, 7]
        netMass: 10.0,
      );
      final fail = await rule.evaluate(d) as Fail;
      expect(fail.severity, RuleSeverity.warning);
      expect(fail.message, contains('outside'));
    });

    test('skips silently when no baseline is available', () async {
      final blankRule = ValueDeclarationRule();
      final d = _buildMinimal(
        commodityCode: '8541100000',
        cif: 1e6,
        netMass: 1.0,
      );
      expect(await blankRule.evaluate(d), isA<Pass>());
    });
  });

  // ── Rule 8: CountryOriginRule ─────────────────────────────────────
  group('CountryOriginRule', () {
    final rule = CountryOriginRule();

    test('passes a plausible origin (LED from CN)', () async {
      final d = _buildMinimal(
        commodityCode: '8541100000',
        countryOfOrigin: 'CN',
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('warns on an implausible origin (LED from CR)', () async {
      final d = _buildMinimal(
        commodityCode: '8541100000',
        countryOfOrigin: 'CR',
      );
      final fail = await rule.evaluate(d) as Fail;
      expect(fail.severity, RuleSeverity.warning);
      expect(fail.message, contains('unusual'));
    });

    test('skips when HS prefix has no reference', () async {
      final d = _buildMinimal(
        commodityCode: '9999999999', // no baseline
        countryOfOrigin: 'XX',
      );
      expect(await rule.evaluate(d), isA<Pass>());
    });
  });

  // ── Rule 9: TariffCodeExistsRule ──────────────────────────────────
  group('TariffCodeExistsRule', () {
    test('passes when the code exists and is currently valid', () async {
      final catalog = _FakeTariff(
        entry: CommodityEntry(
          code: '8541100000',
          hsCode: '854110',
          description: 'LED diodes',
          validFromDate: DateTime.utc(2020, 1, 1),
          validToDate: DateTime.utc(2030, 1, 1),
        ),
      );
      final rule =
          TariffCodeExistsRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(commodityCode: '8541100000');
      expect(await rule.evaluate(d), isA<Pass>());
    });

    test('fails when RIMM returns null for the code', () async {
      final catalog = _FakeTariff(entry: null);
      final rule =
          TariffCodeExistsRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(commodityCode: '8541100000');
      expect((await rule.evaluate(d) as Fail).message,
          contains('does not exist'));
    });

    test('fails on an expired code', () async {
      final catalog = _FakeTariff(
        entry: CommodityEntry(
          code: '8541100000',
          hsCode: '854110',
          description: 'LED',
          validFromDate: DateTime.utc(2020, 1, 1),
          validToDate: DateTime.utc(2025, 1, 1),
        ),
      );
      final rule =
          TariffCodeExistsRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(commodityCode: '8541100000');
      expect((await rule.evaluate(d) as Fail).message, contains('expired'));
    });

    test('fails on a not-yet-valid code', () async {
      final catalog = _FakeTariff(
        entry: CommodityEntry(
          code: '8541100000',
          hsCode: '854110',
          description: 'LED',
          validFromDate: DateTime.utc(2030, 1, 1),
        ),
      );
      final rule =
          TariffCodeExistsRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(commodityCode: '8541100000');
      expect(
        (await rule.evaluate(d) as Fail).message,
        contains('not yet valid'),
      );
    });

    test('degrades to warning on catalog outage', () async {
      final catalog = _FakeTariff(throws: true);
      final rule =
          TariffCodeExistsRule(tariffCatalog: catalog, clock: clock);
      final d = _buildMinimal(commodityCode: '8541100000');
      final fail = await rule.evaluate(d) as Fail;
      expect(fail.severity, RuleSeverity.warning);
    });
  });

  // ── PreValidateDeclarationHandler ──────────────────────────────────
  group('PreValidateDeclarationHandler', () {
    test('runs every rule and collects results', () async {
      final handler = PreValidateDeclarationHandler(
        rules: [RequiredFieldsRule(), HsCodeFormatRule()],
      );
      final report = await handler.handle(
        PreValidateDeclarationQuery(
          declaration: _buildMinimal(commodityCode: '123'),
        ),
      );
      expect(report.results, hasLength(2));
      expect(report.isSubmittable, isFalse);
      expect(report.errors, hasLength(1)); // only HS format fails
    });

    test('short-circuits on first error when configured', () async {
      final handler = PreValidateDeclarationHandler(
        rules: [
          HsCodeFormatRule(), // will fail first
          RequiredFieldsRule(),
        ],
        shortCircuitOnError: true,
      );
      final report = await handler.handle(
        PreValidateDeclarationQuery(
          declaration: _buildMinimal(commodityCode: '123'),
        ),
      );
      expect(report.results, hasLength(1),
          reason:
              'shortCircuitOnError must stop after the first error-level fail.');
    });

    test('toAuditSummary() reports all counts', () async {
      final handler = PreValidateDeclarationHandler(
        rules: [RequiredFieldsRule()],
      );
      final report = await handler
          .handle(PreValidateDeclarationQuery(declaration: _buildMinimal()));
      final summary = report.toAuditSummary();
      expect(summary['ruleCount'], 1);
      expect(summary['errorCount'], 0);
    });
  });
}

// -----------------------------------------------------------------------------
// Fixtures
// -----------------------------------------------------------------------------

Declaration _buildMinimal({
  String exporterCode = '310100580824',
  String declarantCode = '310100975830',
  String officeOfDispatchExportCode = '001',
  String officeOfEntryCode = '002',
  String? deliveryTermsCode,
  String? modeOfTransportAtBorderCode,
  String commodityCode = '8541100000',
  String description = 'LED grow lights 600W full spectrum',
  double? netMass,
  double? grossMass,
  double? cif,
  String countryOfOrigin = 'CN',
  String? invoiceCurrency,
  double? invoiceExchangeRate,
  List<String> docCodes = const [],
}) {
  return Declaration(
    typeOfDeclaration: 'EX',
    generalProcedureCode: '1',
    officeOfDispatchExportCode: officeOfDispatchExportCode,
    officeOfEntryCode: officeOfEntryCode,
    exporterCode: exporterCode,
    declarantCode: declarantCode,
    natureOfTransactionCode1: '1',
    natureOfTransactionCode2: '1',
    documentsReceived: true,
    modeOfTransportAtBorderCode: modeOfTransportAtBorderCode,
    shipping: Shipping(
      countryOfExportCode: 'CR',
      deliveryTermsCode: deliveryTermsCode,
    ),
    sadValuation: SadValuation(
      invoiceCurrencyCode: invoiceCurrency,
      invoiceCurrencyExchangeRate: invoiceExchangeRate,
    ),
    items: [
      DeclarationItem(
        rank: 1,
        commercialDescription: description,
        commodityCode: commodityCode,
        netMass: netMass,
        itemGrossMass: grossMass,
        procedure: ItemProcedure(
          itemCountryOfOriginCode: countryOfOrigin,
          extendedProcedureCode: '1000',
        ),
        itemValuation: ItemValuation(
          costInsuranceFreightAmount: cif,
        ),
        attachedDocuments: docCodes
            .map((c) => AttachedDocument(
                  attachedDocCode: c,
                  attachedDocReference: 'REF',
                ))
            .toList(),
      ),
    ],
  );
}

class _FakeTariff implements TariffCatalogPort {
  final double? rate;
  final CommodityEntry? entry;
  final bool throws;

  const _FakeTariff({this.rate, this.entry, this.throws = false});

  @override
  Future<List<CommodityEntry>> searchCommodities(TariffSearchParams _) async =>
      const [];

  @override
  Future<CommodityEntry?> getCommodityByCode(String code) async {
    if (throws) throw const TariffCatalogException('rimm down');
    return entry;
  }

  @override
  Future<double> getExchangeRate(String ccy, DateTime date) async {
    if (throws) throw const TariffCatalogException('rimm down');
    return rate ?? 520.0;
  }

  @override
  Future<Map<String, dynamic>> getDeliveryTerms(String _) async => const {};

  @override
  Future<Map<String, dynamic>> getCustomsOffice(String _) async => const {};
}
