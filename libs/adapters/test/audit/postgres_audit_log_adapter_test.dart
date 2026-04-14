/// PostgreSQL audit adapter integration tests.
///
/// REQUIREMENT: The `postgres_test` container from the root
/// `docker-compose.yaml` must be running. From repo root:
///
///     make db-up
///
/// The test connects to `localhost:9190` (the `postgres_test` port), DB
/// `aduanext_test`, user `postgres`. The password is read from env var
/// `POSTGRES_TEST_PASSWORD` (also read from `.env` by `make db-up`). If
/// that env var is absent or the container is unreachable, the test group
/// is skipped with a clear message — CI must provide the container as a
/// service and set the env var.
///
/// Every test recreates the schema from scratch (TRUNCATE + ensureSchema)
/// so ordering across tests is irrelevant.
library;

import 'dart:io' show Platform;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  final password = Platform.environment['POSTGRES_TEST_PASSWORD'];
  final host = Platform.environment['POSTGRES_TEST_HOST'] ?? 'localhost';
  final port =
      int.tryParse(Platform.environment['POSTGRES_TEST_PORT'] ?? '') ?? 9190;
  final db = Platform.environment['POSTGRES_TEST_DB'] ?? 'aduanext_test';
  final user = Platform.environment['POSTGRES_TEST_USER'] ?? 'postgres';

  final skipReason = password == null || password.isEmpty
      ? 'POSTGRES_TEST_PASSWORD not set — run `make db-up` and export .env'
      : null;

  group('PostgresAuditLogAdapter', () {
    late PostgresAuditLogAdapter adapter;

    setUp(() async {
      adapter = await PostgresAuditLogAdapter.openForTesting(
        host: host,
        port: port,
        database: db,
        username: user,
        password: password ?? '',
        now: () => DateTime.utc(2026, 4, 13, 10, 0, 0),
      );
      await adapter.debugTruncateForTesting();
    });

    tearDown(() async {
      await adapter.close();
    });

    AuditEvent draft({
      String entityType = 'Declaration',
      String entityId = 'DUA-001',
      String action = 'created',
      Map<String, dynamic>? payload,
      AuditPayloadType payloadType = AuditPayloadType.snapshot,
    }) {
      return AuditEvent.draft(
        entityType: entityType,
        entityId: entityId,
        action: action,
        actorId: 'user-42',
        tenantId: 'tenant-1',
        payload: payload ?? {'status': 'draft'},
        clientTimestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
        payloadType: payloadType,
      );
    }

    test('persists events with sequential sequence numbers', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events.map((e) => e.sequenceNumber), [0, 1, 2]);
      expect(events.map((e) => e.action),
          ['created', 'classified', 'signed']);
      expect(events.every((e) => e.serverTimestamp != null), isTrue);
    });

    test('preserves hash chain across rows', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events[1].previousHash, equals(events[0].eventHash));
    });

    test('first event uses genesis hash', () async {
      await adapter.append(draft());
      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      const hasher = AuditChainHasher();
      expect(
        events.single.previousHash,
        equals(hasher.genesisHash(
          entityType: 'Declaration',
          entityId: 'DUA-001',
        )),
      );
    });

    test('round-trips snapshot and delta payload types', () async {
      await adapter.append(draft(
        action: 'created',
        payload: {
          'items': [
            {'hs': '8543.70.99', 'qty': 10},
          ],
        },
        payloadType: AuditPayloadType.snapshot,
      ));
      await adapter.append(draft(
        action: 'classified',
        payload: {'hsUpdated': true},
        payloadType: AuditPayloadType.delta,
      ));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events[0].payloadType, AuditPayloadType.snapshot);
      expect(events[1].payloadType, AuditPayloadType.delta);
      expect(events[0].payload['items'], isA<List>());
      expect(events[1].payload['hsUpdated'], isTrue);
    });

    test('separates chains per entity', () async {
      await adapter.append(draft(entityId: 'DUA-001'));
      await adapter.append(draft(entityId: 'DUA-002'));
      await adapter.append(draft(entityId: 'DUA-001', action: 'classified'));

      final a = await adapter.queryByEntity('Declaration', 'DUA-001');
      final b = await adapter.queryByEntity('Declaration', 'DUA-002');
      expect(a, hasLength(2));
      expect(b, hasLength(1));
    });

    test('rejects out-of-order explicit sequenceNumber', () async {
      await adapter.append(draft(action: 'created'));
      final bad = AuditEvent(
        entityType: 'Declaration',
        entityId: 'DUA-001',
        action: 'bad',
        actorId: 'user-42',
        tenantId: 'tenant-1',
        payload: const {},
        timestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
        clientTimestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
        sequenceNumber: 7,
        previousHash: 'x' * 64,
        eventHash: '',
        payloadType: AuditPayloadType.snapshot,
      );
      await expectLater(
        adapter.append(bad),
        throwsA(isA<AuditChainSequenceError>()),
      );
    });

    test('verifyChainIntegrity returns true for fresh data', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isTrue,
      );
    });

    test('verifyChainIntegrity returns true for empty entity', () async {
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'missing'),
        isTrue,
      );
    });

    test('detects a tampered payload written directly to the DB', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));

      // Simulate an attacker mutating a row behind our back.
      await adapter.debugRawConnection.execute(
        Sql.named('''
          UPDATE audit_events
          SET payload = '{"status":"forged"}'::jsonb
          WHERE entity_type = @entityType
            AND entity_id = @entityId
            AND sequence_number = @seq
        '''),
        parameters: {
          'entityType': 'Declaration',
          'entityId': 'DUA-001',
          'seq': 1,
        },
      );

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('detects a deleted event in the DB', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));

      await adapter.debugRawConnection.execute(
        Sql.named('''
          DELETE FROM audit_events
          WHERE entity_type = @entityType
            AND entity_id = @entityId
            AND sequence_number = @seq
        '''),
        parameters: {
          'entityType': 'Declaration',
          'entityId': 'DUA-001',
          'seq': 1,
        },
      );

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('DB UNIQUE constraint rejects duplicate (entity, seq)', () async {
      await adapter.append(draft(action: 'created'));
      Object? caught;
      try {
        await adapter.debugRawConnection.execute(
          Sql.named('''
            INSERT INTO audit_events (
              entity_type, entity_id, sequence_number, action,
              actor_id, tenant_id, payload, payload_type,
              client_timestamp, server_timestamp,
              previous_hash, event_hash
            ) VALUES (
              'Declaration', 'DUA-001', 0, 'duplicate',
              'user-42', 'tenant-1', '{}'::jsonb, 'snapshot',
              @clientTs, NULL,
              @prev, @hash
            )
          '''),
          parameters: {
            'clientTs': DateTime.utc(2026, 4, 13, 10, 0, 0),
            'prev': 'x' * 64,
            'hash': 'y' * 64,
          },
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull,
          reason: 'DB UNIQUE constraint should reject duplicate sequence');
    });

    test('ensureSchema is idempotent', () async {
      // Second invocation should not throw.
      await adapter.ensureSchema();
      await adapter.ensureSchema();
      // And the table should still work.
      await adapter.append(draft(action: 'created'));
      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events, hasLength(1));
    });

    test('serializes concurrent appends (25 in parallel)', () async {
      final futures = <Future<void>>[];
      for (var i = 0; i < 25; i++) {
        futures.add(adapter.append(draft(
          action: 'mutation-$i',
          payload: {'step': i},
          payloadType: AuditPayloadType.delta,
        )));
      }
      await Future.wait(futures);

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events, hasLength(25));
      expect(
        events.map((e) => e.sequenceNumber).toList(),
        List<int>.generate(25, (i) => i),
        reason: 'Sequence numbers must be dense 0..24 with no gaps',
      );
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isTrue,
      );
    });
  }, skip: skipReason);
}
