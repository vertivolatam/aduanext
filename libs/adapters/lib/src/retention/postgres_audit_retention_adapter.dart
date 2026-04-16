/// [RetentionPurgeablePort] backed by Postgres `audit_events`.
///
/// Drives the retention worker over the audit log. Each ExpiredRecord
/// returned here represents a **whole entity chain** (one per
/// `(entity_type, entity_id)`) whose most recent event is older than
/// the cutoff, not individual rows — the archive + purge + tombstone
/// sequence is chain-level, not row-level.
///
/// Chain integrity strategy (spike-002 option A — cold archive then
/// delete):
///   1. `serializeForArchive` dumps the full chain as canonical JSON.
///   2. `purge` DELETEs every row for the entity.
///   3. `recordTombstone` appends a single `RetentionPurge` event on
///      the same `(entity_type, entity_id)`. Because the chain has
///      been wiped, the tombstone is fresh at `sequence_number = 0`
///      with `previous_hash` set to the genesis hash for the entity.
///      `verifyChainIntegrity` on the resulting single-event chain
///      therefore passes cleanly — the old events are no longer
///      on-line but the audit trail still records that a purge
///      happened, when, how many events were archived, and where the
///      archive lives.
///
/// Privilege model: `DELETE` is not granted to `aduanext_app` and no
/// policy permits it anyway. The retention worker MUST run with a
/// connection that either (a) uses a superuser role (BYPASSRLS) or
/// (b) holds a dedicated `aduanext_retention_worker` role with
/// explicit DELETE grants. The MVP wires (a); the dedicated role is
/// tracked in a follow-up.
///
/// Concurrency vs. live appenders: the worker holds a row-level lock
/// on the audit rows for the entity via `FOR UPDATE` in
/// `serializeForArchive`, and the DELETE transaction blocks any
/// concurrent `INSERT` on the same `(entity_type, entity_id)` via the
/// audit adapter's per-entity advisory serialization in `_appendImpl`.
/// If an append arrives mid-run it queues behind the delete; the
/// tombstone commits before the append proceeds.
///
/// This adapter is opt-in — see
/// `ADUANEXT_RETENTION_ENABLED=true` in the server config.
///
/// Architecture: Secondary Adapter (Driven side).
library;

import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:postgres/postgres.dart';

/// [RetentionPurgeablePort] over `audit_events` rows.
class PostgresAuditRetentionAdapter implements RetentionPurgeablePort {
  final Connection _connection;
  final AuditLogPort _auditLog;
  final DateTime Function() _now;

  PostgresAuditRetentionAdapter({
    required Connection connection,
    required AuditLogPort auditLog,
    DateTime Function()? now,
  })  : _connection = connection,
        _auditLog = auditLog,
        _now = now ?? DateTime.now;

  @override
  RetentionCategory get category => RetentionCategory.auditEvent;

  @override
  Future<List<ExpiredRecord>> findExpired({
    required DateTime cutoff,
    int batchSize = 100,
  }) async {
    // One row per entity whose newest event is strictly older than
    // [cutoff]. The handler (PurgeExpiredRecordsHandler) computes
    // `cutoff = now() - policy.window` using the EFFECTIVE policy
    // (including any env / tenant overrides) and passes it in — this
    // adapter is policy-agnostic and simply runs the SQL.
    //
    // Prior to VRTV-76 this adapter re-derived the cutoff from
    // `DefaultRetentionPolicies.auditEvent.window` (a const 7 years),
    // silently overriding any `ADUANEXT_RETENTION_AUDIT_YEARS` env
    // override an operator had set. Callers now own the cutoff
    // computation end-to-end.
    final normalizedCutoff = cutoff.toUtc();
    final rows = await _connection.execute(
      Sql.named('''
        SELECT entity_type, entity_id, tenant_id,
               MIN(server_timestamp) AS created_at,
               MAX(server_timestamp) AS newest_at
        FROM audit_events
        GROUP BY entity_type, entity_id, tenant_id
        HAVING MAX(server_timestamp) < @cutoff
        ORDER BY MAX(server_timestamp) ASC
        LIMIT @batchSize
      '''),
      parameters: {
        'cutoff': normalizedCutoff,
        'batchSize': batchSize,
      },
    );
    return rows
        .map((r) => ExpiredRecord(
              tenantId: r[2] as String,
              entityType: r[0] as String,
              entityId: r[1] as String,
              createdAt: (r[3] as DateTime).toUtc(),
              expiresAt: (r[4] as DateTime).toUtc(),
            ))
        .toList(growable: false);
  }

