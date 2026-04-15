/// Legal hold — pauses retention purges for a specific entity.
///
/// Used when a fiscalizacion (DGA audit) or judicial proceeding is
/// pending. While a hold is active, the retention worker MUST skip
/// the entity even if its `expires_at` is in the past. The hold is
/// released when the proceeding ends; from that moment the normal
/// retention window resumes (using the original `created_at`, NOT the
/// hold release date — the worker simply re-evaluates expiry next
/// pass).
///
/// Holds are tenant-scoped and entity-scoped (entityType + entityId).
/// A hold on `('Declaration', 'DUA-2025-001')` does NOT shield other
/// declarations or other entity types from purge.
library;

import 'package:meta/meta.dart';

@immutable
class LegalHold {
  /// Tenant the held entity belongs to.
  final String tenantId;

  /// Entity type — matches `AuditEvent.entityType`.
  final String entityType;

  /// Entity id — matches `AuditEvent.entityId`.
  final String entityId;

  /// Free-form reason ("DGA case 2026-0042"). Audit-logged by the port.
  final String reason;

  /// Actor id of the user who set the hold. Audited.
  final String setByActorId;

  /// When the hold was created (UTC).
  final DateTime setAt;

  /// When the hold was released (UTC). `null` while the hold is active.
  final DateTime? releasedAt;

  /// Actor id of the user who released the hold. `null` while active.
  final String? releasedByActorId;

  const LegalHold({
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.reason,
    required this.setByActorId,
    required this.setAt,
    this.releasedAt,
    this.releasedByActorId,
  });

  /// `true` iff the hold is active at [now].
  bool isActiveAt(DateTime now) {
    final released = releasedAt;
    if (released == null) return true;
    return now.toUtc().isBefore(released.toUtc());
  }

  LegalHold copyWithRelease({
    required String releasedByActorId,
    required DateTime releasedAt,
  }) {
    return LegalHold(
      tenantId: tenantId,
      entityType: entityType,
      entityId: entityId,
      reason: reason,
      setByActorId: setByActorId,
      setAt: setAt,
      releasedAt: releasedAt,
      releasedByActorId: releasedByActorId,
    );
  }

  @override
  String toString() => 'LegalHold($tenantId, $entityType, $entityId, '
      '${releasedAt == null ? "active" : "released $releasedAt"})';
}
