/// SHA-256 chain hashing primitive for the audit log.
///
/// Pure — no I/O. The hasher takes an event plus its predecessor's hash
/// and returns the `eventHash`. The chain scope is per-entity
/// (`entityType` + `entityId`), matching the design decision in
/// spike-002 (option B).
///
/// Algorithm
/// ---------
/// ```
/// genesisHash(entityType, entityId) =
///     SHA256("aduanext-audit-chain-v1:" || entityType || ":" || entityId)
///
/// eventHash(E_n) =
///     SHA256( previousHash(E_n) || ":" ||
///             sequenceNumber(E_n) || ":" ||
///             canonicalJson(E_n) || ":" ||
///             clientTimestamp(E_n).toIso8601 )
/// ```
///
/// The `canonicalJson(E_n)` payload already contains `previousHash`,
/// `sequenceNumber` and `clientTimestamp`. We still concatenate them as
/// prefix/suffix so that any framing-level corruption (e.g. truncated
/// JSON) still invalidates the hash.
library;

import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:crypto/crypto.dart';

import 'audit_event_extensions.dart';

/// Deterministic SHA-256 hasher for per-entity audit chains.
class AuditChainHasher {
  /// Version prefix embedded in the genesis hash so that a future format
  /// change can be introduced without silently colliding with v1 chains.
  static const String genesisPrefix = 'aduanext-audit-chain-v1';

  const AuditChainHasher();

  /// Genesis hash for a new `(entityType, entityId)` chain. The first
  /// appended event's `previousHash` MUST equal this value.
  String genesisHash({
    required String entityType,
    required String entityId,
  }) {
    final bytes = utf8.encode('$genesisPrefix:$entityType:$entityId');
    return sha256.convert(bytes).toString();
  }

  /// Compute the `eventHash` for [event], given its [previousHash] and
  /// [sequenceNumber]. Returns a new [AuditEvent] with chain coordinates
  /// populated.
  ///
  /// Callers should pass the genesis hash for the first event
  /// (`sequenceNumber == 0`).
  AuditEvent seal({
    required AuditEvent event,
    required String previousHash,
    required int sequenceNumber,
    DateTime? serverTimestamp,
  }) {
    final staged = event.copyWithChain(
      sequenceNumber: sequenceNumber,
      previousHash: previousHash,
      eventHash: '',
      serverTimestamp: serverTimestamp,
    );
    final hash = _computeHash(staged);
    return staged.copyWithChain(
      sequenceNumber: sequenceNumber,
      previousHash: previousHash,
      eventHash: hash,
      serverTimestamp: serverTimestamp ?? event.serverTimestamp,
    );
  }

  /// Recompute the hash for [event] and compare with its stored
  /// `eventHash`. Returns `true` iff they match.
  bool verify(AuditEvent event) {
    final staged = event.copyWithChain(
      sequenceNumber: event.sequenceNumber,
      previousHash: event.previousHash,
      eventHash: '',
    );
    return _computeHash(staged) == event.eventHash;
  }

  String _computeHash(AuditEvent event) {
    final canonical = event.toCanonicalJson();
    final input = [
      event.previousHash,
      event.sequenceNumber.toString(),
      canonical,
      event.clientTimestamp.toUtc().toIso8601String(),
    ].join(':');
    return sha256.convert(utf8.encode(input)).toString();
  }
}

/// Error thrown when a caller attempts to append an event whose
/// `sequenceNumber` does not match the expected next position (gap or
/// duplicate).
class AuditChainSequenceError extends Error {
  final String entityType;
  final String entityId;
  final int expected;
  final int actual;

  AuditChainSequenceError({
    required this.entityType,
    required this.entityId,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() =>
      'AuditChainSequenceError($entityType/$entityId): expected $expected, got $actual';
}

/// Error thrown when `verifyChainIntegrity` is called and the chain is
/// inconsistent. Not thrown by adapters (they return `false`), but useful
/// for callers that want a failure-reason channel.
class AuditChainIntegrityError extends Error {
  final String entityType;
  final String entityId;
  final int atSequence;
  final String reason;

  AuditChainIntegrityError({
    required this.entityType,
    required this.entityId,
    required this.atSequence,
    required this.reason,
  });

  @override
  String toString() =>
      'AuditChainIntegrityError($entityType/$entityId @#$atSequence): $reason';
}
