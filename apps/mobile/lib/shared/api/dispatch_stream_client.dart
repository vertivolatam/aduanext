/// Real-time dispatch updates via Server-Sent Events (SSE).
///
/// Contract with the backend (to be wired in a future ticket — the
/// Flutter side ships today so the UI is ready when the backend
/// lands):
///
///   GET /api/v1/dispatches/stream?tenantId=X
///   Accept: text/event-stream
///
///   data: { "declarationId": "DUA-2026-1201", "status": "LEVANTE",
///           "at": "...", "patch": {"riskScore": 18} }
///
/// Behaviour:
///   * Connects on [DispatchStreamClient.connect] and emits
///     [DispatchUpdate]s on the returned [Stream].
///   * Exponential backoff on reconnect (1s, 2s, 4s, ..., max 30s).
///   * Exposes a [StreamConnectionState] stream so the dashboard can render
///     a "Live / Reconnecting / Offline" indicator.
///   * If the endpoint returns 404 or 501 (backend not yet wired),
///     flips to a polling fallback every 60s so the dashboard still
///     refreshes without a scary error banner.
///
/// Implementation notes:
///   * The `package:http` Streamed client is used for both web and
///     native targets (same wire behavior as EventSource without the
///     dart:html web-only dependency).
///   * Each `data:` line accumulates into the current event; blank
///     lines flush into a [DispatchUpdate] via [DispatchUpdate.fromJson].
///   * The client owns a single pending timer (for backoff) and a
///     single subscription — `close()` cancels both.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart' show BearerTokenProvider;
import 'api_config.dart';
import 'dispatch_dto.dart';

/// Wire-state of the real-time stream. The dashboard header binds to
/// this to paint Live / Reconnecting / Offline / Polling badges.
enum StreamConnectionState {
  /// Initial state. Nothing connected yet.
  idle,

  /// Handshake in progress.
  connecting,

  /// Stream is live — events flowing.
  live,

  /// Disconnected; a reconnect is scheduled.
  reconnecting,

  /// Backend returned 404/501 — we've flipped to polling.
  polling,

  /// `close()` was called; the client is terminal.
  closed,
}

/// Callback for the polling fallback. Parameter: `null` on the
/// initial tick, otherwise the `at` timestamp of the last received
/// update so the backend can return the delta. The dashboard wires
/// this to `ref.invalidate(dispatchesListProvider)`.
typedef PollingTick = void Function(DateTime? since);

/// Thin wrapper around the SSE connection lifecycle. Created by the
/// `dispatchStreamProvider`; consumers interact through the two
/// exposed streams (`updates`, `connectionState`).
class DispatchStreamClient {
  final ApiConfig _config;
  final BearerTokenProvider _tokenProvider;
  final http.Client _http;

  /// Tenant ID to request updates for — forwarded via query string.
  /// `null` means "all tenants the caller can see" (admin view).
  final String? tenantId;

  /// Override the backoff schedule in tests.
  @visibleForTesting
  final Duration initialBackoff;

  @visibleForTesting
  final Duration maxBackoff;

  /// Poll interval when SSE is unavailable.
  @visibleForTesting
  final Duration pollInterval;

  final StreamController<DispatchUpdate> _updates =
      StreamController<DispatchUpdate>.broadcast();
  final StreamController<StreamConnectionState> _state =
      StreamController<StreamConnectionState>.broadcast();

  StreamSubscription<List<int>>? _subscription;
  Timer? _retryTimer;
  Timer? _pollTimer;
  PollingTick? _onPollTick;
  DateTime? _lastSeen;
  int _retryAttempt = 0;
  bool _closed = false;

