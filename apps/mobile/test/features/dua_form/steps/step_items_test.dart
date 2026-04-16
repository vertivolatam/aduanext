import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_items.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {InMemoryDraftStore? store}) {
  return ProviderScope(
    overrides: [
      duaDraftStoreProvider
          .overrideWithValue(store ?? InMemoryDraftStore()),
    ],
    child: MaterialApp(
      theme: AduaNextTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('shows empty state when there are no items', (tester) async {
    await tester.pumpWidget(_host(const StepItems()));
    await tester.pump();

    expect(find.text('Sin items. Pulsa "Agregar item" para empezar.'),
        findsOneWidget);
    expect(find.text('Agregar item'), findsOneWidget);
  });

  testWidgets('tapping Agregar item appends a new empty item',
      (tester) async {
    await tester.pumpWidget(_host(const StepItems()));
    await tester.pump();

    await tester.tap(find.text('Agregar item'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StepItems)),
    );
    expect(container.read(duaFormProvider).items, hasLength(1));
    expect(find.text('Descripcion comercial'), findsOneWidget);
  });

  testWidgets('shows totals when items exist', (tester) async {
    // Seed the store so the provider restores with an item in it.
    final seed = DuaDraft.fresh(
      draftId: 'seed',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(items: const [
      DuaDraftLineItem(
        commercialDescription: 'LED',
        quantity: 10,
        grossMassKg: 50,
        fobAmount: 100,
      ),
    ]);
    final store = InMemoryDraftStore(seed);

    await tester.pumpWidget(_host(const StepItems(), store: store));
    // Two pumps: first to restore from the async load, second to
    // paint the restored state.
    await tester.pump();
    await tester.pump();

    expect(find.text('VALOR FOB TOTAL'), findsOneWidget);
    expect(find.text('MASA BRUTA TOTAL (kg)'), findsOneWidget);
    // `1000.00` appears as both the item subtotal and the grand total.
    expect(find.text('1000.00'), findsNWidgets(2));
  });
}
