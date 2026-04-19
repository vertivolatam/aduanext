/// Entity: Declaration State Machine — owns legal status transitions for
/// a [Declaration].
///
/// The `DeclarationStatus` enum already encodes 21 states observed in the
/// ATENA DUA lifecycle (see `value_objects/declaration_status.dart`). What
/// this file adds is the *policy*: which transitions are legal, who may
/// trigger them, and what side-effects each one implies (audit logging,
/// notification firing).
///
/// The transition table is modelled on the official DGA Export Procedures
/// Manual (Oct 2025), Section 6.4, activities 6.4.1 through 6.4.52. Each
/// [StateTransition] is doc-referenced to the exact activity (or range) it
/// encodes — keep the doc reference in sync when the manual is updated.
///
/// Architecture: Domain Entity — pure Dart, zero I/O. The use case
/// `TransitionDeclarationStatusHandler` orchestrates persistence + audit
/// + notification; this file is the policy it consults.
///
/// Ref: docs/references/Procedimientos-Exportacion-ATENA.pdf (section 6.4).
library;

import 'package:meta/meta.dart';

import '../authorization/role.dart';
import '../value_objects/declaration_status.dart';

/// Who (or what) caused a status transition.
///
/// * [system]   — a scheduled job or an inbound ATENA status sync.
/// * [user]     — an authenticated operator (agent, supervisor, admin).
/// * [gateway]  — an inbound ATENA push notification attributable to
///                the customs authority itself.
enum TransitionTrigger { system, user, gateway }

/// A single legal transition in the declaration state machine.
///
/// Transitions are exhaustively enumerated in [DeclarationStateMachine]
/// and consulted by `canTransition` / `apply`.
@immutable
class StateTransition {
  /// Starting state. MUST NOT be equal to [to].
  final DeclarationStatus from;

  /// Destination state.
  final DeclarationStatus to;

  /// Stable label for the business event that causes this transition.
  /// Used as the `action` suffix of the audit event emitted by
  /// `TransitionDeclarationStatusHandler` (e.g. `declaration.status.
  /// atena-accepted`). Kebab-case.
  final String trigger;

  /// Minimum role required when [allowedTriggers] contains
  /// [TransitionTrigger.user]. `null` means "any authenticated user" —
  /// still enforced by the boundary, but no role check in this layer.
  final Role? requiresActorRole;

  /// Which origins may trigger this transition. Most transitions are
  /// system- or gateway-driven (ATENA push); a handful (e.g. cancel,
  /// retry-after-rejection) require an explicit user action.
  final Set<TransitionTrigger> allowedTriggers;

  /// Whether a user-visible notification should be fired on success.
  /// Wired to [DeclarationStatus.triggersNotification] but kept as an
  /// explicit field so per-transition overrides are possible (e.g.
  /// two different paths into `accepted` with different messages).
  final bool firesNotification;

  /// Whether this transition must be recorded in the audit log.
  /// Defaults to `true`; the only `false` cases are internal no-op
  /// refreshes that do not change business-observable state.
  final bool audits;

  /// Documentation anchor — the exact DGA manual activity (or range)
  /// that this transition encodes. Purely informational; surfaced in
  /// the audit payload for compliance cross-referencing.
  final String dgaActivity;

  const StateTransition({
    required this.from,
    required this.to,
    required this.trigger,
    required this.allowedTriggers,
    required this.dgaActivity,
    this.requiresActorRole,
    this.firesNotification = false,
    this.audits = true,
  });

  /// Convenience: returns `true` iff the given [triggerType] is allowed
  /// by this transition's [allowedTriggers].
  bool allows(TransitionTrigger triggerType) =>
      allowedTriggers.contains(triggerType);

  @override
  String toString() =>
      'StateTransition(${from.code} -> ${to.code} via $trigger)';
}

/// Reasons a transition can be denied by [DeclarationStateMachine.canTransition].
enum TransitionDenialReason {
  /// No transition is registered for the given (from, to) pair.
  illegalTransition,

