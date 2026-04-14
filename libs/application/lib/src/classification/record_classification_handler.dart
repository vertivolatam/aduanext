/// Handler for [RecordClassificationCommand].
///
/// Validates the command, constructs the [ClassificationDecision]
/// entity, and logs the decision to the [AuditLogPort] with a snapshot
/// payload. The append is required by SRD priority rule #4 — if the
/// audit append fails, the handler surfaces the infrastructure
/// exception upward (the boundary is responsible for translating).
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:uuid/uuid.dart';

import '../shared/command.dart';
import '../shared/result.dart';
import 'record_classification_command.dart';
import 'record_classification_failure.dart';

/// Handler that records an HITL-confirmed tariff classification.
class RecordClassificationHandler
    implements
        CommandHandler<RecordClassificationCommand,
            ClassificationDecision> {
  /// Audit log port — required (SRD priority rule #4).
  final AuditLogPort auditLog;

  /// UUID generator. Defaulted so production callers can ignore it;
  /// tests override to produce deterministic ids.
  final String Function() _newId;

  /// Clock. Same pattern as [_newId] — defaulted for production,
  /// overridable in tests.
  final DateTime Function() _clock;

  RecordClassificationHandler({
    required this.auditLog,
    String Function()? newId,
    DateTime Function()? clock,
  })  : _newId = newId ?? _defaultUuidGenerator,
        _clock = clock ?? DateTime.now;

  @override
  Future<Result<ClassificationDecision>> handle(
      RecordClassificationCommand command) async {
    // ── Validate ────────────────────────────────────────────────────
    if (command.agentId.isEmpty) {
      return const Result.err(MissingActorFailure(fieldName: 'agentId'));
    }
    if (command.tenantId.isEmpty) {
      return const Result.err(MissingActorFailure(fieldName: 'tenantId'));
    }
    final hs = HsCode(command.hsCode);
    if (!hs.isValid) {
      return Result.err(InvalidHsCodeFailure(command.hsCode));
    }
    if (command.commercialDescription.trim().length < 5) {
      return const Result.err(InvalidDescriptionFailure());
    }

    // ── Construct entity ───────────────────────────────────────────
    final now = _clock().toUtc();
    final decision = ClassificationDecision(
      id: _newId(),
      agentId: command.agentId,
      tenantId: command.tenantId,
      hsCode: hs,
      commercialDescription: command.commercialDescription,
      confirmed: command.confirmed,
      confirmedAt: command.confirmed ? now : null,
      metadata: command.metadata,
      recordedAt: now,
    );

    // ── Audit trail (SRD priority rule #4) ──────────────────────────
    //
    // We do NOT swallow audit failures. If the trail cannot be written,
    // the entire operation fails — the boundary is responsible for
    // translating the infrastructure exception into the right HTTP
    // status.
    await auditLog.append(
      AuditEvent.draft(
        entityType: 'ClassificationDecision',
        entityId: decision.id,
        action: command.confirmed
            ? 'classification.recorded.confirmed'
            : 'classification.recorded.pending',
        actorId: decision.agentId,
        tenantId: decision.tenantId,
        payload: decision.toAuditSnapshot(),
        clientTimestamp: now,
      ),
    );

    return Result.ok(decision);
  }
}

// ── Defaults ──────────────────────────────────────────────────────────

const _uuid = Uuid();

String _defaultUuidGenerator() => _uuid.v4();
