/// Wiring tests for the retention subsystem (VRTV-74).
///
/// These tests exercise the configuration + policy composition layer
/// that lets `AppContainer` decide whether to start a
/// `RetentionWorker`. We deliberately do NOT boot the full container
/// here — that needs a live sidecar + Postgres, which CI provides only
/// for the integration suite. Instead:
///
///   * `RetentionConfig.fromEnv` reads the env vars and builds a
///     `Map<RetentionCategory, RetentionPolicy>` with legal-floor
///     enforcement.
///   * `RetentionWorker` is instantiated against an in-memory
///     handler + fake purgeable + in-memory legal hold, then
///     `runNow()` is driven and asserted to archive, purge, and
///     write a tombstone — proving the chain-integrity contract
///     that the Postgres audit retention adapter will need to honour
///     end-to-end.
library;

import 'dart:typed_data';

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_adapters/retention.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_server/aduanext_server.dart';
import 'package:test/test.dart';

void main() {
  group('RetentionConfig.fromEnv', () {
    test('disabled by default', () {
      final c = RetentionConfig.fromEnv(const <String, String>{});
      expect(c.enabled, isFalse);
      expect(c.auditWindow.inDays, 365 * 7);
      expect(c.duaWindow.inDays, 365 * 7);
      expect(c.sessionWindow.inDays, 90);
      expect(c.runAtHourUtc, 3);
      expect(c.runAtMinuteUtc, 0);
      expect(c.archivePath, '/var/aduanext/archive');
    });

    test('env overrides apply', () {
      final c = RetentionConfig.fromEnv(const {
        'ADUANEXT_RETENTION_ENABLED': 'true',
        'ADUANEXT_RETENTION_AUDIT_YEARS': '10',
        'ADUANEXT_RETENTION_DUA_YEARS': '8',
        'ADUANEXT_RETENTION_SESSION_DAYS': '30',
        'ADUANEXT_RETENTION_RUN_AT_UTC': '04:15',
        'ADUANEXT_ARCHIVE_PATH': '/tmp/aduanext/archive',
      });
      expect(c.enabled, isTrue);
      expect(c.auditWindow.inDays, 365 * 10);
      expect(c.duaWindow.inDays, 365 * 8);
      expect(c.sessionWindow.inDays, 30);
      expect(c.runAtHourUtc, 4);
      expect(c.runAtMinuteUtc, 15);
      expect(c.archivePath, '/tmp/aduanext/archive');
    });

    test('rejects audit window below LGA Art. 30.b legal floor', () {
      expect(
        () => RetentionConfig.fromEnv(const {
          'ADUANEXT_RETENTION_ENABLED': 'true',
          'ADUANEXT_RETENTION_AUDIT_YEARS': '3',
        }),
        throwsArgumentError,
      );
    });

    test('rejects DUA window below LGA Art. 30.b legal floor', () {
      expect(
        () => RetentionConfig.fromEnv(const {
          'ADUANEXT_RETENTION_ENABLED': 'true',
          'ADUANEXT_RETENTION_DUA_YEARS': '2',
        }),
        throwsArgumentError,
      );
    });

    test('rejects malformed RUN_AT_UTC', () {
      expect(
        () => RetentionConfig.fromEnv(const {
          'ADUANEXT_RETENTION_RUN_AT_UTC': 'noon',
        }),
        throwsFormatException,
      );
      expect(
        () => RetentionConfig.fromEnv(const {
          'ADUANEXT_RETENTION_RUN_AT_UTC': '25:00',
        }),
        throwsFormatException,
      );
    });

    test('asPolicies composes windows over defaults with legal floors',
        () {
      final c = RetentionConfig.fromEnv(const {
        'ADUANEXT_RETENTION_ENABLED': 'true',
        'ADUANEXT_RETENTION_AUDIT_YEARS': '9',
      });
      final policies = c.asPolicies();
      final audit = policies[RetentionCategory.auditEvent]!;
      expect(audit.window.inDays, 365 * 9);
      expect(audit.legalMinimum.inDays, 365 * 5);
      // Categories not overridden keep the platform default.
      final classification =
          policies[RetentionCategory.classificationDecision]!;
      expect(classification.window, classification.platformDefault);
    });
  });

  group('RetentionWorker.runNow end-to-end with wired ports', () {
    test(
      'archive → purge → tombstone sequence produces the expected '
      'report AND keeps the audit chain re-verifiable',
      () async {
        // Use the in-memory audit log as the tombstone sink — we want
        // to assert chain integrity on it after the run.
        final audit = InMemoryAuditLogAdapter();
        final legalHolds = InMemoryLegalHoldAdapter();

        // Fake purgeable that publishes a single chain to archive /
        // purge, and records a tombstone via the injected audit log.
        final purgeable = _FakeChainPurgeable(audit: audit);
        purgeable.chains['Declaration:DUA-OLD'] = [
          _ChainEvent(seq: 0, action: 'created'),
          _ChainEvent(seq: 1, action: 'classified'),
          _ChainEvent(seq: 2, action: 'signed'),
        ];

        final archive = _InMemoryArchive();

        final handler = PurgeExpiredRecordsHandler(
          purgeables: [purgeable],
          legalHold: legalHolds,
          archive: archive,
        );
        final worker = RetentionWorker(
          handler: handler,
          now: () => DateTime.utc(2034, 1, 2, 3, 4, 5),
        );

        final report = await worker.runNow();

        expect(report.totalArchived, 1);
        expect(report.totalPurged, 1);
        expect(report.totalHeld, 0);

        // Archive was written under the expected path.
        expect(archive.writes, hasLength(1));
        expect(
          archive.writes.single.path,
          contains('auditEvent/t1/'),
        );
        expect(archive.writes.single.metadata['entity_type'],
            'Declaration');

        // The chain was DELETEd (fake purgeable simulates this).
        expect(purgeable.chains['Declaration:DUA-OLD'], isEmpty);

        // Tombstone event landed on the same chain — at seq=0
        // starting a fresh chain. Integrity verifies.
        final events =
            await audit.queryByEntity('Declaration', 'DUA-OLD');
        expect(events, hasLength(1));
        expect(events.single.action, 'RetentionPurge');
        expect(events.single.sequenceNumber, 0);
        expect(events.single.payload['archivedCount'], 3);
        expect(
          await audit.verifyChainIntegrity('Declaration', 'DUA-OLD'),
          isTrue,
        );
      },
    );

    test('legal-hold skips the purge and reports the entity as held',
        () async {
      final audit = InMemoryAuditLogAdapter();
      final legalHolds = InMemoryLegalHoldAdapter();
      await legalHolds.place(LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'DUA-OLD',
        reason: 'DGA case 2034-0001',
        setByActorId: 'admin-7',
        setAt: DateTime.utc(2033, 12, 1),
      ));
      final purgeable = _FakeChainPurgeable(audit: audit);
      purgeable.chains['Declaration:DUA-OLD'] = [
        _ChainEvent(seq: 0, action: 'created'),
      ];
      final archive = _InMemoryArchive();
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [purgeable],
        legalHold: legalHolds,
        archive: archive,
      );
      final worker = RetentionWorker(
        handler: handler,
        now: () => DateTime.utc(2034, 1, 2),
      );

      final report = await worker.runNow();
      expect(report.totalPurged, 0);
      expect(report.totalHeld, 1);
      // The chain is untouched.
      expect(purgeable.chains['Declaration:DUA-OLD'], hasLength(1));
      // No tombstone written.
      expect(
        await audit.queryByEntity('Declaration', 'DUA-OLD'),
        isEmpty,
      );
    });
  });
}

