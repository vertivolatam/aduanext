/// Port: Tariff Catalog — abstracts tariff/HS code lookups.
///
/// In Costa Rica, this maps to RIMM (Reference Information Management Module).
/// Each country has its own tariff catalog structure.
library;

import '../value_objects/hs_code.dart';

/// A commodity entry from the tariff catalog.
class CommodityEntry {
  final String code;
  final String hsCode;
  final String description;
  final String? descriptionTranslated;
  final DateTime validFromDate;
  final DateTime? validToDate;
  final String? nationalPrecision1;
  final String? nationalPrecision2;
  final String? nationalPrecision3;
  final String? nationalPrecision4;
  final String? supplementaryUnit1Code;
  final String? supplementaryUnit1Description;
  final Map<String, double> taxRates;
  final String? nationalNoteCode;
  final String? nationalNoteDescription;
  final String? regulationCode;
  final String? regulationTitle;
  final bool isSpecificationCodeMandatory;

  const CommodityEntry({
    required this.code,
    required this.hsCode,
    required this.description,
    this.descriptionTranslated,
    required this.validFromDate,
    this.validToDate,
    this.nationalPrecision1,
    this.nationalPrecision2,
    this.nationalPrecision3,
    this.nationalPrecision4,
    this.supplementaryUnit1Code,
    this.supplementaryUnit1Description,
    this.taxRates = const {},
    this.nationalNoteCode,
    this.nationalNoteDescription,
    this.regulationCode,
    this.regulationTitle,
    this.isSpecificationCodeMandatory = false,
  });
}

/// Search parameters for querying the tariff catalog.
class TariffSearchParams {
  final String? textQuery;
  final HsCode? hsCode;
  final String? field;
  final String operator;
  final DateTime? validityDate;
  final int maxResults;
  final int offset;

  const TariffSearchParams({
    this.textQuery,
    this.hsCode,
    this.field,
    this.operator = 'FULL_TEXT',
    this.validityDate,
    this.maxResults = 100,
    this.offset = 0,
  });
}

/// Port: Tariff Catalog — country-agnostic tariff lookup interface.
abstract class TariffCatalogPort {
  /// Search commodities by text description or HS code.
  Future<List<CommodityEntry>> searchCommodities(TariffSearchParams params);

  /// Get a specific commodity by its full code (12 digits).
  Future<CommodityEntry?> getCommodityByCode(String code);

  /// Get exchange rate for a currency on a specific date.
  Future<double> getExchangeRate(String currencyCode, DateTime date);

  /// Get INCOTERM (delivery terms) by code.
  Future<Map<String, dynamic>> getDeliveryTerms(String code);

  /// Get customs office information by code.
  Future<Map<String, dynamic>> getCustomsOffice(String code);
}
