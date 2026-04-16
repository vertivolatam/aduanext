import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:aduanext_mobile/shared/ui/atoms/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(width: 200, child: child),
      ),
    );

void main() {
  testWidgets('renders label uppercased + value', (tester) async {
    await tester.pumpWidget(_wrap(
      const KpiCard(label: 'Activas', value: 3),
    ));

    expect(find.text('ACTIVAS'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('loading state renders --- when value is null', (tester) async {
    await tester.pumpWidget(_wrap(
      const KpiCard(label: 'Levante', value: null, tone: StatusTone.verde),
    ));

    expect(find.text('---'), findsOneWidget);
  });

  testWidgets('onTap fires when card is tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      KpiCard(
        label: 'Requiere acción',
        value: 1,
        tone: StatusTone.rojo,
        onTap: () => taps++,
      ),
    ));

    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });

  testWidgets('without onTap there is no InkWell', (tester) async {
    await tester.pumpWidget(_wrap(
      const KpiCard(label: 'Activas', value: 0),
    ));

    expect(find.byType(InkWell), findsNothing);
  });
}
