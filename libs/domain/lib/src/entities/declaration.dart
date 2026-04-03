/// Entity: Declaration (DUA — Documento Único Aduanero)
///
/// Field names match the ATENA API JSON schema exactly.
/// Source: SIAA-ATENA-DUA-GUIA-TECNICA.pdf, Annex 1 (pages 46-62)
///
/// This is the core aggregate root. All customs operations revolve around it.
///
/// Architecture: Domain Entity — pure business object, zero I/O.
library;

import 'package:meta/meta.dart';
import '../value_objects/declaration_status.dart';
import '../value_objects/hs_code.dart';

/// The root entity for a customs declaration.
@immutable
class Declaration {
  // --- Header (from ATENA JSON root level) ---
  final int? id;
  final int? version;
  final String typeOfDeclaration; // "EX" for export
  final String generalProcedureCode; // "1" or "8"
  final String? typeOfTransitDocumentCode;
  final String officeOfDispatchExportCode; // "001", "005", etc.
  final String? declarationFlow;
  final String exporterCode; // Cédula jurídica, e.g., "310100580824"
  final String? consigneeCode;
  final String? consigneeName;
  final String? consigneeAddress;
  final String declarantCode; // Agent code, e.g., "310100975830"
  final String? declarantReferenceNumber;
  final String? shippingAgentCode;
  final String? cargoHandlerCode;
  final String? consignmentReference;
  final String? comments;
  final String? beneficiaryCode;
  final String? beneficiaryName;
  final String? beneficiaryAddress;
  final String natureOfTransactionCode1;
  final String natureOfTransactionCode2;
  final bool documentsReceived;

  // --- Transport ---
  final String? identityOfMeansOfTransportAtBorder;
  final String? nationalityOfMeansOfTransportAtBorderCode;
  final String? modeOfTransportAtBorderCode;
  final String? identityOfMeansOfTransportAtDepartureOrArrival;
  final String? nationalityOfMeansOfTransportAtArrivalDepartureCode;
  final String officeOfEntryCode; // "002", "003", etc.
  final String? inlandModeOfTransportCode;
  final String? locationOfGoodsCode;

  // --- Financial ---
  final String? bankCode;
  final String? bankBranchCode;
  final String? bankAccountNumber;
  final String? warehouseCode;
  final String? previousCompanyCode;
  final String? originWarehouseForTransferCode;

  // --- Nested objects ---
  final Shipping shipping;
  final Transit? transit;
  final SadValuation sadValuation;
  final List<DeclarationItem> items;
  final List<Invoice> invoices;
  final List<GlobalTax> globalTaxes;
  final List<String> ignoredWarnings;

  // --- Registration (populated after ATENA acceptance) ---
  final String? customsRegistrationNumber;
  final String? customsRegistrationSerial;
  final String? customsRegistrationDate;
  final int? customsRegistrationYear;
  final String? assessmentSerial;
  final int? assessmentNumber;
  final String? assessmentDate;
  final int? assessmentYear;

  // --- Status ---
  final DeclarationStatus status;
  final String? paymentStatus; // "TO_BE_PAID", etc.

  // --- Totals (calculated by ATENA) ---
  final int? totalNumberOfItems;
  final int? totalNumberOfPackages;
  final int? totalNumberOfContainers;
  final int? totalNumberOfAttachedDocuments;
  final double? totalGrossMass;
  final double? totalNetMass;
  final double? totalGlobalTaxes;
  final double? guaranteeAmount;
  final double? totalAssessedAmount;
  final double? totalPaidAmount;
  final double? totalAmountToBePaid;

