/// Command: RecordClassification — record an HITL-confirmed tariff
/// classification decision.
///
/// Maps to SOP-B02 ("Clasificacion Arancelaria con HITL") and closes
/// SRD priority rule #4 (every classification logged in audit trail
/// with SHA-256 hash chain).
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import '../shared/command.dart';

/// Record a tariff classification decision.
///
/// The command carries all the information needed to construct the
/// [ClassificationDecision] entity. The handler is responsible for
/// validating, constructing, and logging.
@immutable
class RecordClassificationCommand
    extends Command<ClassificationDecision> {
  /// Agent performing the classification. Logged as `actorId` in the
  /// audit event.
  final String agentId;

  /// Tenant scope — multi-tenant isolation.
  final String tenantId;

  /// Raw HS code string. Validated by the handler to be 6-12 digits
  /// (matches the domain [HsCode.isValid] contract).
  final String hsCode;

  /// Commercial description of the commodity. Validated to be at least
  /// 5 characters (generic descriptions like "goods" are rejected).
  final String commercialDescription;

  /// Whether the agent has confirmed this decision. Defaults to `true`
  /// because this command is for HITL-confirmed decisions; a pending/
  /// unconfirmed path would use a different command.
  final bool confirmed;

  /// Free-form metadata attached by the caller (AI confidence score,
  /// RAG supporting docs, etc.). Stored in the audit trail.
  final Map<String, dynamic> metadata;

  const RecordClassificationCommand({
    required this.agentId,
    required this.tenantId,
    required this.hsCode,
    required this.commercialDescription,
    this.confirmed = true,
    this.metadata = const {},
  });
}
