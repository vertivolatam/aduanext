/// Test helper: spin up an in-process gRPC [Server] and a matching
/// [GrpcChannelManager] pointed at it.
///
/// The helper owns the lifecycle so each test gets an isolated server on a
/// dynamically-assigned port. Callers pass the concrete [Service]
/// implementations to mount (e.g. a fake [HaciendaAuthServiceBase]) and
/// receive back the manager they can hand to an adapter under test.
///
/// This is a real gRPC round-trip (serialization, HTTP/2, status mapping)
/// which is exactly what we want to cover the error-translation branches
/// introduced by the PR #4 CodeRabbit fixes.
library;

import 'dart:async';
import 'dart:io';

import 'package:aduanext_adapters/adapters.dart';
import 'package:grpc/grpc.dart';

/// A running in-process gRPC server bound to a random local port, plus a
/// [GrpcChannelManager] already pointed at it.
class InProcessGrpcTestHarness {
  final Server server;
  final GrpcChannelManager channelManager;
  final int port;

  InProcessGrpcTestHarness._(this.server, this.channelManager, this.port);

  /// Start a fresh server with the given [services] and return a harness.
  static Future<InProcessGrpcTestHarness> start(List<Service> services) async {
    final server = Server.create(services: services);
    await server.serve(
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );
    final port = server.port!;
    final manager = GrpcChannelManager(
      host: InternetAddress.loopbackIPv4.address,
      port: port,
    );
    return InProcessGrpcTestHarness._(server, manager, port);
  }

  /// Stop the server and shut down the channel. Safe to call multiple times.
  Future<void> stop() async {
    try {
      await channelManager.shutdown();
    } catch (_) {
      // Ignore; we're tearing down.
    }
    await server.shutdown();
  }
}
