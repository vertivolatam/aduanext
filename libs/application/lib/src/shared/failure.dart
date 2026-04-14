/// Base type for expected business failures returned in [Result.err].
///
/// Feature-specific failures extend this with their own subclass
/// (sealed pattern, one file per feature). Infrastructure failures
/// (DB down, port unavailable) are NOT [Failure]s — they are
/// exceptions thrown by adapters and caught at the boundary.
library;

import 'package:meta/meta.dart';

/// Super-type for expected business failures.
///
/// Every [Failure] has a [code] (stable string ID for i18n + logs)
/// and a human-readable [message].
@immutable
abstract class Failure {
  /// Stable identifier for this failure — safe for log matching,
  /// error translation, and analytics. Use `kebab-case`.
  String get code;

  /// Human-readable description of the failure. Languages: this
  /// layer keeps the message in English; i18n happens at the
  /// presentation layer using [code].
  String get message;

  const Failure();

  @override
  String toString() => 'Failure($code): $message';
}

/// Generic "input was invalid" failure. Prefer feature-specific
/// subclasses over this one when you can — they carry more context.
@immutable
class ValidationFailure extends Failure {
  @override
  final String code;
  @override
  final String message;

  /// Name of the field that failed validation. `null` for cross-field
  /// validation errors.
  final String? field;

  const ValidationFailure({
    required this.code,
    required this.message,
    this.field,
  });
}
