import 'package:aduanext_mobile/shared/ui/atoms/hs_code_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('HsCodeChip.format', () {
    test('passes through already-dotted codes', () {
      expect(HsCodeChip.format('8539.50.0000'), '8539.50.0000');
    });

    test('dots 10-digit codes into XXXX.XX.XXXX', () {
      expect(HsCodeChip.format('8539500000'), '8539.50.0000');
    });

    test('dots 6-digit codes into XXXX.XX', () {
      expect(HsCodeChip.format('853950'), '8539.50');
    });

    test('dots 8-digit codes into XXXX.XX.XX', () {
      expect(HsCodeChip.format('85395000'), '8539.50.00');
    });

    test('strips non-digit characters', () {
      expect(HsCodeChip.format('8539.50.0000'), '8539.50.0000');
      expect(HsCodeChip.format('8539abc500000'), '8539.50.0000');
    });

    test('leaves short codes untouched', () {
      expect(HsCodeChip.format('85'), '85');
    });
  });

  testWidgets('renders formatted code', (tester) async {
    await tester.pumpWidget(_wrap(
      const HsCodeChip(code: '8539500000'),
    ));
    expect(find.text('8539.50.0000'), findsOneWidget);
  });
}
