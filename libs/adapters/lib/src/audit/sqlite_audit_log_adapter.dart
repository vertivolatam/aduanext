/// SQLite-backed [AuditLogPort] for mobile / desktop standalone deploys.
///
/// Uses `sqflite_common` so the same code runs on Flutter (via `sqflite`)
/// and on pure-Dart desktop / tests (via `sqflite_common_ffi`). Callers
/// are responsible for initializing the FFI bootstrap in the appropriate
/// entry-point — see
/// [SqliteAuditLogAdapter.openInMemoryForTesting] for a test helper.
///
/// Schema (table `audit_events`):
///
/// | column           | type    | notes                                  |
/// | ---------------- | ------- | -------------------------------------- |
/// | id               | INTEGER | PK autoincrement (storage only)        |
/// | entityType       | TEXT    | PK component of logical chain          |
/// | entityId         | TEXT    | PK component of logical chain          |
/// | sequenceNumber   | INTEGER | 0-based per `(entityType, entityId)`   |
/// | action           | TEXT    |                                        |
/// | actorId          | TEXT    |                                        |
/// | tenantId         | TEXT    |                                        |
/// | payload          | TEXT    | canonical JSON                         |
/// | payloadType      | TEXT    | `snapshot` or `delta`                  |
/// | clientTimestamp  | TEXT    | ISO-8601 UTC                           |
/// | serverTimestamp  | TEXT    | ISO-8601 UTC (nullable)                |
/// | previousHash     | TEXT    |                                        |
/// | eventHash        | TEXT    |                                        |
///
/// Unique index on `(entityType, entityId, sequenceNumber)` enforces
/// monotonic appends at the DB level (no gaps, no duplicates) — in
/// addition to the in-process lock inside [append].
library;

import 'dart:async';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'audit_chain_hasher.dart';
import 'audit_event_extensions.dart';

/// SQLite-backed, tamper-evident audit log.
class SqliteAuditLogAdapter implements AuditLogPort {
  final Database _db;
  final AuditChainHasher _hasher;
  final DateTime Function() _now;

  Future<void> _writeLock = Future<void>.value();

  SqliteAuditLogAdapter._(this._db, this._hasher, this._now);

  /// Open (or create) an on-disk audit log at [path].
  ///
  /// Caller must have initialized `sqflite_common_ffi` (via
  /// `sqfliteFfiInit()` and optionally `databaseFactoryFfi`) OR be
  /// running inside a Flutter app that wires `sqflite` as the
  /// `databaseFactory`.
  static Future<SqliteAuditLogAdapter> open({
    required String path,
    DatabaseFactory? databaseFactory,
    AuditChainHasher? hasher,
    DateTime Function()? now,
  }) async {
    final factory = databaseFactory ?? databaseFactoryFfi;
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createSchema,
      ),
    );
    return SqliteAuditLogAdapter._(
      db,
      hasher ?? const AuditChainHasher(),
      now ?? DateTime.now,
    );
  }

  /// Test helper — returns an adapter backed by an in-memory SQLite DB.
  /// Requires `sqfliteFfiInit()` to have been called.
  static Future<SqliteAuditLogAdapter> openInMemoryForTesting({
    AuditChainHasher? hasher,
    DateTime Function()? now,
  }) {
    return open(
      path: inMemoryDatabasePath,
      hasher: hasher,
      now: now,
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE audit_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        sequenceNumber INTEGER NOT NULL,
        action TEXT NOT NULL,
        actorId TEXT NOT NULL,
        tenantId TEXT NOT NULL,
        payload TEXT NOT NULL,
        payloadType TEXT NOT NULL,
        clientTimestamp TEXT NOT NULL,
        serverTimestamp TEXT,
        previousHash TEXT NOT NULL,
        eventHash TEXT NOT NULL,
        UNIQUE (entityType, entityId, sequenceNumber)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_audit_entity
      ON audit_events (entityType, entityId, sequenceNumber)
    ''');
  }

  Future<void> close() => _db.close();

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
    final tail = await _db.query(
      'audit_events',
      columns: ['sequenceNumber', 'eventHash'],
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [event.entityType, event.entityId],
      orderBy: 'sequenceNumber DESC',
      limit: 1,
    );

    final expectedSeq = tail.isEmpty
        ? 0
        : (tail.first['sequenceNumber'] as int) + 1;
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
        : tail.first['eventHash'] as String;

    final sealed = _hasher.seal(
      event: event,
      previousHash: prevHash,
      sequenceNumber: expectedSeq,
      serverTimestamp: event.serverTimestamp ?? _now().toUtc(),
    );

    await _db.insert('audit_events', sealed.toStorageJson());
    return sealed.eventHash;
  }

  @override
  Future<List<AuditEvent>> queryByEntity(
      String entityType, String entityId) async {
    final rows = await _db.query(
      'audit_events',
      where: 'entityType = ? AND entityId = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'sequenceNumber ASC',
    );
    return rows.map(auditEventFromStorageJson).toList(growable: false);
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

  /// Test-only raw database handle. Used by tampering-detection tests
  /// to simulate an attacker mutating the table behind our back.
  Database get debugRawDatabase => _db;
}
