/// Handler for [TransitionDeclarationStatusCommand].
///
/// Choreography:
///
///   Audit #1: declaration.status.transition-requested
///   ├── load current declaration
///   │   └── Err(DeclarationNotFoundFailure)   — audited as `.failed`
///   ├── state machine canTransition
///   │   └── Err(IllegalTransitionFailure)     — audited as `.denied`
///   ├── persist new status (optimistic)
///   │   └── Err(ConcurrentTransitionFailure)  — audited as `.conflict`
///   Audit #2: declaration.status.transitioned
///   └── fire NotificationEvent (if transition.firesNotification)
///
/// Audit failures propagate as exceptions (SRD rule #4). Dispatcher
/// failures also propagate — the transition succeeded business-wise,
/// but the notification fan-out is part of the same atomic promise
/// and infrastructure teams need to see the fault loudly.
library;

import 'dart:math';

import 'package:aduanext_domain/aduanext_domain.dart';

import '../shared/command.dart';
import '../shared/result.dart';
import 'transition_declaration_status_command.dart';
import 'transition_declaration_status_failure.dart';

/// Produces stable UUID-like ids without pulling the `uuid` package
/// for every single event. We only need uniqueness within a tenant's
/// notification stream — a 128-bit random hex is more than enough.
typedef NotificationIdGenerator = String Function();

