/// Wire DTOs for the dispatch REST endpoints.
///
/// Mirrors the JSON emitted by `apps/server/lib/src/http/dispatch_endpoints.dart`
/// and the ATENA field names carried on the `Declaration` entity. Kept
/// in `apps/mobile` (not libs/domain) so the domain stays pure — the
/// mobile app consumes JSON; it doesn't need the full Declaration
/// aggregate in memory for the dashboard's read path. VRTV-43 (DUA
/// form) will need richer DTOs for submit; those ship with that PR.
///
/// Every DTO is immutable. `fromJson` is strict about required fields
/// so malformed payloads surface as parse errors at the boundary
/// instead of `null` leaking into widgets.
library;

import 'package:aduanext_domain/aduanext_domain.dart';

/// Summary view of a dispatch in the list. The backend `GET
/// /api/v1/dispatches` will eventually emit one of these per row.
///
/// Until the read model lands (the backend currently returns 501), the
/// `FakeApiClient` shapes identical data so the dashboard UI can be
/// built and reviewed before the backend catches up.
class DispatchSummary {
  /// Stable declaration ID from the client — the key on both ends.
  final String declarationId;

  /// ATENA-assigned registration number once accepted
  /// (`customsRegistrationNumber` from the submit response). Null when
  /// still a draft or registration failed.
  final String? customsRegistrationNumber;

  /// Current state of the declaration. Maps to
  /// [DeclarationStatus.code]; parsed via `DeclarationStatus.fromCode`.
  final DeclarationStatus status;

  /// Human-readable commercial description — first line of the first
  /// item, truncated. Used as the card subtitle in the dashboard.
  final String commercialDescription;

  /// Exporter's cédula jurídica — rendered in the UI as "Vertivo S.A."
  /// after the company autocomplete resolves it.
  final String exporterCode;

  /// Exporter display name (resolved server-side from the company
  /// registry). Null if the tenant hasn't synced the exporter yet.
  final String? exporterName;

  /// "001", "005", etc. — ATENA customs office code.
  final String officeOfDispatchExportCode;

  /// Incoterm code (FOB, CIF, FCA, ...) from `shipping.deliveryTermsCode`.
  final String? incotermCode;

  /// Total invoice amount in foreign currency, from `sadValuation`.
  final double? invoiceAmount;

  /// ISO currency code (USD, EUR, CRC, ...).
  final String? invoiceCurrencyCode;

  /// 0-100 risk score from VRTV-42 pre-validation. Null when the
  /// declaration hasn't been pre-validated yet.
  final int? riskScore;

  /// Timestamps (ISO-8601 UTC) captured at each state transition —
  /// used to render the timeline dots. Keys match the
  /// [DeclarationStatus.code] string.
  final Map<String, DateTime> stateTimestamps;

  /// Last time the record was touched by backend (any transition or
  /// mutation). Drives the "hace 4h" relative time in the list.
  final DateTime lastUpdatedAt;

  /// Optional ATENA error envelope when `status == rejected` — shown
  /// verbatim in the red error card. Always null for non-rejected.
  final DispatchError? atenaError;

  const DispatchSummary({
    required this.declarationId,
    required this.status,
    required this.commercialDescription,
    required this.exporterCode,
    required this.officeOfDispatchExportCode,
    required this.stateTimestamps,
    required this.lastUpdatedAt,
    this.customsRegistrationNumber,
    this.exporterName,
    this.incotermCode,
    this.invoiceAmount,
    this.invoiceCurrencyCode,
    this.riskScore,
    this.atenaError,
  });

