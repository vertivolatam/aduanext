/// Notification adapters implementing [NotificationDispatcherPort] and
/// friends.
///
/// * [InMemoryNotificationDispatcherAdapter] — for tests and dev runs.
/// The real Telegram / email adapters land in VRTV-41 / VRTV-46.
library;

export 'src/notifications/in_memory_notification_dispatcher_adapter.dart';
