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
  bool _isShutdown = false;

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
  /// [shutdown] has already been called.
  ClientChannel get channel {
    if (_isShutdown) {
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

  /// Whether [shutdown] has been called.
  bool get isShutdown => _isShutdown;

  /// Gracefully shuts down the channel, allowing pending RPCs to complete.
  ///
  /// After calling this, [channel] will throw [StateError].
  /// This method is idempotent.
  Future<void> shutdown() async {
    if (_isShutdown) return;
    _isShutdown = true;
    await _channel?.shutdown();
    _channel = null;
  }

  /// Forcefully terminates the channel, cancelling pending RPCs.
  ///
  /// Use [shutdown] for graceful termination. This is for emergency cleanup.
  Future<void> terminate() async {
    if (_isShutdown) return;
    _isShutdown = true;
    await _channel?.terminate();
    _channel = null;
  }
}
