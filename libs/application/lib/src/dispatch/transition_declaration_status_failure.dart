/// Business failures for [TransitionDeclarationStatusHandler].
///
/// Infrastructure failures (DB unreachable, dispatcher broken) are NOT
/// modelled here — they propagate as exceptions per the hybrid error
/// model.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import '../shared/failure.dart';

/// Super-type for all dispatch-feature failures. Keeps call sites
/// pattern-matching cleanly.
@immutable
sealed class TransitionDeclarationStatusFailure extends Failure {
  const TransitionDeclarationStatusFailure();
}

/// The declaration could not be loaded for the given id + tenant.
/// Usually means "not found" (including tenant mismatch — adapters
/// MUST return null on cross-tenant lookups, not throw).
@immutable
class DeclarationNotFoundFailure
    extends TransitionDeclarationStatusFailure {
  final String declarationId;

  const DeclarationNotFoundFailure(this.declarationId);

  @override
  String get code => 'declaration-not-found';

  @override
  String get message => 'declaration not found: $declarationId';
}

/// The state machine rejected the requested transition. Carries the
/// machine-readable [reason] and the raw [attemptedFrom]/[attemptedTo]
/// pair for audit + UI.
@immutable
class IllegalTransitionFailure extends TransitionDeclarationStatusFailure {
  final DeclarationStatus attemptedFrom;
  final DeclarationStatus attemptedTo;
  final TransitionDenialReason reason;
  final String detail;

  const IllegalTransitionFailure({
    required this.attemptedFrom,
    required this.attemptedTo,
    required this.reason,
    required this.detail,
  });

  @override
  String get code => switch (reason) {
        TransitionDenialReason.illegalTransition => 'illegal-transition',
        TransitionDenialReason.triggerNotAllowed => 'trigger-not-allowed',
        TransitionDenialReason.insufficientRole => 'insufficient-role',
      };

  @override
  String get message =>
      'cannot transition ${attemptedFrom.code} -> ${attemptedTo.code}: $detail';
}

/// Raised by the handler when the optimistic precondition in
/// [DeclarationRepositoryPort.updateStatus] fails — another writer
/// changed the status between our load and our update. The caller
/// should reload and re-evaluate; this is NOT an illegal transition.
@immutable
class ConcurrentTransitionFailure
    extends TransitionDeclarationStatusFailure {
  final DeclarationStatus observedStatus;
  final DeclarationStatus attemptedFrom;

  const ConcurrentTransitionFailure({
    required this.observedStatus,
    required this.attemptedFrom,
  });

  @override
  String get code => 'concurrent-transition';

  @override
  String get message =>
      'concurrent writer already moved status to ${observedStatus.code} '
      '(expected ${attemptedFrom.code})';
}

/// Raised for structurally invalid commands (missing fields). Kept inside
/// the same sealed hierarchy so call sites can pattern-match with a
/// single exhaustive switch without falling back to a generic `Failure`
/// default.
@immutable
class InvalidTransitionCommandFailure
    extends TransitionDeclarationStatusFailure {
  final String reason;
  const InvalidTransitionCommandFailure(this.reason);

  @override
  String get code => 'invalid-transition-command';

  @override
  String get message => reason;
}
