import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('SqliteAuditLogAdapter', () {
    late SqliteAuditLogAdapter adapter;

    setUp(() async {
      adapter = await SqliteAuditLogAdapter.openInMemoryForTesting(
        now: () => DateTime.utc(2026, 4, 13, 10, 0, 0),
      );
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
        payload: {'items': [{'hs': '8543.70.99', 'qty': 10}]},
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

      // Simulate attacker mutating the DB row behind our back.
      await adapter.debugRawDatabase.update(
        'audit_events',
        {'payload': '{"status":"forged"}'},
        where: 'entityType = ? AND entityId = ? AND sequenceNumber = ?',
        whereArgs: ['Declaration', 'DUA-001', 1],
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

      await adapter.debugRawDatabase.delete(
        'audit_events',
        where: 'entityType = ? AND entityId = ? AND sequenceNumber = ?',
        whereArgs: ['Declaration', 'DUA-001', 1],
      );

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('DB UNIQUE index enforces one row per (entity, sequenceNumber)',
        () async {
      await adapter.append(draft(action: 'created'));
      // Try to insert a duplicate row at sequenceNumber 0 by raw SQL.
      Object? caught;
      try {
        await adapter.debugRawDatabase.insert('audit_events', {
          'entityType': 'Declaration',
          'entityId': 'DUA-001',
          'sequenceNumber': 0,
          'action': 'duplicate',
          'actorId': 'user-42',
          'tenantId': 'tenant-1',
          'payload': '{}',
          'payloadType': 'snapshot',
          'clientTimestamp':
              DateTime.utc(2026, 4, 13, 10, 0, 0).toIso8601String(),
          'serverTimestamp': null,
          'previousHash': 'x' * 64,
          'eventHash': 'y' * 64,
        });
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull,
          reason: 'DB-level uniqueness should reject duplicate sequence');
    });

    test('serializes concurrent appends', () async {
      final futures = <Future<void>>[];
      for (var i = 0; i < 15; i++) {
        futures.add(adapter.append(draft(
          action: 'mutation-$i',
          payload: {'step': i},
          payloadType: AuditPayloadType.delta,
        )));
      }
      await Future.wait(futures);

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events, hasLength(15));
      expect(
        events.map((e) => e.sequenceNumber).toList(),
        List<int>.generate(15, (i) => i),
      );
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isTrue,
      );
    });
  });
}
