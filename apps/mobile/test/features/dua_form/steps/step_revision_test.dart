import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_revision.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _testRouter = GoRouter(
  initialLocation: '/revision',
  routes: [
    GoRoute(
      path: '/revision',
      builder: (_, _) => const Scaffold(body: StepRevision()),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, _) => const Scaffold(body: Text('DASHBOARD-HOST')),
    ),
  ],
);

Widget _host({DuaDraft? seed}) {
  return ProviderScope(
    overrides: [
      duaDraftStoreProvider.overrideWithValue(
        seed == null ? InMemoryDraftStore() : InMemoryDraftStore(seed),
      ),
    ],
    child: MaterialApp.router(
      theme: AduaNextTheme.darkTheme,
      routerConfig: _testRouter,
    ),
  );
}

void main() {
  testWidgets('empty draft shows risk bar + OK banner', (tester) async {
    // An empty draft hits no rules (no items, CRC default currency,
    // empty docs list) so pre-validation reports zero findings and
    // the OK banner shows.
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.text('RIESGO ESTIMADO'), findsOneWidget);
    expect(find.text('RESUMEN DE LA DECLARACION'), findsOneWidget);
    expect(find.text('Pre-validacion OK. Listo para firmar y transmitir.'),
        findsOneWidget);
  });

  testWidgets('complete draft shows OK banner', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(
      exporterCode: '310100',
      exporterName: 'Vertivo',
      customsOfficeCode: '001',
      transportModeCode: '4',
      incotermCode: 'FCA',
      countryOfOriginCode: 'CRI',
      countryOfDestinationCode: 'USA',
      items: const [
        DuaDraftLineItem(
          commercialDescription: 'LED',
          hsCode: '8539.50',
          quantity: 10,
          grossMassKg: 5,
          fobAmount: 100,
        ),
      ],
      invoiceCurrencyCode: 'USD',
      exchangeRate: 500,
      freightAmount: 50,
      insuranceAmount: 20,
      invoices: [
        DuaDraftInvoice(
          number: 'F-1',
          issueDate: DateTime.utc(2026, 4, 1),
          supplier: 'Vertivo',
          totalAmount: 1000,
          currencyCode: 'USD',
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

    await tester.pumpWidget(_host(seed: seed));
    await tester.pump();
    await tester.pump(); // restore

    expect(find.text('Pre-validacion OK. Listo para firmar y transmitir.'),
        findsOneWidget);
  });

  testWidgets('renders Firmar y transmitir button', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.text('Firmar y transmitir'), findsOneWidget);
  });
}
