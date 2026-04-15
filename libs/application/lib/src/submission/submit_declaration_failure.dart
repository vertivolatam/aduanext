/// Sealed hierarchy of expected business failures for
/// [SubmitDeclarationCommand].
///
/// These are NOT infrastructure errors — a gRPC timeout or a Postgres
/// connection drop propagates as an exception per the hybrid error
/// model. A [SubmitDeclarationFailure] is a condition we want the UI to
/// surface to the agent with a specific remediation message.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import '../shared/failure.dart';

@immutable
sealed class SubmitDeclarationFailure extends Failure {
  const SubmitDeclarationFailure();
}

/// A required actor/tenant/declaration field was missing or empty.
@immutable
final class MissingFieldFailure extends SubmitDeclarationFailure {
  final String fieldName;

  const MissingFieldFailure({required this.fieldName});

  @override
  String get code => 'submit.missing-field';

  @override
  String get message =>
      '$fieldName is required and must be non-empty.';
}

/// The declaration as supplied is structurally incomplete (no items, no
/// shipping, no valuation...). Per SRD rule #7 we preserve exact ATENA
/// field names and demand that header-level required fields are present
/// before the handler even attempts a gateway round-trip.
@immutable
final class InvalidDeclarationStructureFailure extends SubmitDeclarationFailure {
  final String reason;

  const InvalidDeclarationStructureFailure(this.reason);

  @override
  String get code => 'submit.invalid-structure';

  @override
  String get message => 'Declaration structure is invalid: $reason';
}

/// The customs authority rejected the authentication. Agent must re-enter
/// credentials or request a password reset.
@immutable
final class AuthenticationFailedFailure extends SubmitDeclarationFailure {
  /// Reason reported by the auth adapter (already translated from gRPC).
  final String reason;

  /// Optional error code from the IDP (e.g. `INVALID_GRANT`).
  final String? idpErrorCode;

  const AuthenticationFailedFailure({
    required this.reason,
    this.idpErrorCode,
  });

  @override
  String get code => 'submit.authentication-failed';

  @override
  String get message => 'Customs authority rejected authentication: $reason'
      '${idpErrorCode != null ? " (code: $idpErrorCode)" : ""}';
}

/// Declaration failed the customs authority's pre-submission validation.
/// The `errors` carry the exact field-level problems reported by ATENA;
/// surface them verbatim to the agent for correction.
@immutable
final class DeclarationValidationFailedFailure
    extends SubmitDeclarationFailure {
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  const DeclarationValidationFailedFailure({
    required this.errors,
    this.warnings = const [],
  });

  @override
  String get code => 'submit.validation-failed';

  @override
  String get message =>
      'ATENA reported ${errors.length} validation error(s); '
      'agent must correct the declaration before re-submitting.';
}

/// XAdES signing failed (invalid cert, wrong PIN, cert expired...).
@immutable
final class SigningFailedFailure extends SubmitDeclarationFailure {
  final String reason;

  const SigningFailedFailure(this.reason);

  @override
  String get code => 'submit.signing-failed';

  @override
  String get message => 'Digital signature failed: $reason';
}

/// Pre-submission rule engine (VRTV-42) rejected the declaration.
/// Carries the full [ValidationReport] so the UI can surface every
/// failing rule at once (field path + message per rule).
@immutable
final class PreValidationFailedFailure extends SubmitDeclarationFailure {
  /// Opaque carrier — we keep it as `Object` to avoid a cycle between
  /// the submission feature slice and the validation feature slice. The
  /// boundary layer casts to `ValidationReport` for UI rendering.
  final Object report;

  /// Human-readable one-line summary (rule counts, first failure).
  final String summary;

  const PreValidationFailedFailure({
    required this.report,
    required this.summary,
  });

  @override
  String get code => 'submit.pre-validation-failed';

  @override
  String get message =>
      'Pre-submission validation blocked the declaration: $summary';
}

/// ATENA returned a non-success response to the submit RPC (e.g.
/// business rule violation discovered at liquidation time that was not
/// caught by validateDeclaration).
@immutable
final class GatewayRejectedSubmissionFailure extends SubmitDeclarationFailure {
  final String reason;
  final String? rawResponse;

  const GatewayRejectedSubmissionFailure({
    required this.reason,
    this.rawResponse,
  });

  @override
  String get code => 'submit.gateway-rejected';

  @override
  String get message =>
      'Customs authority rejected submission: $reason';
}
