import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_general.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return ProviderScope(
    overrides: [
      duaDraftStoreProvider.overrideWithValue(InMemoryDraftStore()),
    ],
    child: MaterialApp(
      theme: AduaNextTheme.darkTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders exporter + aduana controls', (tester) async {
    await tester.pumpWidget(_host(const StepGeneral()));
    await tester.pump();

    expect(find.text('Cedula juridica exportador'), findsOneWidget);
    expect(find.text('Razon social exportador'), findsOneWidget);
    expect(find.text('Aduana de despacho'), findsWidgets);
  });

  testWidgets('typing in exporter name mutates the notifier', (tester) async {
    await tester.pumpWidget(_host(const StepGeneral()));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Razon social exportador'),
      'Vertivo SA',
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StepGeneral)),
    );
    expect(container.read(duaFormProvider).exporterName, 'Vertivo SA');
  });
}
