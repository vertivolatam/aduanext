import 'dart:async';

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryAuditLogAdapter', () {
    late InMemoryAuditLogAdapter adapter;

    setUp(() {
      adapter = InMemoryAuditLogAdapter(
        now: () => DateTime.utc(2026, 4, 13, 10, 0, 0),
      );
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

    test('appends events in order and assigns sequence numbers', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(
        action: 'classified',
        payload: {'hsCode': '8543.70.99'},
        payloadType: AuditPayloadType.delta,
      ));
      await adapter.append(draft(
        action: 'signed',
        payload: {'signatureId': 'sig-1'},
        payloadType: AuditPayloadType.delta,
      ));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events.map((e) => e.sequenceNumber), [0, 1, 2]);
      expect(events.map((e) => e.action),
          ['created', 'classified', 'signed']);
      expect(events.every((e) => e.eventHash.length == 64), isTrue);
      expect(events.every((e) => e.serverTimestamp != null), isTrue);
    });

    test('each event points to the previous one (hash chain)', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(events[1].previousHash, equals(events[0].eventHash));
      expect(events[2].previousHash, equals(events[1].eventHash));
    });

    test('first event points to a deterministic genesis hash', () async {
      await adapter.append(draft());
      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      const hasher = AuditChainHasher();
      expect(
        events.first.previousHash,
        equals(hasher.genesisHash(
          entityType: 'Declaration',
          entityId: 'DUA-001',
        )),
      );
    });

    test('chains for different entities are independent', () async {
      await adapter.append(draft(entityId: 'DUA-001'));
      await adapter.append(draft(entityId: 'DUA-002'));
      await adapter.append(draft(entityId: 'DUA-001', action: 'classified'));

      final a = await adapter.queryByEntity('Declaration', 'DUA-001');
      final b = await adapter.queryByEntity('Declaration', 'DUA-002');
      expect(a, hasLength(2));
      expect(b, hasLength(1));
      expect(a[0].sequenceNumber, 0);
      expect(a[1].sequenceNumber, 1);
      expect(b[0].sequenceNumber, 0);
    });

    test('queryByEntity returns an empty list for unknown entity', () async {
      final events = await adapter.queryByEntity('Declaration', 'missing');
      expect(events, isEmpty);
    });

    test('queryByEntity returns an unmodifiable view', () async {
      await adapter.append(draft());
      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(() => events.add(events.first), throwsUnsupportedError);
    });

    test('rejects events with an out-of-order explicit sequenceNumber',
        () async {
      await adapter.append(draft(action: 'created'));
      // Build an event that explicitly claims sequence 5 when the next
      // expected is 1.
      final badEvent = AuditEvent(
        entityType: 'Declaration',
        entityId: 'DUA-001',
        action: 'tampered',
        actorId: 'user-42',
        tenantId: 'tenant-1',
        payload: const {},
        timestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
        clientTimestamp: DateTime.utc(2026, 4, 13, 10, 0, 0),
        sequenceNumber: 5,
        previousHash: 'x' * 64,
        eventHash: '',
        payloadType: AuditPayloadType.snapshot,
      );
      await expectLater(
        adapter.append(badEvent),
        throwsA(isA<AuditChainSequenceError>()),
      );
    });

    test('verifyChainIntegrity returns true for a freshly built chain',
        () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isTrue,
      );
    });

    test('verifyChainIntegrity returns true for an empty entity', () async {
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'nope'),
        isTrue,
      );
    });

    test('detects a modified (tampered) event', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      // Rewrite event #1 with a different payload but keep the old hash.
      final tampered = AuditEvent(
        entityType: events[1].entityType,
        entityId: events[1].entityId,
        action: events[1].action,
        actorId: events[1].actorId,
        tenantId: events[1].tenantId,
        payload: const {'hsCode': 'FRAUDULENT'},
        timestamp: events[1].timestamp,
        clientTimestamp: events[1].clientTimestamp,
        serverTimestamp: events[1].serverTimestamp,
        sequenceNumber: events[1].sequenceNumber,
        previousHash: events[1].previousHash,
        eventHash: events[1].eventHash,
        payloadType: events[1].payloadType,
      );
      adapter.debugOverwrite('Declaration', 'DUA-001', [events[0], tampered]);

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('detects a deleted event (sequence gap)', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'classified'));
      await adapter.append(draft(action: 'signed'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      // Drop event #1.
      adapter.debugOverwrite(
        'Declaration',
        'DUA-001',
        [events[0], events[2]],
      );

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('detects an inserted event', () async {
      await adapter.append(draft(action: 'created'));
      await adapter.append(draft(action: 'signed'));

      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      const hasher = AuditChainHasher();
      // Forge a new event #1 that claims event[0].eventHash as prev.
      final forged = hasher.seal(
        event: draft(action: 'forged'),
        previousHash: events[0].eventHash,
        sequenceNumber: 1,
      );
      // Insert between original [0] and [1]. Event[1] still has its old
      // sequenceNumber=1 so we expect the chain to break.
      adapter.debugOverwrite(
        'Declaration',
        'DUA-001',
        [events[0], forged, events[1]],
      );

      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isFalse,
      );
    });

    test('serializes concurrent appends into a gap-free sequence', () async {
      // Fire 25 appends "in parallel" — the adapter must internally
      // serialize them so the resulting chain has no duplicates and
      // verifyChainIntegrity stays true.
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
      );
      expect(
        await adapter.verifyChainIntegrity('Declaration', 'DUA-001'),
        isTrue,
      );
    });

    test('append returns the computed eventHash', () async {
      final returned = await adapter.append(draft(action: 'created'));
      final events = await adapter.queryByEntity('Declaration', 'DUA-001');
      expect(returned, equals(events.single.eventHash));
    });
  });
}
