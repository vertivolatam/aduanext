import 'package:aduanext_mobile/shared/api/dispatch_dto.dart';
import 'package:aduanext_mobile/shared/ui/organisms/dua_rejected_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SizedBox(width: 500, child: child)),
    );

void main() {
  testWidgets('renders ATENA code, message, and Rectificar action',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      DuaRejectedPanel(
        error: const DispatchError(
          code: 'E-VAL-0042',
          message: 'Clasificacion arancelaria no corresponde',
        ),
        onRectify: () => tapped = true,
      ),
    ));

    expect(find.text('Error ATENA: E-VAL-0042'), findsOneWidget);
    expect(
      find.text('Clasificacion arancelaria no corresponde'),
      findsOneWidget,
    );

    await tester.tap(find.text('Rectificar →'));
    expect(tapped, isTrue);
  });

  testWidgets('onRectify null disables the action', (tester) async {
    await tester.pumpWidget(_wrap(
      const DuaRejectedPanel(
        error: DispatchError(code: 'E', message: 'm'),
      ),
    ));

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });
}
