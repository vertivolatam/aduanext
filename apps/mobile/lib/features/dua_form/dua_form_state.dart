/// Immutable value object for a DUA draft in flight.
///
/// Only the fields agents actually fill are modeled here — the full
/// ATENA `Declaration` aggregate is assembled at submit time by
/// [DuaFormSubmitMapper] (lands with VRTV-89). Keeping the draft
/// lean lets us serialize it to `SharedPreferences` for autosave
/// without dragging the rest of the domain aggregate through the
/// web storage.
///
/// Steps flag whether they're complete via `complete()` — the
/// stepper semáforo reads this to paint bubble tones.
library;

import 'package:meta/meta.dart';

import 'steps.dart';

@immutable
class DuaDraftLineItem {
  /// User-facing description. Confidence-weighted text that the
  /// classifier uses for AI suggestions.
  final String commercialDescription;

  /// HS code selected by the agent (via RIMM drawer). Null until the
  /// agent confirms a classification.
  final String? hsCode;

  /// Quantity (units) — `null` when still blank.
  final double? quantity;

  /// Gross mass in kg.
  final double? grossMassKg;

  /// FOB value in the invoice currency.
  final double? fobAmount;

  const DuaDraftLineItem({
    this.commercialDescription = '',
    this.hsCode,
    this.quantity,
    this.grossMassKg,
    this.fobAmount,
  });

  DuaDraftLineItem copyWith({
    String? commercialDescription,
    String? hsCode,
    double? quantity,
    double? grossMassKg,
    double? fobAmount,
  }) =>
      DuaDraftLineItem(
        commercialDescription:
            commercialDescription ?? this.commercialDescription,
        hsCode: hsCode ?? this.hsCode,
        quantity: quantity ?? this.quantity,
        grossMassKg: grossMassKg ?? this.grossMassKg,
        fobAmount: fobAmount ?? this.fobAmount,
      );

  /// Whether this item has enough data to ship as part of the DUA.
  /// The items step only flips verde when every line passes.
  bool get isComplete =>
      commercialDescription.trim().isNotEmpty &&
      hsCode != null &&
      (quantity ?? 0) > 0 &&
      (grossMassKg ?? 0) > 0 &&
      (fobAmount ?? 0) > 0;

  Map<String, Object?> toJson() => {
        'commercialDescription': commercialDescription,
        'hsCode': hsCode,
        'quantity': quantity,
        'grossMassKg': grossMassKg,
        'fobAmount': fobAmount,
      };

  factory DuaDraftLineItem.fromJson(Map<String, dynamic> json) =>
      DuaDraftLineItem(
        commercialDescription:
            (json['commercialDescription'] as String?) ?? '',
        hsCode: json['hsCode'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble(),
        grossMassKg: (json['grossMassKg'] as num?)?.toDouble(),
        fobAmount: (json['fobAmount'] as num?)?.toDouble(),
      );
}

/// A single invoice attached to the DUA (Step 5).
@immutable
class DuaDraftInvoice {
  /// Invoice number from the supplier (free-form).
  final String number;

  /// Issue date in ISO-8601 (yyyy-MM-dd). Null until the agent picks.
  final DateTime? issueDate;

  /// Supplier legal name (free-form for MVP — company registry
  /// lookup lands with the same ticket that adds exporter autocomplete).
  final String supplier;

  /// Total amount in the invoice currency.
  final double? totalAmount;

  /// ISO 4217 currency code (USD, EUR, CRC, CNY, ...).
  final String currencyCode;

  const DuaDraftInvoice({
    this.number = '',
    this.issueDate,
    this.supplier = '',
    this.totalAmount,
    this.currencyCode = 'USD',
  });

  DuaDraftInvoice copyWith({
    String? number,
    DateTime? issueDate,
    String? supplier,
    double? totalAmount,
    String? currencyCode,
  }) =>
      DuaDraftInvoice(
        number: number ?? this.number,
        issueDate: issueDate ?? this.issueDate,
        supplier: supplier ?? this.supplier,
        totalAmount: totalAmount ?? this.totalAmount,
        currencyCode: currencyCode ?? this.currencyCode,
      );

