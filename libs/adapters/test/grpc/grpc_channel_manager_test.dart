/// Unit tests for [GrpcChannelManager].
///
/// Covers state machine transitions (fresh -> initialized -> closing ->
/// closed) without hitting a real gRPC server — the only side effect we
/// exercise is `channel.shutdown()` which the `package:grpc` `ClientChannel`
/// handles gracefully even without a peer.
///
/// Regression coverage:
/// - C10: `channel` getter does NOT cache a closed channel across shutdown().
/// - C11: `terminate()` still works while `shutdown()` is in progress
///   (`_isClosing` vs `_isClosed`).
library;

import 'package:aduanext_adapters/adapters.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

void main() {
  group('GrpcChannelManager', () {
    test('defaults to localhost:50051 with insecure credentials', () {
      final mgr = GrpcChannelManager();
      expect(mgr.host, 'localhost');
      expect(mgr.port, 50051);
      expect(mgr.isInitialized, isFalse);
      expect(mgr.isShutdown, isFalse);
    });

    test('lazily initializes the channel on first access', () {
      final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59999);
      expect(mgr.isInitialized, isFalse);

      final channel1 = mgr.channel;
      expect(mgr.isInitialized, isTrue);
      expect(channel1, isA<ClientChannel>());

      // Second access returns the same channel instance.
      final channel2 = mgr.channel;
      expect(identical(channel1, channel2), isTrue,
          reason: 'channel getter must reuse the same ClientChannel until '
              'shutdown/terminate is called.');
    });

    test('shutdown() flips isShutdown and prevents further channel access',
        () async {
      final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59998);
      // Initialize then shutdown.
      final _ = mgr.channel;
      await mgr.shutdown();

      expect(mgr.isShutdown, isTrue);
      expect(() => mgr.channel, throwsA(isA<StateError>()));
    });

    test('shutdown() is idempotent', () async {
      final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59997);
      final _ = mgr.channel;
      await mgr.shutdown();
      // Second call must not throw.
      await mgr.shutdown();
      expect(mgr.isShutdown, isTrue);
    });

    test('terminate() before any channel access still marks closed', () async {
      final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59996);
      expect(mgr.isInitialized, isFalse);
      await mgr.terminate();
      expect(mgr.isShutdown, isTrue);
      expect(() => mgr.channel, throwsA(isA<StateError>()));
    });

    test('terminate() is idempotent', () async {
      final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59995);
      final _ = mgr.channel;
      await mgr.terminate();
      // Second call must not throw.
      await mgr.terminate();
      expect(mgr.isShutdown, isTrue);
    });

    test(
      'C11 regression: terminate() still runs while shutdown() is in progress',
      () async {
        // We don't control shutdown() completion timing in the unit layer
        // (the channel has no pending RPCs), but we can at least assert that
        // invoking both races does NOT throw and leaves the manager closed.
        final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59994);
        final _ = mgr.channel;

        final shutdownFuture = mgr.shutdown();
        // Kick off terminate concurrently. It must observe _isClosing=true
        // but NOT short-circuit based on _isClosed, and still drive the
        // channel to a closed state.
        final terminateFuture = mgr.terminate();

        await Future.wait([shutdownFuture, terminateFuture]);
        expect(mgr.isShutdown, isTrue);
        expect(() => mgr.channel, throwsA(isA<StateError>()));
      },
    );

    test(
      'C10 regression: channel getter throws instead of returning a cached '
      'closed channel after shutdown',
      () async {
        final mgr = GrpcChannelManager(host: '127.0.0.1', port: 59993);
        final _ = mgr.channel;
        await mgr.shutdown();

        // If the manager were caching the closed channel, we would get
        // back a ClientChannel here and subsequent RPCs would fail with
        // cryptic gRPC errors. Instead we must get a StateError.
        expect(
          () => mgr.channel,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('shut down'),
            ),
          ),
        );
      },
    );
  });
}
