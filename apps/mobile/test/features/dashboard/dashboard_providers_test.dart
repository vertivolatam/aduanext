import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:aduanext_mobile/features/dashboard/dashboard_filters.dart';
import 'package:aduanext_mobile/features/dashboard/dashboard_providers.dart';
import 'package:aduanext_mobile/shared/api/api_client.dart';
import 'package:aduanext_mobile/shared/api/api_providers.dart';
import 'package:aduanext_mobile/shared/api/fake_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _buildContainer({FakeApiClient? api}) {
  final fake = api ?? FakeApiClient(now: DateTime.utc(2026, 4, 15, 12));
  return ProviderContainer(
    overrides: [
      apiClientProvider.overrideWith((ref) {
        ref.onDispose(fake.close);
        return fake;
      }),
    ],
  );
}

void main() {
  group('dispatchesListProvider', () {
    test('returns all seeded dispatches with default filters', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final response = await container.read(
        dispatchesListProvider.future,
      );

      expect(response.items, hasLength(3));
    });

    test('refetches when filters change', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final initial =
          await container.read(dispatchesListProvider.future);
      expect(initial.items, hasLength(3));

      // Narrow to rejected only.
      container.read(dashboardFiltersProvider.notifier).state =
          const DashboardFilters(statuses: {DeclarationStatus.rejected});

      final filtered =
          await container.read(dispatchesListProvider.future);
      expect(filtered.items, hasLength(1));
      expect(filtered.items.single.status, DeclarationStatus.rejected);
    });
  });

  group('dashboardKpiSummaryProvider', () {
    test('zero counts while loading', () {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final kpi = container.read(dashboardKpiSummaryProvider);
      expect(kpi.activas, 0);
    });

    test('after load reflects tone buckets', () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      await container.read(dispatchesListProvider.future);
      final kpi = container.read(dashboardKpiSummaryProvider);

      // Seed: 1 levante (verde), 1 validating (amber), 1 rejected (rojo).
      expect(kpi.levante, 1);
      expect(kpi.enProceso, 1);
      expect(kpi.requiereAccion, 1);
      expect(kpi.activas, 3);
    });
  });

  group('dispatchDetailProvider', () {
    test('returns detail with empty audit events when none seeded',
        () async {
      final container = _buildContainer();
      addTearDown(container.dispose);

      final detail = await container.read(
        dispatchDetailProvider(
          const DispatchDetailQuery('DUA-2026-1201'),
        ).future,
      );

      expect(detail.summary.declarationId, 'DUA-2026-1201');
      expect(detail.auditEvents, isEmpty);
    });
  });

  group('ApiClient contract smoke', () {
    test('FakeApiClient implements ApiClient interface', () {
      // Compile-time guard — if FakeApiClient ever drops the contract
      // the assignment fails at build time.
      final ApiClient client = FakeApiClient(
        now: DateTime.utc(2026, 4, 15, 12),
      );
      expect(client, isA<ApiClient>());
    });
  });
}
