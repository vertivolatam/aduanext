import 'package:aduanext_mobile/features/dua_form/dua_form_state.dart';
import 'package:aduanext_mobile/features/dua_form/widgets/item_row.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AduaNextTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders the item index chip + core fields', (tester) async {
    await tester.pumpWidget(_host(
      ItemRow(
        index: 0,
        item: const DuaDraftLineItem(),
        onChanged: (_) {},
        onRemove: () {},
      ),
    ));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Descripcion comercial'), findsOneWidget);
    expect(find.text('Cantidad'), findsOneWidget);
    expect(find.text('Masa bruta (kg)'), findsOneWidget);
    expect(find.text('FOB (unitario)'), findsOneWidget);
    expect(find.text('Sin clasificar'), findsOneWidget);
  });

  testWidgets('shows Clasificar button when callback is provided',
      (tester) async {
    await tester.pumpWidget(_host(
      ItemRow(
        index: 0,
        item: const DuaDraftLineItem(),
        onChanged: (_) {},
        onRemove: () {},
        onRequestClassify: (d) async => '8539.50.0000',
      ),
    ));
    await tester.pump();

    expect(find.text('Clasificar con RIMM'), findsOneWidget);
  });

  testWidgets('edits are surfaced to onChanged', (tester) async {
    DuaDraftLineItem? latest;
    await tester.pumpWidget(_host(
      ItemRow(
        index: 0,
        item: const DuaDraftLineItem(),
        onChanged: (next) => latest = next,
        onRemove: () {},
      ),
    ));
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Descripcion comercial'),
      'LED 50W',
    );
    await tester.pump();

    expect(latest, isNotNull);
    expect(latest!.commercialDescription, 'LED 50W');
  });

  testWidgets('classifier callback pushes the hsCode onto the item',
      (tester) async {
    DuaDraftLineItem? latest;
    await tester.pumpWidget(_host(
      ItemRow(
        index: 0,
        item: const DuaDraftLineItem(commercialDescription: 'LED'),
        onChanged: (next) => latest = next,
        onRemove: () {},
        onRequestClassify: (_) async => '8539.50.0000',
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Clasificar con RIMM'));
    await tester.pump();
    await tester.pump(); // let the future resolve

    expect(latest, isNotNull);
    expect(latest!.hsCode, '8539.50.0000');
  });
}
