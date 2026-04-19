/// Command: TransitionDeclarationStatus — drive the [DeclarationStatus]
/// state machine for a single declaration.
///
/// Invoked from three contexts:
///
///   1. Inbound ATENA push (`TransitionTrigger.gateway`) — the sidecar
///      receives a status notification and calls this command.
///   2. Scheduled worker (`TransitionTrigger.system`) — e.g. LPCO
///      deadline expiry auto-annulling at 5 days.
///   3. Explicit user action (`TransitionTrigger.user`) — the operator
///      cancelled a draft or confirmed manually via boletin.
///
/// The handler consults [DeclarationStateMachine] for legality,
/// persists via [DeclarationRepositoryPort], appends to
/// [AuditLogPort], and fans out a [NotificationEvent] via
/// [NotificationDispatcherPort] when the transition is user-visible.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import '../shared/command.dart';

/// The command intent. Field semantics match the state machine API —
/// see `DeclarationStateMachine.canTransition`.
@immutable
class TransitionDeclarationStatusCommand
    extends Command<DeclarationStatus> {
  /// Stable declaration id — used both to load the entity and to key
  /// the audit chain.
  final String declarationId;

  /// Tenant scope. Enforced by the handler via [AuthorizationPort].
  final String tenantId;

  /// Target state.
  final DeclarationStatus toStatus;

  /// Who/what is driving this transition.
  final TransitionTrigger trigger;

  /// Id of the user / system actor. For gateway triggers, callers pass
  /// a sentinel like `atena-gateway` or the push-notification id.
  final String actorId;

  /// Short free-form note to attach to the audit payload (e.g. "ATENA
  /// push id=xyz", "cancelled by user"). Kept optional — default audit
  /// payload is still rich enough to be useful without this.
  final String? note;

  /// Registration metadata optionally propagated to persistence when
  /// the gateway transitions include it (e.g. the first `accepted`
  /// transition carries the ATENA-assigned registration number).
  final String? registrationNumber;
  final String? assessmentSerial;
  final int? assessmentNumber;
  final String? assessmentDate;

  const TransitionDeclarationStatusCommand({
    required this.declarationId,
    required this.tenantId,
    required this.toStatus,
    required this.trigger,
    required this.actorId,
    this.note,
    this.registrationNumber,
    this.assessmentSerial,
    this.assessmentNumber,
    this.assessmentDate,
  });
}