  const Declaration({
    this.id,
    this.version,
    required this.typeOfDeclaration,
    required this.generalProcedureCode,
    this.typeOfTransitDocumentCode,
    required this.officeOfDispatchExportCode,
    this.declarationFlow,
    required this.exporterCode,
    this.consigneeCode,
    this.consigneeName,
    this.consigneeAddress,
    required this.declarantCode,
    this.declarantReferenceNumber,
    this.shippingAgentCode,
    this.cargoHandlerCode,
    this.consignmentReference,
    this.comments,
    this.beneficiaryCode,
    this.beneficiaryName,
    this.beneficiaryAddress,
    this.natureOfTransactionCode1 = '',
    this.natureOfTransactionCode2 = '',
    this.documentsReceived = false,
    this.identityOfMeansOfTransportAtBorder,
    this.nationalityOfMeansOfTransportAtBorderCode,
    this.modeOfTransportAtBorderCode,
    this.identityOfMeansOfTransportAtDepartureOrArrival,
    this.nationalityOfMeansOfTransportAtArrivalDepartureCode,
    required this.officeOfEntryCode,
    this.inlandModeOfTransportCode,
    this.locationOfGoodsCode,
    this.bankCode,
    this.bankBranchCode,
    this.bankAccountNumber,
    this.warehouseCode,
    this.previousCompanyCode,
    this.originWarehouseForTransferCode,
    required this.shipping,
    this.transit,
    required this.sadValuation,
    required this.items,
    this.invoices = const [],
    this.globalTaxes = const [],
    this.ignoredWarnings = const [],
    this.customsRegistrationNumber,
    this.customsRegistrationSerial,
    this.customsRegistrationDate,
    this.customsRegistrationYear,
    this.assessmentSerial,
    this.assessmentNumber,
    this.assessmentDate,
    this.assessmentYear,
    this.status = DeclarationStatus.draft,
    this.paymentStatus,
    this.totalNumberOfItems,
    this.totalNumberOfPackages,
    this.totalNumberOfContainers,
    this.totalNumberOfAttachedDocuments,
    this.totalGrossMass,
    this.totalNetMass,
    this.totalGlobalTaxes,
    this.guaranteeAmount,
    this.totalAssessedAmount,
    this.totalPaidAmount,
    this.totalAmountToBePaid,
  });
}

/// Shipping details — ATENA JSON "shipping" object.
@immutable
class Shipping {
  final String? tradingCountryCode;
  final String? countryOfExportCode; // "CR"
  final String? countryOfDestinationCode; // "US", "DE", etc.
  final String? countryOfOriginCode;
  final String? countryOfLastConsignmentCode;
  final String? placeOfLoadingCode; // "USMIA", "USSAV", etc.
  final String? placeOfLoadingCountryCode;
  final String? deliveryTermsCode; // INCOTERM: "FOB", "CIF", "CIP"
  final String? deliveryTermsPlace;
  final String? deliveryTermsSituationCode;
  final String? countryOfDestinationRegionCode;
  final String? countryOfExportRegionCode;

  const Shipping({
    this.tradingCountryCode,
    this.countryOfExportCode,
    this.countryOfDestinationCode,
    this.countryOfOriginCode,
    this.countryOfLastConsignmentCode,
    this.placeOfLoadingCode,
    this.placeOfLoadingCountryCode,
    this.deliveryTermsCode,
    this.deliveryTermsPlace,
    this.deliveryTermsSituationCode,
    this.countryOfDestinationRegionCode,
    this.countryOfExportRegionCode,
  });
}

/// Transit details — ATENA JSON "transit" object.
@immutable
class Transit {
  final String? principalCode;
  final String? principalRepresentative;
  final String? transitDate;
  final String? transitPlace;
  final String? transitOfficeOfDestinationCode;
  final String? transitCountryOfDestinationCode;
  final String? transitTimeLimit;
  final String? guaranteeReferenceCode;
  final String? trucksNumber;

  const Transit({
    this.principalCode,
    this.principalRepresentative,
    this.transitDate,
    this.transitPlace,
    this.transitOfficeOfDestinationCode,
    this.transitCountryOfDestinationCode,
    this.transitTimeLimit,
    this.guaranteeReferenceCode,
    this.trucksNumber,
  });
}

/// SAD Valuation — ATENA JSON "sadValuation" object.
/// Contains invoice totals, freight, insurance, and exchange rates.
@immutable
class SadValuation {
  final String invoiceRegime; // "SINGLE_INVOICE"
  final double? totalAmountOfAddedCosts;
  final double? totalAmountOfCostInsuranceFreight;
  final double? invoiceAmountInForeignCurrency;
  final String? invoiceCurrencyCode; // "USD"
  final double? invoiceCurrencyExchangeRate; // 513.13
  final double? invoiceAmountInNationalCurrency;

  // External freight
  final double? externalFreightAmountInForeignCurrency;
  final String? externalFreightCurrencyCode;
  final double? externalFreightCurrencyExchangeRate;

  // Internal freight
  final double? internalFreightAmountInForeignCurrency;
  final String? internalFreightCurrencyCode;

  // Insurance
  final double? insuranceAmountInForeignCurrency;
  final String? insuranceCurrencyCode;

  // Other costs
  final double? otherCostsAmountInForeignCurrency;
  final String? otherCostsCurrencyCode;

  // Deductions
  final double? deductionsAmountInForeignCurrency;
  final String? deductionsCurrencyCode;