  /// The requested transition exists but is not allowed for the caller's
  /// [TransitionTrigger] (e.g. a user attempted a gateway-only transition).
  triggerNotAllowed,

  /// The requested transition exists but the caller's [Role] is below
  /// [StateTransition.requiresActorRole].
  insufficientRole,
}

/// Outcome of a call to [DeclarationStateMachine.canTransition].
@immutable
sealed class TransitionCheck {
  const TransitionCheck._();
}

/// The transition is legal — `apply` is safe to call.
@immutable
final class TransitionAllowed extends TransitionCheck {
  final StateTransition transition;
  const TransitionAllowed(this.transition) : super._();
}

/// The transition was rejected. [reason] is machine-readable; [message]
/// is a short human-readable description safe for audit payloads.
@immutable
final class TransitionDenied extends TransitionCheck {
  final TransitionDenialReason reason;
  final String message;
  const TransitionDenied({
    required this.reason,
    required this.message,
  }) : super._();
}

/// Result of applying a transition via [DeclarationStateMachine.apply].
///
/// The returned value is pure data — the caller (use case handler) is
/// responsible for persisting the new status, writing the audit event,
/// and firing the notification event.
@immutable
class StateTransitionResult {
  final DeclarationStatus previousStatus;
  final DeclarationStatus newStatus;
  final StateTransition transition;

  /// `true` when the caller should emit a user-visible notification.
  /// Convenience copy of [StateTransition.firesNotification] so the
  /// caller does not have to reach through.
  bool get shouldNotify => transition.firesNotification;

  /// `true` when the caller should append an audit event. Convenience
  /// copy of [StateTransition.audits].
  bool get shouldAudit => transition.audits;

  const StateTransitionResult({
    required this.previousStatus,
    required this.newStatus,
    required this.transition,
  });
}

/// The policy object — immutable, thread-safe, shareable as a singleton.
///
/// Usage:
/// ```dart
/// const sm = DeclarationStateMachine();
/// final check = sm.canTransition(
///   from: DeclarationStatus.registered,
///   to: DeclarationStatus.accepted,
///   trigger: TransitionTrigger.gateway,
/// );
/// if (check is TransitionAllowed) {
///   final result = sm.apply(
///     from: DeclarationStatus.registered,
///     to: DeclarationStatus.accepted,
///     trigger: TransitionTrigger.gateway,
///   );
///   // persist + audit + notify
/// }
/// ```
@immutable
class DeclarationStateMachine {
  final List<StateTransition> transitions;

  /// Build with the default transition table. Tests may supply a
  /// custom [transitions] list to exercise edge cases without depending
  /// on the canonical DGA activity set.
  const DeclarationStateMachine({
    List<StateTransition>? transitions,
  }) : transitions = transitions ?? _defaultTransitions;

  /// Returns every registered transition starting from [status]. Useful
  /// for UI affordances (enable/disable buttons) and documentation.
  List<StateTransition> outgoingFrom(DeclarationStatus status) =>
      transitions.where((t) => t.from == status).toList(growable: false);

