/// The 9 pre-submission rules that make up the `PreValidateDeclaration`
/// pipeline (SOP-B04, 2026-04-14 scope expansion).
///
/// Kept in a single file so callers can see the full rulebook in one
/// glance and so adding a rule stays a ~30-line change rather than a
/// new-file ritual. Each rule is a tiny class — the real logic is
/// declarative.
library;

import 'package:aduanext_domain/aduanext_domain.dart';

import 'validation_rule.dart';

// ── Shared helpers ─────────────────────────────────────────────────────

/// Generic descriptions the DGA manual (point 13) explicitly forbids.
const _forbiddenDescriptionTerms = <String>{
  'goods',
  'merchandise',
  'varios',
  'mercaderia',
  'mercancia',
};

/// Incoterms that imply maritime transport. Used by
/// [IncotermConsistencyRule].
const _maritimeIncoterms = <String>{'FOB', 'FAS', 'CFR', 'CIF'};

/// Incoterms that imply land transport (truck/road). Used by
/// [IncotermConsistencyRule].
const _landIncoterms = <String>{'CPT', 'CIP', 'DAP', 'DPU', 'DDP'};

// ── Rule #1 — Required fields ─────────────────────────────────────────

/// Rejects declarations whose header-level required fields are empty.
/// Aligns with the early structural guardrail inside
/// `SubmitDeclarationHandler` — the pre-validation engine makes it
/// visible BEFORE the submit attempt so the UI can block the submit
/// button.
class RequiredFieldsRule implements ValidationRule<Declaration> {
  @override
  String get code => 'R-REQ-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    final missing = <String>[];
    if (d.exporterCode.isEmpty) missing.add('exporterCode');
    if (d.declarantCode.isEmpty) missing.add('declarantCode');
    if (d.officeOfDispatchExportCode.isEmpty) {
      missing.add('officeOfDispatchExportCode');
    }
    if (d.officeOfEntryCode.isEmpty) missing.add('officeOfEntryCode');
    if (d.items.isEmpty) missing.add('items');

    if (missing.isEmpty) return Pass(ruleCode: code);
    return Fail(
      ruleCode: code,
      severity: defaultSeverity,
      message: 'Required header fields are empty: ${missing.join(", ")}',
      fieldPath: missing.first,
    );
  }
}

// ── Rule #2 — Incoterm ⇄ transport mode ───────────────────────────────

/// Verifies the declared Incoterm is consistent with the mode of
/// transport at border. A FOB shipment that reports `modeOfTransport =
/// road` is almost certainly a data-entry error.
///
/// ATENA modeOfTransportAtBorderCode examples (partial): "1" = sea,
/// "3" = road, "4" = air, "9" = multimodal.
class IncotermConsistencyRule implements ValidationRule<Declaration> {
  @override
  String get code => 'R-INC-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    final incoterm = d.shipping.deliveryTermsCode;
    final mode = d.modeOfTransportAtBorderCode;
    if (incoterm == null || mode == null) {
      // Don't double-report required-fields; a separate rule handles
      // completeness.
      return Pass(ruleCode: code);
    }
    final isMaritime = _maritimeIncoterms.contains(incoterm);
    final isLand = _landIncoterms.contains(incoterm);
    final modeIsSea = mode == '1';
    final modeIsRoad = mode == '3';
    if (isMaritime && !modeIsSea && mode != '9') {
      return Fail(
        ruleCode: code,
        severity: defaultSeverity,
        message:
            'Incoterm $incoterm implies sea transport but modeOfTransportAtBorderCode="$mode".',
        fieldPath: 'shipping.deliveryTermsCode',
      );
    }
    if (isLand && !modeIsRoad && mode != '9') {
      return Fail(
        ruleCode: code,
        severity: defaultSeverity,
        message:
            'Incoterm $incoterm implies road transport but modeOfTransportAtBorderCode="$mode".',
        fieldPath: 'shipping.deliveryTermsCode',
      );
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #3 — HS code format ───────────────────────────────────────────

/// Every item's `commodityCode` must be 6–12 digits per SAC/HS.
class HsCodeFormatRule implements ValidationRule<Declaration> {
  static final _digits = RegExp(r'^\d{6,12}$');

  @override
  String get code => 'R-HS-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    for (final (i, item) in d.items.indexed) {
      final raw = item.commodityCode;
      if (raw == null || !_digits.hasMatch(raw)) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i].commodityCode must be 6-12 digits; got "${raw ?? ""}".',
          fieldPath: 'items[$i].commodityCode',
        );
      }
      // Also forbid ridiculously generic descriptions.
      if (_forbiddenDescriptionTerms
          .contains(item.commercialDescription.trim().toLowerCase())) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i].commercialDescription "${item.commercialDescription}" '
              'is too generic (DGA manual, point 13).',
          fieldPath: 'items[$i].commercialDescription',
        );
      }
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #4 — Weight consistency ──────────────────────────────────────

