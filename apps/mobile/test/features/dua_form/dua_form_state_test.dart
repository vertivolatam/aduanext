import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps.dart';
import 'package:flutter_test/flutter_test.dart';

DuaDraft _seed({
  String exporterCode = '',
  String exporterName = '',
  String customsOfficeCode = '',
  List<DuaDraftLineItem> items = const [],
  DuaFormStep currentStep = DuaFormStep.general,
}) =>
    DuaDraft(
      draftId: 'd1',
      createdAt: DateTime.utc(2026, 4, 15),
      updatedAt: DateTime.utc(2026, 4, 15),
      exporterCode: exporterCode,
      exporterName: exporterName,
      customsOfficeCode: customsOfficeCode,
      items: items,
      currentStep: currentStep,
    );

void main() {
  group('DuaDraft step completeness', () {
    test('step1 incomplete when any general field is blank', () {
      expect(_seed().step1Complete, isFalse);
      expect(
        _seed(
          exporterCode: '3101',
          exporterName: 'Vertivo',
        ).step1Complete,
        isFalse,
      );
      expect(
        _seed(
          exporterCode: '3101',
          exporterName: 'Vertivo',
          customsOfficeCode: '001',
        ).step1Complete,
        isTrue,
      );
    });

    test('step3 requires at least one complete line item', () {
      final incomplete = _seed(items: const [
        DuaDraftLineItem(commercialDescription: 'LED'),
      ]);
      expect(incomplete.step3Complete, isFalse);

      final complete = _seed(items: const [
        DuaDraftLineItem(
          commercialDescription: 'LED',
          hsCode: '8539.50.0000',
          quantity: 10,
          grossMassKg: 120,
          fobAmount: 8500,
        ),
      ]);
      expect(complete.step3Complete, isTrue);
    });
  });

  group('DuaDraft.isStepUnlocked', () {
    test('current + past steps always unlocked', () {
      final d = _seed(currentStep: DuaFormStep.items);
      expect(d.isStepUnlocked(DuaFormStep.general), isTrue);
      expect(d.isStepUnlocked(DuaFormStep.items), isTrue);
    });

    test('future step unlocked only when all prior are complete', () {
      final d = _seed(
        exporterCode: '3101',
        exporterName: 'Vertivo',
        customsOfficeCode: '001',
        currentStep: DuaFormStep.general,
      );
      // Step 2 requires step 1 complete (it is) → unlocked.
      expect(d.isStepUnlocked(DuaFormStep.shipping), isTrue);
      // Step 3 requires step 2 complete (it isn't) → locked.
      expect(d.isStepUnlocked(DuaFormStep.items), isFalse);
    });
  });

  group('DuaDraft JSON round-trip', () {
    test('survives serialization', () {
      final original = _seed(
        exporterCode: '310100580824',
        exporterName: 'Vertivo S.A.',
        customsOfficeCode: '001',
        items: const [
          DuaDraftLineItem(
            commercialDescription: 'LED',
            hsCode: '8539.50.0000',
            quantity: 10,
            grossMassKg: 120,
            fobAmount: 8500,
          ),
        ],
        currentStep: DuaFormStep.items,
      );

      final json = original.toJson();
      final restored = DuaDraft.fromJson(json.cast<String, dynamic>());

      expect(restored.exporterCode, original.exporterCode);
      expect(restored.items, hasLength(1));
      expect(restored.items.first.hsCode, '8539.50.0000');
      expect(restored.currentStep, DuaFormStep.items);
    });
  });

  group('DuaFormStep navigation', () {
    test('previous + next helpers cover edges', () {
      expect(DuaFormStep.general.previous, isNull);
      expect(DuaFormStep.general.next, DuaFormStep.shipping);
      expect(DuaFormStep.review.next, isNull);
      expect(DuaFormStep.review.previous, DuaFormStep.documents);
    });
  });
}
