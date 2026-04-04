import 'package:flutter_test/flutter_test.dart';
import 'package:aduanext_mobile/main.dart';

void main() {
  testWidgets('AduaNext app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AduaNextApp());
    await tester.pumpAndSettle();
    expect(find.text('Exportaciones'), findsOneWidget);
  });
}