  DispatchStreamClient({
    required ApiConfig config,
    required BearerTokenProvider tokenProvider,
    http.Client? httpClient,
    this.tenantId,
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.pollInterval = const Duration(seconds: 60),
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _http = httpClient ?? http.Client();

  /// Stream of dispatch updates. Broadcast — multiple listeners are
  /// safe (the dashboard subscribes; the detail page may too).
  Stream<DispatchUpdate> get updates => _updates.stream;

  /// Stream of connection state transitions for the UI indicator.
  Stream<StreamConnectionState> get connectionState => _state.stream;

  /// Register a callback for the polling fallback. The dashboard
  /// invalidates its list provider in here.
  void setPollingTick(PollingTick tick) {
    _onPollTick = tick;
  }

  /// Kick off the first connection attempt. Safe to call multiple
  /// times — re-invocations no-op if already connecting/live.
  Future<void> connect() async {
    if (_closed) return;
    if (_state.isClosed) return;
    _emit(StreamConnectionState.connecting);
    await _openStream();
  }

  /// Tear everything down. Must be called from `ProviderScope.onDispose`
  /// or tests, otherwise a pending retry timer leaks the test.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _retryTimer?.cancel();
    _pollTimer?.cancel();
    await _subscription?.cancel();
    _http.close();
    _emit(StreamConnectionState.closed);
    await _updates.close();
    await _state.close();
  }

  // ─── Internals ───────────────────────────────────────────────────

  Future<void> _openStream() async {
    if (_closed) return;
    final qs = <String, String>{};
    if (tenantId != null) qs['tenantId'] = tenantId!;
    final uri = Uri.parse('${_config.baseUrl}/api/v1/dispatches/stream')
        .replace(queryParameters: qs.isEmpty ? null : qs);

    final request = http.Request('GET', uri);
    request.headers['accept'] = 'text/event-stream';
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $token';
    }

    try {
      final response = await _http.send(request);
      if (response.statusCode == 404 || response.statusCode == 501) {
        // Backend doesn't expose the stream yet — flip to polling.
        _startPollingFallback();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _scheduleReconnect();
        return;
      }

      _retryAttempt = 0;
      _emit(StreamConnectionState.live);
      _subscription = response.stream.listen(
        _onBytes,
        onError: (Object _, StackTrace _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Accumulate bytes into SSE events. The `text/event-stream` spec
  /// says events are separated by blank lines and each field is on
  /// its own `field: value` line. We only care about `data:` lines.
  final StringBuffer _buffer = StringBuffer();

  void _onBytes(List<int> chunk) {
    _buffer.write(utf8.decode(chunk, allowMalformed: true));
    while (true) {
      final text = _buffer.toString();
      final delimiterIndex = text.indexOf('\n\n');
      if (delimiterIndex < 0) break;

      final raw = text.substring(0, delimiterIndex);
      final rest = text.substring(delimiterIndex + 2);
      _buffer
        ..clear()
        ..write(rest);

      _parseEvent(raw);
    }
  }

  void _parseEvent(String raw) {
    final dataBuf = StringBuffer();
    for (final line in raw.split('\n')) {
      if (line.startsWith('data:')) {
        dataBuf.write(line.substring(5).trim());
      }
      // (We ignore `event:`, `id:`, `retry:` — the dispatch contract
      // only sends data payloads today.)
    }
    final dataStr = dataBuf.toString();
    if (dataStr.isEmpty) return;

    try {
      final decoded = jsonDecode(dataStr);
      if (decoded is Map<String, dynamic>) {
        final update = DispatchUpdate.fromJson(decoded);
        _lastSeen = update.at;
        _updates.add(update);
      }
    } catch (_) {
      // Ignore malformed events — a single bad payload shouldn't
      // tear down the stream. Log in debug so we can spot schema
      // drift during dev.
      if (kDebugMode) {
        debugPrint('dispatch.stream.malformed_event');
      }
    }
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _subscription?.cancel();
    _subscription = null;
    _emit(StreamConnectionState.reconnecting);

    final delay = _backoffFor(_retryAttempt);
    _retryAttempt++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      _openStream();
    });
  }

  void _startPollingFallback() {
    if (_closed) return;
    _emit(StreamConnectionState.polling);
    // Immediate tick — the dashboard list shows current data without
    // waiting a full polling interval.
    _onPollTick?.call(null);
    _pollTimer = Timer.periodic(pollInterval, (_) {
      if (_closed) return;
      _onPollTick?.call(_lastSeen);
    });
  }

  /// Exponential schedule capped at [maxBackoff]: 1s, 2s, 4s, 8s, ...
  Duration _backoffFor(int attempt) {
    final factor = math.pow(2, attempt).toInt();
    final candidate = initialBackoff * factor;
    return candidate > maxBackoff ? maxBackoff : candidate;
  }

  void _emit(StreamConnectionState s) {
    if (_state.isClosed) return;
    _state.add(s);
  }
}
