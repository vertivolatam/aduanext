import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:aduanext_mobile/shared/ui/atoms/kpi_card.dart';
import 'package:aduanext_mobile/shared/ui/molecules/kpi_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double width = 900}) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    );

void main() {
  testWidgets('renders four KpiCards', (tester) async {
    await tester.pumpWidget(_wrap(
      const KpiRow(
        summary: KpiSummary(
          activas: 3,
          levante: 1,
          enProceso: 1,
          requiereAccion: 1,
        ),
      ),
    ));

    expect(find.byType(KpiCard), findsNWidgets(4));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('ACTIVAS'), findsOneWidget);
    expect(find.text('LEVANTE'), findsOneWidget);
    expect(find.text('EN PROCESO'), findsOneWidget);
    expect(find.text('REQUIERE ACCIÓN'), findsOneWidget);
  });

  testWidgets('onTap yields null for Activas and the tone for others',
      (tester) async {
    StatusTone? seenTone = StatusTone.gris;
    var activasTapped = false;

    await tester.pumpWidget(_wrap(
      KpiRow(
        summary: const KpiSummary(
          activas: 0,
          levante: 0,
          enProceso: 0,
          requiereAccion: 0,
        ),
        onTap: (tone) {
          if (tone == null) {
            activasTapped = true;
          } else {
            seenTone = tone;
          }
        },
      ),
    ));

    await tester.tap(find.text('LEVANTE'));
    expect(seenTone, StatusTone.verde);
    await tester.tap(find.text('REQUIERE ACCIÓN'));
    expect(seenTone, StatusTone.rojo);
    await tester.tap(find.text('ACTIVAS'));
    expect(activasTapped, isTrue);
  });

  testWidgets('KpiSummary.zero builds without crashing', (tester) async {
    await tester.pumpWidget(_wrap(
      const KpiRow(summary: KpiSummary.zero()),
    ));
    expect(find.byType(KpiCard), findsNWidgets(4));
  });
}
