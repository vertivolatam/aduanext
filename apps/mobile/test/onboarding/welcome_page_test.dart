import 'package:aduanext_mobile/features/onboarding/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WelcomePage', () {
    testWidgets('shows all three role cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: WelcomePage()),
        ),
      );
      expect(find.text('Agente Aduanero'), findsOneWidget);
      expect(find.text('Importador / Pyme'), findsOneWidget);
      expect(find.text('Estudiante / Universidad'), findsOneWidget);
      expect(find.text('Proximamente'), findsNWidgets(2));
    });
  });
}
