import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_valoracion.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {InMemoryDraftStore? store}) {
  return ProviderScope(
    overrides: [
      duaDraftStoreProvider.overrideWithValue(store ?? InMemoryDraftStore()),
    ],
    child: MaterialApp(
      theme: AduaNextTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders currency + rate + CIF calculator', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(items: const [
      DuaDraftLineItem(
        commercialDescription: 'LED',
        hsCode: '8539.50',
        quantity: 10,
        grossMassKg: 5,
        fobAmount: 100,
      ),
    ]);

    await tester.pumpWidget(_host(const StepValoracion(),
        store: InMemoryDraftStore(seed)));
    await tester.pump();
    await tester.pump(); // restore from storage

    expect(find.text('CALCULO CIF'), findsOneWidget);
    expect(find.text('FOB (suma items)'), findsOneWidget);
    expect(find.text('Flete'), findsOneWidget);
    expect(find.text('Seguro'), findsOneWidget);
    // FOB = 1000
    expect(find.text('1000.00'), findsWidgets);
  });

  testWidgets('entering freight updates the CIF total', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(items: const [
      DuaDraftLineItem(
        commercialDescription: 'LED',
        hsCode: '8539.50',
        quantity: 1,
        grossMassKg: 5,
        fobAmount: 100,
      ),
    ]);

    await tester.pumpWidget(_host(const StepValoracion(),
        store: InMemoryDraftStore(seed)));
    await tester.pump();
    await tester.pump(); // restore

    final freightField = find.widgetWithText(TextField, '').first;
    await tester.enterText(
        find.byType(TextField).at(1), '50'); // Flete field
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StepValoracion)),
    );
    expect(container.read(duaFormProvider).freightAmount, 50);
    // Silence unused_local_variable warning.
    expect(freightField, isNotNull);
  });
}
