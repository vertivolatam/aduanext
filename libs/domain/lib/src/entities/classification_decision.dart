/// Entity: ClassificationDecision — an agent's HITL-confirmed tariff
/// classification decision for a single commodity.
///
/// Maps to SOP-B02 ("Clasificacion Arancelaria con HITL"). Every
/// classification is a separate immutable decision — updates never
/// mutate an existing decision; a new [ClassificationDecision] is
/// created instead (append-only pattern, SRD anti-pattern #5).
///
/// Architecture: Domain Entity — pure business object, zero I/O.
///
/// Audit contract: every [ClassificationDecision] creation MUST be
/// logged via [AuditLogPort] with a snapshot payload. See
/// [RecordClassificationHandler] in the application layer.
library;

import 'package:meta/meta.dart';

import '../value_objects/hs_code.dart';

/// An HITL-confirmed classification decision.
@immutable
class ClassificationDecision {
  /// Stable identifier (UUID v4 recommended — generated at construction).
  final String id;

  /// Id of the agent who made the decision (P01: agency, P02: freelance,
  /// or P03: pyme acting under importer-led mode with a contracted
  /// signer). The audit trail uses this as `actorId`.
  final String agentId;

  /// Tenant scope — required for multi-tenant isolation.
  final String tenantId;

  /// HS code confirmed by the agent.
  final HsCode hsCode;

  /// Commercial description of the commodity — must be specific per
  /// DGA manual (point 13 of export procedures). Generic descriptions
  /// ("merchandise", "goods") are rejected upstream by the use case.
  final String commercialDescription;

  /// Whether this decision has been explicitly confirmed by the agent.
  /// Only `confirmed == true` decisions are transmittable to ATENA.
  final bool confirmed;

  /// When the agent confirmed the decision. `null` if not yet confirmed.
  final DateTime? confirmedAt;

  /// DN of the signing certificate that will endorse this decision on
  /// the wire (XAdES-EPES signed DUA payload). Populated at signing time,
  /// not at classification time — may be `null` here.
  final String? signatureSignerDn;

  /// Free-form metadata attached by the caller (e.g. the AI confidence
  /// score, the RAG documents that supported the suggestion, etc.).
  /// Serialized into the audit log so the full decision context is
  /// recoverable later.
  final Map<String, dynamic> metadata;

  /// Timestamp when the decision was first recorded (before confirmation
  /// flow). Always UTC. Distinct from [confirmedAt] because a decision
  /// can exist in `pending` state.
  final DateTime recordedAt;

  const ClassificationDecision({
    required this.id,
    required this.agentId,
    required this.tenantId,
    required this.hsCode,
    required this.commercialDescription,
    required this.recordedAt,
    this.confirmed = false,
    this.confirmedAt,
    this.signatureSignerDn,
    this.metadata = const {},
  });

  /// Returns a snapshot-shaped map suitable for the audit log payload.
  /// Excludes [metadata] keys that start with `_secret_` as a cheap
  /// convention for callers to keep PII out of the trail.
  Map<String, dynamic> toAuditSnapshot() {
    final filteredMetadata = <String, dynamic>{};
    for (final entry in metadata.entries) {
      if (!entry.key.startsWith('_secret_')) {
        filteredMetadata[entry.key] = entry.value;
      }
    }
    return {
      'id': id,
      'agentId': agentId,
      'tenantId': tenantId,
      'hsCode': hsCode.code,
      'commercialDescription': commercialDescription,
      'confirmed': confirmed,
      'confirmedAt': confirmedAt?.toUtc().toIso8601String(),
      'signatureSignerDn': signatureSignerDn,
      'metadata': filteredMetadata,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClassificationDecision) return false;
    return id == other.id &&
        agentId == other.agentId &&
        tenantId == other.tenantId &&
        hsCode == other.hsCode &&
        commercialDescription == other.commercialDescription &&
        confirmed == other.confirmed &&
        confirmedAt == other.confirmedAt &&
        signatureSignerDn == other.signatureSignerDn &&
        recordedAt == other.recordedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        agentId,
        tenantId,
        hsCode,
        commercialDescription,
        confirmed,
        confirmedAt,
        signatureSignerDn,
        recordedAt,
      );

  @override
  String toString() =>
      'ClassificationDecision($id, agent=$agentId, hs=${hsCode.code}, confirmed=$confirmed)';
}
