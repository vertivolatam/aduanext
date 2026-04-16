import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/pre_validation.dart';
import 'package:flutter_test/flutter_test.dart';

DuaDraft _seed({
  List<DuaDraftLineItem> items = const [],
  List<DuaDraftInvoice> invoices = const [],
  List<DuaDraftDocument> documents = const [],
  String? invoiceCurrencyCode,
  double? exchangeRate,
  double? freight,
  double? insurance,
}) =>
    DuaDraft(
      draftId: 'd1',
      createdAt: DateTime.utc(2026, 4, 15),
      updatedAt: DateTime.utc(2026, 4, 15),
      items: items,
      invoices: invoices,
      documents: documents,
      invoiceCurrencyCode: invoiceCurrencyCode,
      exchangeRate: exchangeRate,
      freightAmount: freight,
      insuranceAmount: insurance,
    );

void main() {
  group('preValidate', () {
    test('empty draft surfaces no findings and risk 0', () {
      final r = preValidate(_seed());
      expect(r.findings, isEmpty);
      expect(r.riskScore, 0);
    });

    test('missing HS code on any item raises an error finding', () {
      final r = preValidate(_seed(items: const [
        DuaDraftLineItem(commercialDescription: 'LED'),
      ]));
      expect(r.hasErrors, isTrue);
      expect(r.findings.first.ruleCode, 'HS_CODE_MISSING');
      expect(r.riskScore, greaterThanOrEqualTo(25));
    });

    test('missing exchange rate with USD currency raises an error', () {
      final r = preValidate(_seed(
        invoiceCurrencyCode: 'USD',
      ));
      expect(
        r.findings.any((f) => f.ruleCode == 'MISSING_EXCHANGE_RATE'),
        isTrue,
      );
    });

    test('missing required doc raises an error with attached names', () {
      final r = preValidate(_seed(documents: const [
        DuaDraftDocument(
          code: '380',
          displayName: 'Factura comercial',
          required: true,
        ),
      ]));
      final finding =
          r.findings.firstWhere((f) => f.ruleCode == 'MISSING_REQUIRED_DOCS');
      expect(finding.description, contains('Factura comercial'));
      expect(finding.severity, PreValidationSeverity.error);
    });

    test('invoice/FOB mismatch > 5% raises a warning', () {
      final r = preValidate(_seed(
        items: const [
          DuaDraftLineItem(
            commercialDescription: 'LED',
            hsCode: '8539.50',
            quantity: 10,
            grossMassKg: 5,
            fobAmount: 100,
          ),
        ],
        // Items FOB = 1000; invoice = 2000 → 100% diff.
        invoices: [
          DuaDraftInvoice(
            number: 'F-1',
            issueDate: DateTime.utc(2026, 4, 1),
            supplier: 'Vertivo',
            totalAmount: 2000,
            currencyCode: 'USD',
          ),
        ],
        invoiceCurrencyCode: 'USD',
        exchangeRate: 500,
      ));
      expect(
        r.findings.any((f) => f.ruleCode == 'INVOICE_FOB_MISMATCH'),
        isTrue,
      );
    });

    test('high value shipment raises a warning', () {
      final r = preValidate(_seed(
        items: const [
          DuaDraftLineItem(
            commercialDescription: 'LED',
            hsCode: '8539.50',
            quantity: 100,
            grossMassKg: 500,
            fobAmount: 600,
          ),
        ],
        invoiceCurrencyCode: 'USD',
        exchangeRate: 500,
      ));
      expect(
        r.findings.any((f) => f.ruleCode == 'HIGH_VALUE_SHIPMENT'),
        isTrue,
      );
    });

    test('risk score is clamped to 100', () {
      final r = preValidate(_seed(
        items: const [DuaDraftLineItem(commercialDescription: 'LED')],
        invoiceCurrencyCode: 'USD',
        documents: const [
          DuaDraftDocument(
            code: '380',
            displayName: 'Factura',
            required: true,
          ),
          DuaDraftDocument(
            code: '705',
            displayName: 'BL',
            required: true,
          ),
        ],
      ));
      expect(r.riskScore, lessThanOrEqualTo(100));
      expect(r.riskScore, greaterThan(0));
    });
  });
}
