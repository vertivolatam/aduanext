/// Tests for [RecordClassificationHandler].
///
/// Uses [InMemoryAuditLogAdapter] from `aduanext_adapters` (dev dep)
/// to exercise the Port contract end-to-end without pulling heavy
/// infrastructure. A `_FailingAuditLogAdapter` helper simulates the
/// audit-append-failure path.
library;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('RecordClassificationHandler', () {
    late InMemoryAuditLogAdapter auditLog;
    late RecordClassificationHandler handler;

    final fixedNow = DateTime.utc(2026, 4, 14, 10, 0, 0);

    setUp(() {
      auditLog = InMemoryAuditLogAdapter();
      var counter = 0;
      handler = RecordClassificationHandler(
        auditLog: auditLog,
        newId: () => 'fixed-id-${counter++}',
        clock: () => fixedNow,
      );
    });

    RecordClassificationCommand validCommand({
      String agentId = 'agent-42',
      String tenantId = 'tenant-1',
      String hsCode = '090111',
      String description = 'Green coffee, Arabica, not roasted',
      bool confirmed = true,
      Map<String, dynamic>? metadata,
    }) {
      return RecordClassificationCommand(
        agentId: agentId,
        tenantId: tenantId,
        hsCode: hsCode,
        commercialDescription: description,
        confirmed: confirmed,
        metadata: metadata ?? const {},
      );
    }

    test('happy path returns Ok with a populated decision', () async {
      final result = await handler.handle(validCommand());

      expect(result.isOk, isTrue);
      final decision = result.valueOrNull!;
      expect(decision.id, 'fixed-id-0');
      expect(decision.agentId, 'agent-42');
      expect(decision.tenantId, 'tenant-1');
      expect(decision.hsCode.code, '090111');
      expect(decision.commercialDescription,
          'Green coffee, Arabica, not roasted');
      expect(decision.confirmed, isTrue);
      expect(decision.confirmedAt, fixedNow);
      expect(decision.recordedAt, fixedNow);
    });

    test('happy path logs an audit event with snapshot payload',
        () async {
      await handler.handle(validCommand(metadata: {
        'aiConfidence': 0.93,
        'ragDocs': ['rimm-0901-chapter.md'],
      }));

      final events =
          await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0');
      expect(events, hasLength(1));
      final event = events.single;
      expect(event.action, 'classification.recorded.confirmed');
      expect(event.actorId, 'agent-42');
      expect(event.tenantId, 'tenant-1');
      expect(event.payloadType, AuditPayloadType.snapshot);
      expect(event.payload['hsCode'], '090111');
      expect(event.payload['metadata']['aiConfidence'], 0.93);
      expect(event.payload['metadata']['ragDocs'], ['rimm-0901-chapter.md']);
      expect(event.sequenceNumber, 0);
      // Hash chain is populated by the adapter.
      expect(event.eventHash, isNotEmpty);
      expect(event.previousHash, isNotEmpty);
    });

    test('unconfirmed commands are logged with the pending action',
        () async {
      final result = await handler.handle(validCommand(confirmed: false));
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.confirmed, isFalse);
      expect(result.valueOrNull!.confirmedAt, isNull);

      final events =
          await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0');
      expect(events.single.action, 'classification.recorded.pending');
    });

    test('audit snapshot scrubs keys prefixed with _secret_', () async {
      await handler.handle(validCommand(metadata: {
        '_secret_token': 'super-sensitive',
        'visible': 'ok',
      }));
      final events =
          await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0');
      final meta = events.single.payload['metadata'] as Map;
      expect(meta.containsKey('_secret_token'), isFalse);
      expect(meta['visible'], 'ok');
    });

    // ── Validation failures ────────────────────────────────────────

    test('rejects empty agentId', () async {
      final result = await handler.handle(validCommand(agentId: ''));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<MissingActorFailure>());
      expect((result.failureOrNull as MissingActorFailure).fieldName,
          'agentId');
      // No audit event should have been written.
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects empty tenantId', () async {
      final result = await handler.handle(validCommand(tenantId: ''));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<MissingActorFailure>());
      expect((result.failureOrNull as MissingActorFailure).fieldName,
          'tenantId');
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects HS code shorter than 6 digits', () async {
      final result = await handler.handle(validCommand(hsCode: '12345'));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<InvalidHsCodeFailure>());
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects HS code longer than 12 digits', () async {
      final result =
          await handler.handle(validCommand(hsCode: '1234567890123'));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<InvalidHsCodeFailure>());
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects HS code with non-digits', () async {
      final result =
          await handler.handle(validCommand(hsCode: '0901.11'));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<InvalidHsCodeFailure>());
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects description shorter than 5 chars', () async {
      final result =
          await handler.handle(validCommand(description: 'oil'));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<InvalidDescriptionFailure>());
      expect(
        await auditLog.queryByEntity('ClassificationDecision', 'fixed-id-0'),
        isEmpty,
      );
    });

    test('rejects description that is whitespace-only', () async {
      final result =
          await handler.handle(validCommand(description: '        '));
      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<InvalidDescriptionFailure>());
    });

    // ── Infrastructure failure propagation ─────────────────────────

    test('propagates audit-append exceptions (does not swallow)',
        () async {
      final failing = RecordClassificationHandler(
        auditLog: _FailingAuditLogAdapter(
          StateError('simulated DB down'),
        ),
        newId: () => 'fail-id',
        clock: () => fixedNow,
      );
      await expectLater(
        failing.handle(validCommand()),
        throwsA(isA<StateError>()),
      );
    });

    // ── Deterministic id + clock behaviour ─────────────────────────

    test('consecutive handles get successive ids from the generator',
        () async {
      final a = await handler.handle(validCommand(
        hsCode: '090111',
        description: 'Green coffee, Arabica, not roasted',
      ));
      final b = await handler.handle(validCommand(
        hsCode: '090112',
        description: 'Green coffee, decaffeinated',
      ));
      expect(a.valueOrNull!.id, 'fixed-id-0');
      expect(b.valueOrNull!.id, 'fixed-id-1');
      // The audit log holds two separate per-entity chains.
      expect(
        (await auditLog.queryByEntity(
                'ClassificationDecision', 'fixed-id-0'))
            .length,
        1,
      );
      expect(
        (await auditLog.queryByEntity(
                'ClassificationDecision', 'fixed-id-1'))
            .length,
        1,
      );
    });
  });
}

/// Test double: an [AuditLogPort] that always throws on append.
/// Used to verify the handler does not swallow infrastructure failures.
class _FailingAuditLogAdapter implements AuditLogPort {
  final Object error;
  _FailingAuditLogAdapter(this.error);

  @override
  Future<String> append(AuditEvent event) async => throw error;

  @override
  Future<List<AuditEvent>> queryByEntity(
          String entityType, String entityId) async =>
      const [];

  @override
  Future<bool> verifyChainIntegrity(
          String entityType, String entityId) async =>
      true;
}