  bool get isComplete =>
      number.trim().isNotEmpty &&
      issueDate != null &&
      supplier.trim().isNotEmpty &&
      (totalAmount ?? 0) > 0 &&
      currencyCode.isNotEmpty;

  Map<String, Object?> toJson() => {
        'number': number,
        'issueDate': issueDate?.toUtc().toIso8601String(),
        'supplier': supplier,
        'totalAmount': totalAmount,
        'currencyCode': currencyCode,
      };

  factory DuaDraftInvoice.fromJson(Map<String, dynamic> json) => DuaDraftInvoice(
        number: (json['number'] as String?) ?? '',
        issueDate: json['issueDate'] == null
            ? null
            : DateTime.parse(json['issueDate'] as String).toUtc(),
        supplier: (json['supplier'] as String?) ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble(),
        currencyCode: (json['currencyCode'] as String?) ?? 'USD',
      );
}

/// A single supporting document attached to the DUA (Step 6).
@immutable
class DuaDraftDocument {
  /// ATENA UNCL1001 document code (380 = commercial invoice, 705 =
  /// bill of lading, ...).
  final String code;

  /// Human-readable name shown in the list row.
  final String displayName;

  /// User-facing file name. Real upload URL/hash lands when VRTV-48
  /// wires the storage port.
  final String? fileName;

  /// When true, the checklist flags this doc as required for the
  /// regimen — missing = red tone on the stepper semáforo.
  final bool required;

  const DuaDraftDocument({
    required this.code,
    required this.displayName,
    required this.required,
    this.fileName,
  });

  DuaDraftDocument copyWith({
    String? code,
    String? displayName,
    bool? required,
    String? fileName,
  }) =>
      DuaDraftDocument(
        code: code ?? this.code,
        displayName: displayName ?? this.displayName,
        required: required ?? this.required,
        fileName: fileName ?? this.fileName,
      );

  bool get attached => fileName != null && fileName!.isNotEmpty;

  Map<String, Object?> toJson() => {
        'code': code,
        'displayName': displayName,
        'required': required,
        'fileName': fileName,
      };

  factory DuaDraftDocument.fromJson(Map<String, dynamic> json) =>
      DuaDraftDocument(
        code: json['code'] as String,
        displayName: json['displayName'] as String,
        required: (json['required'] as bool?) ?? false,
        fileName: json['fileName'] as String?,
      );
}

@immutable
class DuaDraft {
  /// Stable client-side id — persists across autosave snapshots so the
  /// submit endpoint deduplicates retries.
  final String draftId;

  /// Step 1 — General
  final String exporterCode;
  final String exporterName;
  final String customsOfficeCode;

  /// Step 2 — Envío
  final String? incotermCode; // "FOB", "CIF", "FCA", ...
  final String? countryOfOriginCode;
  final String? countryOfDestinationCode;
  final String? transportModeCode;

  /// Step 3 — Items
  final List<DuaDraftLineItem> items;

  /// Step 4 — Valoración
  final String? invoiceCurrencyCode;
  final double? exchangeRate;

  /// Freight cost (CRC or invoiceCurrency — UI decides) used for
  /// FOB→CIF conversion on Step 4.
  final double? freightAmount;

  /// Insurance cost — FOB + freight + insurance = CIF.
  final double? insuranceAmount;

  /// Step 5 — Facturas (list of structured invoices).
  final List<DuaDraftInvoice> invoices;

  /// Step 6 — Documentos (structured checklist with required flags).
  final List<DuaDraftDocument> documents;

  /// Step 7 — Revisión is a read-only step; submission state lives
  /// on the notifier (not persisted — you can't resume a submit).

  /// The agent's current step. Drives the stepper's "azul" bubble.
  final DuaFormStep currentStep;

