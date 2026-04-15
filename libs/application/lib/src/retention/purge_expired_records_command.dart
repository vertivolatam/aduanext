/// `PurgeExpiredRecordsCommand` — fire-and-forget command issued by
/// the retention worker. Walks each registered [RetentionPurgeablePort],
/// archives every expired record (skipping legal holds), purges, and
/// records a tombstone audit event.
///
/// The command is intentionally minimal — its only input is `now()`
/// because every retention threshold is computed against that. Tests
/// inject a fake clock to drive scenarios without `Future.delayed`.
library;

import 'package:meta/meta.dart';

import '../shared/command.dart';

/// Outcome of a single retention worker run.
@immutable
class PurgeReport {
  /// Per-category statistics keyed by `RetentionCategory.name`.
  final Map<String, PurgeCategoryStats> byCategory;

  /// Total records archived (sum of [PurgeCategoryStats.archived]).
  int get totalArchived =>
      byCategory.values.fold(0, (sum, s) => sum + s.archived);

  /// Total records purged from live storage.
  int get totalPurged =>
      byCategory.values.fold(0, (sum, s) => sum + s.purged);

  /// Total records skipped because of an active legal hold.
  int get totalHeld =>
      byCategory.values.fold(0, (sum, s) => sum + s.heldByLegal);

  const PurgeReport({required this.byCategory});

  PurgeReport.empty() : byCategory = const {};
}

@immutable
class PurgeCategoryStats {
  final int candidates;
  final int archived;
  final int purged;
  final int heldByLegal;
  final int errors;

  const PurgeCategoryStats({
    required this.candidates,
    required this.archived,
    required this.purged,
    required this.heldByLegal,
    required this.errors,
  });

  Map<String, int> toJson() => {
        'candidates': candidates,
        'archived': archived,
        'purged': purged,
        'held_by_legal': heldByLegal,
        'errors': errors,
      };
}

class PurgeExpiredRecordsCommand extends Command<PurgeReport> {
  final DateTime now;

  /// Cap on records purged per category per run. Bounds memory + I/O
  /// when the worker catches up after a long downtime.
  final int batchSize;

  const PurgeExpiredRecordsCommand({
    required this.now,
    this.batchSize = 100,
  });
}
