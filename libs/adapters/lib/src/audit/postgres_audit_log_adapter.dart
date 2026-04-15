/// PostgreSQL-backed [AuditLogPort] for the Serverpod server deploy.
///
/// Mirrors [SqliteAuditLogAdapter] in semantics (per-entity hash chain,
/// UNIQUE enforcement, append-only) but uses PostgreSQL-native types:
/// `JSONB` for payload, `TIMESTAMPTZ` for timestamps.
///
/// Schema (table `audit_events`):
///
/// | column           | type        | notes                              |
/// | ---------------- | ----------- | ---------------------------------- |
/// | id               | BIGSERIAL   | PK (storage only)                  |
/// | entity_type      | TEXT        | logical chain key (part 1)         |
/// | entity_id        | TEXT        | logical chain key (part 2)         |
/// | sequence_number  | BIGINT      | 0-based per `(entity_type, id)`    |
/// | action           | TEXT        |                                    |
/// | actor_id         | TEXT        |                                    |
/// | tenant_id        | TEXT        |                                    |
/// | payload          | JSONB       | canonical JSON                     |
/// | payload_type     | TEXT        | `snapshot` or `delta`              |
/// | client_timestamp | TIMESTAMPTZ |                                    |
/// | server_timestamp | TIMESTAMPTZ | nullable                           |
/// | previous_hash    | TEXT        | SHA-256 hex                        |
/// | event_hash       | TEXT        | SHA-256 hex                        |
///
/// UNIQUE `(entity_type, entity_id, sequence_number)` provides the same
/// belt-and-suspenders duplicate-detection as the SQLite adapter.
///
/// Column names use `snake_case` (PG convention); the Dart side maps to
/// the mixed-case [AuditEvent] fields on read.
///
/// Schema migration: `ensureSchema()` uses idempotent `CREATE TABLE IF
/// NOT EXISTS` / `CREATE INDEX IF NOT EXISTS`. Safe to call at every
/// startup. A proper migration tool (Flyway / dbmate) is deferred to
/// future work — see the follow-up issue linked from VRTV-55.
library;

import 'dart:async';
import 'dart:convert';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:postgres/postgres.dart';

import 'audit_chain_hasher.dart';
import 'migrations/tenant_isolation_migration.dart';

/// PostgreSQL-backed, tamper-evident audit log.
class PostgresAuditLogAdapter implements AuditLogPort {
  final Connection _connection;
  final AuditChainHasher _hasher;
  final DateTime Function() _now;

  /// In-process serialization to avoid two concurrent appenders computing
  /// the same `expected sequence_number`. The DB UNIQUE constraint is the
  /// final line of defense, but this lock keeps the happy path
  /// exception-free when multiple callers share one adapter instance.
  Future<void> _writeLock = Future<void>.value();

  PostgresAuditLogAdapter._(this._connection, this._hasher, this._now);

  /// Open an adapter against [endpoint] using [settings]. The caller owns
  /// the lifecycle of the connection — call [close] when done.
  ///
  /// For tests, see [openForTesting] which also calls [ensureSchema].
  static Future<PostgresAuditLogAdapter> open({
    required Endpoint endpoint,
    ConnectionSettings? settings,
    AuditChainHasher? hasher,
    DateTime Function()? now,
    bool ensureSchema = false,
  }) async {
    final conn = await Connection.open(
      endpoint,
      settings: settings ??
          const ConnectionSettings(sslMode: SslMode.disable),
    );
    final adapter = PostgresAuditLogAdapter._(
      conn,
      hasher ?? const AuditChainHasher(),
      now ?? DateTime.now,
    );
    if (ensureSchema) {
      await adapter.ensureSchema();
    }
    return adapter;
  }

  /// Test helper — opens against the default `postgres_test` container
  /// (see `docker-compose.yaml`, port `9190`) and ensures the schema
  /// exists. Callers MUST have run `make db-up` first.
  static Future<PostgresAuditLogAdapter> openForTesting({
    String host = 'localhost',
    int port = 9190,
    String database = 'aduanext_test',
    String username = 'postgres',
    required String password,
    AuditChainHasher? hasher,
    DateTime Function()? now,
  }) {
    return open(
      endpoint: Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
      hasher: hasher,
      now: now,
      ensureSchema: true,
    );
  }

