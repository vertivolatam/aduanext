/// PostgreSQL-backed [LegalHoldPort] for the Serverpod server deploy.
///
/// Mirrors the semantics of [InMemoryLegalHoldAdapter]:
///   * At most ONE active hold per `(tenantId, entityType, entityId)`.
///   * `release` is a no-op when no active hold exists (idempotent).
///   * `historyFor` returns every hold (active + released) for the
///     coordinates, most-recent first.
///   * `place` after a prior hold has been released is allowed and
///     produces a brand-new row (append-only; the released one is
///     preserved for audit).
///
/// Schema + RLS live in `migrations/0001_legal_holds.sql` (canonical)
/// and its embedded twin `legal_holds_migration.dart`. This adapter
/// depends on audit-log migration 0002 having already installed the
/// `current_app_tenant()` / `set_app_tenant()` helpers + the
/// `aduanext_app` non-bypassing role — every call sets the
/// transaction-local tenant GUC before reading or writing, matching
/// the pattern from [PostgresAuditLogAdapter].
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:postgres/postgres.dart';

import 'migrations/legal_holds_migration.dart';

/// PostgreSQL-backed [LegalHoldPort].
class PostgresLegalHoldAdapter implements LegalHoldPort {
  final Connection _connection;

  /// Generates surrogate primary keys. Defaults to
  /// `DateTime.now().microsecondsSinceEpoch` + a monotonic counter so
  /// we don't need to add `uuid` as a dependency for a table this
  /// small. Tests can inject deterministic IDs.
  final String Function() _newId;

  PostgresLegalHoldAdapter._(this._connection, this._newId);

  /// Open an adapter against [endpoint] using [settings]. The caller
  /// owns the lifecycle of the connection — call [close] when done.
  static Future<PostgresLegalHoldAdapter> open({
    required Endpoint endpoint,
    ConnectionSettings? settings,
    String Function()? idGenerator,
    bool ensureSchema = false,
  }) async {
    final conn = await Connection.open(
      endpoint,
      settings: settings ??
          const ConnectionSettings(sslMode: SslMode.disable),
    );
    final adapter = PostgresLegalHoldAdapter._(
      conn,
      idGenerator ?? _defaultIdGenerator,
    );
    if (ensureSchema) {
      await adapter.ensureSchema();
    }
    return adapter;
  }

  /// Test helper — opens against the default `postgres_test` container
  /// (see `docker-compose.yaml`, port `9190`) and ensures the schema
  /// exists. Callers MUST have run `make db-up` first.
  static Future<PostgresLegalHoldAdapter> openForTesting({
    String host = 'localhost',
    int port = 9190,
    String database = 'aduanext_test',
    String username = 'postgres',
    required String password,
    String Function()? idGenerator,
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
      idGenerator: idGenerator,
      ensureSchema: true,
    );
  }

  /// Idempotent schema creation — safe to call at every boot.
  Future<void> ensureSchema() async {
    for (final stmt in legalHoldsMigrationStatements) {
      await _connection.execute(stmt);
    }
  }

  /// Close the underlying connection. Idempotent.
  Future<void> close() async {
    if (_connection.isOpen) {
      await _connection.close();
    }
  }

