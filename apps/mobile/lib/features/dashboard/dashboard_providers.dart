/// Riverpod providers for the dashboard feature.
///
/// * [dashboardFiltersProvider] — mutable filter state as a
///   `StateProvider` so widgets can bind specific slots (search box,
///   risk-slider, etc.) without re-building the whole tree.
/// * [dispatchesListProvider] — FutureProvider that fetches the
///   dispatch list from [ApiClient] under the current filters. Keyed
///   off [DashboardFilters] + page so pagination triggers a refetch.
/// * [dispatchDetailProvider] — FutureProvider family returning a
///   single dispatch + its audit events. Used by [DuaDetailPage].
/// * [dashboardKpiSummaryProvider] — derived from the list response;
///   counts DUAs per tone (verde / amber / rojo) for the KPI row.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api/api_providers.dart';
import '../../shared/api/dispatch_dto.dart';
import '../../shared/ui/atoms/declaration_status_semaphore.dart'
    show toneForStatus, StatusTone;
import '../../shared/ui/molecules/kpi_row.dart';
import 'dashboard_filters.dart';

/// Current page (0-indexed) for the dashboard list. Resets to 0 on
/// any filter change — the DashboardPage widget hooks the listener.
final dashboardPageProvider = StateProvider<int>((ref) => 0);

/// Mutable filter state. The dashboard UI updates individual slots
/// via `ref.read(dashboardFiltersProvider.notifier).state = ...`.
final dashboardFiltersProvider = StateProvider<DashboardFilters>(
  (ref) => const DashboardFilters(),
);

/// Page size (fixed at 50 per the issue scope). Exposed as a provider
/// so tests can shrink the page to exercise pagination without
/// seeding 50+ dispatches.
final dashboardPageSizeProvider = Provider<int>((ref) => 50);

/// Fetches the current dispatch list. Reacts to filter + page changes
/// via `ref.watch` — swapping the filter refetches automatically.
final dispatchesListProvider = FutureProvider<DispatchListResponse>(
  (ref) async {
    final api = ref.watch(apiClientProvider);
    final filters = ref.watch(dashboardFiltersProvider);
    final page = ref.watch(dashboardPageProvider);
    final pageSize = ref.watch(dashboardPageSizeProvider);
    final now = DateTime.now();

    return api.listDispatches(
      offset: page * pageSize,
      limit: pageSize,
      statusCodes: filters.statuses.map((s) => s.code).toSet(),
      createdAfter: filters.dateRange.computeCreatedAfter(now),
      riskScoreMin: filters.riskScoreMin,
      riskScoreMax: filters.riskScoreMax,
      exporterCode:
          filters.exporterSearch.isEmpty ? null : filters.exporterSearch,
    );
  },
);

/// Parameter for [dispatchDetailProvider].
class DispatchDetailQuery {
  final String declarationId;

  const DispatchDetailQuery(this.declarationId);

  @override
  bool operator ==(Object other) =>
      other is DispatchDetailQuery &&
      other.declarationId == declarationId;

  @override
  int get hashCode => declarationId.hashCode;
}

/// Per-dispatch detail view. Returns both the summary and the audit
/// events so the detail page renders in a single provider listen.
class DispatchDetail {
  final DispatchSummary summary;
  final List<DispatchAuditEvent> auditEvents;

  const DispatchDetail({
    required this.summary,
    required this.auditEvents,
  });
}

final dispatchDetailProvider =
    FutureProvider.family<DispatchDetail, DispatchDetailQuery>(
  (ref, query) async {
    final api = ref.watch(apiClientProvider);
    final summary = await api.getDispatch(query.declarationId);
    // Audit listing may return NotImplementedApiException if the
    // backend doesn't yet expose it — the page handles that via
    // AsyncValue.error on the widget side; here we propagate.
    final audit = await api.listAuditEvents(query.declarationId);
    return DispatchDetail(summary: summary, auditEvents: audit);
  },
);

/// Counts per StatusTone bucket from the current dispatch list.
/// Empty/loading states collapse to zeroed counts so the KPI row
/// renders without flicker.
final dashboardKpiSummaryProvider = Provider<KpiSummary>((ref) {
  final async = ref.watch(dispatchesListProvider);
  final items = async.asData?.value.items ?? const <DispatchSummary>[];
  if (items.isEmpty) return const KpiSummary.zero();

  var verde = 0;
  var amber = 0;
  var rojo = 0;
  for (final d in items) {
    switch (toneForStatus(d.status)) {
      case StatusTone.verde:
        verde++;
      case StatusTone.amber:
        amber++;
      case StatusTone.rojo:
        rojo++;
      case StatusTone.gris:
        break; // Not counted in the "active" totals.
    }
  }
  return KpiSummary(
    activas: verde + amber + rojo,
    levante: verde,
    enProceso: amber,
    requiereAccion: rojo,
  );
});
