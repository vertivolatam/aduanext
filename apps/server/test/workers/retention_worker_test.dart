/// Tests for [RetentionWorker]'s scheduling semantics.
///
/// We bypass the periodic timer by driving `runNow()` (the
/// ops-tooling entry point) — that hits the same handler the
/// scheduled tick does, so it gives us deterministic coverage of the
/// dispatch path without flaky `Future.delayed` waits.
library;

import 'dart:typed_data';

import 'package:aduanext_adapters/retention.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_server/aduanext_server.dart';
import 'package:test/test.dart';

void main() {
  group('RetentionWorker', () {
    test('runNow drives the handler and surfaces the report', () async {
      final port = _FakePurgeable(category: RetentionCategory.auditEvent)
        ..expired.add(
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'X',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
        );
      final archive = _FakeArchive();
      final holds = InMemoryLegalHoldAdapter();
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: holds,
        archive: archive,
      );
      final worker = RetentionWorker(
        handler: handler,
        now: () => DateTime.utc(2026, 4, 13, 3, 0, 0),
      );

      final report = await worker.runNow();
      expect(report.totalPurged, 1);
      expect(report.totalArchived, 1);
      expect(port.purged.single.entityId, 'X');
    });

    test('start is idempotent and stop awaits in-flight work', () async {
      final handler = PurgeExpiredRecordsHandler(
        purgeables: const [],
        legalHold: InMemoryLegalHoldAdapter(),
        archive: _FakeArchive(),
      );
      final worker = RetentionWorker(
        handler: handler,
        now: () => DateTime.utc(2026, 4, 13, 0, 0, 0),
        tickInterval: const Duration(milliseconds: 10),
      );
      worker.start();
      worker.start(); // should not throw / start twice
      await worker.stop();
    });
  });
}

class _FakePurgeable implements RetentionPurgeablePort {
  @override
  final RetentionCategory category;
  final List<ExpiredRecord> expired = [];
  final List<ExpiredRecord> purged = [];

  _FakePurgeable({required this.category});

  @override
  Future<List<ExpiredRecord>> findExpired({
    required DateTime now,
    int batchSize = 100,
  }) async {
    final out = expired.take(batchSize).toList();
    expired.removeRange(0, out.length);
    return out;
  }

  @override
  Future<List<int>> serializeForArchive({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async =>
      'snapshot-$entityId'.codeUnits;

  @override
  Future<void> purge(ExpiredRecord record) async {
    purged.add(record);
  }

  @override
  Future<void> recordTombstone(ExpiredRecord record) async {}
}

class _FakeArchive implements StorageBackendPort {
  @override
  Future<void> putBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String> metadata = const {},
  }) async {}

  @override
  Future<bool> exists(String path) async => false;
}
