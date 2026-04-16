/// Immutable filter state for the DashboardPage.
///
/// Captured as a value object so Riverpod providers emit a fresh
/// snapshot on every change — widgets `watch` the filter once and
/// re-render without diffing individual fields.
library;

import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:meta/meta.dart';

/// Preset windows for the date-range filter. "Custom" lets a future
/// date picker UI bind arbitrary start/end dates without bloating
/// this enum.
enum DashboardDateRange {
  last7Days('Últimos 7 días', 7),
  last30Days('Últimos 30 días', 30),
  last90Days('Últimos 90 días', 90),
  anyTime('Todo el tiempo', null);

  final String displayName;
  final int? days;

  const DashboardDateRange(this.displayName, this.days);

  DateTime? computeCreatedAfter(DateTime now) {
    final d = days;
    if (d == null) return null;
    return now.toUtc().subtract(Duration(days: d));
  }
}

@immutable
class DashboardFilters {
  /// Empty = no status filter.
  final Set<DeclarationStatus> statuses;

  final DashboardDateRange dateRange;

  /// 0-100. Null-ended ranges mean "no bound" — the dashboard page
  /// clamps before sending to the backend.
  final int? riskScoreMin;
  final int? riskScoreMax;

  /// Free-text exporter filter (cédula jurídica OR company name
  /// contains). Empty means "any".
  final String exporterSearch;

  const DashboardFilters({
    this.statuses = const {},
    this.dateRange = DashboardDateRange.last30Days,
    this.riskScoreMin,
    this.riskScoreMax,
    this.exporterSearch = '',
  });

  /// True when any filter is active — the DashboardPage uses this to
  /// show a "Limpiar filtros" button.
  bool get hasActiveFilter =>
      statuses.isNotEmpty ||
      dateRange != DashboardDateRange.last30Days ||
      riskScoreMin != null ||
      riskScoreMax != null ||
      exporterSearch.isNotEmpty;

  DashboardFilters copyWith({
    Set<DeclarationStatus>? statuses,
    DashboardDateRange? dateRange,
    int? riskScoreMin,
    int? riskScoreMax,
    String? exporterSearch,
    bool clearRiskScoreMin = false,
    bool clearRiskScoreMax = false,
  }) {
    return DashboardFilters(
      statuses: statuses ?? this.statuses,
      dateRange: dateRange ?? this.dateRange,
      riskScoreMin: clearRiskScoreMin ? null : (riskScoreMin ?? this.riskScoreMin),
      riskScoreMax: clearRiskScoreMax ? null : (riskScoreMax ?? this.riskScoreMax),
      exporterSearch: exporterSearch ?? this.exporterSearch,
    );
  }

  DashboardFilters cleared() => const DashboardFilters();

  @override
  bool operator ==(Object other) =>
      other is DashboardFilters &&
      _setEquals(statuses, other.statuses) &&
      dateRange == other.dateRange &&
      riskScoreMin == other.riskScoreMin &&
      riskScoreMax == other.riskScoreMax &&
      exporterSearch == other.exporterSearch;

  @override
  int get hashCode => Object.hash(
        statuses.length,
        statuses.fold<int>(0, (acc, s) => acc ^ s.hashCode),
        dateRange,
        riskScoreMin,
        riskScoreMax,
        exporterSearch,
      );

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
