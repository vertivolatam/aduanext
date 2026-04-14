/// Failures specific to [RecordClassificationCommand].
///
/// Kept in its own file so feature-local changes don't churn the
/// shared failure base.
library;

import 'package:meta/meta.dart';

import '../shared/failure.dart';

/// Sealed hierarchy of classification-specific failures.
///
/// Callers can pattern-match on concrete subtypes for precise error
/// handling in the presentation layer.
@immutable
sealed class RecordClassificationFailure extends Failure {
  const RecordClassificationFailure();
}

/// The supplied HS code is malformed (not 6-12 digits).
@immutable
final class InvalidHsCodeFailure extends RecordClassificationFailure {
  final String supplied;

  const InvalidHsCodeFailure(this.supplied);

  @override
  String get code => 'classification.invalid-hs-code';

  @override
  String get message =>
      'HS code must be 6-12 digits (got: "$supplied")';
}

/// The commercial description is too short or empty.
@immutable
final class InvalidDescriptionFailure extends RecordClassificationFailure {
  final int minLength;

  const InvalidDescriptionFailure({this.minLength = 5});

  @override
  String get code => 'classification.invalid-description';

  @override
  String get message =>
      'Commercial description must be at least $minLength characters '
      '(generic terms like "goods" are rejected — DGA manual, point 13).';
}

/// Required actor/tenant identifier is missing or empty.
@immutable
final class MissingActorFailure extends RecordClassificationFailure {
  final String fieldName; // "agentId" | "tenantId"

  const MissingActorFailure({required this.fieldName});

  @override
  String get code => 'classification.missing-actor';

  @override
  String get message => '$fieldName is required and must be non-empty';
}
