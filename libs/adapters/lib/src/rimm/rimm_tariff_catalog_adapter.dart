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

  RimmTariffCatalogAdapter({
    required GrpcChannelManager channelManager,
  }) : _channelManager = channelManager;

  /// Returns a fresh gRPC stub backed by the current channel.
  ///
  /// Not cached — see [AtenaCustomsGatewayAdapter] for rationale: the
  /// channel lifecycle is managed externally and caching a stub risks
  /// leaking a closed channel reference across shutdown/terminate.
  HaciendaApiClient get _apiClient =>
      HaciendaApiClient(_channelManager.channel);

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

      try {
        return response.resultList.map(_parseCommodityEntry).toList();
      } on TariffCatalogException {
        rethrow;
      } on FormatException catch (e) {
        throw TariffCatalogException(
          'Failed to decode commodity search payload from sidecar: ${e.message}',
        );
      } on TypeError catch (e) {
        throw TariffCatalogException(
          'Unexpected commodity entry shape from sidecar: $e',
        );
      }
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

      try {
        return _parseCommodityEntry(response.resultList.first);
      } on TariffCatalogException {
        rethrow;
      } on FormatException catch (e) {
        throw TariffCatalogException(
          'Failed to decode commodity payload for code "$code": ${e.message}',
        );
      } on TypeError catch (e) {
        throw TariffCatalogException(
          'Unexpected commodity entry shape for code "$code": $e',
        );
      }
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

      try {
        final json =
            jsonDecode(response.resultList.first) as Map<String, dynamic>;
        final rate = json['exchangeRate'] ?? json['rate'] ?? json['value'];

        if (rate == null) {
          throw TariffCatalogException(
            'Exchange rate response missing rate field for $currencyCode',
          );
        }

        return (rate is num) ? rate.toDouble() : double.parse(rate.toString());
      } on TariffCatalogException {
        rethrow;
      } on FormatException catch (e) {
        throw TariffCatalogException(
          'Failed to decode exchange rate payload for $currencyCode: ${e.message}',
        );
      } on TypeError catch (e) {
        throw TariffCatalogException(
          'Unexpected exchange rate shape for $currencyCode: $e',
        );
      }
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

      try {
        return jsonDecode(response.resultList.first) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw TariffCatalogException(
          'Failed to decode delivery terms payload for code "$code": ${e.message}',
        );
      } on TypeError catch (e) {
        throw TariffCatalogException(
          'Unexpected delivery terms shape for code "$code": $e',
        );
      }
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

      try {
        return jsonDecode(response.resultList.first) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw TariffCatalogException(
          'Failed to decode customs office payload for code "$code": ${e.message}',
        );
      } on TypeError catch (e) {
        throw TariffCatalogException(
          'Unexpected customs office shape for code "$code": $e',
        );
      }
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
  ///
  /// Throws a [TariffCatalogException] if required fields are missing or
  /// invalid (notably [CommodityEntry.validFromDate]). We intentionally do
  /// NOT fabricate a `DateTime.now()` fallback for validity dates because
  /// that would silently turn broken payloads into valid-looking commodity
  /// entries and poison tariff filtering downstream.
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

    final code = json['code'] as String? ?? '';
    final hsCode = json['hsCode'] as String? ?? code;

    // Parse validity dates. Fail explicitly on missing/invalid data.
    final validFromRaw = json['validFromDate'] as String? ??
        json['validityStartDate'] as String?;
    if (validFromRaw == null || validFromRaw.isEmpty) {
      throw TariffCatalogException(
        'RIMM commodity entry missing validFromDate '
        '(code="$code", hsCode="$hsCode").',
      );
    }
    final validFromDate = DateTime.tryParse(validFromRaw);
    if (validFromDate == null) {
      throw TariffCatalogException(
        'RIMM commodity entry has unparseable validFromDate="$validFromRaw" '
        '(code="$code", hsCode="$hsCode").',
      );
    }

    final validToRaw = json['validToDate'] as String? ??
        json['validityEndDate'] as String?;
    DateTime? validToDate;
    if (validToRaw != null && validToRaw.isNotEmpty) {
      validToDate = DateTime.tryParse(validToRaw);
      if (validToDate == null) {
        throw TariffCatalogException(
          'RIMM commodity entry has unparseable validToDate="$validToRaw" '
          '(code="$code", hsCode="$hsCode").',
        );
      }
    }

    return CommodityEntry(
      code: code,
      hsCode: hsCode,
      description: json['description'] as String? ?? '',
      descriptionTranslated: json['descriptionTranslated'] as String? ??
          json['translatedDescription'] as String?,
      validFromDate: validFromDate,
      validToDate: validToDate,
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
