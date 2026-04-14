import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AuditChainHasher', () {
    final hasher = const AuditChainHasher();

    final baseClientTs = DateTime.utc(2026, 4, 13, 10, 0, 0);

    AuditEvent draft({
      String entityType = 'Declaration',
      String entityId = 'DUA-001',
      String action = 'created',
      Map<String, dynamic>? payload,
    }) {
      return AuditEvent.draft(
        entityType: entityType,
        entityId: entityId,
        action: action,
        actorId: 'user-42',
        tenantId: 'tenant-1',
        payload: payload ?? {'status': 'draft', 'items': 3},
        clientTimestamp: baseClientTs,
      );
    }

    test('genesisHash is deterministic and scoped per entity', () {
      final a = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final aAgain = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final b = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-002',
      );
      final c = hasher.genesisHash(
        entityType: 'Classification',
        entityId: 'DUA-001',
      );

      expect(a, equals(aAgain));
      expect(a, isNot(equals(b)));
      expect(a, isNot(equals(c)));
      expect(a, hasLength(64)); // SHA-256 hex
    });

    test('seal produces a non-empty eventHash and populates chain coordinates',
        () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final sealed = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );

      expect(sealed.sequenceNumber, 0);
      expect(sealed.previousHash, prev);
      expect(sealed.eventHash, hasLength(64));
      expect(sealed.eventHash, isNot(prev));
    });

    test('seal is deterministic for the same inputs', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final a = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final b = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );
      expect(a.eventHash, equals(b.eventHash));
    });

    test('seal is insensitive to payload map key order', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final a = hasher.seal(
        event: draft(payload: {'status': 'draft', 'items': 3}),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final b = hasher.seal(
        event: draft(payload: {'items': 3, 'status': 'draft'}),
        previousHash: prev,
        sequenceNumber: 0,
      );
      expect(a.eventHash, equals(b.eventHash));
    });

    test('seal changes hash when any field changes', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final baseline = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final differentAction = hasher.seal(
        event: draft(action: 'submitted'),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final differentPayload = hasher.seal(
        event: draft(payload: {'status': 'signed', 'items': 3}),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final differentSequence = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 1,
      );
      final differentPrev = hasher.seal(
        event: draft(),
        previousHash: 'x' * 64,
        sequenceNumber: 0,
      );

      expect(differentAction.eventHash, isNot(baseline.eventHash));
      expect(differentPayload.eventHash, isNot(baseline.eventHash));
      expect(differentSequence.eventHash, isNot(baseline.eventHash));
      expect(differentPrev.eventHash, isNot(baseline.eventHash));
    });

    test('verify returns true for a freshly sealed event', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final sealed = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );
      expect(hasher.verify(sealed), isTrue);
    });

    test('verify returns false when any chain field is tampered with', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final sealed = hasher.seal(
        event: draft(),
        previousHash: prev,
        sequenceNumber: 0,
      );

      final tamperedPayload = sealed.copyWithChain(
        sequenceNumber: sealed.sequenceNumber,
        previousHash: sealed.previousHash,
        eventHash: sealed.eventHash,
      );
      // Build a new event via constructor with mutated payload so the
      // stored eventHash no longer matches.
      final mutated = AuditEvent(
        entityType: tamperedPayload.entityType,
        entityId: tamperedPayload.entityId,
        action: tamperedPayload.action,
        actorId: tamperedPayload.actorId,
        tenantId: tamperedPayload.tenantId,
        payload: {'status': 'signed', 'items': 3}, // changed
        timestamp: tamperedPayload.timestamp,
        clientTimestamp: tamperedPayload.clientTimestamp,
        serverTimestamp: tamperedPayload.serverTimestamp,
        sequenceNumber: tamperedPayload.sequenceNumber,
        previousHash: tamperedPayload.previousHash,
        eventHash: tamperedPayload.eventHash, // stale
        payloadType: tamperedPayload.payloadType,
      );

      expect(hasher.verify(mutated), isFalse);
    });

    test('canonical JSON sorts keys at every depth', () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final a = hasher.seal(
        event: draft(payload: {
          'b': {
            'z': 1,
            'a': 2,
          },
          'a': [
            {'y': 1, 'x': 2},
            {'m': 3, 'n': 4},
          ],
        }),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final b = hasher.seal(
        event: draft(payload: {
          'a': [
            {'x': 2, 'y': 1},
            {'n': 4, 'm': 3},
          ],
          'b': {
            'a': 2,
            'z': 1,
          },
        }),
        previousHash: prev,
        sequenceNumber: 0,
      );
      expect(a.eventHash, equals(b.eventHash));
    });

    test('list order inside payload is preserved (semantically meaningful)',
        () {
      final prev = hasher.genesisHash(
        entityType: 'Declaration',
        entityId: 'DUA-001',
      );
      final ascending = hasher.seal(
        event: draft(payload: {'items': [1, 2, 3]}),
        previousHash: prev,
        sequenceNumber: 0,
      );
      final descending = hasher.seal(
        event: draft(payload: {'items': [3, 2, 1]}),
        previousHash: prev,
        sequenceNumber: 0,
      );
      expect(ascending.eventHash, isNot(descending.eventHash));
    });
  });
}
