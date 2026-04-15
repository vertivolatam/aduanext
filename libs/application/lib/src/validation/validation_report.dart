/// Aggregate result of running every registered rule over a single
/// [Declaration].
library;

import 'package:meta/meta.dart';

import 'validation_rule.dart';

@immutable
class ValidationReport {
  /// Every [RuleResult] returned by the rule batch, in execution order.
  final List<RuleResult> results;

  ValidationReport({required List<RuleResult> results})
      : results = List<RuleResult>.unmodifiable(results);

  /// Only the [Fail] results (the passes are useful for audit but not
  /// for decision-making by the submit handler).
  Iterable<Fail> get failures => results.whereType<Fail>();

  /// Error-level failures. Non-empty means "block the submission".
  List<Fail> get errors =>
      failures.where((f) => f.severity == RuleSeverity.error).toList();

  /// Warning-level failures. Non-empty + empty [errors] means "proceed
  /// only if the agent overrides with a justification".
  List<Fail> get warnings =>
      failures.where((f) => f.severity == RuleSeverity.warning).toList();

  /// Info-level failures — never block.
  List<Fail> get infos =>
      failures.where((f) => f.severity == RuleSeverity.info).toList();

  /// `true` iff no error-level failures.
  bool get isSubmittable => errors.isEmpty;

  /// `true` iff the report is completely clean (no failures of any
  /// severity).
  bool get isClean => failures.isEmpty;

  /// JSON-friendly summary for audit logs.
  Map<String, dynamic> toAuditSummary() {
    return {
      'ruleCount': results.length,
      'errorCount': errors.length,
      'warningCount': warnings.length,
      'infoCount': infos.length,
      if (failures.isNotEmpty)
        'failures': failures
            .map((f) => {
                  'ruleCode': f.ruleCode,
                  'severity': f.severity.name,
                  'message': f.message,
                  if (f.fieldPath != null) 'fieldPath': f.fieldPath,
                })
            .toList(),
    };
  }
}
