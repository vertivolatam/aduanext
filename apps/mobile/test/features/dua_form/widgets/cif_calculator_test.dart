import 'package:aduanext_mobile/features/dua_form/widgets/cif_calculator.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AduaNextTheme.darkTheme,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );

void main() {
  testWidgets('sums FOB + freight + insurance to CIF', (tester) async {
    double? freight;
    double? insurance;
    await tester.pumpWidget(_host(
      CifCalculator(
        fobAmount: 1000,
        freightAmount: 50,
        insuranceAmount: 25,
        onFreightChanged: (v) => freight = v,
        onInsuranceChanged: (v) => insurance = v,
        currencyLabel: 'USD',
      ),
    ));
    await tester.pump();

    expect(find.text('CALCULO CIF'), findsOneWidget);
    // CIF = 1000 + 50 + 25 = 1075
    expect(find.text('1075.00 USD'), findsOneWidget);
    // Silence unused warnings
    expect(freight, isNull);
    expect(insurance, isNull);
  });

  testWidgets('emits onFreightChanged on edit', (tester) async {
    double? freight;
    await tester.pumpWidget(_host(
      CifCalculator(
        fobAmount: 100,
        freightAmount: null,
        insuranceAmount: null,
        onFreightChanged: (v) => freight = v,
        onInsuranceChanged: (_) {},
      ),
    ));
    await tester.pump();

    // Enter text in the first TextField (Flete).
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.pump();

    expect(freight, 20);
  });
}
