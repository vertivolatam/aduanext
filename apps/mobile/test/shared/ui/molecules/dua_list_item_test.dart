import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/api/dispatch_dto.dart';
import 'package:aduanext_mobile/shared/ui/atoms/declaration_status_semaphore.dart';
import 'package:aduanext_mobile/shared/ui/molecules/dua_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DispatchSummary _seed({
  DeclarationStatus status = DeclarationStatus.levante,
  int? riskScore = 18,
}) =>
    DispatchSummary(
      declarationId: 'DUA-2026-1201',
      status: status,
      commercialDescription: 'LED grow lights 240W',
      exporterCode: '310100580824',
      officeOfDispatchExportCode: '001',
      riskScore: riskScore,
      stateTimestamps: {},
      lastUpdatedAt: DateTime.utc(2026, 4, 10, 12),
    );

Widget _wrap(Widget child, {double width = 500}) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    );

void main() {
  testWidgets('renders declarationId, description, status pill',
      (tester) async {
    await tester.pumpWidget(_wrap(DuaListItem(dispatch: _seed())));

    expect(find.text('DUA-2026-1201'), findsOneWidget);
    expect(find.text('LED grow lights 240W'), findsOneWidget);
    expect(find.text('Levante autorizado'), findsOneWidget);
  });

  testWidgets('hides risk score badge when score is null', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaListItem(dispatch: _seed(riskScore: null)),
    ));

    expect(find.textContaining('Risk:'), findsNothing);
  });

  testWidgets('right-hint and subtitle render', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaListItem(
        dispatch: _seed(),
        rightHint: 'Retiro disponible',
        rightSubtitle: 'Aduana Santamaria',
      ),
    ));

    expect(find.text('Retiro disponible'), findsOneWidget);
    expect(find.text('Aduana Santamaria'), findsOneWidget);
  });

  testWidgets('onTap fires when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      DuaListItem(dispatch: _seed(), onTap: () => taps++),
    ));

    await tester.tap(find.text('DUA-2026-1201'));
    expect(taps, 1);
  });

  testWidgets('footer widget is rendered', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaListItem(
        dispatch: _seed(),
        footer: const ColoredBox(
          color: Color(0xFF000000),
          child: SizedBox(height: 20, child: Text('FOOTER-SLOT')),
        ),
      ),
    ));

    expect(find.text('FOOTER-SLOT'), findsOneWidget);
  });

  testWidgets('highlightTone override applies', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaListItem(
        dispatch: _seed(status: DeclarationStatus.draft),
        highlightTone: StatusTone.verde,
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
