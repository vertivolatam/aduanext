/// Adapter: ATENA Customs Gateway — Implements [CustomsGatewayPort] via gRPC sidecar.
///
/// Uses [HaciendaApiClient] to proxy all DUA API operations through the
/// hacienda-sidecar: validate, liquidate, rectify, get status, upload docs.
///
/// The Declaration entity is serialized to JSON for the gRPC payload,
/// matching the ATENA API schema exactly.
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'dart:convert';

import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';

import '../generated/hacienda.pbgrpc.dart';
import '../grpc/grpc_channel_manager.dart';

/// Domain exception for customs gateway operations.
class CustomsGatewayException implements Exception {
  final String message;
  final int? httpStatus;
  final String? grpcCode;

  const CustomsGatewayException(
    this.message, {
    this.httpStatus,
    this.grpcCode,
  });

  @override
  String toString() => 'CustomsGatewayException: $message'
      '${httpStatus != null ? ' (HTTP $httpStatus)' : ''}'
      '${grpcCode != null ? ' (gRPC: $grpcCode)' : ''}';
}

/// Implements [CustomsGatewayPort] by delegating to the hacienda-sidecar
/// [HaciendaApiClient] gRPC service.
class AtenaCustomsGatewayAdapter implements CustomsGatewayPort {
  final GrpcChannelManager _channelManager;

  HaciendaApiClient? _client;

  AtenaCustomsGatewayAdapter({
    required GrpcChannelManager channelManager,
  }) : _channelManager = channelManager;

  HaciendaApiClient get _apiClient =>
      _client ??= HaciendaApiClient(_channelManager.channel);

  @override
  Future<DeclarationResult> submitDeclaration(Declaration declaration) async {
    // Submit = liquidate in ATENA (DUA API #3).
    return liquidateDeclaration(declaration);
  }

