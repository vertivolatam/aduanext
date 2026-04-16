/// Client-side pre-validation engine for the DUA draft.
///
/// Local pass of the 9 rules VRTV-42 enforces server-side — gives
/// Step 7 (Revisión) an instant verdict without waiting for the
/// `POST /api/v1/dispatches/pre-validate` roundtrip.
///
/// The server-side VRTV-42 engine remains the source of truth. This
/// mirror is opportunistic: it surfaces common mistakes early but
/// never replaces the submit-path validation.
///
/// Risk score formula (mirrors VRTV-42 reference weights):
///   * Each failing rule adds its `weight` to a running total
///     (clamped to 0-100).
///   * The stepper semáforo cues off the score:
///       0-30  — verde  (low risk)
///       31-60 — amarillo (warning)
///       61-100 — rojo (high risk, likely rejected)
library;

import 'package:meta/meta.dart';

import 'dua_form_state.dart';

/// Severity of a rule finding.
enum PreValidationSeverity { info, warning, error }

/// A single rule finding returned by the pre-validation engine.
@immutable
class PreValidationFinding {
  /// Stable rule code (mirrors the VRTV-42 engine naming) — useful
  /// for cross-referencing with audit logs.
  final String ruleCode;

  final String title;
  final String? description;
  final PreValidationSeverity severity;

  /// Contribution to the aggregate risk score (0-100). Rules with
  /// severity `info` should always have `riskWeight == 0`.
  final int riskWeight;

  const PreValidationFinding({
    required this.ruleCode,
    required this.title,
    required this.severity,
    this.description,
    this.riskWeight = 0,
  });
}

@immutable
class PreValidationResult {
  final List<PreValidationFinding> findings;

  /// 0-100 aggregate risk — sum of weights, clamped.
  final int riskScore;

  bool get hasErrors =>
      findings.any((f) => f.severity == PreValidationSeverity.error);
  bool get hasWarnings =>
      findings.any((f) => f.severity == PreValidationSeverity.warning);

  const PreValidationResult({required this.findings, required this.riskScore});
}

/// Pure function — runs the 6 MVP rules against the draft.
///
/// Deterministic output so the UI test suite can pin expected
/// findings per draft fixture.
PreValidationResult preValidate(DuaDraft draft) {
  final findings = <PreValidationFinding>[];

  // Rule 1: missing HS code on any item.
  final missingHs =
      draft.items.where((i) => i.hsCode == null || i.hsCode!.isEmpty);
  if (missingHs.isNotEmpty) {
    findings.add(PreValidationFinding(
      ruleCode: 'HS_CODE_MISSING',
      title: '${missingHs.length} item(s) sin HS code',
      description: 'Clasifica cada linea en el paso 3 antes de transmitir.',
      severity: PreValidationSeverity.error,
      riskWeight: 25,
    ));
  }

  // Rule 2: invoice total mismatch vs. items FOB total > 5%.
  if (draft.invoices.isNotEmpty) {
    final invoiceSum = draft.totalInvoiceAmount;
    final itemSum = draft.totalFob;
    if (itemSum > 0 && invoiceSum > 0) {
      final diff = (invoiceSum - itemSum).abs();
      final tolerance = itemSum * 0.05;
      if (diff > tolerance) {
        findings.add(const PreValidationFinding(
          ruleCode: 'INVOICE_FOB_MISMATCH',
          title: 'Diferencia > 5% entre facturas y FOB items',
          description:
              'Revisa montos — una diferencia material puede activar aforo fisico.',
          severity: PreValidationSeverity.warning,
          riskWeight: 15,
        ));
      }
    }
  }

  // Rule 3: missing exchange rate when currency != CRC.
  if ((draft.invoiceCurrencyCode ?? 'CRC') != 'CRC' &&
      (draft.exchangeRate ?? 0) <= 0) {
    findings.add(const PreValidationFinding(
      ruleCode: 'MISSING_EXCHANGE_RATE',
      title: 'Tipo de cambio faltante',
      description: 'Ingresa el tipo de cambio RIMM del dia en el paso 4.',
      severity: PreValidationSeverity.error,
      riskWeight: 20,
    ));
  }

  // Rule 4: required docs missing.
  final missingRequired =
      draft.documents.where((d) => d.required && !d.attached).toList();
  if (missingRequired.isNotEmpty) {
    findings.add(PreValidationFinding(
      ruleCode: 'MISSING_REQUIRED_DOCS',
      title: '${missingRequired.length} documento(s) requerido(s) sin adjuntar',
      description:
          missingRequired.map((d) => d.displayName).join(', '),
      severity: PreValidationSeverity.error,
      riskWeight: 20,
    ));
  }

  // Rule 5: CIF = 0 — FOB present but no freight/insurance reported.
  if (draft.totalFob > 0 && draft.totalCif == draft.totalFob) {
    findings.add(const PreValidationFinding(
      ruleCode: 'NO_FREIGHT_INSURANCE',
      title: 'Flete y seguro en cero',
      description:
          'Verifica si el incoterm asigna costos al exportador (EXW/FCA).',
      severity: PreValidationSeverity.info,
      riskWeight: 0,
    ));
  }

  // Rule 6: FOB total > USD 50,000 — higher-value shipments auto-flag
  // for manual review.
  if (draft.totalFob > 50000 && (draft.invoiceCurrencyCode ?? 'USD') == 'USD') {
    findings.add(const PreValidationFinding(
      ruleCode: 'HIGH_VALUE_SHIPMENT',
      title: 'Monto declarado > USD 50,000',
      description:
          'Envios de alto valor se flagean para revision manual — prepara '
          'documentacion de respaldo completa.',
      severity: PreValidationSeverity.warning,
      riskWeight: 10,
    ));
  }

  final totalRisk =
      findings.fold<int>(0, (sum, f) => sum + f.riskWeight).clamp(0, 100);

  return PreValidationResult(findings: findings, riskScore: totalRisk);
}
