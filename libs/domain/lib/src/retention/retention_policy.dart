/// Retention policy — the per-data-type rules that drive the
/// retention worker.
///
/// LGA Art. 30.b mandates a 5-year minimum retention for operational
/// records of *auxiliares de funcion publica* (customs agents). Some
/// records require longer retention by tenant choice or by regulatory
/// override (judicial / administrative proceedings — see [LegalHold]).
///
/// AduaNext defaults exceed the legal minimum so that "nothing was
/// quietly deleted right at the threshold" is true. Tenants may
/// extend retention but never shorten it below the legal floor.
library;

import 'package:meta/meta.dart';

/// Retention category — what kind of data this policy governs.
///
/// Adding a new category requires:
/// 1. Mapping it to a concrete table / port at the adapter layer.
/// 2. Updating the retention worker to schedule purges for it.
/// 3. Reflecting the change in
///    `docs/site/content/docs/compliance/data-retention-policy.md`.
enum RetentionCategory {
  /// Tamper-evident audit trail (chain-hashed). LGA Art. 30.b minimum.
  auditEvent,

  /// Full DUA submissions + signed XML.
  duaSubmission,

  /// Classification decisions (HS code attempts + confirmations).
  classificationDecision,

  /// Ephemeral session logs (login / logout / refresh).
  userSessionLog,

  /// Pre-submission validation rule outcomes (debugging artefacts).
  validationOutcome,

  /// Notification delivery receipts (Telegram, WhatsApp, email).
  notificationReceipt,
}

/// Retention window for a [RetentionCategory].
@immutable
class RetentionPolicy {
  final RetentionCategory category;

  /// The legal floor — never shorter than this regardless of tenant
  /// configuration. Enforced by [withTenantOverride].
  final Duration legalMinimum;

  /// AduaNext's default — typically the legal minimum plus a buffer.
  final Duration platformDefault;

  /// Active window (defaults to [platformDefault] unless a tenant
  /// override is applied).
  final Duration window;

  const RetentionPolicy({
    required this.category,
    required this.legalMinimum,
    required this.platformDefault,
    Duration? window,
  }) : window = window ?? platformDefault;

  /// Returns a copy with [override] applied. Throws [ArgumentError] if
  /// [override] is shorter than [legalMinimum].
  RetentionPolicy withTenantOverride(Duration override) {
    if (override < legalMinimum) {
      throw ArgumentError.value(
        override,
        'override',
        'Tenant override is shorter than the legal minimum '
            '(${legalMinimum.inDays}d) for $category',
      );
    }
    return RetentionPolicy(
      category: category,
      legalMinimum: legalMinimum,
      platformDefault: platformDefault,
      window: override,
    );
  }

  /// Compute the `expires_at` instant for a record created at [createdAt].
  DateTime expiresAt(DateTime createdAt) =>
      createdAt.toUtc().add(window);

  /// `true` iff a record created at [createdAt] is past its retention
  /// window evaluated at [now].
  bool hasExpired({
    required DateTime createdAt,
    required DateTime now,
  }) {
    return now.toUtc().isAfter(expiresAt(createdAt));
  }

  @override
  bool operator ==(Object other) =>
      other is RetentionPolicy &&
      other.category == category &&
      other.legalMinimum == legalMinimum &&
      other.platformDefault == platformDefault &&
      other.window == window;

  @override
  int get hashCode =>
      Object.hash(category, legalMinimum, platformDefault, window);

  @override
  String toString() =>
      'RetentionPolicy($category, window=${window.inDays}d, '
      'legalMin=${legalMinimum.inDays}d)';
}

/// AduaNext's default retention table. Tenants can extend a category
/// via [RetentionPolicy.withTenantOverride]; they cannot reduce below
/// [RetentionPolicy.legalMinimum].
class DefaultRetentionPolicies {
  DefaultRetentionPolicies._();

  /// Five years (LGA Art. 30.b minimum).
  static const Duration _fiveYears = Duration(days: 365 * 5);

  /// Seven years (platform default for compliance-critical data — buffer
  /// over the 5-year floor).
  static const Duration _sevenYears = Duration(days: 365 * 7);

  /// 90 days (session telemetry).
  static const Duration _ninetyDays = Duration(days: 90);

  /// 1 year (debugging artefacts that have no compliance value).
  static const Duration _oneYear = Duration(days: 365);

  static const RetentionPolicy auditEvent = RetentionPolicy(
    category: RetentionCategory.auditEvent,
    legalMinimum: _fiveYears,
    platformDefault: _sevenYears,
  );

  static const RetentionPolicy duaSubmission = RetentionPolicy(
    category: RetentionCategory.duaSubmission,
    legalMinimum: _fiveYears,
    platformDefault: _sevenYears,
  );

  static const RetentionPolicy classificationDecision = RetentionPolicy(
    category: RetentionCategory.classificationDecision,
    legalMinimum: _fiveYears,
    platformDefault: _fiveYears,
  );

  static const RetentionPolicy userSessionLog = RetentionPolicy(
    category: RetentionCategory.userSessionLog,
    legalMinimum: _ninetyDays,
    platformDefault: _ninetyDays,
  );

  static const RetentionPolicy validationOutcome = RetentionPolicy(
    category: RetentionCategory.validationOutcome,
    legalMinimum: _oneYear,
    platformDefault: _oneYear,
  );

  static const RetentionPolicy notificationReceipt = RetentionPolicy(
    category: RetentionCategory.notificationReceipt,
    legalMinimum: _oneYear,
    platformDefault: _oneYear,
  );

  /// All built-in policies, indexed by category.
  static const Map<RetentionCategory, RetentionPolicy> all = {
    RetentionCategory.auditEvent: auditEvent,
    RetentionCategory.duaSubmission: duaSubmission,
    RetentionCategory.classificationDecision: classificationDecision,
    RetentionCategory.userSessionLog: userSessionLog,
    RetentionCategory.validationOutcome: validationOutcome,
    RetentionCategory.notificationReceipt: notificationReceipt,
  };
}
