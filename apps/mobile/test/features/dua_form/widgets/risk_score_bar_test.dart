import 'package:aduanext_mobile/features/dua_form/widgets/risk_score_bar.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AduaNextTheme.darkTheme,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: child)),
  );
}

void main() {
  testWidgets('shows Bajo label when score ≤ 30', (tester) async {
    await tester.pumpWidget(_host(const RiskScoreBar(score: 10)));
    await tester.pump();

    expect(find.text('Bajo'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
  });

  testWidgets('shows Medio label in 31-60 band', (tester) async {
    await tester.pumpWidget(_host(const RiskScoreBar(score: 45)));
    await tester.pump();

    expect(find.text('Medio'), findsOneWidget);
  });

  testWidgets('shows Alto label above 60 and clamps to 100', (tester) async {
    await tester.pumpWidget(_host(const RiskScoreBar(score: 150)));
    await tester.pump();

    expect(find.text('Alto'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
  });
}
