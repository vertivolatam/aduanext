import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:aduanext_mobile/shared/ui/atoms/risk_score_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('RiskScoreBadge.toneForScore', () {
    test('75+ is critical (rojo)', () {
      expect(RiskScoreBadge.toneForScore(75), StatusTone.rojo);
      expect(RiskScoreBadge.toneForScore(99), StatusTone.rojo);
    });
    test('50-74 and 25-49 are amber', () {
      expect(RiskScoreBadge.toneForScore(50), StatusTone.amber);
      expect(RiskScoreBadge.toneForScore(73), StatusTone.amber);
      expect(RiskScoreBadge.toneForScore(25), StatusTone.amber);
    });
    test('0-24 is verde', () {
      expect(RiskScoreBadge.toneForScore(0), StatusTone.verde);
      expect(RiskScoreBadge.toneForScore(24), StatusTone.verde);
    });
  });

  testWidgets('renders "Risk: N" by default', (tester) async {
    await tester.pumpWidget(_wrap(const RiskScoreBadge(score: 45)));
    expect(find.text('Risk: 45'), findsOneWidget);
  });

  testWidgets('compact variant drops the prefix', (tester) async {
    await tester.pumpWidget(_wrap(
      const RiskScoreBadge(score: 18, compact: true),
    ));
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Risk: 18'), findsNothing);
  });

  testWidgets('null score renders em-dash', (tester) async {
    await tester.pumpWidget(_wrap(const RiskScoreBadge(score: null)));
    expect(find.text('Risk: —'), findsOneWidget);
  });
}
