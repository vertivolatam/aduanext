import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/ui/molecules/status_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SizedBox(width: 900, child: child)),
    );

void main() {
  testWidgets('renders one chip per available status', (tester) async {
    await tester.pumpWidget(_wrap(
      StatusFilterChips(
        selected: const {},
        onChanged: (_) {},
      ),
    ));

    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('Registrada'), findsOneWidget);
    expect(find.text('Levante autorizado'), findsOneWidget);
    expect(find.text('Rechazada'), findsOneWidget);
    // Limpiar button is hidden when nothing is selected
    expect(find.text('Limpiar'), findsNothing);
  });

  testWidgets('tapping a chip toggles it into the onChanged set',
      (tester) async {
    Set<DeclarationStatus>? seen;
    await tester.pumpWidget(_wrap(
      StatusFilterChips(
        selected: const {},
        onChanged: (next) => seen = next,
      ),
    ));

    // Horizontal scroll — ensure the chip is on-screen before tapping.
    await tester.ensureVisible(find.text('Rechazada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechazada'));
    expect(seen, {DeclarationStatus.rejected});
  });

  testWidgets('Limpiar appears and clears selection', (tester) async {
    Set<DeclarationStatus>? seen;
    await tester.pumpWidget(_wrap(
      StatusFilterChips(
        selected: const {DeclarationStatus.rejected},
        onChanged: (next) => seen = next,
      ),
    ));

    expect(find.text('Limpiar'), findsOneWidget);
    await tester.ensureVisible(find.text('Limpiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar'));
    expect(seen, isNotNull);
    expect(seen!, isEmpty);
  });
}
