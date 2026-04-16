import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:aduanext_mobile/features/dashboard/dashboard_filters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardFilters', () {
    test('default has no active filter', () {
      const f = DashboardFilters();
      expect(f.hasActiveFilter, isFalse);
    });

    test('statuses trigger hasActiveFilter', () {
      const f = DashboardFilters(statuses: {DeclarationStatus.levante});
      expect(f.hasActiveFilter, isTrue);
    });

    test('exporter search triggers hasActiveFilter', () {
      const f = DashboardFilters(exporterSearch: 'Vertivo');
      expect(f.hasActiveFilter, isTrue);
    });

    test('copyWith preserves untouched fields', () {
      const f = DashboardFilters(
        statuses: {DeclarationStatus.levante},
        riskScoreMin: 30,
      );
      final next = f.copyWith(exporterSearch: 'Vertivo');
      expect(next.statuses, {DeclarationStatus.levante});
      expect(next.riskScoreMin, 30);
      expect(next.exporterSearch, 'Vertivo');
    });

    test('clearRiskScoreMin wipes the lower bound', () {
      const f = DashboardFilters(riskScoreMin: 30, riskScoreMax: 80);
      final next = f.copyWith(clearRiskScoreMin: true);
      expect(next.riskScoreMin, isNull);
      expect(next.riskScoreMax, 80);
    });

    test('equality holds for identical filters', () {
      const a = DashboardFilters(
        statuses: {DeclarationStatus.levante, DeclarationStatus.rejected},
        exporterSearch: 'x',
      );
      const b = DashboardFilters(
        statuses: {DeclarationStatus.rejected, DeclarationStatus.levante},
        exporterSearch: 'x',
      );
      expect(a, equals(b));
    });
  });

  group('DashboardDateRange', () {
    test('last7Days yields a date 7 days before now (UTC)', () {
      final now = DateTime.utc(2026, 4, 15, 12);
      final cutoff = DashboardDateRange.last7Days.computeCreatedAfter(now);
      expect(cutoff, DateTime.utc(2026, 4, 8, 12));
    });

    test('anyTime returns null', () {
      final now = DateTime.utc(2026, 4, 15, 12);
      expect(
        DashboardDateRange.anyTime.computeCreatedAfter(now),
        isNull,
      );
    });
  });
}
