import 'package:aduanext_mobile/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AduaNext app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AduaNextApp()));
    await tester.pumpAndSettle();
    expect(find.text('Exportaciones'), findsWidgets);
  });
}
