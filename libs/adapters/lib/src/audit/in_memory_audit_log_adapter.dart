/// In-memory [AuditLogPort] — for tests and dev runs.
///
/// NOT for production. Events live only in the process heap. Concurrent
/// `append()` calls are serialized via a single-slot [Future] chain so the
/// per-entity sequence number stays monotonically increasing.
library;

import 'dart:async';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import 'audit_chain_hasher.dart';

/// Pure-memory implementation of [AuditLogPort].
class InMemoryAuditLogAdapter implements AuditLogPort {
  final AuditChainHasher _hasher;

  /// Stream of server timestamps used to mark sync time. Tests can override
  /// via the constructor.
  final DateTime Function() _now;

  /// Keyed by `"$entityType/$entityId"`.
  final Map<String, List<AuditEvent>> _byEntity = {};

  /// Serialization lock — ensures `append()` calls don't interleave while
  /// they read-then-write the chain.
  Future<void> _writeLock = Future<void>.value();

  InMemoryAuditLogAdapter({
    AuditChainHasher? hasher,
    DateTime Function()? now,
  })  : _hasher = hasher ?? const AuditChainHasher(),
        _now = now ?? DateTime.now;

  String _key(String entityType, String entityId) => '$entityType/$entityId';

  @override
  Future<String> append(AuditEvent event) {
    final completer = Completer<String>();
    _writeLock = _writeLock.then((_) async {
      try {
        final hash = _appendSync(event);
        completer.complete(hash);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  String _appendSync(AuditEvent event) {
    final key = _key(event.entityType, event.entityId);
    final chain = _byEntity.putIfAbsent(key, () => <AuditEvent>[]);

    final expectedSeq = chain.length;
    // Accept drafts (sequenceNumber == -1) and correctly-numbered events.
    if (event.sequenceNumber != -1 &&
        event.sequenceNumber != expectedSeq) {
      throw AuditChainSequenceError(
        entityType: event.entityType,
        entityId: event.entityId,
        expected: expectedSeq,
        actual: event.sequenceNumber,
      );
    }

    final prevHash = chain.isEmpty
        ? _hasher.genesisHash(
            entityType: event.entityType,
            entityId: event.entityId,
          )
        : chain.last.eventHash;

    final sealed = _hasher.seal(
      event: event,
      previousHash: prevHash,
      sequenceNumber: expectedSeq,
      serverTimestamp: event.serverTimestamp ?? _now().toUtc(),
    );
    chain.add(sealed);
    return sealed.eventHash;
  }

  @override
  Future<List<AuditEvent>> queryByEntity(
      String entityType, String entityId) async {
    final chain = _byEntity[_key(entityType, entityId)];
    if (chain == null) return const [];
    // Defensive copy so callers can't mutate our internal state.
    return List<AuditEvent>.unmodifiable(chain);
  }

  @override
  Future<bool> verifyChainIntegrity(
      String entityType, String entityId) async {
    final chain = _byEntity[_key(entityType, entityId)];
    if (chain == null || chain.isEmpty) return true;

    var expectedPrev = _hasher.genesisHash(
      entityType: entityType,
      entityId: entityId,
    );
    for (var i = 0; i < chain.length; i++) {
      final event = chain[i];
      if (event.sequenceNumber != i) return false;
      if (event.previousHash != expectedPrev) return false;
      if (!_hasher.verify(event)) return false;
      expectedPrev = event.eventHash;
    }
    return true;
  }

  /// Test-only hook — replace the internal chain for an entity with
  /// [events]. Used by the tampering-detection tests.
  @visibleForTesting
  void debugOverwrite(
      String entityType, String entityId, List<AuditEvent> events) {
    _byEntity[_key(entityType, entityId)] = List<AuditEvent>.from(events);
  }
}
