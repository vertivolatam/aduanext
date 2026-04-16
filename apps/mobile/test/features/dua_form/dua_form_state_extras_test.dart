// Tests for the VRTV-89 additions to DuaDraft (invoices, documents,
// freight, insurance, CIF computation).
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuaDraft totals', () {
    test('totalFob = sum over items of quantity × fobAmount', () {
      final d = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
        items: const [
          DuaDraftLineItem(
            commercialDescription: 'A',
            quantity: 10,
            fobAmount: 100,
          ),
          DuaDraftLineItem(
            commercialDescription: 'B',
            quantity: 5,
            fobAmount: 20,
          ),
        ],
      );
      expect(d.totalFob, 1100);
    });

    test('totalCif = totalFob + freight + insurance', () {
      final d = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
        items: const [
          DuaDraftLineItem(
              commercialDescription: 'A', quantity: 1, fobAmount: 100),
        ],
        freightAmount: 20,
        insuranceAmount: 5,
      );
      expect(d.totalCif, 125);
    });

    test('totalInvoiceAmount sums invoice amounts', () {
      final d = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
        invoices: [
          DuaDraftInvoice(
            number: '1',
            issueDate: DateTime.utc(2026, 4, 1),
            supplier: 'S',
            totalAmount: 100,
          ),
          DuaDraftInvoice(
            number: '2',
            issueDate: DateTime.utc(2026, 4, 1),
            supplier: 'S',
            totalAmount: 250,
          ),
        ],
      );
      expect(d.totalInvoiceAmount, 350);
    });
  });

  group('step5/step6 completeness', () {
    test('step5Complete requires at least one complete invoice', () {
      final d0 = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
      );
      expect(d0.step5Complete, isFalse);

      final d1 = d0.copyWith(invoices: [
        DuaDraftInvoice(
          number: 'F-1',
          issueDate: DateTime.utc(2026, 4, 1),
          supplier: 'Vertivo',
          totalAmount: 100,
        ),
      ]);
      expect(d1.step5Complete, isTrue);
    });

    test('step6Complete requires every required doc to be attached', () {
      final d0 = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
        documents: const [
          DuaDraftDocument(
            code: '380',
            displayName: 'Factura',
            required: true,
          ),
          DuaDraftDocument(
            code: '861',
            displayName: 'Certificado origen',
            required: false,
          ),
        ],
      );
      expect(d0.step6Complete, isFalse);

      final attached = d0.copyWith(documents: [
        d0.documents[0].copyWith(fileName: 'factura.pdf'),
        d0.documents[1],
      ]);
      expect(attached.step6Complete, isTrue);
    });
  });

  group('JSON round-trip for new fields', () {
    test('invoices, documents, freight, insurance survive', () {
      final original = DuaDraft(
        draftId: 'd',
        createdAt: DateTime.utc(2026, 4, 1),
        updatedAt: DateTime.utc(2026, 4, 1),
        freightAmount: 50,
        insuranceAmount: 10,
        invoices: [
          DuaDraftInvoice(
            number: 'F-1',
            issueDate: DateTime.utc(2026, 4, 1),
            supplier: 'Vertivo',
            totalAmount: 100,
          ),
        ],
        documents: const [
          DuaDraftDocument(
            code: '380',
            displayName: 'Factura',
            required: true,
            fileName: 'factura.pdf',
          ),
        ],
      );
      final round = DuaDraft.fromJson(original.toJson().cast<String, dynamic>());
      expect(round.freightAmount, 50);
      expect(round.insuranceAmount, 10);
      expect(round.invoices, hasLength(1));
      expect(round.invoices.first.supplier, 'Vertivo');
      expect(round.documents, hasLength(1));
      expect(round.documents.first.fileName, 'factura.pdf');
    });
  });
}