  /// Validate that a transition is legal in the current context.
  TransitionCheck canTransition({
    required DeclarationStatus from,
    required DeclarationStatus to,
    required TransitionTrigger trigger,
    Role? actorRole,
  }) {
    if (from == to) {
      return const TransitionDenied(
        reason: TransitionDenialReason.illegalTransition,
        message: 'no-op transition (from == to)',
      );
    }
    // Collect every registered (from, to) candidate — there may be more
    // than one (e.g. auto-confirm via gateway vs manual confirm by a
    // supervisor). Pick the first one that accepts the [trigger]; this
    // gives us a deterministic, table-order-driven resolution.
    final candidates = <StateTransition>[];
    for (final t in transitions) {
      if (t.from == from && t.to == to) candidates.add(t);
    }
    if (candidates.isEmpty) {
      return TransitionDenied(
        reason: TransitionDenialReason.illegalTransition,
        message: 'no transition from ${from.code} to ${to.code}',
      );
    }
    StateTransition? match;
    for (final t in candidates) {
      if (t.allows(trigger)) {
        match = t;
        break;
      }
    }
    if (match == null) {
      final allAccepted = candidates
          .expand((t) => t.allowedTriggers)
          .map((t) => t.name)
          .toSet()
          .join(', ');
      return TransitionDenied(
        reason: TransitionDenialReason.triggerNotAllowed,
        message:
            'transition ${from.code} -> ${to.code} does not accept trigger '
            '${trigger.name} (accepts $allAccepted)',
      );
    }
    // Role gating ONLY applies to user triggers — system/gateway
    // callers run under the server's own identity (no user role), and
    // requiring a role from them would make every automated push
    // unreachable.
    final requiredRole = match.requiresActorRole;
    if (requiredRole != null && trigger == TransitionTrigger.user) {
      if (actorRole == null || !actorRole.satisfies(requiredRole)) {
        return TransitionDenied(
          reason: TransitionDenialReason.insufficientRole,
          message:
              'transition ${from.code} -> ${to.code} requires role '
              '${requiredRole.code} or higher',
        );
      }
    }
    return TransitionAllowed(match);
  }

  /// Apply a transition. Throws [StateError] if the transition is
  /// illegal — callers should have checked [canTransition] first.
  /// The returned [StateTransitionResult] carries the side-effect
  /// directives (audit, notify) for the use case layer to execute.
  StateTransitionResult apply({
    required DeclarationStatus from,
    required DeclarationStatus to,
    required TransitionTrigger trigger,
    Role? actorRole,
  }) {
    final check = canTransition(
      from: from,
      to: to,
      trigger: trigger,
      actorRole: actorRole,
    );
    return switch (check) {
      TransitionAllowed(:final transition) => StateTransitionResult(
          previousStatus: from,
          newStatus: to,
          transition: transition,
        ),
      TransitionDenied(:final message) =>
        throw StateError('illegal transition: $message'),
    };
  }
}

// ---------------------------------------------------------------------------
// Default transition table — modelled on DGA Manual section 6.4.
// ---------------------------------------------------------------------------
//
// We encode 30 transitions across the 21 states. The table is intentionally
// additive: activities in the manual that do NOT change the business-observable
// status (e.g. RIMM consultations, tariff lookups) are out of scope.
//
// Conventions:
//   * `system`  — scheduled worker or ATENA status-pull
//   * `gateway` — ATENA pushed us this transition
//   * `user`    — explicit operator action (role-gated)
//
// Every transition that a P03 pyme or P02 freelance agent would care about
// fires a notification (`firesNotification: true`) so VRTV-41 can surface it.