  factory DispatchSummary.fromJson(Map<String, dynamic> json) {
    final statusCode = _requireString(json, 'status');
    final tsRaw = json['stateTimestamps'];
    final Map<String, DateTime> timestamps = {};
    if (tsRaw is Map<String, dynamic>) {
      for (final entry in tsRaw.entries) {
        final v = entry.value;
        if (v is String) timestamps[entry.key] = DateTime.parse(v).toUtc();
      }
    }

    final errorRaw = json['atenaError'];
    return DispatchSummary(
      declarationId: _requireString(json, 'declarationId'),
      status: DeclarationStatus.fromCode(statusCode),
      commercialDescription: _requireString(json, 'commercialDescription'),
      exporterCode: _requireString(json, 'exporterCode'),
      officeOfDispatchExportCode:
          _requireString(json, 'officeOfDispatchExportCode'),
      customsRegistrationNumber:
          json['customsRegistrationNumber'] as String?,
      exporterName: json['exporterName'] as String?,
      incotermCode: json['incotermCode'] as String?,
      invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
      invoiceCurrencyCode: json['invoiceCurrencyCode'] as String?,
      riskScore: (json['riskScore'] as num?)?.toInt(),
      stateTimestamps: timestamps,
      lastUpdatedAt: DateTime.parse(_requireString(json, 'lastUpdatedAt'))
          .toUtc(),
      atenaError: errorRaw is Map<String, dynamic>
          ? DispatchError.fromJson(errorRaw)
          : null,
    );
  }

  /// Number of hours since [lastUpdatedAt] — for the "hace 4h" badge.
  int hoursSinceUpdate(DateTime now) =>
      now.toUtc().difference(lastUpdatedAt).inHours;
}

/// Paginated dispatch list response.
class DispatchListResponse {
  final List<DispatchSummary> items;
  final int total;
  final int offset;
  final int limit;

  const DispatchListResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  factory DispatchListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) {
      throw const FormatException('"items" must be a JSON array');
    }
    return DispatchListResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(DispatchSummary.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? raw.length,
    );
  }

  bool get hasMore => offset + items.length < total;
}

/// ATENA error envelope attached to rejected dispatches.
class DispatchError {
  final String code; // e.g. "E-VAL-0042"
  final String message; // long Spanish message

  const DispatchError({required this.code, required this.message});

  factory DispatchError.fromJson(Map<String, dynamic> json) => DispatchError(
        code: _requireString(json, 'code'),
        message: _requireString(json, 'message'),
      );
}

/// Single event on the audit timeline for a dispatch.
///
/// Named `DispatchAuditEvent` rather than plain `AuditEvent` to avoid
/// the collision with `AuditEvent` in `aduanext_domain` (the domain
/// port shape) — keeping the DTO explicitly wire-side lets the mobile
/// layer evolve the surface without rippling into domain tests.
class DispatchAuditEvent {
  final String id;
  final DateTime at;
  final String actorId;
  final String actorName;
  final String action; // e.g. "classification.confirmed"
  final Map<String, dynamic> payload;

  const DispatchAuditEvent({
    required this.id,
    required this.at,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.payload,
  });

  factory DispatchAuditEvent.fromJson(Map<String, dynamic> json) =>
      DispatchAuditEvent(
        id: _requireString(json, 'id'),
        at: DateTime.parse(_requireString(json, 'at')).toUtc(),
        actorId: _requireString(json, 'actorId'),
        actorName: _requireString(json, 'actorName'),
        action: _requireString(json, 'action'),
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ??
            const {},
      );
}

/// Real-time stream event (SSE). Implemented client-side in VRTV-86;
/// the DTO lives here so both the stream and list code reuse it.
class DispatchUpdate {
  final String declarationId;
  final DeclarationStatus status;
  final DateTime at;

  /// Partial update to apply to the existing [DispatchSummary] — only
  /// the fields that changed are emitted.
  final Map<String, dynamic> patch;

  const DispatchUpdate({
    required this.declarationId,
    required this.status,
    required this.at,
    required this.patch,
  });

  factory DispatchUpdate.fromJson(Map<String, dynamic> json) {
    final statusCode = _requireString(json, 'status');
    return DispatchUpdate(
      declarationId: _requireString(json, 'declarationId'),
      status: DeclarationStatus.fromCode(statusCode),
      at: DateTime.parse(_requireString(json, 'at')).toUtc(),
      patch: (json['patch'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

String _requireString(Map<String, dynamic> json, String field) {
  final v = json[field];
  if (v is! String) {
    throw FormatException(
      '"$field" is required and must be a JSON string '
      '(got ${v?.runtimeType})',
    );
  }
  return v;
}
