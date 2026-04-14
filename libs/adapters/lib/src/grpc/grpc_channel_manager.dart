/// Singleton manager for the gRPC ClientChannel to the hacienda-sidecar.
///
/// Provides lazy initialization of the channel and graceful shutdown.
/// The sidecar host and port are configurable, defaulting to localhost:50051.
library;

import 'package:grpc/grpc.dart';

/// Manages a single shared [ClientChannel] to the hacienda-sidecar gRPC server.
///
/// Usage:
/// ```dart
/// final manager = GrpcChannelManager(host: 'localhost', port: 50051);
/// final channel = manager.channel;
/// // Use channel to create gRPC clients...
/// await manager.shutdown();
/// ```
class GrpcChannelManager {
  final String host;
  final int port;
  final ChannelCredentials credentials;

  ClientChannel? _channel;

  /// True once a graceful [shutdown] has been requested. Blocks new channel
  /// access but does NOT block [terminate] from escalating to a forced close.
  bool _isClosing = false;

  /// True once the channel has been fully closed (either gracefully or
  /// forcefully). After this point the manager rejects further usage.
  bool _isClosed = false;

  /// Creates a channel manager targeting the given [host] and [port].
  ///
  /// By default, uses insecure credentials (no TLS) suitable for
  /// localhost sidecar communication. For production, pass
  /// [ChannelCredentials.secure].
  GrpcChannelManager({
    this.host = 'localhost',
    this.port = 50051,
    this.credentials = const ChannelCredentials.insecure(),
  });

  /// Returns the lazily-initialized [ClientChannel].
  ///
  /// Creates the channel on first access. Throws [StateError] if
  /// [shutdown] or [terminate] has already been called.
  ClientChannel get channel {
    if (_isClosing || _isClosed) {
      throw StateError(
        'GrpcChannelManager has been shut down. '
        'Create a new instance to reconnect.',
      );
    }
    return _channel ??= ClientChannel(
      host,
      port: port,
      options: ChannelOptions(credentials: credentials),
    );
  }

  /// Whether the channel has been created (lazy init has occurred).
  bool get isInitialized => _channel != null;

  /// Whether [shutdown] or [terminate] has been called (closing or closed).
  bool get isShutdown => _isClosing || _isClosed;

  /// Gracefully shuts down the channel, allowing pending RPCs to complete.
  ///
  /// After calling this, [channel] will throw [StateError].
  /// This method is idempotent. If a graceful shutdown is in progress and
  /// [terminate] is called concurrently, the terminate path will still force
  /// a close on the underlying channel.
  Future<void> shutdown() async {
    if (_isClosed) return;
    if (_isClosing) return;
    _isClosing = true;
    try {
      await _channel?.shutdown();
    } finally {
      _isClosed = true;
      _channel = null;
    }
  }

  /// Forcefully terminates the channel, cancelling pending RPCs.
  ///
  /// Use [shutdown] for graceful termination. This is for emergency cleanup
  /// and will still act on the channel even if a graceful [shutdown] is
  /// currently awaiting pending RPCs.
  Future<void> terminate() async {
    if (_isClosed) return;
    _isClosing = true;
    final channel = _channel;
    if (channel == null) {
      _isClosed = true;
      return;
    }
    try {
      await channel.terminate();
    } finally {
      _isClosed = true;
      _channel = null;
    }
  }
}
