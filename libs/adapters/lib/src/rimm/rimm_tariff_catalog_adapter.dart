/// Adapter: RIMM Tariff Catalog — Implements [TariffCatalogPort] via gRPC sidecar.
///
/// Uses [HaciendaApiClient.rimmSearch] to query the RIMM (Reference Information
/// Management Module) which provides tariff codes, exchange rates, delivery
/// terms, and customs office lookups for Costa Rica's ATENA system.
///
/// Each RIMM endpoint is accessed via a generic search RPC with different
/// `endpoint` values: "commodity/search", "exchangeRate/search", etc.
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'dart:convert';

import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';

import '../generated/hacienda.pbgrpc.dart';
import '../grpc/grpc_channel_manager.dart';

/// Domain exception for tariff catalog operations.
class TariffCatalogException implements Exception {
  final String message;
  final String? grpcCode;

  const TariffCatalogException(this.message, {this.grpcCode});

  @override
  String toString() => 'TariffCatalogException: $message'
      '${grpcCode != null ? ' (gRPC: $grpcCode)' : ''}';
}

/// Implements [TariffCatalogPort] by delegating to the hacienda-sidecar
/// [HaciendaApiClient.rimmSearch] gRPC method.
class RimmTariffCatalogAdapter implements TariffCatalogPort {
  final GrpcChannelManager _channelManager;

  HaciendaApiClient? _client;

  RimmTariffCatalogAdapter({
    required GrpcChannelManager channelManager,
  }) : _channelManager = channelManager;

  HaciendaApiClient get _apiClient =>
      _client ??= HaciendaApiClient(_channelManager.channel);

