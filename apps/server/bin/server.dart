/// Entry point for the AduaNext primary server.
///
/// Boot order:
///   1. Parse [ServerConfig] from env.
///   2. Open [AppContainer] (gRPC channel + adapters + audit log).
///   3. Bind the shelf handler to the configured host/port.
///   4. Wait for SIGINT/SIGTERM; tear down the container cleanly.
///
/// Exit codes:
///   0 — normal shutdown after signal.
///   2 — invalid / missing configuration.
///   3 — dependency boot failure (sidecar unreachable, bad p12 path,
///       Postgres connect failure).
library;

import 'dart:async';
import 'dart:io';

import 'package:aduanext_server/aduanext_server.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  _configureLogging();
  final log = Logger('aduanext.server');

  final ServerConfig config;
  try {
    config = ServerConfig.fromEnv();
  } on FormatException catch (e) {
    log.severe('Invalid configuration: $e');
    exit(2);
  }
  log.info(
    'Starting AduaNext server on ${config.httpHost}:${config.httpPort} '
    '(sidecar=${config.sidecarHost}:${config.sidecarPort})',
  );

  final AppContainer container;
  try {
    container = await AppContainer.boot(config);
  } catch (e, st) {
    log.severe('Failed to boot dependency container', e, st);
    exit(3);
  }

  final handler = buildHandler(container);
  final server = await shelf_io.serve(
    handler,
    config.httpHost,
    config.httpPort,
  );
  log.info('HTTP server listening on ${server.address.host}:${server.port}');

  // Kick off the retention worker when wired (VRTV-74). AppContainer
  // only constructs it when both `ADUANEXT_RETENTION_ENABLED=true`
  // and a Postgres audit log are configured — everything else is a
  // dev/test mode where a daily DELETE loop would be counter-productive.
  final retentionWorker = container.retentionWorker;
  if (retentionWorker != null) {
    retentionWorker.start();
    log.info(
      'Retention worker scheduled — daily at '
      '${container.retention.runAtHourUtc.toString().padLeft(2, "0")}:'
      '${container.retention.runAtMinuteUtc.toString().padLeft(2, "0")} UTC, '
      'archive=${container.retention.archivePath}',
    );
  } else {
    log.info(
      'Retention worker NOT started (set ADUANEXT_RETENTION_ENABLED=true '
      'and ADUANEXT_POSTGRES_URL to enable)',
    );
  }

  // Graceful shutdown on SIGINT / SIGTERM.
  final done = Completer<void>();
  void triggerShutdown(ProcessSignal signal) {
    if (done.isCompleted) return;
    log.info('Received ${signal.toString()}, shutting down...');
    done.complete();
  }

  final sigint = ProcessSignal.sigint.watch().listen(triggerShutdown);
  final sigterm = ProcessSignal.sigterm.watch().listen(triggerShutdown);

  await done.future;

  try {
    await server.close(force: false).timeout(const Duration(seconds: 5));
  } on TimeoutException {
    log.warning('HTTP server graceful close timed out; forcing.');
    await server.close(force: true);
  }
  await sigint.cancel();
  await sigterm.cancel();
  await container.close();

  log.info('Shutdown complete.');
}

void _configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    // Single-line structured-ish output for container log tailing.
    stdout.writeln(
      '${r.time.toIso8601String()} '
      '${r.level.name.padRight(7)} '
      '${r.loggerName} '
      '${r.message}'
      '${r.error != null ? " ${r.error}" : ""}',
    );
    if (r.stackTrace != null) {
      stderr.writeln(r.stackTrace);
    }
  });
}