  @override
  Future<ValidationResult> validateDeclaration(Declaration declaration) async {
    try {
      final jsonPayload = _declarationToJson(declaration);

      final response = await _apiClient.validateDeclaration(
        ValidateDeclarationRequest(jsonPayload: jsonPayload),
      );

      return _parseValidationResult(response);
    } on GrpcError catch (e) {
      throw CustomsGatewayException(
        e.message ?? 'gRPC error during declaration validation',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<DeclarationStatus> getDeclarationStatus(
    String registrationKey,
  ) async {
    try {
      // registrationKey format: "officeCode-serial-number-year"
      final parts = registrationKey.split('-');
      if (parts.length < 4) {
        throw CustomsGatewayException(
          'Invalid registration key format. '
          'Expected "officeCode-serial-number-year", got "$registrationKey".',
        );
      }

      final response = await _apiClient.getDeclaration(
        GetDeclarationRequest(
          customsOfficeCode: parts[0],
          serial: parts[1],
          number: int.tryParse(parts[2]) ?? 0,
          year: int.tryParse(parts[3]) ?? 0,
        ),
      );

      if (response.hasError() && response.error.isNotEmpty) {
        throw CustomsGatewayException(
          response.error,
          httpStatus: response.httpStatus,
        );
      }

      final json = jsonDecode(response.jsonPayload) as Map<String, dynamic>;
      final statusCode = json['status'] as String? ?? 'DRAFT';

      return DeclarationStatus.fromCode(statusCode);
    } on GrpcError catch (e) {
      throw CustomsGatewayException(
        e.message ?? 'gRPC error fetching declaration status',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<DeclarationResult> liquidateDeclaration(
    Declaration declaration,
  ) async {
    try {
      final jsonPayload = _declarationToJson(declaration);

      final response = await _apiClient.liquidateDeclaration(
        LiquidateDeclarationRequest(jsonPayload: jsonPayload),
      );

      return _parseDeclarationResult(response);
    } on GrpcError catch (e) {
      throw CustomsGatewayException(
        e.message ?? 'gRPC error during declaration liquidation',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<DeclarationResult> rectifyDeclaration(
    Declaration original,
    Declaration corrected,
  ) async {
    try {
      // First validate the rectification.
      final validateResponse = await _apiClient.validateRectification(
        ValidateRectificationRequest(
          jsonPayload: _declarationToJson(corrected),
        ),
      );

      if (validateResponse.hasError() && validateResponse.error.isNotEmpty) {
        return DeclarationResult(
          success: false,
          errorMessage: validateResponse.error,
          rawResponse: validateResponse.jsonPayload,
        );
      }

      // Then submit the rectification.
      final response = await _apiClient.rectifyDeclaration(
        RectifyDeclarationRequest(
          jsonPayload: _declarationToJson(corrected),
        ),
      );

      return _parseDeclarationResult(response);
    } on GrpcError catch (e) {
      throw CustomsGatewayException(
        e.message ?? 'gRPC error during declaration rectification',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<String> uploadAttachment({
    required String declarationId,
    required String docCode,
    required String docReference,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final response = await _apiClient.uploadDocument(
        UploadDocumentRequest(
          declarationId: declarationId,
          docCode: docCode,
          docReference: docReference,
          fileContent: fileBytes,
          fileName: fileName,
          contentType: _inferContentType(fileName),
        ),
      );

      if (response.hasError() && response.error.isNotEmpty) {
        throw CustomsGatewayException(
          response.error,
          httpStatus: response.httpStatus,
        );
      }

      // The response JSON contains the upload path.
      final json = jsonDecode(response.jsonPayload) as Map<String, dynamic>;
      return json['path'] as String? ?? response.jsonPayload;
    } on GrpcError catch (e) {
      throw CustomsGatewayException(
        e.message ?? 'gRPC error during document upload',
        grpcCode: e.codeName,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Serializes a [Declaration] to a JSON string matching the ATENA API schema.
  String _declarationToJson(Declaration d) {
    final map = <String, dynamic>{
      if (d.id != null) 'id': d.id,
      if (d.version != null) 'version': d.version,
      'typeOfDeclaration': d.typeOfDeclaration,
      'generalProcedureCode': d.generalProcedureCode,
      if (d.typeOfTransitDocumentCode != null)
        'typeOfTransitDocumentCode': d.typeOfTransitDocumentCode,
      'officeOfDispatchExportCode': d.officeOfDispatchExportCode,
      if (d.declarationFlow != null) 'declarationFlow': d.declarationFlow,
      'exporterCode': d.exporterCode,
      if (d.consigneeCode != null) 'consigneeCode': d.consigneeCode,
      if (d.consigneeName != null) 'consigneeName': d.consigneeName,
      if (d.consigneeAddress != null) 'consigneeAddress': d.consigneeAddress,
      'declarantCode': d.declarantCode,
      if (d.declarantReferenceNumber != null)
        'declarantReferenceNumber': d.declarantReferenceNumber,
      if (d.shippingAgentCode != null)
        'shippingAgentCode': d.shippingAgentCode,
      if (d.cargoHandlerCode != null) 'cargoHandlerCode': d.cargoHandlerCode,
      if (d.consignmentReference != null)
        'consignmentReference': d.consignmentReference,
      if (d.comments != null) 'comments': d.comments,
      if (d.beneficiaryCode != null) 'beneficiaryCode': d.beneficiaryCode,
      if (d.beneficiaryName != null) 'beneficiaryName': d.beneficiaryName,
      if (d.beneficiaryAddress != null)
        'beneficiaryAddress': d.beneficiaryAddress,
      'natureOfTransactionCode1': d.natureOfTransactionCode1,
      'natureOfTransactionCode2': d.natureOfTransactionCode2,
      'documentsReceived': d.documentsReceived,
      if (d.identityOfMeansOfTransportAtBorder != null)
        'identityOfMeansOfTransportAtBorder':
            d.identityOfMeansOfTransportAtBorder,
      if (d.nationalityOfMeansOfTransportAtBorderCode != null)
        'nationalityOfMeansOfTransportAtBorderCode':
            d.nationalityOfMeansOfTransportAtBorderCode,
      if (d.modeOfTransportAtBorderCode != null)
        'modeOfTransportAtBorderCode': d.modeOfTransportAtBorderCode,
      if (d.identityOfMeansOfTransportAtDepartureOrArrival != null)
        'identityOfMeansOfTransportAtDepartureOrArrival':
            d.identityOfMeansOfTransportAtDepartureOrArrival,
      if (d.nationalityOfMeansOfTransportAtArrivalDepartureCode != null)
        'nationalityOfMeansOfTransportAtArrivalDepartureCode':
            d.nationalityOfMeansOfTransportAtArrivalDepartureCode,
      'officeOfEntryCode': d.officeOfEntryCode,
      if (d.inlandModeOfTransportCode != null)
        'inlandModeOfTransportCode': d.inlandModeOfTransportCode,
      if (d.locationOfGoodsCode != null)
        'locationOfGoodsCode': d.locationOfGoodsCode,
      if (d.bankCode != null) 'bankCode': d.bankCode,
      if (d.bankBranchCode != null) 'bankBranchCode': d.bankBranchCode,
      if (d.bankAccountNumber != null)
        'bankAccountNumber': d.bankAccountNumber,
      if (d.warehouseCode != null) 'warehouseCode': d.warehouseCode,
      if (d.previousCompanyCode != null)
        'previousCompanyCode': d.previousCompanyCode,
      if (d.originWarehouseForTransferCode != null)
        'originWarehouseForTransferCode': d.originWarehouseForTransferCode,
      'shipping': _shippingToMap(d.shipping),
      if (d.transit != null) 'transit': _transitToMap(d.transit!),
      'sadValuation': _sadValuationToMap(d.sadValuation),
      'items': d.items.map(_itemToMap).toList(),
      if (d.invoices.isNotEmpty)
        'invoices': d.invoices.map(_invoiceToMap).toList(),
      if (d.globalTaxes.isNotEmpty)
        'globalTaxes': d.globalTaxes.map(_globalTaxToMap).toList(),
      if (d.ignoredWarnings.isNotEmpty) 'ignoredWarnings': d.ignoredWarnings,
    };
    return jsonEncode(map);
  }

  Map<String, dynamic> _shippingToMap(Shipping s) => <String, dynamic>{
        if (s.tradingCountryCode != null)
          'tradingCountryCode': s.tradingCountryCode,
        if (s.countryOfExportCode != null)
          'countryOfExportCode': s.countryOfExportCode,
        if (s.countryOfDestinationCode != null)
          'countryOfDestinationCode': s.countryOfDestinationCode,
        if (s.countryOfOriginCode != null)
          'countryOfOriginCode': s.countryOfOriginCode,
        if (s.countryOfLastConsignmentCode != null)
          'countryOfLastConsignmentCode': s.countryOfLastConsignmentCode,
        if (s.placeOfLoadingCode != null)
          'placeOfLoadingCode': s.placeOfLoadingCode,
        if (s.placeOfLoadingCountryCode != null)
          'placeOfLoadingCountryCode': s.placeOfLoadingCountryCode,
        if (s.deliveryTermsCode != null)
          'deliveryTermsCode': s.deliveryTermsCode,
        if (s.deliveryTermsPlace != null)
          'deliveryTermsPlace': s.deliveryTermsPlace,
        if (s.deliveryTermsSituationCode != null)
          'deliveryTermsSituationCode': s.deliveryTermsSituationCode,
        if (s.countryOfDestinationRegionCode != null)
          'countryOfDestinationRegionCode': s.countryOfDestinationRegionCode,
        if (s.countryOfExportRegionCode != null)
          'countryOfExportRegionCode': s.countryOfExportRegionCode,
      };

  Map<String, dynamic> _transitToMap(Transit t) => <String, dynamic>{
        if (t.principalCode != null) 'principalCode': t.principalCode,
        if (t.principalRepresentative != null)
          'principalRepresentative': t.principalRepresentative,
        if (t.transitDate != null) 'transitDate': t.transitDate,
        if (t.transitPlace != null) 'transitPlace': t.transitPlace,
        if (t.transitOfficeOfDestinationCode != null)
          'transitOfficeOfDestinationCode': t.transitOfficeOfDestinationCode,
        if (t.transitCountryOfDestinationCode != null)
          'transitCountryOfDestinationCode': t.transitCountryOfDestinationCode,
        if (t.transitTimeLimit != null) 'transitTimeLimit': t.transitTimeLimit,
        if (t.guaranteeReferenceCode != null)
          'guaranteeReferenceCode': t.guaranteeReferenceCode,
        if (t.trucksNumber != null) 'trucksNumber': t.trucksNumber,
      };

  Map<String, dynamic> _sadValuationToMap(SadValuation sv) =>
      <String, dynamic>{
        'invoiceRegime': sv.invoiceRegime,
        if (sv.totalAmountOfAddedCosts != null)
          'totalAmountOfAddedCosts': sv.totalAmountOfAddedCosts,
        if (sv.totalAmountOfCostInsuranceFreight != null)
          'totalAmountOfCostInsuranceFreight':
              sv.totalAmountOfCostInsuranceFreight,
        if (sv.invoiceAmountInForeignCurrency != null)
          'invoiceAmountInForeignCurrency': sv.invoiceAmountInForeignCurrency,
        if (sv.invoiceCurrencyCode != null)
          'invoiceCurrencyCode': sv.invoiceCurrencyCode,
        if (sv.invoiceCurrencyExchangeRate != null)
          'invoiceCurrencyExchangeRate': sv.invoiceCurrencyExchangeRate,
        if (sv.invoiceAmountInNationalCurrency != null)
          'invoiceAmountInNationalCurrency': sv.invoiceAmountInNationalCurrency,
        if (sv.externalFreightAmountInForeignCurrency != null)
          'externalFreightAmountInForeignCurrency':
              sv.externalFreightAmountInForeignCurrency,
        if (sv.externalFreightCurrencyCode != null)
          'externalFreightCurrencyCode': sv.externalFreightCurrencyCode,
        if (sv.externalFreightCurrencyExchangeRate != null)
          'externalFreightCurrencyExchangeRate':
              sv.externalFreightCurrencyExchangeRate,
        if (sv.internalFreightAmountInForeignCurrency != null)
          'internalFreightAmountInForeignCurrency':
              sv.internalFreightAmountInForeignCurrency,
        if (sv.internalFreightCurrencyCode != null)
          'internalFreightCurrencyCode': sv.internalFreightCurrencyCode,
        if (sv.insuranceAmountInForeignCurrency != null)
          'insuranceAmountInForeignCurrency':
              sv.insuranceAmountInForeignCurrency,
        if (sv.insuranceCurrencyCode != null)
          'insuranceCurrencyCode': sv.insuranceCurrencyCode,
        if (sv.otherCostsAmountInForeignCurrency != null)
          'otherCostsAmountInForeignCurrency':
              sv.otherCostsAmountInForeignCurrency,
        if (sv.otherCostsCurrencyCode != null)
          'otherCostsCurrencyCode': sv.otherCostsCurrencyCode,
        if (sv.deductionsAmountInForeignCurrency != null)
          'deductionsAmountInForeignCurrency':
              sv.deductionsAmountInForeignCurrency,
        if (sv.deductionsCurrencyCode != null)
          'deductionsCurrencyCode': sv.deductionsCurrencyCode,
      };

  Map<String, dynamic> _itemToMap(DeclarationItem item) => <String, dynamic>{
        if (item.id != null) 'id': item.id,
        if (item.version != null) 'version': item.version,
        'rank': item.rank,
        if (item.commodityCode != null) 'commodityCode': item.commodityCode,
        if (item.commodityCodeNationalPrecision2 != null)
          'commodityCodeNationalPrecision2':
              item.commodityCodeNationalPrecision2,
        if (item.commodityCodeNationalPrecision3 != null)
          'commodityCodeNationalPrecision3':
              item.commodityCodeNationalPrecision3,
        if (item.commodityCodeNationalPrecision4 != null)
          'commodityCodeNationalPrecision4':
              item.commodityCodeNationalPrecision4,
        if (item.specificationCode != null)
          'specificationCode': item.specificationCode,
        'commercialDescription': item.commercialDescription,
        if (item.invoiceReference != null)
          'invoiceReference': item.invoiceReference,
        if (item.invoiceLine != null) 'invoiceLine': item.invoiceLine,
        if (item.itemGrossMass != null) 'itemGrossMass': item.itemGrossMass,
        if (item.netMass != null) 'netMass': item.netMass,
        if (item.packageNumber != null) 'packageNumber': item.packageNumber,
        if (item.packageMark1 != null) 'packageMark1': item.packageMark1,
        if (item.packageMark2 != null) 'packageMark2': item.packageMark2,
        if (item.itemPackageTypeCode != null)
          'itemPackageTypeCode': item.itemPackageTypeCode,
        if (item.modeOfPayment != null) 'modeOfPayment': item.modeOfPayment,
        if (item.dutiesAndTaxesAmount != null)
          'dutiesAndTaxesAmount': item.dutiesAndTaxesAmount,
        if (item.guaranteedAmount != null)
          'guaranteedAmount': item.guaranteedAmount,
        'procedure': _procedureToMap(item.procedure),
        'itemValuation': _itemValuationToMap(item.itemValuation),
        if (item.attachedDocuments.isNotEmpty)
          'attachedDocuments':
              item.attachedDocuments.map(_attachedDocToMap).toList(),
        if (item.containers.isNotEmpty)
          'containers': item.containers.map(_containerToMap).toList(),
        if (item.vins.isNotEmpty) 'vins': item.vins,
        if (item.itemTaxes.isNotEmpty)
          'itemTaxes': item.itemTaxes.map(_itemTaxToMap).toList(),
      };

  Map<String, dynamic> _procedureToMap(ItemProcedure p) => <String, dynamic>{
        if (p.quota != null) 'quota': p.quota,
        if (p.valuationMethodCode != null)
          'valuationMethodCode': p.valuationMethodCode,
        if (p.countryOfOriginRegionCode != null)
          'countryOfOriginRegionCode': p.countryOfOriginRegionCode,
        'itemCountryOfOriginCode': p.itemCountryOfOriginCode,
        'extendedProcedureCode': p.extendedProcedureCode,
        'nationalProcedureCode': p.nationalProcedureCode,
        if (p.processingProgramsProductCode != null)
          'processingProgramsProductCode': p.processingProgramsProductCode,
        if (p.previousDocument != null)
          'previousDocument': _previousDocToMap(p.previousDocument!),
      };

  Map<String, dynamic> _previousDocToMap(PreviousDocument pd) =>
      <String, dynamic>{
        if (pd.previousCustomsOffice != null)
          'previousCustomsOffice': pd.previousCustomsOffice,
        if (pd.previousRegistrationNumber != null)
          'previousRegistrationNumber': pd.previousRegistrationNumber,
        if (pd.previousRegistrationSerial != null)
          'previousRegistrationSerial': pd.previousRegistrationSerial,
        if (pd.previousRegistrationYear != null)
          'previousRegistrationYear': pd.previousRegistrationYear,
        if (pd.previousItemRank != null)
          'previousItemRank': pd.previousItemRank,
      };

  Map<String, dynamic> _itemValuationToMap(ItemValuation iv) =>
      <String, dynamic>{
        if (iv.itemInvoiceAmountInForeignCurrency != null)
          'itemInvoiceAmountInForeignCurrency':
              iv.itemInvoiceAmountInForeignCurrency,
        if (iv.itemInvoiceCurrencyCode != null)
          'itemInvoiceCurrencyCode': iv.itemInvoiceCurrencyCode,
        if (iv.itemInvoiceCurrencyExchangeRate != null)
          'itemInvoiceCurrencyExchangeRate':
              iv.itemInvoiceCurrencyExchangeRate,
        if (iv.itemInvoiceAmountInNationalCurrency != null)
          'itemInvoiceAmountInNationalCurrency':
              iv.itemInvoiceAmountInNationalCurrency,
        if (iv.statisticalValue != null) 'statisticalValue': iv.statisticalValue,
        if (iv.costInsuranceFreightAmount != null)
          'costInsuranceFreightAmount': iv.costInsuranceFreightAmount,
        if (iv.marketValueAmount != null)
          'marketValueAmount': iv.marketValueAmount,
        if (iv.marketValueRate != null) 'marketValueRate': iv.marketValueRate,
        if (iv.marketValueCurrencyCode != null)
          'marketValueCurrencyCode': iv.marketValueCurrencyCode,
        if (iv.marketValueBasisDescription != null)
          'marketValueBasisDescription': iv.marketValueBasisDescription,
        if (iv.marketValueBasisAmount != null)
          'marketValueBasisAmount': iv.marketValueBasisAmount,
        if (iv.itemExternalFreightAmountInForeignCurrency != null)
          'itemExternalFreightAmountInForeignCurrency':
              iv.itemExternalFreightAmountInForeignCurrency,
        if (iv.itemInternalFreightAmountInForeignCurrency != null)
          'itemInternalFreightAmountInForeignCurrency':
              iv.itemInternalFreightAmountInForeignCurrency,
        if (iv.itemInsuranceAmountInForeignCurrency != null)
          'itemInsuranceAmountInForeignCurrency':
              iv.itemInsuranceAmountInForeignCurrency,
        if (iv.itemOtherCostsAmountInForeignCurrency != null)
          'itemOtherCostsAmountInForeignCurrency':
              iv.itemOtherCostsAmountInForeignCurrency,
        if (iv.itemDeductionsAmountInForeignCurrency != null)
          'itemDeductionsAmountInForeignCurrency':
              iv.itemDeductionsAmountInForeignCurrency,
      };

  Map<String, dynamic> _attachedDocToMap(AttachedDocument ad) =>
      <String, dynamic>{
        'attachedDocCode': ad.attachedDocCode,
        'attachedDocReference': ad.attachedDocReference,
        if (ad.date != null) 'date': ad.date,
        if (ad.path != null) 'path': ad.path,
      };

  Map<String, dynamic> _containerToMap(Container c) => <String, dynamic>{
        'containerReference': c.containerReference,
        if (c.containerTypeCode != null)
          'containerTypeCode': c.containerTypeCode,
        if (c.sealNumber1 != null) 'sealNumber1': c.sealNumber1,
        if (c.sealingPartyCode != null) 'sealingPartyCode': c.sealingPartyCode,
        if (c.numberOfPackages != null) 'numberOfPackages': c.numberOfPackages,
        if (c.emptyFullIndicatorCode != null)
          'emptyFullIndicatorCode': c.emptyFullIndicatorCode,
      };

  Map<String, dynamic> _invoiceToMap(Invoice inv) => <String, dynamic>{
        if (inv.invoiceReference != null)
          'invoiceReference': inv.invoiceReference,
        if (inv.workingMode != null) 'workingMode': inv.workingMode,
        if (inv.deliveryTermsCode != null)
          'deliveryTermsCode': inv.deliveryTermsCode,
        if (inv.termsOfPaymentCode != null)
          'termsOfPaymentCode': inv.termsOfPaymentCode,
        if (inv.exporterName != null) 'exporterName': inv.exporterName,
        if (inv.exporterAddress != null) 'exporterAddress': inv.exporterAddress,
        if (inv.invoiceAmountInForeignCurrency != null)
          'invoiceAmountInForeignCurrency': inv.invoiceAmountInForeignCurrency,
        if (inv.invoiceCurrencyCode != null)
          'invoiceCurrencyCode': inv.invoiceCurrencyCode,
        if (inv.invoiceCurrencyExchangeRate != null)
          'invoiceCurrencyExchangeRate': inv.invoiceCurrencyExchangeRate,
        if (inv.totalAmountOfCostInsuranceFreight != null)
          'totalAmountOfCostInsuranceFreight':
              inv.totalAmountOfCostInsuranceFreight,
      };

  Map<String, dynamic> _globalTaxToMap(GlobalTax gt) => <String, dynamic>{
        'code': gt.code,
        if (gt.description != null) 'description': gt.description,
        'amount': gt.amount,
        if (gt.baseAmount != null) 'baseAmount': gt.baseAmount,
        if (gt.rate != null) 'rate': gt.rate,
        'manual': gt.manual,
        if (gt.methodOfPayment != null) 'methodOfPayment': gt.methodOfPayment,
        if (gt.benCode != null) 'benCode': gt.benCode,
        if (gt.benName != null) 'benName': gt.benName,
        if (gt.initAmount != null) 'initAmount': gt.initAmount,
      };

  Map<String, dynamic> _itemTaxToMap(ItemTax it) => <String, dynamic>{
        'code': it.code,
        if (it.description != null) 'description': it.description,
        'amount': it.amount,
        if (it.baseAmount != null) 'baseAmount': it.baseAmount,
        if (it.rate != null) 'rate': it.rate,
      };

  /// Parses an [ApiResponse] into a [DeclarationResult].
  DeclarationResult _parseDeclarationResult(ApiResponse response) {
    if (response.hasError() && response.error.isNotEmpty) {
      return DeclarationResult(
        success: false,
        errorMessage: response.error,
        rawResponse: response.jsonPayload,
      );
    }

    try {
      final json = jsonDecode(response.jsonPayload) as Map<String, dynamic>;

      return DeclarationResult(
        success: response.httpStatus >= 200 && response.httpStatus < 300,
        registrationNumber:
            json['customsRegistrationNumber'] as String?,
        assessmentSerial: json['assessmentSerial'] as String?,
        assessmentNumber: json['assessmentNumber'] as int?,
        assessmentDate: json['assessmentDate'] as String?,
        rawResponse: response.jsonPayload,
      );
    } on FormatException {
      return DeclarationResult(
        success: response.httpStatus >= 200 && response.httpStatus < 300,
        rawResponse: response.jsonPayload,
      );
    }
  }

  /// Parses an [ApiResponse] into a [ValidationResult].
  ValidationResult _parseValidationResult(ApiResponse response) {
    if (response.hasError() && response.error.isNotEmpty) {
      return ValidationResult(
        valid: false,
        errors: [
          ValidationError(code: 'GRPC_ERROR', message: response.error),
        ],
      );
    }

    try {
      final json = jsonDecode(response.jsonPayload) as Map<String, dynamic>;
      final errors = <ValidationError>[];
      final warnings = <ValidationWarning>[];

      final errorList = json['errors'] as List<dynamic>? ?? [];
      for (final e in errorList) {
        final errorMap = e as Map<String, dynamic>;
        errors.add(ValidationError(
          code: errorMap['code'] as String? ?? 'UNKNOWN',
          message: errorMap['message'] as String? ?? '',
          field: errorMap['field'] as String?,
        ));
      }

      final warningList = json['warnings'] as List<dynamic>? ?? [];
      for (final w in warningList) {
        final warnMap = w as Map<String, dynamic>;
        warnings.add(ValidationWarning(
          code: warnMap['code'] as String? ?? 'UNKNOWN',
          message: warnMap['message'] as String? ?? '',
        ));
      }

      return ValidationResult(
        valid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } on FormatException {
      return ValidationResult(
        valid: response.httpStatus >= 200 && response.httpStatus < 300,
      );
    }
  }

  /// Infers MIME content type from file extension.
  String _inferContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'xml' => 'application/xml',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }
}