  @override
  Future<List<CommodityEntry>> searchCommodities(
    TariffSearchParams params,
  ) async {
    try {
      final restrictions = <RimmRestriction>[];

      if (params.textQuery != null && params.textQuery!.isNotEmpty) {
        restrictions.add(RimmRestriction(
          value: params.textQuery!,
          operator: params.operator,
          field_3: params.field ?? 'description',
        ));
      }

      if (params.hsCode != null) {
        restrictions.add(RimmRestriction(
          value: params.hsCode!.code,
          operator: 'STARTS_WITH',
          field_3: 'code',
        ));
      }

      final validityDate = params.validityDate ?? DateTime.now();
      final formattedDate =
          '${validityDate.year}-${validityDate.month.toString().padLeft(2, '0')}-${validityDate.day.toString().padLeft(2, '0')}';

      final request = RimmSearchRequest(
        endpoint: 'commodity/search',
        restrictions: restrictions,
        meta: RimmMeta(
          operator: params.operator,
          validityDate: formattedDate,
        ),
        max: params.maxResults,
        offset: params.offset,
      );

      final response = await _apiClient.rimmSearch(request);

      if (response.hasError() && response.error.isNotEmpty) {
        throw TariffCatalogException(response.error);
      }

      return response.resultList
          .map(_parseCommodityEntry)
          .toList();
    } on GrpcError catch (e) {
      throw TariffCatalogException(
        e.message ?? 'gRPC error during commodity search',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<CommodityEntry?> getCommodityByCode(String code) async {
    try {
      final request = RimmSearchRequest(
        endpoint: 'commodity/search',
        restrictions: [
          RimmRestriction(
            value: code,
            operator: 'EQUALS',
            field_3: 'code',
          ),
        ],
        meta: RimmMeta(
          operator: 'EQUALS',
          validityDate: _todayFormatted(),
        ),
        max: 1,
      );

      final response = await _apiClient.rimmSearch(request);

      if (response.hasError() && response.error.isNotEmpty) {
        throw TariffCatalogException(response.error);
      }

      if (response.resultList.isEmpty) return null;

      return _parseCommodityEntry(response.resultList.first);
    } on GrpcError catch (e) {
      throw TariffCatalogException(
        e.message ?? 'gRPC error fetching commodity by code',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<double> getExchangeRate(String currencyCode, DateTime date) async {
    try {
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final request = RimmSearchRequest(
        endpoint: 'exchangeRate/search',
        restrictions: [
          RimmRestriction(
            value: currencyCode,
            operator: 'EQUALS',
            field_3: 'currencyCode',
          ),
        ],
        meta: RimmMeta(
          operator: 'EQUALS',
          validityDate: formattedDate,
        ),
        max: 1,
      );

      final response = await _apiClient.rimmSearch(request);

      if (response.hasError() && response.error.isNotEmpty) {
        throw TariffCatalogException(
          'Exchange rate lookup failed: ${response.error}',
        );
      }

      if (response.resultList.isEmpty) {
        throw TariffCatalogException(
          'No exchange rate found for $currencyCode on $formattedDate',
        );
      }

      final json =
          jsonDecode(response.resultList.first) as Map<String, dynamic>;
      final rate = json['exchangeRate'] ?? json['rate'] ?? json['value'];

      if (rate == null) {
        throw TariffCatalogException(
          'Exchange rate response missing rate field for $currencyCode',
        );
      }

      return (rate is num) ? rate.toDouble() : double.parse(rate.toString());
    } on GrpcError catch (e) {
      throw TariffCatalogException(
        e.message ?? 'gRPC error fetching exchange rate',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getDeliveryTerms(String code) async {
    try {
      final request = RimmSearchRequest(
        endpoint: 'deliveryTerms/search',
        restrictions: [
          RimmRestriction(
            value: code,
            operator: 'EQUALS',
            field_3: 'code',
          ),
        ],
        meta: RimmMeta(
          operator: 'EQUALS',
          validityDate: _todayFormatted(),
        ),
        max: 1,
      );

      final response = await _apiClient.rimmSearch(request);

      if (response.hasError() && response.error.isNotEmpty) {
        throw TariffCatalogException(
          'Delivery terms lookup failed: ${response.error}',
        );
      }

      if (response.resultList.isEmpty) {
        throw TariffCatalogException(
          'No delivery terms found for code "$code"',
        );
      }

      return jsonDecode(response.resultList.first) as Map<String, dynamic>;
    } on GrpcError catch (e) {
      throw TariffCatalogException(
        e.message ?? 'gRPC error fetching delivery terms',
        grpcCode: e.codeName,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomsOffice(String code) async {
    try {
      final request = RimmSearchRequest(
        endpoint: 'customsOffice/search',
        restrictions: [
          RimmRestriction(
            value: code,
            operator: 'EQUALS',
            field_3: 'code',
          ),
        ],
        meta: RimmMeta(
          operator: 'EQUALS',
          validityDate: _todayFormatted(),
        ),
        max: 1,
      );

      final response = await _apiClient.rimmSearch(request);

      if (response.hasError() && response.error.isNotEmpty) {
        throw TariffCatalogException(
          'Customs office lookup failed: ${response.error}',
        );
      }

      if (response.resultList.isEmpty) {
        throw TariffCatalogException(
          'No customs office found for code "$code"',
        );
      }

      return jsonDecode(response.resultList.first) as Map<String, dynamic>;
    } on GrpcError catch (e) {
      throw TariffCatalogException(
        e.message ?? 'gRPC error fetching customs office',
        grpcCode: e.codeName,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses a JSON string from RIMM into a [CommodityEntry].
  CommodityEntry _parseCommodityEntry(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    // Parse tax rates from the RIMM response.
    final taxRates = <String, double>{};
    final taxes = json['taxes'] as Map<String, dynamic>? ?? {};
    for (final entry in taxes.entries) {
      final rate = entry.value;
      if (rate is num) {
        taxRates[entry.key] = rate.toDouble();
      }
    }

    // Parse validity dates.
    final validFrom = json['validFromDate'] as String? ??
        json['validityStartDate'] as String? ??
        '';
    final validTo = json['validToDate'] as String? ??
        json['validityEndDate'] as String?;

    return CommodityEntry(
      code: json['code'] as String? ?? '',
      hsCode: json['hsCode'] as String? ??
          json['code'] as String? ??
          '',
      description: json['description'] as String? ?? '',
      descriptionTranslated: json['descriptionTranslated'] as String? ??
          json['translatedDescription'] as String?,
      validFromDate: DateTime.tryParse(validFrom) ?? DateTime.now(),
      validToDate: validTo != null ? DateTime.tryParse(validTo) : null,
      nationalPrecision1: json['nationalPrecision1'] as String?,
      nationalPrecision2: json['nationalPrecision2'] as String?,
      nationalPrecision3: json['nationalPrecision3'] as String?,
      nationalPrecision4: json['nationalPrecision4'] as String?,
      supplementaryUnit1Code: json['supplementaryUnit1Code'] as String?,
      supplementaryUnit1Description:
          json['supplementaryUnit1Description'] as String?,
      taxRates: taxRates,
      nationalNoteCode: json['nationalNoteCode'] as String?,
      nationalNoteDescription: json['nationalNoteDescription'] as String?,
      regulationCode: json['regulationCode'] as String?,
      regulationTitle: json['regulationTitle'] as String?,
      isSpecificationCodeMandatory:
          json['isSpecificationCodeMandatory'] as bool? ?? false,
    );
  }

  /// Returns today's date formatted as YYYY-MM-DD.
  String _todayFormatted() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
