/// In-memory fake for [ApiClient], used when:
///
///   * `--dart-define=API_FAKE=true` is set (offline dev).
///   * Widget tests need deterministic data without spinning up the
///     backend.
///   * Integration tests exercise the Riverpod graph end-to-end.
///
/// The seed data matches the mockups in
/// `.superpowers/brainstorm/.../08-monitoring-dashboard.html` so the
/// dashboard PRs have the same visual references the design review
/// used.
library;

import 'package:aduanext_domain/aduanext_domain.dart';

import 'api_client.dart';
import 'api_exception.dart';
import 'dispatch_dto.dart';

/// Seed data source — isolated so tests can replace/extend without
/// poking at `FakeApiClient` internals.
class FakeDispatchSeed {
  static List<DispatchSummary> defaults(DateTime now) {
    // Stable "ago" offsets so the "hace Nh" rendering is predictable in
    // screenshots/golden tests.
    DateTime hoursAgo(int h) => now.subtract(Duration(hours: h));
    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    return [
      // 1 — LEVANTE granted (green card in mockup)
      DispatchSummary(
        declarationId: 'DUA-2026-1201',
        customsRegistrationNumber: '001-2026-00001201',
        status: DeclarationStatus.levante,
        commercialDescription:
            'LED grow lights 240W — Shenzhen → Heredia — FCA \$10,000',
        exporterCode: '310100580824',
        exporterName: 'Vertivo S.A.',
        officeOfDispatchExportCode: '001',
        incotermCode: 'FCA',
        invoiceAmount: 10000,
        invoiceCurrencyCode: 'USD',
        riskScore: 18,
        stateTimestamps: {
          'REGISTERED': daysAgo(3),
          'ACCEPTED': daysAgo(3),
          'VALIDATING': daysAgo(2),
          'PAYMENT_PENDING': daysAgo(2),
          'LEVANTE': daysAgo(1),
        },
        lastUpdatedAt: hoursAgo(2),
      ),
      // 2 — In validation with risk score
      DispatchSummary(
        declarationId: 'DUA-2026-1202',
        customsRegistrationNumber: '001-2026-00001202',
        status: DeclarationStatus.validating,
        commercialDescription:
            'Sensores Atlas Scientific — New York → Heredia — FCA \$1,500',
        exporterCode: '310100580824',
        exporterName: 'Vertivo S.A.',
        officeOfDispatchExportCode: '001',
        incotermCode: 'FCA',
        invoiceAmount: 1500,
        invoiceCurrencyCode: 'USD',
        riskScore: 45,
        stateTimestamps: {
          'REGISTERED': hoursAgo(8),
          'ACCEPTED': hoursAgo(6),
          'VALIDATING': hoursAgo(4),
        },
        lastUpdatedAt: hoursAgo(4),
      ),
      // 3 — Rejected (requires action)
      DispatchSummary(
        declarationId: 'DUA-2026-1203',
        customsRegistrationNumber: '001-2026-00001203',
        status: DeclarationStatus.rejected,
        commercialDescription:
            'LED Driver Mean Well — Shenzhen → Heredia — FOB \$2,400',
        exporterCode: '310100580824',
        exporterName: 'Vertivo S.A.',
        officeOfDispatchExportCode: '001',
        incotermCode: 'FOB',
        invoiceAmount: 2400,
        invoiceCurrencyCode: 'USD',
        riskScore: 72,
        stateTimestamps: {
          'REGISTERED': hoursAgo(30),
          'ACCEPTED': hoursAgo(28),
          'VALIDATING': hoursAgo(26),
        },
        lastUpdatedAt: hoursAgo(2),
        atenaError: const DispatchError(
          code: 'E-VAL-0042',
          message:
              'Clasificacion arancelaria 8504.40.0000 no corresponde con '
              'la descripcion comercial declarada. La nota nacional exige '
              'especificacion del tipo de convertidor.',
        ),
      ),
    ];
  }
}

/// [ApiClient] backed entirely by in-memory data. Deterministic: same
/// seed => same output. Does not simulate latency by default; pass
/// `artificialLatency` to exercise loading states in widgets.
class FakeApiClient implements ApiClient {
  final List<DispatchSummary> _dispatches;
  final Map<String, List<DispatchAuditEvent>> _audit;

  /// When set, every method awaits this before returning so the UI
  /// can show loading spinners in screenshots.
  final Duration artificialLatency;

  /// Simulate a specific backend error on the next call. Cleared after
  /// one use so tests don't leak state.
  ApiException? _nextError;

  FakeApiClient({
    List<DispatchSummary>? dispatches,
    Map<String, List<DispatchAuditEvent>>? audit,
    this.artificialLatency = Duration.zero,
    DateTime? now,
  })  : _dispatches =
            dispatches ?? FakeDispatchSeed.defaults(now ?? DateTime.now()),
        _audit = audit ?? <String, List<DispatchAuditEvent>>{};

  /// Queue a single error to be thrown on the next API call — lets
  /// tests exercise 401 / 503 / timeout paths without reaching into
  /// the http layer.
  void queueError(ApiException e) {
    _nextError = e;
  }

  @override
  Future<DispatchListResponse> listDispatches({
    int offset = 0,
    int limit = 50,
    Set<String> statusCodes = const {},
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? riskScoreMin,
    int? riskScoreMax,
    String? exporterCode,
  }) async {
    await _tick();
    final filtered = _dispatches.where((d) {
      if (statusCodes.isNotEmpty && !statusCodes.contains(d.status.code)) {
        return false;
      }
      if (exporterCode != null &&
          exporterCode.isNotEmpty &&
          d.exporterCode != exporterCode) {
        return false;
      }
      if (riskScoreMin != null && (d.riskScore ?? 0) < riskScoreMin) {
        return false;
      }
      if (riskScoreMax != null && (d.riskScore ?? 100) > riskScoreMax) {
        return false;
      }
      if (createdAfter != null) {
        final firstTs = _earliestTimestamp(d);
        if (firstTs == null || firstTs.isBefore(createdAfter.toUtc())) {
          return false;
        }
      }
      if (createdBefore != null) {
        final firstTs = _earliestTimestamp(d);
        if (firstTs == null || firstTs.isAfter(createdBefore.toUtc())) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    final total = filtered.length;
    final end = (offset + limit).clamp(0, total);
    final page = offset >= total
        ? const <DispatchSummary>[]
        : filtered.sublist(offset, end);

    return DispatchListResponse(
      items: page,
      total: total,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<DispatchSummary> getDispatch(String declarationId) async {
    await _tick();
    for (final d in _dispatches) {
      if (d.declarationId == declarationId) return d;
    }
    throw const NotFoundApiException();
  }

  @override
  Future<List<DispatchAuditEvent>> listAuditEvents(
    String declarationId, {
    int offset = 0,
    int limit = 100,
  }) async {
    await _tick();
    final all = _audit[declarationId] ?? const <DispatchAuditEvent>[];
    if (offset >= all.length) return const [];
    return all.sublist(offset, (offset + limit).clamp(0, all.length));
  }

  @override
  Future<void> close() async {
    // No resources to release — kept for interface parity.
  }

  // ─── Internals ────────────────────────────────────────────────

  Future<void> _tick() async {
    final err = _nextError;
    if (err != null) {
      _nextError = null;
      throw err;
    }
    if (artificialLatency > Duration.zero) {
      await Future<void>.delayed(artificialLatency);
    }
  }

  DateTime? _earliestTimestamp(DispatchSummary d) {
    if (d.stateTimestamps.isEmpty) return null;
    return d.stateTimestamps.values
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }
}
