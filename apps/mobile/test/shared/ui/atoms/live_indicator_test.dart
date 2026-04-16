import 'dart:async';

import 'package:aduanext_mobile/shared/api/dispatch_dto.dart';
import 'package:aduanext_mobile/shared/api/dispatch_stream_client.dart';
import 'package:aduanext_mobile/shared/api/dispatch_stream_providers.dart';
import 'package:aduanext_mobile/shared/ui/atoms/live_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStreamClient implements DispatchStreamClient {
  final StreamController<StreamConnectionState> _controller;
  final StreamConnectionState _initial;

  _FakeStreamClient(this._initial)
      : _controller = StreamController.broadcast();

  @override
  Stream<StreamConnectionState> get connectionState {
    // Fresh stream per listener that emits the initial state first.
    // Prevents the state loss that happens when the subscription
    // attaches after a microtask-driven initial event.
    late StreamController<StreamConnectionState> sub;
    sub = StreamController<StreamConnectionState>(
      onListen: () {
        sub.add(_initial);
        _controller.stream.pipe(sub);
      },
    );
    return sub.stream;
  }

  @override
  Stream<DispatchUpdate> get updates => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }

  @override
  void setPollingTick(PollingTick tick) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Widget _wrap(DispatchStreamClient client) {
  return ProviderScope(
    overrides: [
      dispatchStreamClientProvider.overrideWith((ref) {
        ref.onDispose(client.close);
        return client;
      }),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Center(child: LiveIndicator()),
      ),
    ),
  );
}

void main() {
  testWidgets('renders "En vivo" for live state', (tester) async {
    final client = _FakeStreamClient(StreamConnectionState.live);
    await tester.pumpWidget(_wrap(client));
    await tester.pumpAndSettle();

    expect(find.text('En vivo'), findsOneWidget);
  });

  testWidgets('renders "Reconectando..." for reconnecting state',
      (tester) async {
    final client = _FakeStreamClient(StreamConnectionState.reconnecting);
    await tester.pumpWidget(_wrap(client));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reconectando...'), findsOneWidget);
    // Pause the pulsing animation so the tester doesn't complain
    // about an active ticker on teardown.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders "Sin conexión" for idle / closed states',
      (tester) async {
    final client = _FakeStreamClient(StreamConnectionState.idle);
    await tester.pumpWidget(_wrap(client));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
  });

  testWidgets('renders polling label for polling state', (tester) async {
    final client = _FakeStreamClient(StreamConnectionState.polling);
    await tester.pumpWidget(_wrap(client));
    await tester.pumpAndSettle();

    expect(find.text('Polling 60s'), findsOneWidget);
  });
}
