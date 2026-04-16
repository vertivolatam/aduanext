import 'package:aduanext_mobile/shared/ui/atoms/classification_confidence_bar.dart';
import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('toneForConfidence', () {
    test('>= 85 is verde', () {
      expect(ClassificationConfidenceBar.toneForConfidence(85),
          StatusTone.verde);
      expect(ClassificationConfidenceBar.toneForConfidence(100),
          StatusTone.verde);
    });

    test('60–84 is amber', () {
      expect(ClassificationConfidenceBar.toneForConfidence(60),
          StatusTone.amber);
      expect(ClassificationConfidenceBar.toneForConfidence(84),
          StatusTone.amber);
    });

    test('< 60 is rojo', () {
      expect(ClassificationConfidenceBar.toneForConfidence(59),
          StatusTone.rojo);
      expect(ClassificationConfidenceBar.toneForConfidence(0),
          StatusTone.rojo);
    });
  });

  testWidgets('renders CONFIANZA label + percentage', (tester) async {
    await tester.pumpWidget(_wrap(
      const ClassificationConfidenceBar(confidence: 92),
    ));

    expect(find.text('Confianza'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
  });

  testWidgets('clamps out-of-range values to 0-100', (tester) async {
    await tester.pumpWidget(_wrap(
      const ClassificationConfidenceBar(confidence: 150),
    ));
    expect(find.text('100%'), findsOneWidget);

    await tester.pumpWidget(_wrap(
      const ClassificationConfidenceBar(confidence: -5),
    ));
    expect(find.text('0%'), findsOneWidget);
  });
}
