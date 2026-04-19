/// In-memory [NotificationDispatcherPort] — for tests and dev runs.
///
/// Records every fired [NotificationEvent] in insertion order. Tests
/// assert on the recorded list to verify that state transitions,
/// invitation flows, etc. emit the right events without reaching out
/// to Telegram / email. The real dispatcher adapter (VRTV-41) wraps
/// this with retry queues + channel fan-out.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

/// Pure-memory implementation of [NotificationDispatcherPort].
class InMemoryNotificationDispatcherAdapter
    implements NotificationDispatcherPort {
  final List<NotificationEvent> _fired = [];

  /// If set, [fire] throws this error (used by tests to exercise the
  /// "dispatcher infrastructure broken" path, which is NOT a business
  /// failure and should surface as an exception).
  Object? _nextError;

  /// Idempotency ledger — we accept a re-fire of an event id but drop
  /// the duplicate so tests can assert "fired exactly once" semantics.
  final Set<String> _seenIds = <String>{};

  /// Seed a forced error for the next [fire] call.
  @visibleForTesting
  void arrangeNextFireThrows(Object error) {
    _nextError = error;
  }

  /// Snapshot of fired events in insertion order. Callers MUST NOT
  /// mutate — we return an unmodifiable view.
  List<NotificationEvent> get fired =>
      List<NotificationEvent>.unmodifiable(_fired);

  /// Convenience filter used by many tests.
  List<NotificationEvent> firedForDeclaration(String declarationId) => _fired
      .where((e) => e.declarationId == declarationId)
      .toList(growable: false);

  @override
  Future<void> fire(NotificationEvent event) async {
    final error = _nextError;
    if (error != null) {
      _nextError = null;
      throw error;
    }
    if (_seenIds.add(event.id)) {
      _fired.add(event);
    }
  }

  @visibleForTesting
  void clear() {
    _fired.clear();
    _seenIds.clear();
    _nextError = null;
  }
}
