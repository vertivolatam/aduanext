/// Runtime configuration for the retention worker.
///
/// Parsed out of [Platform.environment] so the same binary can be
/// tuned per environment without a rebuild. Defaults match
/// `docs/site/content/docs/compliance/data-retention-policy.md` — if
/// you change one, change the other.
library;

import 'dart:io';

import 'package:aduanext_domain/aduanext_domain.dart';

/// Snapshot of the retention subsystem's runtime knobs.
class RetentionConfig {
  /// Master switch. When `false` the worker is not wired at all —
  /// useful for dev databases where the audit / DUA data is throwaway
  /// and a background DELETE loop would just create noise.
  final bool enabled;

  /// Retention window for audit events. Floor = LGA Art. 30.b
  /// (5 years) — shorter values throw at boot.
  final Duration auditWindow;

  /// Retention window for DUA submissions. Same legal floor as audit.
  final Duration duaWindow;

  /// Retention window for session logs. Shorter by design — these
  /// are telemetry, not compliance evidence.
  final Duration sessionWindow;

  /// UTC hour (0-23) at which the daily run fires.
  final int runAtHourUtc;

  /// UTC minute (0-59) at which the daily run fires.
  final int runAtMinuteUtc;

  /// Absolute path to the filesystem archive root. Production uses an
  /// S3/GCS adapter (separate issue); this is the default placeholder.
  final String archivePath;

  const RetentionConfig({
    required this.enabled,
    required this.auditWindow,
    required this.duaWindow,
    required this.sessionWindow,
    required this.runAtHourUtc,
    required this.runAtMinuteUtc,
    required this.archivePath,
  });

  /// Defaults match the compliance doc: 7 years audit/DUA, 90 days
  /// sessions, 03:00 UTC daily, `/var/aduanext/archive`.
  static const RetentionConfig defaults = RetentionConfig(
    enabled: false,
    auditWindow: Duration(days: 365 * 7),
    duaWindow: Duration(days: 365 * 7),
    sessionWindow: Duration(days: 90),
    runAtHourUtc: 3,
    runAtMinuteUtc: 0,
    archivePath: '/var/aduanext/archive',
  );

  /// Parse from environment variables. See field-level docstrings for
  /// the expected variable names. Falls back to [defaults] field-by-field.
  factory RetentionConfig.fromEnv([Map<String, String>? source]) {
    final env = source ?? Platform.environment;
    final enabled = (env['ADUANEXT_RETENTION_ENABLED'] ?? '').toLowerCase() ==
        'true';
    final auditYears =
        int.tryParse(env['ADUANEXT_RETENTION_AUDIT_YEARS'] ?? '') ?? 7;
    final duaYears =
        int.tryParse(env['ADUANEXT_RETENTION_DUA_YEARS'] ?? '') ?? 7;
    final sessionDays =
        int.tryParse(env['ADUANEXT_RETENTION_SESSION_DAYS'] ?? '') ?? 90;
    final runAt = _parseHhMm(env['ADUANEXT_RETENTION_RUN_AT_UTC']);
    final archivePath =
        env['ADUANEXT_ARCHIVE_PATH'] ?? defaults.archivePath;

    final auditWindow = Duration(days: 365 * auditYears);
    final duaWindow = Duration(days: 365 * duaYears);
    final sessionWindow = Duration(days: sessionDays);

    // Enforce the legal floors at boot so a mis-configured environment
    // fails fast rather than silently purging too aggressively.
    final auditPolicy = DefaultRetentionPolicies.auditEvent;
    if (auditWindow < auditPolicy.legalMinimum) {
      throw ArgumentError.value(
        'ADUANEXT_RETENTION_AUDIT_YEARS=$auditYears',
        'auditWindow',
        'Below the LGA Art. 30.b legal floor of '
            '${auditPolicy.legalMinimum.inDays}d',
      );
    }
    final duaPolicy = DefaultRetentionPolicies.duaSubmission;
    if (duaWindow < duaPolicy.legalMinimum) {
      throw ArgumentError.value(
        'ADUANEXT_RETENTION_DUA_YEARS=$duaYears',
        'duaWindow',
        'Below the LGA Art. 30.b legal floor of '
            '${duaPolicy.legalMinimum.inDays}d',
      );
    }

    return RetentionConfig(
      enabled: enabled,
      auditWindow: auditWindow,
      duaWindow: duaWindow,
      sessionWindow: sessionWindow,
      runAtHourUtc: runAt.$1,
      runAtMinuteUtc: runAt.$2,
      archivePath: archivePath,
    );
  }

  /// Build the effective [RetentionPolicy] map with our env-tuned
  /// windows applied over the platform defaults.
  Map<RetentionCategory, RetentionPolicy> asPolicies() {
    return {
      RetentionCategory.auditEvent: DefaultRetentionPolicies.auditEvent
          .withTenantOverride(auditWindow),
      RetentionCategory.duaSubmission: DefaultRetentionPolicies.duaSubmission
          .withTenantOverride(duaWindow),
      RetentionCategory.classificationDecision:
          DefaultRetentionPolicies.classificationDecision,
      RetentionCategory.userSessionLog:
          DefaultRetentionPolicies.userSessionLog
              .withTenantOverride(sessionWindow),
      RetentionCategory.validationOutcome:
          DefaultRetentionPolicies.validationOutcome,
      RetentionCategory.notificationReceipt:
          DefaultRetentionPolicies.notificationReceipt,
    };
  }
}

/// Parse `"HH:MM"` (UTC) into a (hour, minute) record. Invalid input
/// falls back to (3, 0) — the doc'd default. Invalid but non-empty
/// values throw so operators see the mis-config at boot.
(int, int) _parseHhMm(String? raw) {
  if (raw == null || raw.isEmpty) {
    return (RetentionConfig.defaults.runAtHourUtc,
        RetentionConfig.defaults.runAtMinuteUtc);
  }
  final parts = raw.split(':');
  if (parts.length != 2) {
    throw FormatException(
      'ADUANEXT_RETENTION_RUN_AT_UTC must be "HH:MM", got "$raw"',
    );
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || hour < 0 || hour > 23) {
    throw FormatException(
      'ADUANEXT_RETENTION_RUN_AT_UTC hour out of range in "$raw"',
    );
  }
  if (minute == null || minute < 0 || minute > 59) {
    throw FormatException(
      'ADUANEXT_RETENTION_RUN_AT_UTC minute out of range in "$raw"',
    );
  }
  return (hour, minute);
}
