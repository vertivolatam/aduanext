/// Port: Notifications — abstracts messaging channels.
///
/// Supports Telegram (primary), WhatsApp (secondary), and email.
library;

/// A notification to be sent to a user.
class Notification {
  final String recipientId;
  final String title;
  final String body;
  final NotificationPriority priority;
  final Map<String, String> metadata;

  const Notification({
    required this.recipientId,
    required this.title,
    required this.body,
    this.priority = NotificationPriority.normal,
    this.metadata = const {},
  });
}

enum NotificationPriority { low, normal, high, urgent }

/// Port: Notification — channel-agnostic notification interface.
abstract class NotificationPort {
  Future<void> send(Notification notification);
  Future<void> sendBatch(List<Notification> notifications);
}
