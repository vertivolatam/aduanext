/// Port: Audit Log — immutable append-only audit trail.
///
/// Every classification decision, declaration submission, and state transition
/// is recorded for compliance with Ley 7557 control-a-posteriori requirements.
/// Records must be tamper-evident (hash-chained).
library;

/// An audit event to be logged.
class AuditEvent {
  final String entityType;
  final String entityId;
  final String action;
  final String actorId;
  final String tenantId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const AuditEvent({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.actorId,
    required this.tenantId,
    required this.payload,
    required this.timestamp,
  });
}

/// Port: Audit Log — append-only, tamper-evident audit trail.
abstract class AuditLogPort {
  /// Append an event to the audit log. Returns the checksum.
  Future<String> append(AuditEvent event);

  /// Query audit events for an entity.
  Future<List<AuditEvent>> queryByEntity(String entityType, String entityId);

  /// Verify the integrity of the audit chain for an entity.
  Future<bool> verifyChainIntegrity(String entityType, String entityId);
}
