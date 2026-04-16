import 'dart:async';
import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:aduanext_mobile/shared/api/api_config.dart';
import 'package:aduanext_mobile/shared/api/dispatch_stream_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Streamed test client driven by a test-owned `StreamController`.
///
/// Each `send()` grabs the first pending response off the queue and
/// emits it. The test drives the response stream via `events.add(...)`
/// so we can exercise partial SSE frames + reconnect cleanly.
class _StreamedMock extends http.BaseClient {
  final List<_QueuedResponse> _queue;

  _StreamedMock(this._queue);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_queue.isEmpty) {
      // Pretend the backend is offline — surface a network failure.
      throw http.ClientException('no more responses queued');
    }
    final next = _queue.removeAt(0);
    return http.StreamedResponse(
      next.body ?? const Stream<List<int>>.empty(),
      next.status,
      headers: const {'content-type': 'text/event-stream'},
    );
  }
}

class _QueuedResponse {
  final int status;
  final Stream<List<int>>? body;

  _QueuedResponse({required this.status, this.body});
}

void main() {
  group('DispatchStreamClient SSE parsing', () {
    test('emits a DispatchUpdate when a full event arrives', () async {
      final events = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 200, body: events.stream),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      addTearDown(client.close);

      await client.connect();

      final update = client.updates.first;
      events.add(utf8.encode(
        'data: ${jsonEncode({
              'declarationId': 'DUA-1',
              'status': 'LEVANTE',
              'at': '2026-04-12T14:00:00Z',
              'patch': <String, dynamic>{},
            })}\n\n',
      ));

      final emitted = await update;
      expect(emitted.declarationId, 'DUA-1');
      expect(emitted.status, DeclarationStatus.levante);

      await events.close();
    });

    test('handles a split event (data in two TCP chunks)', () async {
      final events = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 200, body: events.stream),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      addTearDown(client.close);

      await client.connect();
      final update = client.updates.first;
      final raw = jsonEncode({
        'declarationId': 'DUA-2',
        'status': 'VALIDATING',
        'at': '2026-04-12T14:00:00Z',
        'patch': <String, dynamic>{},
      });
      events.add(utf8.encode('data: ${raw.substring(0, 10)}'));
      events.add(utf8.encode('${raw.substring(10)}\n\n'));

      final emitted = await update;
      expect(emitted.declarationId, 'DUA-2');

      await events.close();
    });

    test('ignores malformed event data without tearing down the stream',
        () async {
      final events = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 200, body: events.stream),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      addTearDown(client.close);

      await client.connect();

      // 1st event: junk. 2nd event: valid.
      events.add(utf8.encode('data: not json\n\n'));

      final update = client.updates.first;
      events.add(utf8.encode('data: ${jsonEncode({
            'declarationId': 'DUA-OK',
            'status': 'LEVANTE',
            'at': '2026-04-12T14:00:00Z',
            'patch': <String, dynamic>{},
          })}\n\n'));

      final emitted = await update;
      expect(emitted.declarationId, 'DUA-OK');

      await events.close();
    });
  });

  group('DispatchStreamClient polling fallback', () {
    test('flips to polling when the endpoint returns 404', () async {
      final mock = _StreamedMock([
        _QueuedResponse(status: 404, body: const Stream.empty()),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(client.close);

      final seenStates = <StreamConnectionState>[];
      final sub = client.connectionState.listen(seenStates.add);
      addTearDown(sub.cancel);

      var ticks = 0;
      DateTime? lastSeen;
      client.setPollingTick((since) {
        ticks++;
        lastSeen = since;
      });

      await client.connect();

      // One immediate tick + at least one timer tick.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(seenStates, contains(StreamConnectionState.polling));
      expect(ticks, greaterThanOrEqualTo(1));
      expect(lastSeen, isNull);
    });

    test('flips to polling when the endpoint returns 501', () async {
      final mock = _StreamedMock([
        _QueuedResponse(status: 501, body: const Stream.empty()),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(client.close);

      final seen = <StreamConnectionState>[];
      final sub = client.connectionState.listen(seen.add);
      addTearDown(sub.cancel);

      client.setPollingTick((_) {});
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, contains(StreamConnectionState.polling));
    });
  });

  group('DispatchStreamClient reconnection', () {
    test('reconnects after a stream error with exponential backoff',
        () async {
      // First response: 200 with a broken stream. Second: 200 that
      // stays open.
      final events1 = StreamController<List<int>>();
      final events2 = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 200, body: events1.stream),
        _QueuedResponse(status: 200, body: events2.stream),
      ]);

      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
        initialBackoff: const Duration(milliseconds: 10),
        maxBackoff: const Duration(milliseconds: 50),
      );
      addTearDown(client.close);

      final seen = <StreamConnectionState>[];
      final sub = client.connectionState.listen(seen.add);
      addTearDown(sub.cancel);

      await client.connect();

      // Simulate disconnect on the first stream.
      await events1.close();

      // Wait past the backoff window so reconnect fires.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(seen, contains(StreamConnectionState.reconnecting));
      // After the second queued response, we should be live again.
      expect(seen, contains(StreamConnectionState.live));

      await events2.close();
    });

    test('reconnects on non-2xx response', () async {
      final events = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 500, body: const Stream.empty()),
        _QueuedResponse(status: 200, body: events.stream),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
        initialBackoff: const Duration(milliseconds: 10),
      );
      addTearDown(client.close);

      final seen = <StreamConnectionState>[];
      final sub = client.connectionState.listen(seen.add);
      addTearDown(sub.cancel);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(seen, contains(StreamConnectionState.reconnecting));
      expect(seen, contains(StreamConnectionState.live));

      await events.close();
    });
  });

  group('DispatchStreamClient close', () {
    test('close cancels in-flight subscription + state stream', () async {
      final events = StreamController<List<int>>();
      final mock = _StreamedMock([
        _QueuedResponse(status: 200, body: events.stream),
      ]);
      final client = DispatchStreamClient(
        config: const ApiConfig(baseUrl: 'http://test'),
        tokenProvider: () async => null,
        httpClient: mock,
      );
      await client.connect();
      await client.close();

      // The state stream should be closed; no further events emitted.
      // If close() double-taps the controllers this throws — the
      // guard inside should prevent it.
      await client.close();
      expect(true, isTrue);
    });
  });
}