// ── Helpers ────────────────────────────────────────────────────────

/// In-memory [RetentionPurgeablePort] over a `chains` map keyed by
/// `entityType:entityId`. Mirrors the shape of the Postgres audit
/// retention adapter so the worker-level semantics can be asserted
/// without a real database.
class _FakeChainPurgeable implements RetentionPurgeablePort {
  final AuditLogPort audit;
  final Map<String, List<_ChainEvent>> chains = {};
  final Map<String, int> _archivedCountCache = {};

  _FakeChainPurgeable({required this.audit});

  @override
  RetentionCategory get category => RetentionCategory.auditEvent;

  @override
  Future<List<ExpiredRecord>> findExpired({
    required DateTime cutoff,
    int batchSize = 100,
  }) async {
    return chains.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) {
          final parts = e.key.split(':');
          return ExpiredRecord(
            tenantId: 't1',
            entityType: parts[0],
            entityId: parts[1],
            createdAt: DateTime.utc(2020, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          );
        })
        .take(batchSize)
        .toList();
  }

  @override
  Future<List<int>> serializeForArchive({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    final key = '$entityType:$entityId';
    return (chains[key] ?? const [])
        .map((e) => e.action)
        .join(',')
        .codeUnits;
  }

  @override
  Future<void> purge(ExpiredRecord record) async {
    final key = '${record.entityType}:${record.entityId}';
    _archivedCountCache[key] = chains[key]?.length ?? 0;
    chains[key] = [];
  }

  @override
  Future<void> recordTombstone(ExpiredRecord record) async {
    final key = '${record.entityType}:${record.entityId}';
    final archivedCount = _archivedCountCache.remove(key) ?? 0;
    await audit.append(AuditEvent.draft(
      entityType: record.entityType,
      entityId: record.entityId,
      action: 'RetentionPurge',
      actorId: 'system.retention_worker',
      tenantId: record.tenantId,
      payload: {
        'archivedCount': archivedCount,
        'cutoffDate':
            DateTime.utc(2034, 1, 2, 3, 4, 5).toIso8601String(),
      },
      clientTimestamp: DateTime.utc(2034, 1, 2, 3, 4, 5),
    ));
  }
}

class _ChainEvent {
  final int seq;
  final String action;
  _ChainEvent({required this.seq, required this.action});
}

class _InMemoryArchive implements StorageBackendPort {
  final List<_Write> writes = [];

  @override
  Future<void> putBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String> metadata = const {},
  }) async {
    writes.add(_Write(path: path, bytes: bytes, metadata: metadata));
  }

  @override
  Future<bool> exists(String path) async {
    return writes.any((w) => w.path == path);
  }
}

class _Write {
  final String path;
  final Uint8List bytes;
  final Map<String, String> metadata;
  _Write({
    required this.path,
    required this.bytes,
    required this.metadata,
  });
}