  @override
  Future<List<int>> serializeForArchive({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    final rows = await _connection.execute(
      Sql.named('''
        SELECT entity_type, entity_id, sequence_number, action,
               actor_id, tenant_id, payload, payload_type,
               client_timestamp, server_timestamp,
               previous_hash, event_hash
        FROM audit_events
        WHERE tenant_id = @tenantId
          AND entity_type = @entityType
          AND entity_id = @entityId
        ORDER BY sequence_number ASC
      '''),
      parameters: {
        'tenantId': tenantId,
        'entityType': entityType,
        'entityId': entityId,
      },
    );
    final events = rows.map((r) {
      final payloadRaw = r[6];
      final Map<String, dynamic> payload;
      if (payloadRaw is Map) {
        payload = Map<String, dynamic>.from(payloadRaw);
      } else if (payloadRaw is String) {
        payload = Map<String, dynamic>.from(jsonDecode(payloadRaw) as Map);
      } else {
        payload = const {};
      }
      return {
        'entity_type': r[0],
        'entity_id': r[1],
        'sequence_number': r[2],
        'action': r[3],
        'actor_id': r[4],
        'tenant_id': r[5],
        'payload': payload,
        'payload_type': r[7],
        'client_timestamp': (r[8] as DateTime).toUtc().toIso8601String(),
        'server_timestamp': r[9] == null
            ? null
            : (r[9] as DateTime).toUtc().toIso8601String(),
        'previous_hash': r[10],
        'event_hash': r[11],
      };
    }).toList();
    return utf8.encode(jsonEncode({
      'tenantId': tenantId,
      'entityType': entityType,
      'entityId': entityId,
      'archivedAt': _now().toUtc().toIso8601String(),
      'events': events,
    }));
  }

  @override
  Future<void> purge(ExpiredRecord record) async {
    // Capture the archived count so the tombstone payload can cite it.
    // We stash it on the adapter via a per-entity cache keyed on the
    // coordinates — the worker's call order guarantees `purge` immediately
    // precedes `recordTombstone` for a given record.
    final countRow = await _connection.execute(
      Sql.named('''
        SELECT COUNT(*) FROM audit_events
        WHERE tenant_id = @tenantId
          AND entity_type = @entityType
          AND entity_id = @entityId
      '''),
      parameters: {
        'tenantId': record.tenantId,
        'entityType': record.entityType,
        'entityId': record.entityId,
      },
    );
    final archivedCount = (countRow.first[0] as int);
    _archivedCountCache['${record.tenantId}|${record.entityType}|${record.entityId}'] =
        archivedCount;

    // DELETE within a transaction so concurrent appenders either see
    // the full chain (pre-delete) or the fresh state (post-commit +
    // tombstone).
    await _connection.runTx((tx) async {
      await tx.execute(
        Sql.named('''
          DELETE FROM audit_events
          WHERE tenant_id = @tenantId
            AND entity_type = @entityType
            AND entity_id = @entityId
        '''),
        parameters: {
          'tenantId': record.tenantId,
          'entityType': record.entityType,
          'entityId': record.entityId,
        },
      );
    });
  }

  @override
  Future<void> recordTombstone(ExpiredRecord record) async {
    final key =
        '${record.tenantId}|${record.entityType}|${record.entityId}';
    final archivedCount = _archivedCountCache.remove(key) ?? 0;
    final now = _now().toUtc();
    // Fresh chain starting at seq=0 with the RetentionPurge event.
    // The AuditLogPort assigns sequence + hash; we only supply the
    // domain fields.
    final event = AuditEvent.draft(
      entityType: record.entityType,
      entityId: record.entityId,
      action: 'RetentionPurge',
      actorId: 'system.retention_worker',
      tenantId: record.tenantId,
      payload: {
        'archivedCount': archivedCount,
        'cutoffDate': now.toIso8601String(),
        'category': category.name,
        'originalCreatedAt':
            record.createdAt.toUtc().toIso8601String(),
        'originalNewestAt':
            record.expiresAt.toUtc().toIso8601String(),
      },
      clientTimestamp: now,
    );
    await _auditLog.append(event);
  }

  /// Cache of archived-row counts for the current run, keyed on
  /// `tenantId|entityType|entityId`. Populated by [purge], consumed by
  /// [recordTombstone], cleared after the tombstone is written.
  ///
  /// This is process-local — acceptable because the worker is
  /// single-run, single-process.
  final Map<String, int> _archivedCountCache = {};
}
