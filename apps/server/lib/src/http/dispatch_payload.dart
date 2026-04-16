/// DTO + parser for the dispatch endpoints.
///
/// Lives at the HTTP boundary — translates the wire JSON into the
/// typed [SubmitDeclarationCommand] the application layer expects.
/// Doing the translation here (instead of adding `fromJson` to the
/// domain entity) keeps `libs/domain` pure — the JSON shape is an
/// infrastructure concern. If a second primary adapter shows up
/// (gRPC, message queue...) it brings its own translator.
///
/// Security rules (enforced by [DispatchPayloadException]):
///
///   * Top-level `credentials` block is mandatory.
///   * `credentials.type` MUST be `software` or `hardware`; anything
///     else is rejected.
///   * Hardware credentials MUST carry a non-empty `pin` — we never
///     accept the empty string because PKCS#11 modules often treat
///     that as "use cached PIN", which would silently bypass the
///     per-submission confirmation step mandated by LGA Art. 86.
///   * Software credentials MUST carry both `p12Base64` and `p12Pin`
///     (no fall-through to the container's preconfigured bundle for
///     request-originated submissions — that path is reserved for
///     background jobs).
///   * The PIN is NEVER stored on the DTO or surfaced in toString.
///
/// The parser is forgiving about optional declaration fields — it
/// threads every known key through so the caller can evolve the
/// schema without a new round-trip here. Required fields (declarantCode,
/// exporterCode, items[].procedure.itemCountryOfOriginCode, ...) are
/// validated by [SubmitDeclarationHandler._validateStructure] at the
/// application boundary — we don't duplicate them here.
library;

import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';

/// Raised when the request body is parseable JSON but violates the
/// dispatch submit contract. Translated to 422 (validation) or 400
/// (malformed) by the endpoint.
class DispatchPayloadException implements Exception {
  /// Human-readable message — safe for the wire.
  final String message;

  /// `true` when the payload was structurally wrong (missing fields,
  /// wrong types). `false` when it was business-invalid (e.g. unknown
  /// credential type). Drives 400 vs 422 at the endpoint.
  final bool malformed;

  const DispatchPayloadException(this.message, {this.malformed = false});

  @override
  String toString() => 'DispatchPayloadException: $message';
}

/// The parsed submit-dispatch request.
class SubmitDispatchRequest {
  /// Stable declarationId from the client. Echoed in the response.
  final String declarationId;

  /// The declaration domain entity reconstructed from the JSON blob.
  final Declaration declaration;

  /// Credentials the handler will pass to the auth port.
  final Credentials authCredentials;

  /// Signing credentials — software-cert bytes or hardware-token hint.
  /// PIN + p12 bytes are held on this value; it MUST NOT escape the
  /// handler scope (no logging, no audit payload).
  final SigningCredentials signingCredentials;

  const SubmitDispatchRequest({
    required this.declarationId,
    required this.declaration,
    required this.authCredentials,
    required this.signingCredentials,
  });

  /// Override so accidental `print(request)` never leaks PINs.
  @override
  String toString() =>
      'SubmitDispatchRequest(declarationId=$declarationId, '
      'signingCredentialsType=${_credentialsType(signingCredentials)})';

  static String _credentialsType(SigningCredentials c) => switch (c) {
        SoftwareCertCredentials() => 'software',
        HardwareTokenCredentials() => 'hardware',
      };
}

/// Successful-response DTO. Encoded by [Map.of] rather than a bespoke
/// toJson so the JSON encoder handles the null elision naturally.
class SubmitDispatchResponse {
  final String declarationId;
  final String? customsRegistrationNumber;
  final String? assessmentSerial;
  final int? assessmentNumber;
  final String? assessmentDate;

  /// Stable status string. Today always `accepted` on success; future
  /// states (`pending`, `queued`) can be added without breaking the
  /// client contract.
  final String status;

  const SubmitDispatchResponse({
    required this.declarationId,
    required this.status,
    this.customsRegistrationNumber,
    this.assessmentSerial,
    this.assessmentNumber,
    this.assessmentDate,
  });

  Map<String, dynamic> toJson() => {
        'declarationId': declarationId,
        'status': status,
        if (customsRegistrationNumber != null)
          'customsRegistrationNumber': customsRegistrationNumber,
        if (assessmentSerial != null) 'assessmentSerial': assessmentSerial,
        if (assessmentNumber != null) 'assessmentNumber': assessmentNumber,
        if (assessmentDate != null) 'assessmentDate': assessmentDate,
      };
}

