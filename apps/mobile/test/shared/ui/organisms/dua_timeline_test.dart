import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/shared/api/dispatch_dto.dart';
import 'package:aduanext_mobile/shared/ui/atoms/timeline_dot.dart';
import 'package:aduanext_mobile/shared/ui/organisms/dua_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DispatchSummary _seed({
  DeclarationStatus status = DeclarationStatus.levante,
  Map<String, DateTime>? stateTimestamps,
}) =>
    DispatchSummary(
      declarationId: 'DUA-1',
      status: status,
      commercialDescription: 'LED',
      exporterCode: 'x',
      officeOfDispatchExportCode: '001',
      stateTimestamps: stateTimestamps ??
          {
            'REGISTERED': DateTime.utc(2026, 3, 28),
            'ACCEPTED': DateTime.utc(2026, 3, 28),
            'VALIDATING': DateTime.utc(2026, 3, 29),
            'PAYMENT_PENDING': DateTime.utc(2026, 3, 29),
            'LEVANTE': DateTime.utc(2026, 3, 30),
          },
      lastUpdatedAt: DateTime.utc(2026, 4, 1),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(width: 600, child: child),
      ),
    );

void main() {
  testWidgets('expanded variant renders 6 steps with labels', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaTimeline(dispatch: _seed()),
    ));

    expect(find.byType(TimelineDot), findsNWidgets(6));
    expect(find.text('Registro'), findsOneWidget);
    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Validada'), findsOneWidget);
    expect(find.text('Pagada'), findsOneWidget);
    expect(find.text('Levante'), findsOneWidget);
    expect(find.text('Confirmada'), findsOneWidget);
  });

  testWidgets('compact variant renders 6 dots, no labels', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaTimeline(
        dispatch: _seed(),
        variant: TimelineVariant.compact,
      ),
    ));

    expect(find.byType(TimelineDot), findsNWidgets(6));
    expect(find.text('Registro'), findsNothing);
  });

  testWidgets('future dates render as em-dash', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaTimeline(
        dispatch: _seed(
          status: DeclarationStatus.validating,
          stateTimestamps: {
            'REGISTERED': DateTime.utc(2026, 3, 28),
            'ACCEPTED': DateTime.utc(2026, 3, 28),
            'VALIDATING': DateTime.utc(2026, 3, 29),
          },
        ),
      ),
    ));

    // Three states populated → three formatted dates; three future
    // states → three em-dashes.
    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('draft dispatch renders all dots as future', (tester) async {
    await tester.pumpWidget(_wrap(
      DuaTimeline(
        dispatch: _seed(
          status: DeclarationStatus.draft,
          stateTimestamps: const {},
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('—'), findsNWidgets(6));
  });
}
