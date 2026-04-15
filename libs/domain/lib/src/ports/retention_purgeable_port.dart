/// Port: Retention Purgeable — capability mixin implemented by adapters
/// whose data falls under a [RetentionPolicy].
///
/// The retention worker walks each implementer in turn:
///   1. `findExpired(now, batchSize)` — returns a page of purge candidates.
///   2. for each candidate that is NOT under a [LegalHold]:
///      a. archive the entity bytes via [StorageBackendPort];
///      b. `purge(...)` removes the entity from the live store;
///      c. `recordTombstone(...)` appends a final audit event.
///
/// Splitting find / purge / tombstone keeps the worker logic
/// independent of the underlying store and makes each step
/// individually retryable.
library;

import '../retention/retention_policy.dart';

/// One row returned by [RetentionPurgeablePort.findExpired].
class ExpiredRecord {
  final String tenantId;
  final String entityType;
  final String entityId;

  /// When the record was created. Used by the worker to serialise
  /// archive paths (e.g. `.../{tenant}/{year}/...`).
  final DateTime createdAt;

  /// `expires_at` snapshot at query time. Carried so the worker logs
  /// can show *why* the record was eligible.
  final DateTime expiresAt;

  const ExpiredRecord({
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    required this.expiresAt,
  });
}

abstract class RetentionPurgeablePort {
  /// The category this port purges. The worker uses this to look up
  /// the right [RetentionPolicy].
  RetentionCategory get category;

  /// Page through records whose `expires_at` is before [now]. Adapters
  /// MUST honour [batchSize] so the worker can keep memory bounded.
  Future<List<ExpiredRecord>> findExpired({
    required DateTime now,
    int batchSize = 100,
  });

  /// Serialize the entity at the given coordinates to bytes for
  /// archive. Caller (worker) writes the bytes to
  /// [StorageBackendPort] before invoking [purge].
  Future<List<int>> serializeForArchive({
    required String tenantId,
    required String entityType,
    required String entityId,
  });

  /// Delete the live data for [record]. MUST be idempotent — the
  /// worker may call this twice on retry.
  Future<void> purge(ExpiredRecord record);

  /// Append a tombstone audit event preserving chain integrity. The
  /// worker calls this AFTER [purge] succeeds so the chain ends with
  /// a `RetentionPurge` action whose `previous_hash` matches the last
  /// real event.
  ///
  /// Optional — adapters that don't carry their own chain (e.g. session
  /// logs) return `null` and the worker skips the tombstone step.
  Future<void> recordTombstone(ExpiredRecord record) async {
    // Default: no tombstone. Override for chain-bearing adapters.
  }
}
