import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_facturas.dart';
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
  testWidgets('shows empty state when no invoices', (tester) async {
    await tester.pumpWidget(_host(const StepFacturas()));
    await tester.pump();

    expect(find.text('Sin facturas. Agrega al menos una para continuar.'),
        findsOneWidget);
    expect(find.text('Agregar factura'), findsOneWidget);
  });

  testWidgets('Agregar factura appends a row', (tester) async {
    await tester.pumpWidget(_host(const StepFacturas()));
    await tester.pump();

    await tester.tap(find.text('Agregar factura'));
    await tester.pump();

    expect(find.text('Numero de factura'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StepFacturas)),
    );
    expect(container.read(duaFormProvider).invoices, hasLength(1));
  });

  testWidgets('total facturas aggregates invoice amounts', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(invoices: [
      DuaDraftInvoice(
        number: 'F-1',
        issueDate: DateTime.utc(2026, 4, 1),
        supplier: 'Vertivo',
        totalAmount: 300,
      ),
      DuaDraftInvoice(
        number: 'F-2',
        issueDate: DateTime.utc(2026, 4, 2),
        supplier: 'Vertivo',
        totalAmount: 700,
      ),
    ]);

    await tester.pumpWidget(_host(const StepFacturas(),
        store: InMemoryDraftStore(seed)));
    await tester.pump();
    await tester.pump(); // restore

    expect(find.text('TOTAL FACTURAS'), findsOneWidget);
    expect(find.text('1000.00'), findsOneWidget);
  });
}