String _defaultNotificationIdGenerator() {
  // RFC 4122-ish: 32 random hex chars. Deterministic test seed not
  // necessary — tests inject their own generator when they care.
  final rng = Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buf.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

class TransitionDeclarationStatusHandler
    implements
        CommandHandler<TransitionDeclarationStatusCommand,
            DeclarationStatus> {
  final DeclarationRepositoryPort repository;
  final DeclarationStateMachine stateMachine;
  final AuditLogPort auditLog;
  final NotificationDispatcherPort notifications;

  /// Optional authorization port. When the command carries a user
  /// trigger, we consult this port to enforce the state machine's
  /// role requirement AND the tenant membership. Gateway / system
  /// triggers skip this check (they run under the server's own
  /// identity — outside the request-scoped authorization context).
  final AuthorizationPort? authorization;

  /// Clock (overridable for tests).
  final DateTime Function() _clock;

  final NotificationIdGenerator _idGen;

  TransitionDeclarationStatusHandler({
    required this.repository,
    required this.auditLog,
    required this.notifications,
    DeclarationStateMachine? stateMachine,
    this.authorization,
    DateTime Function()? clock,
    NotificationIdGenerator? idGenerator,
  })  : stateMachine = stateMachine ?? const DeclarationStateMachine(),
        _clock = clock ?? DateTime.now,
        _idGen = idGenerator ?? _defaultNotificationIdGenerator;

  @override
  Future<Result<DeclarationStatus>> handle(
    TransitionDeclarationStatusCommand command,
  ) async {
    // ── Validate command ───────────────────────────────────────────────
    if (command.declarationId.isEmpty) {
      await _audit(
        command,
        'declaration.status.transition-rejected',
        payload: {'reason': 'empty declarationId'},
      );
      return Result.err(
        const InvalidTransitionCommandFailure('empty declarationId'),
      );
    }
    if (command.tenantId.isEmpty) {
      await _audit(
        command,
        'declaration.status.transition-rejected',
        payload: {'reason': 'empty tenantId'},
      );
      return Result.err(
        const InvalidTransitionCommandFailure('empty tenantId'),
      );
    }

    // ── Authorize user triggers ────────────────────────────────────────
    //
    // For user-initiated transitions we ALSO enforce tenant membership
    // via the authorization port (defense in depth — the adapter enforces
    // it at the storage layer via RLS too). Gateway / system callers
    // skip this because they run outside a request context.
    final auth = authorization;
    if (command.trigger == TransitionTrigger.user && auth != null) {
      auth.requireTenant(command.tenantId);
    }

    // ── Audit #1: requested ────────────────────────────────────────────
    final actorRole =
        command.trigger == TransitionTrigger.user && auth != null
            ? auth.currentMembership()?.role
            : null;
    await _audit(
      command,
      'declaration.status.transition-requested',
      payload: _requestedPayload(command, actorRole),
    );

    // ── Load declaration ───────────────────────────────────────────────
    final declaration = await repository.getById(command.declarationId);
    if (declaration == null) {
      await _audit(
        command,
        'declaration.status.transition-failed',
        payload: {
          'reason': 'not-found',
          'toStatus': command.toStatus.code,
        },
      );
      return Result.err(
        DeclarationNotFoundFailure(command.declarationId),
      );
    }

    // ── State machine check ────────────────────────────────────────────
    final check = stateMachine.canTransition(
      from: declaration.status,
      to: command.toStatus,
      trigger: command.trigger,
      actorRole: actorRole,
    );
    if (check is TransitionDenied) {
      await _audit(
        command,
        'declaration.status.transition-denied',
        payload: {
          'fromStatus': declaration.status.code,
          'toStatus': command.toStatus.code,
          'reason': check.reason.name,
          'detail': check.message,
        },
      );
      return Result.err(IllegalTransitionFailure(
        attemptedFrom: declaration.status,
        attemptedTo: command.toStatus,
        reason: check.reason,
        detail: check.message,
      ));
    }
    final allowed = check as TransitionAllowed;
    final transition = allowed.transition;

    // ── Persist with optimistic precondition ───────────────────────────
    try {
      await repository.updateStatus(
        declarationId: command.declarationId,
        expectedPreviousStatus: declaration.status,
        newStatus: command.toStatus,
        registrationNumber: command.registrationNumber,
        assessmentSerial: command.assessmentSerial,
        assessmentNumber: command.assessmentNumber,
        assessmentDate: command.assessmentDate,
      );
    } on ConcurrentDeclarationUpdateException catch (e) {
      await _audit(
        command,
        'declaration.status.transition-conflict',
        payload: {
          'expectedStatus': e.expectedPreviousStatus.code,
          'observedStatus': e.actualStoredStatus.code,
          'toStatus': command.toStatus.code,
        },
      );
      return Result.err(ConcurrentTransitionFailure(
        observedStatus: e.actualStoredStatus,
        attemptedFrom: e.expectedPreviousStatus,
      ));
    }

    // ── Audit #2: transitioned ─────────────────────────────────────────
    if (transition.audits) {
      await _audit(
        command,
        'declaration.status.transitioned',
        payload: {
          'fromStatus': declaration.status.code,
          'toStatus': command.toStatus.code,
          'trigger': command.trigger.name,
          'businessTrigger': transition.trigger,
          'dgaActivity': transition.dgaActivity,
          if (command.note != null) 'note': command.note,
          if (command.registrationNumber != null)
            'registrationNumber': command.registrationNumber,
          if (command.assessmentNumber != null)
            'assessmentNumber': command.assessmentNumber,
          if (actorRole != null) 'actorRole': actorRole.code,
        },
      );
    }

    // ── Notify (if policy says so) ─────────────────────────────────────
    //
    // The state-machine handler does NOT know who the recipients are —
    // that mapping (declaration -> interested users) is a separate
    // concern owned by the notification dispatcher adapter. We pass
    // an empty recipients list and an event-level `declarationId`
    // + tenant so the adapter can resolve the audience at send-time.
    if (transition.firesNotification) {
      await notifications.fire(
        NotificationEvent(
          id: _idGen(),
          type: NotificationEventType.declarationStatusChanged,
          tenantId: command.tenantId,
          declarationId: command.declarationId,
          previousStatus: declaration.status,
          newStatus: command.toStatus,
          recipientUserIds: const <String>[],
          metadata: {
            'businessTrigger': transition.trigger,
            'dgaActivity': transition.dgaActivity,
            if (command.registrationNumber != null)
              'registrationNumber': command.registrationNumber,
          },
          severity: _severityFor(command.toStatus),
          emittedAt: _clock().toUtc(),
        ),
      );
    }

    return Result.ok(command.toStatus);
  }

  Map<String, dynamic> _requestedPayload(
    TransitionDeclarationStatusCommand command,
    Role? actorRole,
  ) {
    return <String, dynamic>{
      'declarationId': command.declarationId,
      'toStatus': command.toStatus.code,
      'trigger': command.trigger.name,
      if (actorRole != null) 'actorRole': actorRole.code,
      if (command.note != null) 'note': command.note,
    };
  }

  Future<void> _audit(
    TransitionDeclarationStatusCommand command,
    String action, {
    required Map<String, dynamic> payload,
  }) {
    return auditLog.append(
      AuditEvent.draft(
        entityType: 'Declaration',
        entityId: command.declarationId,
        action: action,
        actorId: command.actorId,
        tenantId: command.tenantId,
        payload: payload,
        clientTimestamp: _clock().toUtc(),
      ),
    );
  }

  /// Small domain policy: which states map to which severity. The
  /// dispatcher adapter uses this to choose between silent and push
  /// channels. Kept internal to the handler — presentation layers
  /// should NOT re-implement this, they should consume the event.
  NotificationSeverity _severityFor(DeclarationStatus status) {
    return switch (status) {
      DeclarationStatus.rejected ||
      DeclarationStatus.annulled =>
        NotificationSeverity.critical,
      DeclarationStatus.physicalInspection ||
      DeclarationStatus.documentReview ||
      DeclarationStatus.lpcoPending =>
        NotificationSeverity.warning,
      DeclarationStatus.levante ||
      DeclarationStatus.accepted ||
      DeclarationStatus.confirmed ||
      DeclarationStatus.finalConfirmed ||
      DeclarationStatus.departureFull ||
      DeclarationStatus.arrivedAtPort =>
        NotificationSeverity.success,
      _ => NotificationSeverity.info,
    };
  }
}

