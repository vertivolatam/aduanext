import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_documentos.dart';
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
  testWidgets('seeds the baseline checklist on first entry', (tester) async {
    await tester.pumpWidget(_host(const StepDocumentos()));
    // Pump through restore + post-frame seed + rebuild.
    // Cycle multiple frames so: restore() resolves, ref.listen fires,
    // postFrameCallback runs, and the re-render happens.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Baseline docs — factura + lista empaque always required.
    expect(find.text('Factura comercial'), findsOneWidget);
    expect(find.text('Lista de empaque'), findsOneWidget);
    expect(find.text('REQUERIDO'), findsWidgets);
  });

  testWidgets('maritimo transport adds Bill of Lading', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(transportModeCode: '1'); // Maritimo

    await tester.pumpWidget(_host(const StepDocumentos(),
        store: InMemoryDraftStore(seed)));
    // Cycle multiple frames so: restore() resolves, ref.listen fires,
    // postFrameCallback runs, and the re-render happens.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Bill of Lading'), findsOneWidget);
  });

  testWidgets('aereo transport adds Air Waybill', (tester) async {
    final seed = DuaDraft.fresh(
      draftId: 's',
      now: DateTime.utc(2026, 4, 15),
    ).copyWith(transportModeCode: '4'); // Aereo

    await tester.pumpWidget(_host(const StepDocumentos(),
        store: InMemoryDraftStore(seed)));
    // Cycle multiple frames so: restore() resolves, ref.listen fires,
    // postFrameCallback runs, and the re-render happens.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Air Waybill (AWB)'), findsOneWidget);
  });

  testWidgets('warning banner when required docs missing', (tester) async {
    await tester.pumpWidget(_host(const StepDocumentos()));
    // Cycle multiple frames so: restore() resolves, ref.listen fires,
    // postFrameCallback runs, and the re-render happens.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.textContaining('documento(s) requerido(s)'),
      findsOneWidget,
    );
  });
}
