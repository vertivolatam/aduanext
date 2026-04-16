import 'package:aduanext_mobile/features/classifier/classification_dto.dart';
import 'package:aduanext_mobile/features/classifier/classifier_drawer.dart';
import 'package:aduanext_mobile/features/classifier/classifier_providers.dart';
import 'package:aduanext_mobile/features/classifier/classification_client.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget drawer) {
  return ProviderScope(
    overrides: [
      classificationClientProvider.overrideWith((ref) {
        final fake = FakeClassificationClient();
        ref.onDispose(fake.close);
        return fake;
      }),
    ],
    child: MaterialApp(
      theme: AduaNextTheme.darkTheme,
      home: Scaffold(
        endDrawer: drawer,
        body: const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  final state = tester.state<ScaffoldState>(find.byType(Scaffold).first);
  state.openEndDrawer();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search submit populates suggestion cards', (tester) async {
    ClassifierConfirmation? confirmed;

    await tester.pumpWidget(_host(
      ClassifierDrawer(
        contextLabel: 'Item 3: Reflector',
        initialDescription: 'LED reflector aluminio',
        onConfirm: (r) => confirmed = r,
      ),
    ));

    await _openDrawer(tester);
    expect(find.text('Clasificador RIMM'), findsOneWidget);
    expect(find.text('Item 3: Reflector'), findsOneWidget);

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('RECOMENDADO'), findsOneWidget);
    expect(find.text('8539.50.0000'), findsOneWidget);
    expect(find.text('7616.99.0000'), findsOneWidget);
    expect(find.text('9405.99.0000'), findsOneWidget);

    // Confirm button is disabled until we pick a suggestion.
    final confirmFinder = find.widgetWithText(
      ElevatedButton,
      'Confirmar selección',
    );
    final initialButton = tester.widget<ElevatedButton>(confirmFinder);
    expect(initialButton.onPressed, isNull);

    // Tap the recommended card.
    await tester.tap(find.text('8539.50.0000'));
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<ElevatedButton>(confirmFinder);
    expect(enabledButton.onPressed, isNotNull);

    // Confirm.
    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();

    expect(confirmed, isNotNull);
    expect(confirmed!.suggestion.hsCode, '8539.50.0000');
    expect(confirmed!.mode, ClassificationSearchMode.aiSuggestion);
  });

  testWidgets('empty state renders before any search runs', (tester) async {
    await tester.pumpWidget(_host(
      ClassifierDrawer(onConfirm: (_) {}),
    ));
    await _openDrawer(tester);
    expect(
      find.textContaining('Ingresa la descripción comercial'),
      findsOneWidget,
    );
  });

  testWidgets('Ley 7557 warning shows in the footer', (tester) async {
    await tester.pumpWidget(_host(
      ClassifierDrawer(onConfirm: (_) {}),
    ));
    await _openDrawer(tester);
    expect(find.textContaining('Ley 7557'), findsOneWidget);
  });

  testWidgets('selecting a mode updates the query on next submit',
      (tester) async {
    await tester.pumpWidget(_host(
      ClassifierDrawer(onConfirm: (_) {}),
    ));
    await _openDrawer(tester);

    await tester.tap(find.text('Por HS Code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '8539.50.0000',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    // Query state reflects the picked mode.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    expect(
      container.read(classifierQueryProvider)?.mode,
      ClassificationSearchMode.hsCode,
    );
  });
}
