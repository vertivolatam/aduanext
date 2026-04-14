/// Deterministic JSON serialization for [AuditEvent].
///
/// Hashing an event requires a byte-for-byte stable representation. We get
/// that by sorting every `Map` key alphabetically (recursively) before
/// encoding to JSON — otherwise Dart's `Map` iteration order can shift
/// between inserts/platforms and break the chain.
library;

import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';

/// Extensions for canonical serialization of [AuditEvent] instances.
extension AuditEventCanonical on AuditEvent {
  /// Canonical JSON representation of the hashable fields.
  ///
  /// Deliberately excludes [AuditEvent.eventHash] (which is the output of
  /// the hash function) and [AuditEvent.serverTimestamp] (assigned after
  /// sync — it would break tamper detection).
  ///
  /// Includes [AuditEvent.previousHash] and [AuditEvent.sequenceNumber]
  /// because those are bound to the chain position.
  String toCanonicalJson() {
    final map = <String, dynamic>{
      'action': action,
      'actorId': actorId,
      'clientTimestamp': clientTimestamp.toUtc().toIso8601String(),
      'entityId': entityId,
      'entityType': entityType,
      'payload': _canonicalize(payload),
      'payloadType': payloadType.name,
      'previousHash': previousHash,
      'sequenceNumber': sequenceNumber,
      'tenantId': tenantId,
    };
    return jsonEncode(_sortMap(map));
  }

  /// Full JSON representation used for persistence/export (includes
  /// [AuditEvent.eventHash] and [AuditEvent.serverTimestamp]).
  Map<String, dynamic> toStorageJson() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'actorId': actorId,
      'tenantId': tenantId,
      'payload': jsonEncode(_canonicalize(payload)),
      'payloadType': payloadType.name,
      'clientTimestamp': clientTimestamp.toUtc().toIso8601String(),
      'serverTimestamp': serverTimestamp?.toUtc().toIso8601String(),
      'sequenceNumber': sequenceNumber,
      'previousHash': previousHash,
      'eventHash': eventHash,
    };
  }
}

/// Reconstruct an [AuditEvent] from a storage map (inverse of
/// [AuditEventCanonical.toStorageJson]).
AuditEvent auditEventFromStorageJson(Map<String, dynamic> row) {
  final clientTs = DateTime.parse(row['clientTimestamp'] as String).toUtc();
  final serverTsRaw = row['serverTimestamp'] as String?;
  final payloadRaw = row['payload'];
  final payload = payloadRaw is String
      ? (jsonDecode(payloadRaw) as Map<String, dynamic>)
      : Map<String, dynamic>.from(payloadRaw as Map);
  return AuditEvent(
    entityType: row['entityType'] as String,
    entityId: row['entityId'] as String,
    action: row['action'] as String,
    actorId: row['actorId'] as String,
    tenantId: row['tenantId'] as String,
    payload: payload,
    timestamp: clientTs,
    clientTimestamp: clientTs,
    serverTimestamp:
        serverTsRaw == null ? null : DateTime.parse(serverTsRaw).toUtc(),
    sequenceNumber: (row['sequenceNumber'] as num).toInt(),
    previousHash: row['previousHash'] as String,
    eventHash: row['eventHash'] as String,
    payloadType: AuditPayloadType.values
        .firstWhere((t) => t.name == row['payloadType'] as String),
  );
}

/// Recursively alphabetize the keys of every map inside [value].
/// Leaves lists in their original order (semantics matter) and leaves
/// scalars untouched.
dynamic _canonicalize(dynamic value) {
  if (value is Map) {
    final sorted = <String, dynamic>{};
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    for (final k in keys) {
      sorted[k] = _canonicalize(value[k]);
    }
    return sorted;
  }
  if (value is List) {
    return value.map(_canonicalize).toList();
  }
  return value;
}

/// Alphabetize the top-level keys of [map].
Map<String, dynamic> _sortMap(Map<String, dynamic> map) {
  final keys = map.keys.toList()..sort();
  final result = <String, dynamic>{};
  for (final k in keys) {
    result[k] = map[k];
  }
  return result;
}