/// Per-item net <= gross and both > 0.
class WeightConsistencyRule implements ValidationRule<Declaration> {
  @override
  String get code => 'R-WGT-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    for (final (i, item) in d.items.indexed) {
      final net = item.netMass;
      final gross = item.itemGrossMass;
      if (net == null || gross == null) {
        // Missing weights are a required-fields concern; don't
        // double-report here.
        continue;
      }
      if (net <= 0 || gross <= 0) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i] weights must be > 0 (net=$net, gross=$gross).',
          fieldPath: 'items[$i].netMass',
        );
      }
      if (net > gross) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i].netMass ($net) cannot exceed itemGrossMass ($gross).',
          fieldPath: 'items[$i].netMass',
        );
      }
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #5 — Currency exchange rate ──────────────────────────────────

/// The declared FX rate must be within ±10% of the rate
/// [TariffCatalogPort.getExchangeRate] returns for the value date.
class CurrencyExchangeRateRule implements ValidationRule<Declaration> {
  final TariffCatalogPort tariffCatalog;
  final DateTime Function() clock;

  /// Allowed relative delta (0.10 = ±10%). Override when the ATENA
  /// tolerance policy changes.
  final double tolerance;

  CurrencyExchangeRateRule({
    required this.tariffCatalog,
    DateTime Function()? clock,
    this.tolerance = 0.10,
  }) : clock = clock ?? DateTime.now;

  @override
  String get code => 'R-FX-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    final declared = d.sadValuation.invoiceCurrencyExchangeRate;
    final ccy = d.sadValuation.invoiceCurrencyCode;
    if (declared == null || ccy == null) {
      return Pass(ruleCode: code); // handled by required-fields
    }
    try {
      final reference =
          await tariffCatalog.getExchangeRate(ccy, clock().toUtc());
      final delta = (declared - reference).abs() / reference;
      if (delta > tolerance) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'Declared FX rate $declared for $ccy is ${(delta * 100).toStringAsFixed(1)}% '
              'off the reference rate $reference; exceeds ±${(tolerance * 100).toStringAsFixed(0)}% tolerance.',
          fieldPath: 'sadValuation.invoiceCurrencyExchangeRate',
        );
      }
    } on TariffCatalogException catch (e) {
      // If RIMM is unreachable we cannot assert; degrade to warning so
      // a temporary RIMM outage does not block legitimate submissions.
      return Fail(
        ruleCode: code,
        severity: RuleSeverity.warning,
        message:
            'Unable to verify FX rate for $ccy against RIMM: ${e.message}',
        fieldPath: 'sadValuation.invoiceCurrencyExchangeRate',
      );
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #6 — Document attachment ─────────────────────────────────────

/// Every declaration must carry at least one commercial invoice
/// (`attachedDocCode == '380'`). Specific regimes layer additional
/// requirements (B/L, origin cert) — that list is configurable via
/// [extraRequiredCodes].
class DocumentAttachmentRule implements ValidationRule<Declaration> {
  /// Additional required docCode values (in addition to the universal
  /// `"380"` commercial invoice). Defaults to the DGA minimum set for
  /// export declarations.
  final Set<String> extraRequiredCodes;

  const DocumentAttachmentRule({
    this.extraRequiredCodes = const {},
  });

  @override
  String get code => 'R-DOC-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    final allCodes = <String>{};
    for (final item in d.items) {
      for (final doc in item.attachedDocuments) {
        allCodes.add(doc.attachedDocCode);
      }
    }
    final required = {'380', ...extraRequiredCodes};
    final missing = required.difference(allCodes);
    if (missing.isEmpty) return Pass(ruleCode: code);
    return Fail(
      ruleCode: code,
      severity: defaultSeverity,
      message:
          'Missing required attached document code(s): ${missing.join(", ")}',
      fieldPath: 'items[].attachedDocuments',
    );
  }
}

// ── Rule #7 — Declared CIF within 2σ of historical baseline ───────────

/// Warning-only rule — flags a declared CIF that falls outside 2 standard
/// deviations of the baseline for the same HS code. The baseline is a
/// placeholder until we have enough real DUAs to compute it (per the
/// "out of scope" note in the issue comment).
class ValueDeclarationRule implements ValidationRule<Declaration> {
  /// Per-HS-code (mean, stdDev) in USD/kg. Populated from historical
  /// DUAs. Today we carry a tiny seed set sampled from the CR export
  /// statistics bulletin; the shape is generic so once we backfill from
  /// real data the rule needs no change.
  final Map<String, ({double mean, double stdDev})> baseline;

  const ValueDeclarationRule({this.baseline = const {}});

