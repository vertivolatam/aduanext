/// Port: Audit Log — immutable append-only audit trail.
///
/// Every classification decision, declaration submission, and state transition
/// is recorded for compliance with CAUCA Art. 24 and LGA (Ley 7557) Art. 30.
/// Records must be tamper-evident (hash-chained per entity) and serve as
/// legal proof of acts performed by agents and tenants.
library;

import 'package:meta/meta.dart';

/// Kind of payload stored in an audit event.
///
/// * [snapshot]  — full state of the entity at event time (typical for creation
///                 events and periodic checkpoints).
/// * [delta]     — diff describing the fields that changed relative to the
///                 previous snapshot (typical for updates).
enum AuditPayloadType {
  snapshot,
  delta,
}

/// An audit event to be logged.
///
/// Events are immutable once appended. Integrity is guaranteed by
/// [eventHash], which is computed from [previousHash] plus the canonical
/// serialization of the other fields (see
/// `audit_chain_hasher.dart` in `libs/adapters`).
///
/// The hash chain is **per-entity** (keyed by [entityType] + [entityId]).
/// A global checkpoint chain may be layered on top in a future iteration.
@immutable
class AuditEvent {
  /// Domain entity type (e.g. `Declaration`, `Classification`, `User`).
  final String entityType;

  /// Domain entity id (stable within [entityType]).
  final String entityId;

  /// Action being logged (e.g. `created`, `classified`, `signed`, `submitted`).
  final String action;

  /// Id of the actor performing the action (user, system, agent).
  final String actorId;

  /// Tenant scope — required for multi-tenant isolation.
  final String tenantId;

  /// Business payload. Must be JSON-serializable (primitives, `Map`, `List`).
  final Map<String, dynamic> payload;

  /// Legacy timestamp. Kept for backwards compatibility; new code should
  /// prefer [clientTimestamp] / [serverTimestamp].
  ///
  /// When constructed without explicit dual timestamps, this falls back to
  /// [clientTimestamp].
  final DateTime timestamp;

  /// Timestamp captured on the device where the action happened. Always set.
  final DateTime clientTimestamp;

  /// Timestamp captured on the platform (server) once the event syncs.
  /// `null` until the event is persisted server-side (offline-first flows).
  final DateTime? serverTimestamp;

  /// Zero-based position of this event in the per-entity chain.
  /// `0` means the genesis event for ([entityType], [entityId]).
  final int sequenceNumber;

  /// Hash of the previous event in the per-entity chain. For the genesis
  /// event this holds the deterministic genesis hash (see
  /// `AuditChainHasher.genesisHash`).
  final String previousHash;

  /// SHA-256 hash of this event, computed deterministically from
  /// [previousHash], [sequenceNumber], canonical JSON of the event fields
  /// and [clientTimestamp]. Empty string means "not yet computed"
  /// (only valid while the event is being prepared inside an adapter).
  final String eventHash;

  /// Whether [payload] is a full snapshot or a delta relative to the
  /// previous snapshot.
  final AuditPayloadType payloadType;

  const AuditEvent({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.actorId,
    required this.tenantId,
    required this.payload,
    required this.timestamp,
    required this.clientTimestamp,
    required this.sequenceNumber,
    required this.previousHash,
    required this.eventHash,
    required this.payloadType,
    this.serverTimestamp,
  });

  /// Convenience constructor for callers that do not yet know the chain
  /// coordinates. The adapter is expected to populate [sequenceNumber],
  /// [previousHash] and [eventHash] at `append()` time.
  factory AuditEvent.draft({
    required String entityType,
    required String entityId,
    required String action,
    required String actorId,
    required String tenantId,
    required Map<String, dynamic> payload,
    required DateTime clientTimestamp,
    AuditPayloadType payloadType = AuditPayloadType.snapshot,
    DateTime? serverTimestamp,
  }) {
    return AuditEvent(
      entityType: entityType,
      entityId: entityId,
      action: action,
      actorId: actorId,
      tenantId: tenantId,
      payload: payload,
      timestamp: clientTimestamp,
      clientTimestamp: clientTimestamp,
      serverTimestamp: serverTimestamp,
      sequenceNumber: -1,
      previousHash: '',
      eventHash: '',
      payloadType: payloadType,
    );
  }

  /// Returns a copy of this event with chain coordinates filled in.
  /// Used by adapters during `append()`.
  AuditEvent copyWithChain({
    required int sequenceNumber,
    required String previousHash,
    required String eventHash,
    DateTime? serverTimestamp,
  }) {
    return AuditEvent(
      entityType: entityType,
      entityId: entityId,
      action: action,
      actorId: actorId,
      tenantId: tenantId,
      payload: payload,
      timestamp: timestamp,
      clientTimestamp: clientTimestamp,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      sequenceNumber: sequenceNumber,
      previousHash: previousHash,
      eventHash: eventHash,
      payloadType: payloadType,
    );
  }
}

/// Port: Audit Log — append-only, tamper-evident audit trail.
abstract class AuditLogPort {
  /// Append an event to the audit log. Returns the computed `eventHash`.
  ///
  /// The adapter is responsible for:
  /// * assigning the correct [AuditEvent.sequenceNumber],
  /// * wiring [AuditEvent.previousHash] to the last event for
  ///   ([AuditEvent.entityType], [AuditEvent.entityId]),
  /// * computing [AuditEvent.eventHash].
  ///
  /// Out-of-order events (already-assigned `sequenceNumber` that does not
  /// match the next expected one) MUST be rejected.
  Future<String> append(AuditEvent event);

  /// Query audit events for an entity, ordered by ascending sequence number.
  Future<List<AuditEvent>> queryByEntity(String entityType, String entityId);

  /// Verify the integrity of the per-entity chain. Returns `true` iff every
  /// stored event's `eventHash` matches a fresh recomputation and the chain
  /// has no gaps.
  Future<bool> verifyChainIntegrity(String entityType, String entityId);
}
