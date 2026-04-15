/// `RetentionWorker` — schedules `PurgeExpiredRecordsCommand` runs.
///
/// Strategy: a `Timer.periodic` checks the clock once per minute and
/// fires the command whenever the wall clock crosses the configured
/// daily UTC time (default 03:00). This is intentionally NOT a real
/// cron — for "once a day at HH:MM" granularity the periodic-check
/// pattern is simpler, requires no external dep, and survives DST
/// changes (we evaluate UTC).
///
/// Concurrency: only one run is in flight at a time. If the previous
/// run is still going when the next tick arrives, we skip — the next
/// tick (1 min later) re-evaluates.
///
/// Errors: caught and logged. The worker NEVER aborts on a failed run;
/// the next pass picks up where this one left off (`findExpired` is
/// driven by `expires_at`, so partially-purged batches are safe).
library;

import 'dart:async';

import 'package:aduanext_application/aduanext_application.dart';
import 'package:logging/logging.dart';

class RetentionWorker {
  final PurgeExpiredRecordsHandler _handler;
  final DateTime Function() _now;
  final Duration _tickInterval;

  /// UTC hour (0-23) at which the daily run fires.
  final int dailyHourUtc;

  /// UTC minute (0-59) at which the daily run fires.
  final int dailyMinuteUtc;

  final Logger _log;

  Timer? _timer;
  Future<void>? _inflight;
  DateTime? _lastFireDate;

  RetentionWorker({
    required PurgeExpiredRecordsHandler handler,
    DateTime Function()? now,
    Duration tickInterval = const Duration(minutes: 1),
    this.dailyHourUtc = 3,
    this.dailyMinuteUtc = 0,
    Logger? logger,
  })  : _handler = handler,
        _now = now ?? DateTime.now,
        _tickInterval = tickInterval,
        _log = logger ?? Logger('aduanext.retention.worker');

  /// Start the scheduler. Idempotent — calling twice is a no-op.
  void start() {
    if (_timer != null) return;
    _log.info(
      'Retention worker started — daily run at '
      '${dailyHourUtc.toString().padLeft(2, "0")}:'
      '${dailyMinuteUtc.toString().padLeft(2, "0")} UTC',
    );
    _timer = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  /// Stop the scheduler. Awaits any in-flight run.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    if (_inflight != null) {
      await _inflight;
    }
  }

  /// Force a run NOW. Returns the [PurgeReport]. Used by ops tooling
  /// and tests; the scheduler still runs at its normal cadence.
  Future<PurgeReport> runNow() async {
    final pending = _inflight;
    if (pending != null) {
      // Wait for the in-flight run to complete; we don't double-run.
      await pending;
    }
    return _execute();
  }

  void _onTick() {
    if (_inflight != null) return;
    final now = _now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    if (_lastFireDate != null && _lastFireDate == today) return;
    if (now.hour < dailyHourUtc) return;
    if (now.hour == dailyHourUtc && now.minute < dailyMinuteUtc) return;
    _lastFireDate = today;
    _inflight = _execute().then((_) {}, onError: (Object e, StackTrace st) {
      _log.severe('Retention run threw', e, st);
    }).whenComplete(() {
      _inflight = null;
    });
  }

  Future<PurgeReport> _execute() async {
    final start = _now().toUtc();
    _log.info('Retention worker run starting at $start');
    final result = await _handler.handle(
      PurgeExpiredRecordsCommand(now: start),
    );
    if (result is Ok<PurgeReport>) {
      final r = result.value;
      _log.info(
        'Retention run done — purged ${r.totalPurged}, '
        'archived ${r.totalArchived}, held ${r.totalHeld}',
      );
      return r;
    } else if (result is Err<PurgeReport>) {
      _log.warning('Retention run failed: ${(result).failure}');
      return PurgeReport.empty();
    }
    return PurgeReport.empty();
  }
}