  /// Set the session-scoped tenant context. Matches the pattern in
  /// [PostgresAuditLogAdapter]: callers that run the adapter outside
  /// the shelf middleware (tests, fiscalizador export, long-running
  /// workers) MUST call this before every read/write, or RLS will
  /// filter every row.
  Future<void> setSessionTenant(String? tenantId) async {
    if (tenantId == null) {
      await _connection.execute(
        Sql.named(
            '''SELECT set_config('app.current_tenant_id', '', false)'''),
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

  /// Toggle the admin-bypass flag for the session. See the docstring
  /// on [PostgresAuditLogAdapter.setSessionAdminBypass] — same
  /// contract, same audit requirement.
  Future<void> setSessionAdminBypass(bool enabled) async {
    await _connection.execute(
      Sql.named(
        '''SELECT set_config('app.bypass_rls', @flag, false)''',
      ),
      parameters: {'flag': enabled ? 'admin' : ''},
    );
  }

  @override
  Future<void> place(LegalHold hold) async {
    // Wrap tenant-binding + active-check + INSERT in a single
    // transaction so concurrent placers race cleanly against the
    // partial unique index. The DB index is the final line of defense;
    // the explicit check converts the race into a clean StateError
    // matching the in-memory adapter's contract.
    await _connection.runTx((tx) async {
      await tx.execute(
        Sql.named('SELECT set_app_tenant(@tenantId)'),
        parameters: {'tenantId': hold.tenantId},
      );
      final active = await tx.execute(
        Sql.named('''
          SELECT id, set_at, set_by_actor_id
          FROM legal_holds
          WHERE tenant_id = @tenantId
            AND entity_type = @entityType
            AND entity_id = @entityId
            AND released_at IS NULL
          LIMIT 1
          FOR UPDATE
        '''),
        parameters: {
          'tenantId': hold.tenantId,
          'entityType': hold.entityType,
          'entityId': hold.entityId,
        },
      );
      if (active.isNotEmpty) {
        throw StateError(
          'A legal hold is already active for '
          '(${hold.tenantId}, ${hold.entityType}, ${hold.entityId}) '
          '(set ${active.first[1]} by ${active.first[2]})',
        );
      }
      await tx.execute(
        Sql.named('''
          INSERT INTO legal_holds (
            id, tenant_id, entity_type, entity_id, reason,
            set_by_actor_id, set_at, released_at, released_by_actor_id
          ) VALUES (
            @id, @tenantId, @entityType, @entityId, @reason,
            @setByActorId, @setAt, NULL, NULL
          )
        '''),
        parameters: {
          'id': _newId(),
          'tenantId': hold.tenantId,
          'entityType': hold.entityType,
          'entityId': hold.entityId,
          'reason': hold.reason,
          'setByActorId': hold.setByActorId,
          'setAt': hold.setAt.toUtc(),
        },
      );
    });
  }

  @override
  Future<void> release({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String releasedByActorId,
    required DateTime releasedAt,
  }) async {
    await _connection.runTx((tx) async {
      await tx.execute(
        Sql.named('SELECT set_app_tenant(@tenantId)'),
        parameters: {'tenantId': tenantId},
      );
      // No-op when no active hold exists — matches in-memory behavior.
      await tx.execute(
        Sql.named('''
          UPDATE legal_holds
          SET released_at = @releasedAt,
              released_by_actor_id = @releasedBy
          WHERE tenant_id = @tenantId
            AND entity_type = @entityType
            AND entity_id = @entityId
            AND released_at IS NULL
        '''),
        parameters: {
          'releasedAt': releasedAt.toUtc(),
          'releasedBy': releasedByActorId,
          'tenantId': tenantId,
          'entityType': entityType,
          'entityId': entityId,
        },
      );
    });
  }

  @override
  Future<bool> isHeld({
    required String tenantId,
    required String entityType,
    required String entityId,
    required DateTime now,
  }) async {
    await setSessionTenant(tenantId);
    // "Active at now" means released_at is NULL OR released_at > now.
    // We still use the partial index (released_at IS NULL) for the
    // fast path, then fall back to a scan when a release is in the
    // future (rare — the port contract allows it but production always
    // releases with `now`).
    final rows = await _connection.execute(
      Sql.named('''
        SELECT 1
        FROM legal_holds
        WHERE tenant_id = @tenantId
          AND entity_type = @entityType
          AND entity_id = @entityId
          AND (released_at IS NULL OR released_at > @now)
        LIMIT 1
      '''),
      parameters: {
        'tenantId': tenantId,
        'entityType': entityType,
        'entityId': entityId,
        'now': now.toUtc(),
      },
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<LegalHold>> historyFor({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    await setSessionTenant(tenantId);
    final rows = await _connection.execute(
      Sql.named('''
        SELECT tenant_id, entity_type, entity_id, reason,
               set_by_actor_id, set_at, released_at, released_by_actor_id
        FROM legal_holds
        WHERE tenant_id = @tenantId
          AND entity_type = @entityType
          AND entity_id = @entityId
        ORDER BY set_at DESC
      '''),
      parameters: {
        'tenantId': tenantId,
        'entityType': entityType,
        'entityId': entityId,
      },
    );
    return rows.map(_rowToLegalHold).toList(growable: false);
  }

  LegalHold _rowToLegalHold(ResultRow row) {
    final releasedRaw = row[6];
    final releasedByRaw = row[7];
    return LegalHold(
      tenantId: row[0] as String,
      entityType: row[1] as String,
      entityId: row[2] as String,
      reason: row[3] as String,
      setByActorId: row[4] as String,
      setAt: (row[5] as DateTime).toUtc(),
      releasedAt:
          releasedRaw == null ? null : (releasedRaw as DateTime).toUtc(),
      releasedByActorId: releasedByRaw as String?,
    );
  }

  /// Test-only raw connection handle for RLS + tampering-detection
  /// tests. Production code MUST NOT use this.
  Connection get debugRawConnection => _connection;

  /// Test-only: switch the effective session role. The RLS test suite
  /// uses this to drop from the `postgres` superuser (BYPASSRLS) to
  /// `aduanext_app` so the policies are actually enforced.
  ///
  /// Pass `null` to RESET (restore the original role).
  Future<void> debugSetSessionRole(String? roleName) async {
    if (roleName == null) {
      await _connection.execute('RESET ROLE');
    } else {
      await _connection.execute('SET ROLE $roleName');
    }
  }

  /// Delete all rows. Test-only helper to reset state between tests
  /// without re-running migrations.
  Future<void> debugTruncateForTesting() async {
    await _connection.execute('TRUNCATE TABLE legal_holds');
  }
}

int _counter = 0;

/// Default ID generator — monotonic + reasonably unique without
/// pulling in `uuid`. Format: `lh_{microsEpoch}_{counter}`.
String _defaultIdGenerator() {
  _counter++;
  return 'lh_${DateTime.now().toUtc().microsecondsSinceEpoch}_$_counter';
}