  const SadValuation({
    this.invoiceRegime = 'SINGLE_INVOICE',
    this.totalAmountOfAddedCosts,
    this.totalAmountOfCostInsuranceFreight,
    this.invoiceAmountInForeignCurrency,
    this.invoiceCurrencyCode,
    this.invoiceCurrencyExchangeRate,
    this.invoiceAmountInNationalCurrency,
    this.externalFreightAmountInForeignCurrency,
    this.externalFreightCurrencyCode,
    this.externalFreightCurrencyExchangeRate,
    this.internalFreightAmountInForeignCurrency,
    this.internalFreightCurrencyCode,
    this.insuranceAmountInForeignCurrency,
    this.insuranceCurrencyCode,
    this.otherCostsAmountInForeignCurrency,
    this.otherCostsCurrencyCode,
    this.deductionsAmountInForeignCurrency,
    this.deductionsCurrencyCode,
  });
}

/// A line item in the declaration — ATENA JSON "items[]" object.
@immutable
class DeclarationItem {
  final int? id;
  final int? version;
  final int rank;
  final String? commodityCode; // Full tariff code, e.g., "48191000"
  final String? commodityCodeNationalPrecision2; // "00"
  final String? commodityCodeNationalPrecision3; // "00"
  final String? commodityCodeNationalPrecision4;
  final String? specificationCode;
  final String commercialDescription; // Must be specific per DGA manual point 13
  final String? invoiceReference; // "SINGLE_INVOICE_REFERENCE"
  final int? invoiceLine;
  final double? itemGrossMass;
  final double? netMass;
  final int? packageNumber;
  final String? packageMark1;
  final String? packageMark2;
  final String? itemPackageTypeCode; // "BX", "AE", etc.
  final String? modeOfPayment;
  final double? dutiesAndTaxesAmount;
  final double? guaranteedAmount;

  // Procedure
  final ItemProcedure procedure;

  // Item valuation
  final ItemValuation itemValuation;

  // Attached documents
  final List<AttachedDocument> attachedDocuments;

  // Containers
  final List<Container> containers;

  // Vehicle identification numbers
  final List<String> vins;

  // Item taxes
  final List<ItemTax> itemTaxes;

  const DeclarationItem({
    this.id,
    this.version,
    this.rank = 1,
    this.commodityCode,
    this.commodityCodeNationalPrecision2,
    this.commodityCodeNationalPrecision3,
    this.commodityCodeNationalPrecision4,
    this.specificationCode,
    required this.commercialDescription,
    this.invoiceReference,
    this.invoiceLine,
    this.itemGrossMass,
    this.netMass,
    this.packageNumber,
    this.packageMark1,
    this.packageMark2,
    this.itemPackageTypeCode,
    this.modeOfPayment,
    this.dutiesAndTaxesAmount,
    this.guaranteedAmount,
    required this.procedure,
    required this.itemValuation,
    this.attachedDocuments = const [],
    this.containers = const [],
    this.vins = const [],
    this.itemTaxes = const [],
  });

  HsCode? get hsCode =>
      commodityCode != null ? HsCode(commodityCode!) : null;
}

/// Item procedure details — ATENA JSON "items[].procedure" object.
@immutable
class ItemProcedure {
  final String? quota;
  final String? valuationMethodCode;
  final String? countryOfOriginRegionCode;
  final String itemCountryOfOriginCode; // "CR"
  final String extendedProcedureCode; // "1000", "8000"
  final String nationalProcedureCode; // "000"
  final String? processingProgramsProductCode;
  final PreviousDocument? previousDocument;

  const ItemProcedure({
    this.quota,
    this.valuationMethodCode,
    this.countryOfOriginRegionCode,
    required this.itemCountryOfOriginCode,
    required this.extendedProcedureCode,
    this.nationalProcedureCode = '000',
    this.processingProgramsProductCode,
    this.previousDocument,
  });
}

@immutable
class PreviousDocument {
  final String? previousCustomsOffice;
  final String? previousRegistrationNumber;
  final String? previousRegistrationSerial;
  final String? previousRegistrationYear;
  final String? previousItemRank;

  const PreviousDocument({
    this.previousCustomsOffice,
    this.previousRegistrationNumber,
    this.previousRegistrationSerial,
    this.previousRegistrationYear,
    this.previousItemRank,
  });
}

/// Item valuation — ATENA JSON "items[].itemValuation" object.
@immutable
class ItemValuation {
  final double? itemInvoiceAmountInForeignCurrency;
  final String? itemInvoiceCurrencyCode; // "USD"
  final double? itemInvoiceCurrencyExchangeRate;
  final double? itemInvoiceAmountInNationalCurrency;
  final double? statisticalValue;
  final double? costInsuranceFreightAmount;
  final double? marketValueAmount;
  final double? marketValueRate;
  final String? marketValueCurrencyCode;
  final String? marketValueBasisDescription;
  final double? marketValueBasisAmount;

