/// Framework for pre-submission validation rules (SOP-B04).
///
/// A [ValidationRule] inspects a [Declaration] and returns a [RuleResult].
/// Rules run in the order they are registered and are collected into a
/// [ValidationReport]. The report is then consumed by the submit handler
/// — errors short-circuit, warnings propagate into the audit trail but
/// do not block submission (unless `treatWarningsAsErrors` is set).
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

/// Severity of a failing rule. Ordered by blocking-ness ascending.
enum RuleSeverity {
  /// Informational only. Surfaced to the agent but never blocks.
  info,

  /// Warning — blocks unless the agent explicitly overrides with a
  /// recorded justification (per the 2026-04-14 comment on VRTV-42).
  warning,

  /// Error — ALWAYS blocks. An error cannot be overridden; the agent
  /// must fix the data.
  error,
}

/// Outcome of one rule execution.
@immutable
sealed class RuleResult {
  final String ruleCode;

  const RuleResult({required this.ruleCode});

  /// `true` if this result is a pass.
  bool get isPass => this is Pass;

  /// `true` if this is a non-blocking result (either pass or below
  /// [RuleSeverity.error]).
  bool get isNonBlocking => switch (this) {
        Pass _ => true,
        Fail(:final severity) => severity != RuleSeverity.error,
      };
}

/// The rule accepts the input.
@immutable
final class Pass extends RuleResult {
  const Pass({required super.ruleCode});

  @override
  String toString() => 'Pass($ruleCode)';
}

/// The rule rejects the input. Carries a message and an optional
/// JSON-pointer-ish [fieldPath] so the UI can highlight the offending
/// field.
@immutable
final class Fail extends RuleResult {
  final RuleSeverity severity;
  final String message;
  final String? fieldPath;

  const Fail({
    required super.ruleCode,
    required this.severity,
    required this.message,
    this.fieldPath,
  });

  @override
  String toString() =>
      'Fail($ruleCode, $severity, $message${fieldPath != null ? ", $fieldPath" : ""})';
}

/// Contract implemented by each of the 9 rules. Generic in the input
/// type so future queries (e.g. `User` pre-onboarding checks) can share
/// the framework.
abstract class ValidationRule<T> {
  /// Stable machine code for log matching and i18n.
  String get code;

  /// Default severity when the rule fails. Individual rule
  /// implementations can still return [Fail] with a different severity
  /// for specific cases (e.g. `WeightConsistencyRule` uses `warning`
  /// when weights are suspicious but not invalid).
  RuleSeverity get defaultSeverity;

  /// Inspect [input] and return a [RuleResult].
  ///
  /// Rules MUST be pure — no I/O other than the injected Ports they
  /// hold as collaborators.
  Future<RuleResult> evaluate(T input);
}