  /// Timestamps for autosave. `updatedAt` is refreshed on every
  /// mutation; `savedAt` is refreshed after a successful persist.
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? savedAt;

  const DuaDraft({
    required this.draftId,
    required this.createdAt,
    required this.updatedAt,
    this.exporterCode = '',
    this.exporterName = '',
    this.customsOfficeCode = '',
    this.incotermCode,
    this.countryOfOriginCode,
    this.countryOfDestinationCode,
    this.transportModeCode,
    this.items = const [],
    this.invoiceCurrencyCode,
    this.exchangeRate,
    this.freightAmount,
    this.insuranceAmount,
    this.invoices = const [],
    this.documents = const [],
    this.currentStep = DuaFormStep.general,
    this.savedAt,
  });

  factory DuaDraft.fresh({required String draftId, required DateTime now}) =>
      DuaDraft(draftId: draftId, createdAt: now, updatedAt: now);

  DuaDraft copyWith({
    String? exporterCode,
    String? exporterName,
    String? customsOfficeCode,
    String? incotermCode,
    String? countryOfOriginCode,
    String? countryOfDestinationCode,
    String? transportModeCode,
    List<DuaDraftLineItem>? items,
    String? invoiceCurrencyCode,
    double? exchangeRate,
    double? freightAmount,
    double? insuranceAmount,
    List<DuaDraftInvoice>? invoices,
    List<DuaDraftDocument>? documents,
    DuaFormStep? currentStep,
    DateTime? updatedAt,
    DateTime? savedAt,
  }) =>
      DuaDraft(
        draftId: draftId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        exporterCode: exporterCode ?? this.exporterCode,
        exporterName: exporterName ?? this.exporterName,
        customsOfficeCode: customsOfficeCode ?? this.customsOfficeCode,
        incotermCode: incotermCode ?? this.incotermCode,
        countryOfOriginCode: countryOfOriginCode ?? this.countryOfOriginCode,
        countryOfDestinationCode:
            countryOfDestinationCode ?? this.countryOfDestinationCode,
        transportModeCode: transportModeCode ?? this.transportModeCode,
        items: items ?? this.items,
        invoiceCurrencyCode: invoiceCurrencyCode ?? this.invoiceCurrencyCode,
        exchangeRate: exchangeRate ?? this.exchangeRate,
        freightAmount: freightAmount ?? this.freightAmount,
        insuranceAmount: insuranceAmount ?? this.insuranceAmount,
        invoices: invoices ?? this.invoices,
        documents: documents ?? this.documents,
        currentStep: currentStep ?? this.currentStep,
        savedAt: savedAt ?? this.savedAt,
      );

  // ─── Computed totals ───────────────────────────────────────────

  /// Total FOB across all items (quantity × unit FOB).
  double get totalFob => items.fold<double>(
        0,
        (sum, i) => sum + ((i.quantity ?? 0) * (i.fobAmount ?? 0)),
      );

  /// FOB + freight + insurance = CIF (Step 4 CIF calculator).
  double get totalCif =>
      totalFob + (freightAmount ?? 0) + (insuranceAmount ?? 0);

  /// Sum of invoice totals in their invoice currency (Step 5).
  double get totalInvoiceAmount => invoices.fold<double>(
        0,
        (sum, i) => sum + (i.totalAmount ?? 0),
      );

  // ─── Step completeness ─────────────────────────────────────────

  bool get step1Complete =>
      exporterCode.isNotEmpty &&
      exporterName.isNotEmpty &&
      customsOfficeCode.isNotEmpty;

  bool get step2Complete =>
      incotermCode != null &&
      incotermCode!.isNotEmpty &&
      countryOfOriginCode != null &&
      countryOfOriginCode!.isNotEmpty &&
      countryOfDestinationCode != null &&
      countryOfDestinationCode!.isNotEmpty;

  bool get step3Complete =>
      items.isNotEmpty && items.every((i) => i.isComplete);

  bool get step4Complete =>
      invoiceCurrencyCode != null &&
      invoiceCurrencyCode!.isNotEmpty &&
      (exchangeRate ?? 0) > 0;

