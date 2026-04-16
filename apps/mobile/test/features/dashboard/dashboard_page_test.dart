import 'package:aduanext_mobile/features/dashboard/dashboard_page.dart';
import 'package:aduanext_mobile/features/dashboard/dashboard_providers.dart';
import 'package:aduanext_mobile/shared/api/api_config.dart';
import 'package:aduanext_mobile/shared/api/api_providers.dart';
import 'package:aduanext_mobile/shared/api/fake_api_client.dart';
import 'package:aduanext_mobile/shared/theme/aduanext_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        // Force the fake config so the stream provider swaps in its
        // no-op client — otherwise the real DispatchStreamClient
        // tries to connect to localhost and the test hangs.
        apiConfigProvider.overrideWithValue(
          const ApiConfig(baseUrl: 'http://test', useFake: true),
        ),
        apiClientProvider.overrideWith((ref) {
          final fake =
              FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
          ref.onDispose(fake.close);
          return fake;
        }),
      ],
      child: MaterialApp(
        theme: AduaNextTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('DashboardPage renders KPI row + seeded DUA list',
      (tester) async {
    await tester.pumpWidget(_wrap(const DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Monitoreo DUAs'), findsOneWidget);
    expect(find.text('ACTIVAS'), findsOneWidget);
    expect(find.text('LEVANTE'), findsOneWidget);
    expect(find.text('DUA-2026-1201'), findsOneWidget);
    expect(find.text('DUA-2026-1202'), findsOneWidget);
    expect(find.text('DUA-2026-1203'), findsOneWidget);
  });

  testWidgets('DashboardPage empty state renders when filter yields no rows',
      (tester) async {
    await tester.pumpWidget(_wrap(const DashboardPage()));
    await tester.pumpAndSettle();

    // Narrow to ANNULLED which has no seeded rows; filters push page=0
    // and the provider refetches.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardPage)),
    );
    container.read(dashboardFiltersProvider.notifier).state =
        container.read(dashboardFiltersProvider).copyWith(
      statuses: {
        // The StatusFilterChips.defaultStatuses set doesn't include
        // CANCELLED as a chip, so we use ANNULLED which does appear.
        // Either way, none of the seeds match, so the list is empty.
      },
    );
    // Force empty via an exporter search that matches nothing.
    container.read(dashboardFiltersProvider.notifier).state =
        container.read(dashboardFiltersProvider).copyWith(
              exporterSearch: 'no-such-code',
            );
    await tester.pumpAndSettle();

    expect(
      find.text('No hay DUAs que coincidan con los filtros.'),
      findsOneWidget,
    );
  });
}
