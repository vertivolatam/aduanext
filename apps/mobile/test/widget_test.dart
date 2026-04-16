import 'package:aduanext_mobile/main.dart';
import 'package:aduanext_mobile/shared/api/api_config.dart';
import 'package:aduanext_mobile/shared/api/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AduaNext app renders dashboard with fake API', (tester) async {
    // Force the fake API so the test doesn't try to hit an HTTP backend.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigProvider.overrideWithValue(
            const ApiConfig(baseUrl: 'http://test', useFake: true),
          ),
        ],
        child: const AduaNextApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The default route is /dashboard; its header reads "Monitoreo DUAs".
    expect(find.text('Monitoreo DUAs'), findsOneWidget);
    // KPI row uppercase labels render.
    expect(find.text('ACTIVAS'), findsOneWidget);
    // The seeded fake emits 3 dispatches — at least one declarationId visible.
    expect(find.text('DUA-2026-1201'), findsOneWidget);
  });
}
