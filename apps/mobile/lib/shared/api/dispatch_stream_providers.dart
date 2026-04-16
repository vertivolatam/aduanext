/// Riverpod providers that wire [DispatchStreamClient] into the
/// dashboard lifecycle.
///
/// The stream is a singleton per scope: the dashboard subscribes
/// once; the detail page may tap the same broadcast stream without
/// opening a second socket.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_providers.dart';
import 'dispatch_dto.dart';
import 'dispatch_stream_client.dart';

/// Tenant ID override for the stream. Today resolves to `null`
/// (stream fans out across all tenants the caller can see); VRTV-60
/// will feed this from the decoded JWT.
final dispatchStreamTenantIdProvider = Provider<String?>((ref) => null);

/// The [DispatchStreamClient] itself. Lazily starts when anything
/// watches its derived providers. Disposed with the ProviderScope.
final dispatchStreamClientProvider = Provider<DispatchStreamClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  // The fake mode never opens a real stream — the dashboard doesn't
  // need a `Live` indicator in offline dev.
  if (config.useFake) {
    final noop = _NoopStreamClient();
    ref.onDispose(noop.close);
    return noop;
  }

  final token = ref.watch(bearerTokenProvider);
  final tenantId = ref.watch(dispatchStreamTenantIdProvider);
  final client = DispatchStreamClient(
    config: config,
    tokenProvider: token,
    tenantId: tenantId,
  );
  // Kick off the connection eagerly — providers that watch
  // `dispatchStreamStateProvider` below see transitions immediately.
  unawaited(client.connect());
  ref.onDispose(client.close);
  return client;
});

/// Current connection state as a [StreamProvider]. UI binds to this
/// to paint the Live / Reconnecting / Offline / Polling badge.
final dispatchStreamStateProvider = StreamProvider<StreamConnectionState>((ref) {
  return ref.watch(dispatchStreamClientProvider).connectionState;
});

/// Broadcast stream of [DispatchUpdate]s. Emitted as events arrive;
/// consumers (dashboard list, detail page) react to individual
/// updates without tearing down the page-level Future.
final dispatchStreamUpdatesProvider =
    StreamProvider.autoDispose((ref) {
  return ref.watch(dispatchStreamClientProvider).updates;
});

/// Internal: stand-in client used when `ApiConfig.useFake == true`.
/// Emits `polling` once so the UI doesn't render a "connecting"
/// spinner forever in offline dev.
class _NoopStreamClient implements DispatchStreamClient {
  final StreamController<StreamConnectionState> _s =
      StreamController<StreamConnectionState>.broadcast();

  _NoopStreamClient() {
    // Defer so listeners attach before we emit.
    Future<void>.microtask(() {
      if (!_s.isClosed) _s.add(StreamConnectionState.polling);
    });
  }

  @override
  Stream<StreamConnectionState> get connectionState => _s.stream;

  @override
  Stream<DispatchUpdate> get updates => const Stream.empty();

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {
    if (!_s.isClosed) await _s.close();
  }

  @override
  void setPollingTick(PollingTick tick) {}

  // The rest of the DispatchStreamClient surface is not part of the
  // public contract — noSuchMethod keeps this impl small without
  // having to mirror every internal field.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
