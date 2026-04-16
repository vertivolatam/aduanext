import 'package:aduanext_mobile/features/dua_form/draft_store.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_notifier.dart';
import 'package:aduanext_mobile/features/dua_form/dua_form_page.dart';
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
  testWidgets('renders breadcrumb, title, Guardar + Siguiente', (tester) async {
    await tester.pumpWidget(_host(const DuaFormPage()));
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Nueva DUA'), findsOneWidget);
    // Both header and footer render a "Siguiente" button on step 1.
    expect(find.text('Siguiente'), findsNWidgets(2));
    expect(find.text('Guardar'), findsOneWidget);
    // Step counter in footer.
    expect(find.text('Paso 1 de 7'), findsOneWidget);
  });

  testWidgets('Anterior is disabled on the first step', (tester) async {
    await tester.pumpWidget(_host(const DuaFormPage()));
    await tester.pump();

    final prevButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Anterior'),
    );
    expect(prevButton.onPressed, isNull);
  });

  testWidgets('Siguiente is disabled when next step is locked',
      (tester) async {
    await tester.pumpWidget(_host(const DuaFormPage()));
    await tester.pump();

    // Step 1 is incomplete by default → Step 2 (shipping) is
    // unlocked only when step 1 completes. So Siguiente should be
    // disabled. Actually `isStepUnlocked` for the immediate next
    // is the prior-steps-complete check; with step 1 blank, step 2
    // is locked.
    final nextButtons = tester.widgetList<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Siguiente'),
    );
    for (final b in nextButtons) {
      expect(b.onPressed, isNull);
    }
  });

  testWidgets('stepper semáforo renders 7 numbered bubbles', (tester) async {
    await tester.pumpWidget(_host(const DuaFormPage()));
    await tester.pump();

    for (var i = 1; i <= 7; i++) {
      expect(find.text('$i'), findsOneWidget);
    }
  });
}