  /// Idempotent schema creation. Safe to call multiple times.
  ///
  /// Applies migrations in order:
  ///   0001 — base `audit_events` table + per-entity index (inline).
  ///   0002 — tenant isolation via RLS (see tenant_isolation_migration.dart).
  Future<void> ensureSchema() async {
    // 0001 — base schema.
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS audit_events (
        id               BIGSERIAL PRIMARY KEY,
        entity_type      TEXT        NOT NULL,
        entity_id        TEXT        NOT NULL,
        sequence_number  BIGINT      NOT NULL,
        action           TEXT        NOT NULL,
        actor_id         TEXT        NOT NULL,
        tenant_id        TEXT        NOT NULL,
        payload          JSONB       NOT NULL,
        payload_type     TEXT        NOT NULL,
        client_timestamp TIMESTAMPTZ NOT NULL,
        server_timestamp TIMESTAMPTZ,
        previous_hash    TEXT        NOT NULL,
        event_hash       TEXT        NOT NULL,
        CONSTRAINT audit_events_entity_seq_unique
          UNIQUE (entity_type, entity_id, sequence_number)
      )
    ''');
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_audit_events_entity
      ON audit_events (entity_type, entity_id, sequence_number)
    ''');

    // 0002 — RLS + tenant helpers. Statements are issued one at a
    // time because the postgres Dart driver does not accept multi-
    // statement batches on a prepared statement.
    for (final stmt in tenantIsolationMigrationStatements) {
      await _connection.execute(stmt);
    }
  }

  /// Close the underlying connection. Idempotent.
  Future<void> close() async {
    if (_connection.isOpen) {
      await _connection.close();
    }
  }

  @override
  Future<String> append(AuditEvent event) {
    final completer = Completer<String>();
    _writeLock = _writeLock.then((_) async {
      try {
        final hash = await _appendImpl(event);
        completer.complete(hash);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<String> _appendImpl(AuditEvent event) async {
    // Wrap tail-read + insert in a single transaction so that concurrent
    // writes from other adapter instances (different processes) cannot
    // race past each other. The UNIQUE constraint is the safety net that
    // turns a lost race into a retriable error.
    return _connection.runTx<String>((tx) async {
      // Set the transaction-local RLS tenant to match the event's
      // tenant_id. This matches the INSERT WITH CHECK policy, so any
      // attempt to smuggle a different tenant_id through would be
      // rejected by Postgres itself (defense in depth vs. application
      // bugs). The `true` argument scopes the setting to this
      // transaction — rolled back on commit/rollback.
      await tx.execute(
        Sql.named("SELECT set_app_tenant(@tenantId)"),
        parameters: {'tenantId': event.tenantId},
      );
      final tail = await tx.execute(
        Sql.named('''
          SELECT sequence_number, event_hash
          FROM audit_events
          WHERE entity_type = @entityType AND entity_id = @entityId
          ORDER BY sequence_number DESC
          LIMIT 1
          FOR UPDATE
        '''),
        parameters: {
          'entityType': event.entityType,
          'entityId': event.entityId,
        },
      );

      final expectedSeq = tail.isEmpty
          ? 0
          : (tail.first[0] as int) + 1;
      if (event.sequenceNumber != -1 && event.sequenceNumber != expectedSeq) {
        throw AuditChainSequenceError(
          entityType: event.entityType,
          entityId: event.entityId,
          expected: expectedSeq,
          actual: event.sequenceNumber,
        );
      }

      final prevHash = tail.isEmpty
          ? _hasher.genesisHash(
              entityType: event.entityType,
              entityId: event.entityId,
            )
          : tail.first[1] as String;

      final sealed = _hasher.seal(
        event: event,
        previousHash: prevHash,
        sequenceNumber: expectedSeq,
        serverTimestamp: event.serverTimestamp ?? _now().toUtc(),
      );

      await tx.execute(
        Sql.named('''
          INSERT INTO audit_events (
            entity_type, entity_id, sequence_number, action,
            actor_id, tenant_id, payload, payload_type,
            client_timestamp, server_timestamp,
            previous_hash, event_hash
          ) VALUES (
            @entityType, @entityId, @sequenceNumber, @action,
            @actorId, @tenantId, @payload::jsonb, @payloadType,
            @clientTs, @serverTs,
            @previousHash, @eventHash
          )
        '''),
        parameters: {
          'entityType': sealed.entityType,
          'entityId': sealed.entityId,
          'sequenceNumber': sealed.sequenceNumber,
          'action': sealed.action,
          'actorId': sealed.actorId,
          'tenantId': sealed.tenantId,
          'payload': jsonEncode(_canonicalPayload(sealed.payload)),
          'payloadType': sealed.payloadType.name,
          'clientTs': sealed.clientTimestamp.toUtc(),
          'serverTs': sealed.serverTimestamp?.toUtc(),
          'previousHash': sealed.previousHash,
          'eventHash': sealed.eventHash,
        },
      );

      return sealed.eventHash;
    });
  }

  @override
  Future<List<AuditEvent>> queryByEntity(
      String entityType, String entityId) async {
    // RLS filters by the session's `app.current_tenant_id`. Callers
    // that want a cross-tenant view MUST wrap the call in
    // [withAdminBypass] — doing so from a fiscalizador export
    // endpoint is the only legitimate use.
    final rows = await _connection.execute(
      Sql.named('''
        SELECT entity_type, entity_id, sequence_number, action,
               actor_id, tenant_id, payload, payload_type,
               client_timestamp, server_timestamp,
               previous_hash, event_hash
        FROM audit_events
        WHERE entity_type = @entityType AND entity_id = @entityId
        ORDER BY sequence_number ASC
      '''),
      parameters: {
        'entityType': entityType,
        'entityId': entityId,
      },
    );
    return rows.map(_rowToEvent).toList(growable: false);
  }

  /// Set the session-scoped tenant context. Callers that run the
  /// adapter outside the shelf middleware (tests, fiscalizador export,
  /// long-running workers) MUST call this before every
  /// [queryByEntity] / [verifyChainIntegrity] call; otherwise RLS
  /// filters every row and the result is empty (fail-secure default).
  ///
  /// The setting uses `set_config(..., false)` which scopes it to the
  /// whole session. In a connection-pooled deployment, the middleware
  /// MUST call this on every request to refresh the value, since the
  /// connection is shared across users.
  Future<void> setSessionTenant(String? tenantId) async {
    if (tenantId == null) {
      // Clearing: set to empty so `current_app_tenant()` returns NULL.
      await _connection.execute(
        Sql.named('''SELECT set_config('app.current_tenant_id', '', false)'''),
      );
      return;
    }
    await _connection.execute(
      Sql.named(
        '''SELECT set_config('app.current_tenant_id', @tenantId, false)''',
      ),
      parameters: {'tenantId': tenantId},
    );
  }

  /// Toggle the admin-bypass flag for the session. When set to
  /// `'admin'`, the SELECT policy lets rows through regardless of
  /// tenant — callers MUST audit-log the bypass itself before flipping
  /// it (contract, not enforced in code).
  ///
  /// Pass `null` to clear the flag.
  Future<void> setSessionAdminBypass(bool enabled) async {
    await _connection.execute(
      Sql.named(
        '''SELECT set_config('app.bypass_rls', @flag, false)''',
      ),
      parameters: {'flag': enabled ? 'admin' : ''},
    );
  }

  @override
  Future<bool> verifyChainIntegrity(
      String entityType, String entityId) async {
    final events = await queryByEntity(entityType, entityId);
    if (events.isEmpty) return true;

    var expectedPrev = _hasher.genesisHash(
      entityType: entityType,
      entityId: entityId,
    );
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      if (e.sequenceNumber != i) return false;
      if (e.previousHash != expectedPrev) return false;
      if (!_hasher.verify(e)) return false;
      expectedPrev = e.eventHash;
    }
    return true;
  }

  AuditEvent _rowToEvent(ResultRow row) {
    final payloadRaw = row[6];
    final Map<String, dynamic> payload;
    if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    } else if (payloadRaw is String) {
      payload = Map<String, dynamic>.from(jsonDecode(payloadRaw) as Map);
    } else {
      payload = const {};
    }
    final clientTs = (row[8] as DateTime).toUtc();
    final serverTsRaw = row[9];
    return AuditEvent(
      entityType: row[0] as String,
      entityId: row[1] as String,
      action: row[3] as String,
      actorId: row[4] as String,
      tenantId: row[5] as String,
      payload: payload,
      timestamp: clientTs,
      clientTimestamp: clientTs,
      serverTimestamp: serverTsRaw == null
          ? null
          : (serverTsRaw as DateTime).toUtc(),
      sequenceNumber: (row[2] as num).toInt(),
      previousHash: row[10] as String,
      eventHash: row[11] as String,
      payloadType: AuditPayloadType.values
          .firstWhere((t) => t.name == row[7] as String),
    );
  }

  /// Test-only raw connection handle for tampering-detection tests.
  /// Production code MUST NOT use this.
  Connection get debugRawConnection => _connection;

  /// Test-only: switch the effective session role. The RLS test suite
  /// uses this to drop from the `postgres` superuser (which has
  /// BYPASSRLS) to the non-bypassing `aduanext_app` role so that the
  /// policies are actually enforced.
  ///
  /// Pass `null` to RESET (restore the original role).
  Future<void> debugSetSessionRole(String? roleName) async {
    if (roleName == null) {
      await _connection.execute('RESET ROLE');
    } else {
      await _connection.execute('SET ROLE $roleName');
    }
  }

  /// Delete all audit events. Test-only helper to reset state between
  /// tests without re-running migrations.
  Future<void> debugTruncateForTesting() async {
    await _connection.execute('TRUNCATE TABLE audit_events RESTART IDENTITY');
  }
}

/// Recursively alphabetize map keys so the `JSONB` we persist matches the
/// canonical form used by the hasher. Lists keep order; scalars pass through.
dynamic _canonicalPayload(dynamic value) {
  if (value is Map) {
    final sorted = <String, dynamic>{};
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    for (final k in keys) {
      sorted[k] = _canonicalPayload(value[k]);
    }
    return sorted;
  }
  if (value is List) {
    return value.map(_canonicalPayload).toList();
  }
  return value;
}
