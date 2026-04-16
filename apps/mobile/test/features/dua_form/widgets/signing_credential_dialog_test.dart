import 'package:aduanext_mobile/features/dua_form/widgets/signing_credential_dialog.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SigningCredential?> _openDialog(WidgetTester tester) async {
  SigningCredential? result;
  await tester.pumpWidget(MaterialApp(
    theme: AduaNextTheme.darkTheme,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showDialog<SigningCredential?>(
                context: context,
                builder: (_) => const SigningCredentialDialog(),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('renders software mode by default', (tester) async {
    await _openDialog(tester);

    expect(find.text('Firmar y transmitir'), findsWidgets);
    expect(find.text('Archivo .p12 (nombre)'), findsOneWidget);
    expect(find.text('PIN'), findsOneWidget);
  });

  testWidgets('confirm is disabled until .p12 + PIN are filled',
      (tester) async {
    await _openDialog(tester);

    final confirm = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Firmar y transmitir').last,
    );
    expect(confirm.onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Archivo .p12 (nombre)'),
      'firma.p12',
    );
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'PIN'), '1234');
    await tester.pump();

    final confirmAfter = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Firmar y transmitir').last,
    );
    expect(confirmAfter.onPressed, isNotNull);
  });

  testWidgets('switching to hardware mode reveals Detectar token',
      (tester) async {
    await _openDialog(tester);

    await tester.tap(find.text('Hardware token'));
    await tester.pump();

    expect(find.text('Detectar token'), findsOneWidget);
  });

  testWidgets('detect token emits the token id', (tester) async {
    await _openDialog(tester);
    await tester.tap(find.text('Hardware token'));
    await tester.pump();

    await tester.tap(find.text('Detectar token'));
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('Token detectado: TOKEN-STUB-001'),
      findsOneWidget,
    );
  });
}