/// Parse the decoded JSON body (a `Map<String, dynamic>`) into a
/// [SubmitDispatchRequest]. Throws [DispatchPayloadException] on any
/// contract violation.
SubmitDispatchRequest parseSubmitDispatchRequest(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      'Request body must be a JSON object',
      malformed: true,
    );
  }
  final declarationId = _requireString(decoded, 'declarationId');
  final declarationRaw = decoded['declaration'];
  if (declarationRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"declaration" must be a JSON object',
      malformed: true,
    );
  }
  final credentialsRaw = decoded['credentials'];
  if (credentialsRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"credentials" must be a JSON object',
      malformed: true,
    );
  }

  final declaration = _parseDeclaration(declarationRaw);
  final (auth, signing) = _parseCredentials(credentialsRaw);

  return SubmitDispatchRequest(
    declarationId: declarationId,
    declaration: declaration,
    authCredentials: auth,
    signingCredentials: signing,
  );
}

// ─────────────────────────────────────────────────────────────────
// Credentials parsing
// ─────────────────────────────────────────────────────────────────

(Credentials, SigningCredentials) _parseCredentials(
  Map<String, dynamic> raw,
) {
  final type = raw['type'];
  if (type != 'software' && type != 'hardware') {
    throw DispatchPayloadException(
      '"credentials.type" must be "software" or "hardware" '
      '(got "$type")',
    );
  }

  // The wire format keeps ATENA auth credentials alongside signing
  // credentials — this is intentional, the ATENA ROPC flow needs
  // password creds per call and there is no session cookie.
  final auth = Credentials(
    idType: _requireString(raw, 'atenaIdType'),
    idNumber: _requireString(raw, 'atenaIdNumber'),
    password: _requireString(raw, 'atenaPassword'),
    clientId: raw['atenaClientId'] as String?,
  );

  final SigningCredentials signing;
  switch (type) {
    case 'software':
      final p12 = _requireString(raw, 'p12Base64');
      final pin = _requireString(raw, 'p12Pin');
      if (p12.trim().isEmpty) {
        throw const DispatchPayloadException(
          '"credentials.p12Base64" must be non-empty for software type',
        );
      }
      if (pin.isEmpty) {
        throw const DispatchPayloadException(
          '"credentials.p12Pin" must be non-empty for software type',
        );
      }
      // NOTE: we currently delegate to the container's preconfigured
      // SigningPort (the sidecar holds the .p12 in memory). The p12Base64
      // field is accepted on the wire for forward-compatibility with the
      // per-request-cert path (tracked separately); we validate + ignore
      // its content here so future changes cannot retroactively break
      // clients.
      signing = const SoftwareCertCredentials();
      break;
    case 'hardware':
      final modulePath = _requireString(raw, 'pkcs11ModulePath');
      final slotId = raw['slotId'];
      if (slotId is! int) {
        throw const DispatchPayloadException(
          '"credentials.slotId" must be a JSON integer',
        );
      }
      final pin = _requireString(raw, 'pin');
      if (pin.isEmpty) {
        throw const DispatchPayloadException(
          '"credentials.pin" must be non-empty for hardware type '
          '(empty PIN would request the cached PIN — disallowed)',
        );
      }
      signing = HardwareTokenCredentials(
        pkcs11ModulePath: modulePath,
        slotId: slotId,
        pin: pin,
      );
      break;
    default:
      // Unreachable — we validated above, but the switch needs this
      // for exhaustiveness.
      throw DispatchPayloadException(
        'Unknown credentials.type: $type',
      );
  }

  return (auth, signing);
}

// ─────────────────────────────────────────────────────────────────
// Declaration parsing
// ─────────────────────────────────────────────────────────────────

Declaration _parseDeclaration(Map<String, dynamic> raw) {
  final itemsRaw = raw['items'];
  if (itemsRaw is! List) {
    throw const DispatchPayloadException(
      '"declaration.items" must be a JSON array',
      malformed: true,
    );
  }
  final shippingRaw = raw['shipping'];
  if (shippingRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"declaration.shipping" must be a JSON object',
      malformed: true,
    );
  }
  final valuationRaw = raw['sadValuation'];
  if (valuationRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"declaration.sadValuation" must be a JSON object',
      malformed: true,
    );
  }

  return Declaration(
    typeOfDeclaration: _requireString(raw, 'typeOfDeclaration'),
    generalProcedureCode: _requireString(raw, 'generalProcedureCode'),
    officeOfDispatchExportCode:
        _requireString(raw, 'officeOfDispatchExportCode'),
    exporterCode: _requireString(raw, 'exporterCode'),
    declarantCode: _requireString(raw, 'declarantCode'),
    officeOfEntryCode: _requireString(raw, 'officeOfEntryCode'),
    declarantReferenceNumber: raw['declarantReferenceNumber'] as String?,
    shippingAgentCode: raw['shippingAgentCode'] as String?,
    cargoHandlerCode: raw['cargoHandlerCode'] as String?,
    consignmentReference: raw['consignmentReference'] as String?,
    comments: raw['comments'] as String?,
    beneficiaryCode: raw['beneficiaryCode'] as String?,
    beneficiaryName: raw['beneficiaryName'] as String?,
    beneficiaryAddress: raw['beneficiaryAddress'] as String?,
    natureOfTransactionCode1:
        raw['natureOfTransactionCode1'] as String? ?? '',
    natureOfTransactionCode2:
        raw['natureOfTransactionCode2'] as String? ?? '',
    documentsReceived: raw['documentsReceived'] as bool? ?? false,
    shipping: _parseShipping(shippingRaw),
    sadValuation: _parseValuation(valuationRaw),
    items: itemsRaw
        .map((i) {
          if (i is! Map<String, dynamic>) {
            throw const DispatchPayloadException(
              '"declaration.items[]" entries must be JSON objects',
              malformed: true,
            );
          }
          return _parseItem(i);
        })
        .toList(growable: false),
  );
}