  bool get step5Complete =>
      invoices.isNotEmpty && invoices.every((i) => i.isComplete);

  /// Step 6 — every *required* doc has a file attached.
  bool get step6Complete =>
      documents.isNotEmpty &&
      documents.where((d) => d.required).every((d) => d.attached);

  bool isStepComplete(DuaFormStep step) {
    switch (step) {
      case DuaFormStep.general:
        return step1Complete;
      case DuaFormStep.shipping:
        return step2Complete;
      case DuaFormStep.items:
        return step3Complete;
      case DuaFormStep.valuation:
        return step4Complete;
      case DuaFormStep.invoices:
        return step5Complete;
      case DuaFormStep.documents:
        return step6Complete;
      case DuaFormStep.review:
        return step1Complete &&
            step2Complete &&
            step3Complete &&
            step4Complete &&
            step5Complete &&
            step6Complete;
    }
  }

  /// Whether a step is reachable — gates tab navigation so agents
  /// can't jump ahead past incomplete prerequisites. Past + current
  /// steps are always reachable.
  bool isStepUnlocked(DuaFormStep step) {
    if (step.index <= currentStep.index) return true;
    // Future step unlocked only when all prior steps pass.
    for (var i = 0; i < step.index; i++) {
      if (!isStepComplete(DuaFormStep.values[i])) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        'draftId': draftId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'savedAt': savedAt?.toUtc().toIso8601String(),
        'exporterCode': exporterCode,
        'exporterName': exporterName,
        'customsOfficeCode': customsOfficeCode,
        'incotermCode': incotermCode,
        'countryOfOriginCode': countryOfOriginCode,
        'countryOfDestinationCode': countryOfDestinationCode,
        'transportModeCode': transportModeCode,
        'items': items.map((i) => i.toJson()).toList(),
        'invoiceCurrencyCode': invoiceCurrencyCode,
        'exchangeRate': exchangeRate,
        'freightAmount': freightAmount,
        'insuranceAmount': insuranceAmount,
        'invoices': invoices.map((i) => i.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
        'currentStep': currentStep.name,
      };

  factory DuaDraft.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final rawInvoices = (json['invoices'] as List?) ?? const [];
    final rawDocs = (json['documents'] as List?) ?? const [];
    final stepName = json['currentStep'] as String? ?? DuaFormStep.general.name;
    final step = DuaFormStep.values.firstWhere(
      (s) => s.name == stepName,
      orElse: () => DuaFormStep.general,
    );
    return DuaDraft(
      draftId: json['draftId'] as String,
      createdAt:
          DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt:
          DateTime.parse(json['updatedAt'] as String).toUtc(),
      savedAt: json['savedAt'] == null
          ? null
          : DateTime.parse(json['savedAt'] as String).toUtc(),
      exporterCode: (json['exporterCode'] as String?) ?? '',
      exporterName: (json['exporterName'] as String?) ?? '',
      customsOfficeCode: (json['customsOfficeCode'] as String?) ?? '',
      incotermCode: json['incotermCode'] as String?,
      countryOfOriginCode: json['countryOfOriginCode'] as String?,
      countryOfDestinationCode: json['countryOfDestinationCode'] as String?,
      transportModeCode: json['transportModeCode'] as String?,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(DuaDraftLineItem.fromJson)
          .toList(growable: false),
      invoiceCurrencyCode: json['invoiceCurrencyCode'] as String?,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble(),
      freightAmount: (json['freightAmount'] as num?)?.toDouble(),
      insuranceAmount: (json['insuranceAmount'] as num?)?.toDouble(),
      invoices: rawInvoices
          .whereType<Map<String, dynamic>>()
          .map(DuaDraftInvoice.fromJson)
          .toList(growable: false),
      documents: rawDocs
          .whereType<Map<String, dynamic>>()
          .map(DuaDraftDocument.fromJson)
          .toList(growable: false),
      currentStep: step,
    );
  }
}
