import 'package:aduanext_mobile/shared/ui/atoms/hs_code_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HsCodeChip formatea el código HS', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HsCodeChip(code: '8471.30.00.00')),
      ),
    );
    expect(find.byType(HsCodeChip), findsOneWidget);
  });
}
