import 'package:aduanext_mobile/features/dua_form/widgets/aduana_picker.dart';
import 'package:aduanext_mobile/features/dua_form/widgets/country_picker.dart';
import 'package:aduanext_mobile/features/dua_form/widgets/incoterm_picker.dart';
import 'package:aduanext_mobile/features/dua_form/widgets/transport_mode_picker.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AduaNextTheme.darkTheme,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

Future<void> _openDropdown(WidgetTester tester) async {
  // Taps the visible DropdownButton frame instead of the hint Text, which
  // is wrapped by the underlying decorator and rejects taps.
  await tester.tap(find.byType(DropdownButton<String>));
  await tester.pumpAndSettle();
}

void main() {
  group('AduanaPicker', () {
    testWidgets('emits the selected 3-digit code', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        AduanaPicker(
          selectedCode: null,
          onChanged: (v) => picked = v,
        ),
      ));
      await tester.pump();

      await _openDropdown(tester);
      await tester.tap(find.text('Aduana Limon').last);
      await tester.pumpAndSettle();

      expect(picked, '002');
    });
  });

  group('IncotermPicker', () {
    testWidgets('sea-mode includes FOB/CIF', (tester) async {
      await tester.pumpWidget(_host(
        IncotermPicker(
          selectedCode: null,
          transportModeCode: '1',
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      await _openDropdown(tester);

      expect(find.text('FOB'), findsWidgets);
      expect(find.text('CIF'), findsWidgets);
    });

    testWidgets('aereo mode filters out FOB/CIF', (tester) async {
      await tester.pumpWidget(_host(
        IncotermPicker(
          selectedCode: null,
          transportModeCode: '4', // aereo
          onChanged: (_) {},
        ),
      ));
      await tester.pump();

      await _openDropdown(tester);

      expect(find.text('FOB'), findsNothing);
      expect(find.text('CIF'), findsNothing);
      expect(find.text('FCA'), findsWidgets);
    });
  });

  group('CountryPicker', () {
    testWidgets('emits ISO alpha-3 code', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        CountryPicker(
          label: 'Pais',
          selectedCode: null,
          onChanged: (v) => picked = v,
        ),
      ));
      await tester.pump();

      await _openDropdown(tester);
      await tester.tap(find.text('Costa Rica').last);
      await tester.pumpAndSettle();

      expect(picked, 'CRI');
    });
  });

  group('TransportModePicker', () {
    testWidgets('emits 1-digit code', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(
        TransportModePicker(
          selectedCode: null,
          onChanged: (v) => picked = v,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Maritimo'));
      await tester.pump();

      expect(picked, '1');
    });
  });
}
