/// Port: Notification Dispatcher — fires channel-agnostic notification
/// *events* at the domain boundary.
///
/// Distinct from `NotificationPort`:
///   * `NotificationPort` is the low-level "send this message on this
///     channel" primitive. Adapters like `TelegramNotificationAdapter`
///     implement it directly.
///   * `NotificationDispatcherPort` is the higher-level orchestration
///     port used by use cases. A single fire() call may fan out to
///     multiple channels (Telegram + email), respect per-tenant
///     templates, and queue retries.
///
/// This separation lets the state-machine handler (VRTV-40) stay
/// channel-agnostic while Telegram (VRTV-41), email (VRTV-46), and
/// WhatsApp (future) grow independently behind the dispatcher.
///
/// The production adapter for this port lands in VRTV-41; this library
/// ships an in-memory adapter in `libs/adapters` for tests.
library;

import 'package:meta/meta.dart';

import '../value_objects/declaration_status.dart';

/// The kind of notification event a use case emits. Adapters are free
/// to ignore events they don't handle (e.g. an SMS-only adapter would
/// ignore email events).
enum NotificationEventType {
  /// A declaration changed status and the policy wants us to notify.
  declarationStatusChanged,

  /// A pyme invited a freelance agent (VRTV-46).
  tenantInvitationSent,

  /// An agent accepted a tenant invitation (VRTV-46).
  tenantInvitationAccepted,
}

/// Severity / routing hint carried with every event. The dispatcher may
/// use this to short-circuit rate limiting (urgent bypasses normal
/// quotas) or choose between silent and push channels.
enum NotificationSeverity { info, success, warning, critical }

/// Domain-level notification event. Pure data — no I/O.
///
/// Fields are kept minimal and presentation-agnostic: the dispatcher
/// adapter is responsible for turning this into a message body
/// (template lookup, i18n, emoji rendering). That way a template change
/// never cascades into the application layer.
@immutable
class NotificationEvent {
  /// Stable identifier — UUID v4 recommended. Used as idempotency key
  /// by the dispatcher adapter so retries do not produce duplicate
  /// Telegram messages.
  final String id;

  final NotificationEventType type;

  /// Tenant scope — required.
  final String tenantId;

  /// The declaration this event relates to, when relevant. `null` for
  /// non-declaration events (e.g. tenant invitations).
  final String? declarationId;

  /// Convenience — the old/new status when [type] is
  /// [NotificationEventType.declarationStatusChanged]. `null` otherwise.
  final DeclarationStatus? previousStatus;
  final DeclarationStatus? newStatus;

  /// User ids of the recipients — the adapter looks up each user's
  /// preferred channel + address (telegramChatId, email, ...).
  final List<String> recipientUserIds;

  /// Free-form metadata the adapter can inject into the template.
  /// Keep to JSON-safe primitives.
  final Map<String, Object?> metadata;

  final NotificationSeverity severity;

  /// Emitted time (UTC). The adapter may use this to drop events older
  /// than its TTL window.
  final DateTime emittedAt;

  const NotificationEvent({
    required this.id,
    required this.type,
    required this.tenantId,
    required this.recipientUserIds,
    required this.emittedAt,
    this.declarationId,
    this.previousStatus,
    this.newStatus,
    this.metadata = const {},
    this.severity = NotificationSeverity.info,
  });

  @override
  String toString() =>
      'NotificationEvent($id, $type, tenant=$tenantId, '
      'recipients=${recipientUserIds.length})';
}

/// Port: dispatches [NotificationEvent]s.
///
/// Adapter contract:
///   * MUST NOT throw on delivery failure for a single recipient —
///     partial failures are recorded (retry queue) and the call still
///     returns. Throwing is reserved for "the dispatcher infrastructure
///     itself is broken" (config missing, queue unreachable).
///   * MUST be idempotent on [NotificationEvent.id].
abstract class NotificationDispatcherPort {
  Future<void> fire(NotificationEvent event);
}