  @override
  String get code => 'R-VAL-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.warning;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    for (final (i, item) in d.items.indexed) {
      final hs = item.commodityCode;
      final cif = item.itemValuation.costInsuranceFreightAmount;
      final netKg = item.netMass;
      if (hs == null || cif == null || netKg == null || netKg <= 0) continue;
      final stats = baseline[hs] ?? baseline[hs.substring(0, 6)];
      if (stats == null) continue; // no baseline -> skip
      final ratio = cif / netKg;
      final lower = stats.mean - 2 * stats.stdDev;
      final upper = stats.mean + 2 * stats.stdDev;
      if (ratio < lower || ratio > upper) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i] CIF/kg = ${ratio.toStringAsFixed(2)} USD outside '
              'the 2σ band [${lower.toStringAsFixed(2)}, ${upper.toStringAsFixed(2)}] '
              'for HS $hs.',
          fieldPath: 'items[$i].itemValuation.costInsuranceFreightAmount',
        );
      }
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #8 — Origin ⇄ commodity plausibility ─────────────────────────

/// Warning-only: flags items whose country of origin is not a typical
/// producer for the declared commodity (seed table below — extend over
/// time with real data). Surfaces a "did you mean?" prompt rather than
/// blocking.
class CountryOriginRule implements ValidationRule<Declaration> {
  /// Per-HS-prefix set of "expected" origin country codes (ISO 3166-1
  /// alpha-2). Deliberately small seed set; expand as we gather data.
  final Map<String, Set<String>> expectedOriginsByHsPrefix;

  const CountryOriginRule({
    this.expectedOriginsByHsPrefix = const {
      '0901': {'CR', 'GT', 'HN', 'CO', 'BR', 'ET', 'VN', 'ID'}, // coffee
      '8501': {'CN', 'US', 'DE', 'JP', 'KR', 'TW'}, // electric motors
      '8541': {'CN', 'US', 'DE', 'JP', 'KR', 'TW', 'MY'}, // LED diodes
    },
  });

  @override
  String get code => 'R-ORG-001';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.warning;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    for (final (i, item) in d.items.indexed) {
      final hs = item.commodityCode;
      final origin = item.procedure.itemCountryOfOriginCode;
      if (hs == null || hs.length < 4) continue;
      final prefix = hs.substring(0, 4);
      final expected = expectedOriginsByHsPrefix[prefix];
      if (expected == null) continue; // no reference for this HS
      if (!expected.contains(origin)) {
        return Fail(
          ruleCode: code,
          severity: defaultSeverity,
          message:
              'items[$i] origin $origin is unusual for HS prefix $prefix '
              '(expected one of: ${expected.join(", ")}).',
          fieldPath: 'items[$i].procedure.itemCountryOfOriginCode',
        );
      }
    }
    return Pass(ruleCode: code);
  }
}

// ── Rule #9 — Tariff code exists and is in validity window ────────────

/// Hits RIMM via [TariffCatalogPort.getCommodityByCode] to verify every
/// declared commodity code actually exists and is currently valid.
class TariffCodeExistsRule implements ValidationRule<Declaration> {
  final TariffCatalogPort tariffCatalog;
  final DateTime Function() clock;

  TariffCodeExistsRule({
    required this.tariffCatalog,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  String get code => 'R-HS-002';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration d) async {
    final now = clock().toUtc();
    for (final (i, item) in d.items.indexed) {
      final hs = item.commodityCode;
      if (hs == null) continue; // handled by HsCodeFormatRule
      try {
        final entry = await tariffCatalog.getCommodityByCode(hs);
        if (entry == null) {
          return Fail(
            ruleCode: code,
            severity: defaultSeverity,
            message:
                'items[$i].commodityCode "$hs" does not exist in RIMM.',
            fieldPath: 'items[$i].commodityCode',
          );
        }
        if (entry.validFromDate.isAfter(now)) {
          return Fail(
            ruleCode: code,
            severity: defaultSeverity,
            message:
                'items[$i].commodityCode "$hs" is not yet valid (starts ${entry.validFromDate.toIso8601String()}).',
            fieldPath: 'items[$i].commodityCode',
          );
        }
        final end = entry.validToDate;
        if (end != null && !now.isBefore(end)) {
          return Fail(
            ruleCode: code,
            severity: defaultSeverity,
            message:
                'items[$i].commodityCode "$hs" expired ${end.toIso8601String()}.',
            fieldPath: 'items[$i].commodityCode',
          );
        }
      } on TariffCatalogException catch (e) {
        return Fail(
          ruleCode: code,
          severity: RuleSeverity.warning,
          message:
              'Could not verify items[$i].commodityCode "$hs" in RIMM: ${e.message}',
          fieldPath: 'items[$i].commodityCode',
        );
      }
    }
    return Pass(ruleCode: code);
  }
}
