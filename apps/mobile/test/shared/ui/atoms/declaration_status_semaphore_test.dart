import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('toneForStatus', () {
    test('levante family maps to verde', () {
      expect(toneForStatus(DeclarationStatus.levante), StatusTone.verde);
      expect(toneForStatus(DeclarationStatus.confirmed), StatusTone.verde);
      expect(toneForStatus(DeclarationStatus.finalConfirmed),
          StatusTone.verde);
    });

    test('validating/payment_pending family maps to amber', () {
      expect(toneForStatus(DeclarationStatus.validating), StatusTone.amber);
      expect(toneForStatus(DeclarationStatus.paymentPending),
          StatusTone.amber);
      expect(toneForStatus(DeclarationStatus.documentReview),
          StatusTone.amber);
    });

    test('rejected/annulled/cancelled map to rojo', () {
      expect(toneForStatus(DeclarationStatus.rejected), StatusTone.rojo);
      expect(toneForStatus(DeclarationStatus.annulled), StatusTone.rojo);
      expect(toneForStatus(DeclarationStatus.cancelled), StatusTone.rojo);
    });

    test('draft / registered / accepted map to gris', () {
      expect(toneForStatus(DeclarationStatus.draft), StatusTone.gris);
      expect(toneForStatus(DeclarationStatus.registered), StatusTone.gris);
      expect(toneForStatus(DeclarationStatus.accepted), StatusTone.gris);
    });
  });

  group('DeclarationStatusSemaphore widget', () {
    testWidgets('renders displayName by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const DeclarationStatusSemaphore(status: DeclarationStatus.levante),
      ));

      expect(find.text('Levante autorizado'), findsOneWidget);
    });

    testWidgets('labelOverride replaces the displayName', (tester) async {
      await tester.pumpWidget(_wrap(
        const DeclarationStatusSemaphore(
          status: DeclarationStatus.levante,
          labelOverride: 'Levante',
        ),
      ));

      expect(find.text('Levante'), findsOneWidget);
      expect(find.text('Levante autorizado'), findsNothing);
    });

    testWidgets('renders for every StatusTone without overflow',
        (tester) async {
      for (final status in [
        DeclarationStatus.levante,
        DeclarationStatus.validating,
        DeclarationStatus.rejected,
        DeclarationStatus.draft,
      ]) {
        await tester.pumpWidget(_wrap(
          DeclarationStatusSemaphore(status: status),
        ));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
