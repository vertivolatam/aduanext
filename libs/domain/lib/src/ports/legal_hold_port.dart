/// Port: Legal Hold — manages and queries [LegalHold]s.
///
/// Adapters: in-memory (tests / dev), Postgres (production).
library;

import '../retention/legal_hold.dart';

abstract class LegalHoldPort {
  /// Create a new active hold. Throws [StateError] if a hold for the
  /// same `(tenantId, entityType, entityId)` is already active.
  Future<void> place(LegalHold hold);

  /// Release the active hold for the given coordinates. No-op if none.
  Future<void> release({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String releasedByActorId,
    required DateTime releasedAt,
  });

  /// `true` iff there is an active hold for the entity at [now].
  Future<bool> isHeld({
    required String tenantId,
    required String entityType,
    required String entityId,
    required DateTime now,
  });

  /// Read the full history (active + released) for an entity. Used by
  /// the audit-export use case (VRTV-67/68).
  Future<List<LegalHold>> historyFor({
    required String tenantId,
    required String entityType,
    required String entityId,
  });
}
