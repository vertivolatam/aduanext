/// Query: PreValidateDeclaration — runs the 9-rule pipeline over a
/// [Declaration] and returns a [ValidationReport].
///
/// Query (read-only) rather than a Command: it emits no state change
/// and can be safely retried. Submit handlers consume the report as a
/// short-circuit gate BEFORE the ATENA dry-run.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import 'validation_report.dart';
import 'validation_rule.dart';

@immutable
class PreValidateDeclarationQuery {
  final Declaration declaration;

  const PreValidateDeclarationQuery({required this.declaration});
}

/// Executes a fixed list of [ValidationRule]s over a [Declaration] and
/// assembles the [ValidationReport].
///
/// The rule list is passed in so callers can compose different rule
/// sets (e.g. strict-mode vs lenient-mode) without touching this class.
class PreValidateDeclarationHandler {
  final List<ValidationRule<Declaration>> rules;

  /// Whether rule failures should short-circuit the pipeline on the
  /// first [RuleSeverity.error]. `true` = stop on first error (faster,
  /// less complete report). `false` = always run every rule (slower but
  /// more informative — useful for the UI's validation panel).
  final bool shortCircuitOnError;

  const PreValidateDeclarationHandler({
    required this.rules,
    this.shortCircuitOnError = false,
  });

  Future<ValidationReport> handle(PreValidateDeclarationQuery query) async {
    final results = <RuleResult>[];
    for (final rule in rules) {
      final r = await rule.evaluate(query.declaration);
      results.add(r);
      if (shortCircuitOnError &&
          r is Fail &&
          r.severity == RuleSeverity.error) {
        break;
      }
    }
    return ValidationReport(results: results);
  }
}
