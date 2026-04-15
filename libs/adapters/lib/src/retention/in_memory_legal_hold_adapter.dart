/// In-memory [LegalHoldPort] adapter — for tests and dev runs. The
/// production Postgres-backed adapter ships in a follow-up issue (it
/// requires a `legal_holds` table with the same schema, which the
/// future migration tool will own).
library;

import 'package:aduanext_domain/aduanext_domain.dart';

class InMemoryLegalHoldAdapter implements LegalHoldPort {
  /// Keyed by `(tenantId, entityType, entityId)`. The latest hold for
  /// each key is kept at the head of its list; released holds remain
  /// in the history for [historyFor].
  final Map<_Key, List<LegalHold>> _holds = {};

  @override
  Future<void> place(LegalHold hold) async {
    final key = _Key(hold.tenantId, hold.entityType, hold.entityId);
    final list = _holds.putIfAbsent(key, () => <LegalHold>[]);
    if (list.isNotEmpty && list.first.releasedAt == null) {
      throw StateError(
        'A legal hold is already active for $key '
        '(set ${list.first.setAt} by ${list.first.setByActorId})',
      );
    }
    list.insert(0, hold);
  }

  @override
  Future<void> release({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String releasedByActorId,
    required DateTime releasedAt,
  }) async {
    final key = _Key(tenantId, entityType, entityId);
    final list = _holds[key];
    if (list == null || list.isEmpty || list.first.releasedAt != null) {
      return;
    }
    list[0] = list.first.copyWithRelease(
      releasedByActorId: releasedByActorId,
      releasedAt: releasedAt,
    );
  }

  @override
  Future<bool> isHeld({
    required String tenantId,
    required String entityType,
    required String entityId,
    required DateTime now,
  }) async {
    final list = _holds[_Key(tenantId, entityType, entityId)];
    if (list == null || list.isEmpty) return false;
    return list.first.isActiveAt(now);
  }

  @override
  Future<List<LegalHold>> historyFor({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    final list = _holds[_Key(tenantId, entityType, entityId)];
    return List.unmodifiable(list ?? const <LegalHold>[]);
  }
}

class _Key {
  final String tenantId;
  final String entityType;
  final String entityId;
  const _Key(this.tenantId, this.entityType, this.entityId);

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.tenantId == tenantId &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(tenantId, entityType, entityId);

  @override
  String toString() => '($tenantId, $entityType, $entityId)';
}