  // Per-item freight, insurance, other costs, deductions (foreign + national)
  final double? itemExternalFreightAmountInForeignCurrency;
  final double? itemInternalFreightAmountInForeignCurrency;
  final double? itemInsuranceAmountInForeignCurrency;
  final double? itemOtherCostsAmountInForeignCurrency;
  final double? itemDeductionsAmountInForeignCurrency;

  const ItemValuation({
    this.itemInvoiceAmountInForeignCurrency,
    this.itemInvoiceCurrencyCode,
    this.itemInvoiceCurrencyExchangeRate,
    this.itemInvoiceAmountInNationalCurrency,
    this.statisticalValue,
    this.costInsuranceFreightAmount,
    this.marketValueAmount,
    this.marketValueRate,
    this.marketValueCurrencyCode,
    this.marketValueBasisDescription,
    this.marketValueBasisAmount,
    this.itemExternalFreightAmountInForeignCurrency,
    this.itemInternalFreightAmountInForeignCurrency,
    this.itemInsuranceAmountInForeignCurrency,
    this.itemOtherCostsAmountInForeignCurrency,
    this.itemDeductionsAmountInForeignCurrency,
  });
}

/// Attached document — ATENA JSON "items[].attachedDocuments[]" object.
@immutable
class AttachedDocument {
  final String attachedDocCode; // "003" for factura
  final String attachedDocReference;
  final String? date;
  final String? path; // Returned by API #6 (upload), e.g., "temp-20241219/..."

  const AttachedDocument({
    required this.attachedDocCode,
    required this.attachedDocReference,
    this.date,
    this.path,
  });
}

/// Container — ATENA JSON "items[].containers[]" object.
@immutable
class Container {
  final String containerReference; // "DMOU2459120"
  final String? containerTypeCode; // "45VH"
  final String? sealNumber1;
  final String? sealingPartyCode;
  final int? numberOfPackages;
  final String? emptyFullIndicatorCode;

  const Container({
    required this.containerReference,
    this.containerTypeCode,
    this.sealNumber1,
    this.sealingPartyCode,
    this.numberOfPackages,
    this.emptyFullIndicatorCode,
  });
}

/// Invoice — ATENA JSON "invoices[]" object.
@immutable
class Invoice {
  final String? invoiceReference; // "SINGLE_INVOICE_REFERENCE"
  final String? workingMode; // "PER_VALUE", "PER_WEIGHT"
  final String? deliveryTermsCode; // INCOTERM: "FOB", "CIF"
  final String? termsOfPaymentCode;
  final String? exporterName;
  final String? exporterAddress;
  final double? invoiceAmountInForeignCurrency;
  final String? invoiceCurrencyCode;
  final double? invoiceCurrencyExchangeRate;
  final double? totalAmountOfCostInsuranceFreight;

  const Invoice({
    this.invoiceReference,
    this.workingMode,
    this.deliveryTermsCode,
    this.termsOfPaymentCode,
    this.exporterName,
    this.exporterAddress,
    this.invoiceAmountInForeignCurrency,
    this.invoiceCurrencyCode,
    this.invoiceCurrencyExchangeRate,
    this.totalAmountOfCostInsuranceFreight,
  });
}

/// Global tax — ATENA JSON "globalTaxes[]" object.
/// Example codes: "PRO" (Pago PROCOMER), "G20" (Mejora Puestos Fronterizos),
///   "G38"/"G39" (Gravamen TM Ley 8461), "G40"/"G41" (Impuesto TM Ley 6975)
@immutable
class GlobalTax {
  final String code;
  final String? description;
  final double amount;
  final double? baseAmount;
  final double? rate;
  final bool manual;
  final String? methodOfPayment;
  final String? benCode;
  final String? benName;
  final double? initAmount;

  const GlobalTax({
    required this.code,
    this.description,
    required this.amount,
    this.baseAmount,
    this.rate,
    this.manual = false,
    this.methodOfPayment,
    this.benCode,
    this.benName,
    this.initAmount,
  });
}

/// Item tax — ATENA JSON "items[].itemTaxes[]" object.
@immutable
class ItemTax {
  final String code;
  final String? description;
  final double amount;
  final double? baseAmount;
  final double? rate;

  const ItemTax({
    required this.code,
    this.description,
    required this.amount,
    this.baseAmount,
    this.rate,
  });
}