const List<StateTransition> _defaultTransitions = [
  // --- Draft -> Registered (activity 6.4.1 — submit DUA to ATENA) ---
  StateTransition(
    from: DeclarationStatus.draft,
    to: DeclarationStatus.registered,
    trigger: 'declaration.submitted',
    allowedTriggers: {TransitionTrigger.user, TransitionTrigger.system},
    requiresActorRole: Role.agent,
    firesNotification: false,
    dgaActivity: '6.4.1',
  ),
  // --- Registered -> Validating (activity 6.4.2-6.4.5 — ATENA runs
  //     format, tariff, valuation and documentary checks) ---
  StateTransition(
    from: DeclarationStatus.registered,
    to: DeclarationStatus.validating,
    trigger: 'atena.validation-started',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: false,
    dgaActivity: '6.4.2-6.4.5',
  ),
  // --- Validating -> PaymentPending (activity 6.4.6-6.4.8 — assessed,
  //     awaiting funds) ---
  StateTransition(
    from: DeclarationStatus.validating,
    to: DeclarationStatus.paymentPending,
    trigger: 'atena.assessed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.6-6.4.8',
  ),
  // --- Validating -> Rejected (activity 6.4.4 — format/tariff/valuation
  //     rejected) ---
  StateTransition(
    from: DeclarationStatus.validating,
    to: DeclarationStatus.rejected,
    trigger: 'atena.validation-failed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.4',
  ),
  // --- Registered -> Rejected (fast-path — structural rejection at
  //     submission) ---
  StateTransition(
    from: DeclarationStatus.registered,
    to: DeclarationStatus.rejected,
    trigger: 'atena.registration-rejected',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.3',
  ),
  // --- PaymentPending -> Accepted (activity 6.4.14 — payment confirmed) ---
  StateTransition(
    from: DeclarationStatus.paymentPending,
    to: DeclarationStatus.accepted,
    trigger: 'atena.payment-confirmed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.14',
  ),
  // --- Accepted -> LpcoPending (activity 6.4.15 — notas tecnicas required) ---
  StateTransition(
    from: DeclarationStatus.accepted,
    to: DeclarationStatus.lpcoPending,
    trigger: 'atena.lpco-required',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.15',
  ),
  // --- LpcoPending -> Accepted (agent uploaded LPCO; back to the
  //     main track) ---
  StateTransition(
    from: DeclarationStatus.lpcoPending,
    to: DeclarationStatus.accepted,
    trigger: 'atena.lpco-submitted',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.15',
  ),
  // --- LpcoPending -> Annulled (activity 6.4.16 — 5-day LPCO deadline
  //     expired; system auto-annuls) ---
  StateTransition(
    from: DeclarationStatus.lpcoPending,
    to: DeclarationStatus.annulled,
    trigger: 'atena.lpco-deadline-expired',
    allowedTriggers: {TransitionTrigger.system, TransitionTrigger.gateway},
    firesNotification: true,
    dgaActivity: '6.4.16',
  ),
  // --- Accepted -> Levante (activity 6.4.18 note 2 — risk selectivity
  //     returned "no review") ---
  StateTransition(
    from: DeclarationStatus.accepted,
    to: DeclarationStatus.levante,
    trigger: 'atena.selectivity-no-review',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.18',
  ),
  // --- Accepted -> DocumentReview (activity 6.4.18 — documentary risk) ---
  StateTransition(
    from: DeclarationStatus.accepted,
    to: DeclarationStatus.documentReview,
    trigger: 'atena.selectivity-document',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.18',
  ),
  // --- Accepted -> PhysicalInspection (activity 6.4.18 — documentary +
  //     physical risk) ---
  StateTransition(
    from: DeclarationStatus.accepted,
    to: DeclarationStatus.physicalInspection,
    trigger: 'atena.selectivity-physical',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.18',
  ),
  // --- DocumentReview -> Levante (activity 6.4.20 — documental cleared) ---
  StateTransition(
    from: DeclarationStatus.documentReview,
    to: DeclarationStatus.levante,
    trigger: 'atena.document-review-passed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.20',
  ),
  // --- DocumentReview -> Rejected (documental review found defects) ---
  StateTransition(
    from: DeclarationStatus.documentReview,
    to: DeclarationStatus.rejected,
    trigger: 'atena.document-review-failed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.20',
  ),
  // --- PhysicalInspection -> Levante (physical + documental cleared) ---
  StateTransition(
    from: DeclarationStatus.physicalInspection,
    to: DeclarationStatus.levante,
    trigger: 'atena.physical-inspection-passed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.20',
  ),
  // --- PhysicalInspection -> Rejected (physical found defects) ---
  StateTransition(
    from: DeclarationStatus.physicalInspection,
    to: DeclarationStatus.rejected,
    trigger: 'atena.physical-inspection-failed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.20',
  ),
  // --- Levante -> LevanteTransit (activity 6.4.21 — goods can move) ---
  StateTransition(
    from: DeclarationStatus.levante,
    to: DeclarationStatus.levanteTransit,
    trigger: 'atena.transit-started',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: false,
    dgaActivity: '6.4.21',
  ),
  // --- LevanteTransit -> T1Mobilization (section 6.5 — T1 control) ---
  StateTransition(
    from: DeclarationStatus.levanteTransit,
    to: DeclarationStatus.t1Mobilization,
    trigger: 'atena.t1-registered',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: false,
    dgaActivity: '6.5',
  ),
  // --- T1Mobilization -> ArrivedAtPort (activity 6.4.32 — COARRI) ---
  StateTransition(
    from: DeclarationStatus.t1Mobilization,
    to: DeclarationStatus.arrivedAtPort,
    trigger: 'atena.arrived-at-port',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.32',
  ),
  // --- LevanteTransit -> ArrivedAtPort (short-path when T1 is skipped) ---
  StateTransition(
    from: DeclarationStatus.levanteTransit,
    to: DeclarationStatus.arrivedAtPort,
    trigger: 'atena.arrived-at-port-direct',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.32',
  ),
  // --- ArrivedAtPort -> DepartureFull (activity 6.4.33 — full departure) ---
  StateTransition(
    from: DeclarationStatus.arrivedAtPort,
    to: DeclarationStatus.departureFull,
    trigger: 'atena.departure-full',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.33',
  ),
  // --- ArrivedAtPort -> DeparturePartial (activity 6.4.34) ---
  StateTransition(
    from: DeclarationStatus.arrivedAtPort,
    to: DeclarationStatus.departurePartial,
    trigger: 'atena.departure-partial',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.34',
  ),
  // --- DeparturePartial -> DepartureFull (remaining containers departed) ---
  StateTransition(
    from: DeclarationStatus.departurePartial,
    to: DeclarationStatus.departureFull,
    trigger: 'atena.remaining-departed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.34',
  ),
  // --- DepartureFull -> ConfirmationWindow (activity 6.4.35 — 10-day
  //     window opens) ---
  StateTransition(
    from: DeclarationStatus.departureFull,
    to: DeclarationStatus.confirmationWindow,
    trigger: 'atena.confirmation-window-opened',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: false,
    dgaActivity: '6.4.35',
  ),
  // --- ConfirmationWindow -> Confirmed (activity 6.4.36 — auto) ---
  StateTransition(
    from: DeclarationStatus.confirmationWindow,
    to: DeclarationStatus.confirmed,
    trigger: 'atena.auto-confirmed',
    allowedTriggers: {TransitionTrigger.system, TransitionTrigger.gateway},
    firesNotification: true,
    dgaActivity: '6.4.36',
  ),
  // --- ConfirmationWindow -> Confirmed (activity 6.4.37 — manual via
  //     boletin) ---
  StateTransition(
    from: DeclarationStatus.confirmationWindow,
    to: DeclarationStatus.confirmed,
    trigger: 'atena.manually-confirmed',
    allowedTriggers: {TransitionTrigger.user, TransitionTrigger.gateway},
    requiresActorRole: Role.supervisor,
    firesNotification: true,
    dgaActivity: '6.4.37',
  ),
  // --- Confirmed -> FinalConfirmed (activities 6.4.45-6.4.52 —
  //     final verification) ---
  StateTransition(
    from: DeclarationStatus.confirmed,
    to: DeclarationStatus.finalConfirmed,
    trigger: 'atena.final-verification-passed',
    allowedTriggers: {TransitionTrigger.gateway, TransitionTrigger.system},
    firesNotification: true,
    dgaActivity: '6.4.45-6.4.52',
  ),
  // --- Rejected -> Registered (agent fixed errors and resubmits) ---
  StateTransition(
    from: DeclarationStatus.rejected,
    to: DeclarationStatus.registered,
    trigger: 'declaration.resubmitted',
    allowedTriggers: {TransitionTrigger.user},
    requiresActorRole: Role.agent,
    firesNotification: false,
    dgaActivity: '6.4.1',
  ),
  // --- Draft -> Cancelled (user abandons draft — audited but silent) ---
  StateTransition(
    from: DeclarationStatus.draft,
    to: DeclarationStatus.cancelled,
    trigger: 'declaration.cancelled',
    allowedTriggers: {TransitionTrigger.user},
    requiresActorRole: Role.agent,
    firesNotification: false,
    dgaActivity: 'n/a',
  ),
];