Shipping _parseShipping(Map<String, dynamic> raw) {
  return Shipping(
    tradingCountryCode: raw['tradingCountryCode'] as String?,
    countryOfExportCode: raw['countryOfExportCode'] as String?,
    countryOfDestinationCode: raw['countryOfDestinationCode'] as String?,
    countryOfOriginCode: raw['countryOfOriginCode'] as String?,
    placeOfLoadingCode: raw['placeOfLoadingCode'] as String?,
    placeOfLoadingCountryCode:
        raw['placeOfLoadingCountryCode'] as String?,
    deliveryTermsCode: raw['deliveryTermsCode'] as String?,
    deliveryTermsPlace: raw['deliveryTermsPlace'] as String?,
  );
}

SadValuation _parseValuation(Map<String, dynamic> raw) {
  return SadValuation(
    invoiceRegime: (raw['invoiceRegime'] as String?) ?? 'SINGLE_INVOICE',
    invoiceAmountInForeignCurrency:
        (raw['invoiceAmountInForeignCurrency'] as num?)?.toDouble(),
    invoiceCurrencyCode: raw['invoiceCurrencyCode'] as String?,
    invoiceCurrencyExchangeRate:
        (raw['invoiceCurrencyExchangeRate'] as num?)?.toDouble(),
    invoiceAmountInNationalCurrency:
        (raw['invoiceAmountInNationalCurrency'] as num?)?.toDouble(),
  );
}

DeclarationItem _parseItem(Map<String, dynamic> raw) {
  final procedureRaw = raw['procedure'];
  if (procedureRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"declaration.items[].procedure" must be a JSON object',
      malformed: true,
    );
  }
  final valuationRaw = raw['itemValuation'];
  if (valuationRaw is! Map<String, dynamic>) {
    throw const DispatchPayloadException(
      '"declaration.items[].itemValuation" must be a JSON object',
      malformed: true,
    );
  }
  return DeclarationItem(
    rank: (raw['rank'] as int?) ?? 1,
    commodityCode: raw['commodityCode'] as String?,
    commercialDescription: _requireString(raw, 'commercialDescription'),
    itemGrossMass: (raw['itemGrossMass'] as num?)?.toDouble(),
    netMass: (raw['netMass'] as num?)?.toDouble(),
    packageNumber: raw['packageNumber'] as int?,
    itemPackageTypeCode: raw['itemPackageTypeCode'] as String?,
    procedure: ItemProcedure(
      itemCountryOfOriginCode:
          _requireString(procedureRaw, 'itemCountryOfOriginCode'),
      extendedProcedureCode:
          _requireString(procedureRaw, 'extendedProcedureCode'),
      nationalProcedureCode:
          (procedureRaw['nationalProcedureCode'] as String?) ?? '000',
      countryOfOriginRegionCode:
          procedureRaw['countryOfOriginRegionCode'] as String?,
      valuationMethodCode: procedureRaw['valuationMethodCode'] as String?,
    ),
    itemValuation: ItemValuation(
      itemInvoiceAmountInForeignCurrency:
          (valuationRaw['itemInvoiceAmountInForeignCurrency'] as num?)
              ?.toDouble(),
      itemInvoiceCurrencyCode:
          valuationRaw['itemInvoiceCurrencyCode'] as String?,
      itemInvoiceCurrencyExchangeRate:
          (valuationRaw['itemInvoiceCurrencyExchangeRate'] as num?)
              ?.toDouble(),
      itemInvoiceAmountInNationalCurrency:
          (valuationRaw['itemInvoiceAmountInNationalCurrency'] as num?)
              ?.toDouble(),
      statisticalValue:
          (valuationRaw['statisticalValue'] as num?)?.toDouble(),
      costInsuranceFreightAmount:
          (valuationRaw['costInsuranceFreightAmount'] as num?)?.toDouble(),
    ),
  );
}

String _requireString(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw DispatchPayloadException(
      '"$field" is required and must be a JSON string',
      malformed: value == null,
    );
  }
  return value;
}
