import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/steps/step_envio.dart';
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
  testWidgets('renders transport picker + incoterm picker + country pickers',
      (tester) async {
    await tester.pumpWidget(_host(const StepEnvio()));
    await tester.pump();

    expect(find.text('MEDIO DE TRANSPORTE'), findsOneWidget);
    expect(find.text('Incoterm'), findsWidgets);
    expect(find.text('Pais de origen'), findsOneWidget);
    expect(find.text('Pais de destino'), findsOneWidget);
    expect(find.text('Aereo'), findsOneWidget);
    expect(find.text('Maritimo'), findsOneWidget);
  });

  testWidgets('tapping a transport chip writes to state', (tester) async {
    await tester.pumpWidget(_host(const StepEnvio()));
    await tester.pump();

    await tester.tap(find.text('Aereo'));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StepEnvio)),
    );
    expect(container.read(duaFormProvider).transportModeCode, '4');
  });
}
