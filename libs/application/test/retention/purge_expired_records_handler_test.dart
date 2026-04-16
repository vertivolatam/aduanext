/// Unit tests for [PurgeExpiredRecordsHandler].
///
/// Drives every branch of the handler: legal-hold skip, archive +
/// purge + tombstone happy path, partial failure (one bad record does
/// NOT abort the whole run), per-category stats accuracy.
library;

import 'dart:typed_data';

import 'package:aduanext_adapters/retention.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PurgeExpiredRecordsHandler', () {
    final now = DateTime.utc(2026, 4, 13, 3, 0, 0);

    test('archives, purges, and records tombstones for expired records',
        () async {
      final port = _FakePurgeable(category: RetentionCategory.auditEvent)
        ..expired.addAll([
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'A-1',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'A-2',
            createdAt: DateTime.utc(2019, 6, 1),
            expiresAt: DateTime.utc(2026, 1, 1),
          ),
        ]);
      final archive = _FakeArchive();
      final holds = InMemoryLegalHoldAdapter();

      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: holds,
        archive: archive,
      );

      final result = await handler.handle(
        PurgeExpiredRecordsCommand(now: now),
      );
      expect(result.isOk, isTrue);
      final report = (result as Ok<PurgeReport>).value;
      final stats = report.byCategory['auditEvent']!;
      expect(stats.candidates, 2);
      expect(stats.archived, 2);
      expect(stats.purged, 2);
      expect(stats.heldByLegal, 0);
      expect(stats.errors, 0);
      expect(port.purged.map((r) => r.entityId), ['A-1', 'A-2']);
      expect(port.tombstones.length, 2);
      expect(archive.writes.length, 2);
      // Path layout matches the contract used by FilesystemArchiveAdapter.
      expect(
        archive.writes.first.path,
        'auditEvent/t1/2018/Declaration/A-1.json',
      );
    });

    test('skips records under an active legal hold', () async {
      final port = _FakePurgeable(category: RetentionCategory.auditEvent)
        ..expired.addAll([
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'HELD',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'FREE',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
        ]);
      final archive = _FakeArchive();
      final holds = InMemoryLegalHoldAdapter();
      await holds.place(LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'HELD',
        reason: 'DGA fiscalizacion 2026-0042',
        setByActorId: 'admin',
        setAt: DateTime.utc(2026, 3, 1),
      ));

      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: holds,
        archive: archive,
      );

      final result = await handler.handle(
        PurgeExpiredRecordsCommand(now: now),
      );
      final stats = (result as Ok<PurgeReport>)
          .value
          .byCategory['auditEvent']!;
      expect(stats.heldByLegal, 1);
      expect(stats.purged, 1);
      expect(port.purged.single.entityId, 'FREE');
      expect(archive.writes.single.path, contains('FREE'));
    });

    test('one bad record does NOT abort the whole run', () async {
      final port = _FakePurgeable(category: RetentionCategory.auditEvent)
        ..expired.addAll([
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'BOMB',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
          ExpiredRecord(
            tenantId: 't1',
            entityType: 'Declaration',
            entityId: 'GOOD',
            createdAt: DateTime.utc(2018, 1, 1),
            expiresAt: DateTime.utc(2025, 1, 1),
          ),
        ])
        ..failOn.add('BOMB');
      final archive = _FakeArchive();
      final holds = InMemoryLegalHoldAdapter();

      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: holds,
        archive: archive,
      );

      final result = await handler.handle(
        PurgeExpiredRecordsCommand(now: now),
      );
      final stats = (result as Ok<PurgeReport>)
          .value
          .byCategory['auditEvent']!;
      expect(stats.errors, 1);
      expect(stats.purged, 1);
      expect(port.purged.single.entityId, 'GOOD');
    });

    test('legal hold released before run → record is purged', () async {
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
      await holds.place(LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'X',
        reason: 'old hold',
        setByActorId: 'admin',
        setAt: DateTime.utc(2025, 1, 1),
      ));
      await holds.release(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'X',
        releasedByActorId: 'admin',
        releasedAt: DateTime.utc(2025, 6, 1),
      );

      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: holds,
        archive: archive,
      );

      final result = await handler.handle(
        PurgeExpiredRecordsCommand(now: now),
      );
      final stats = (result as Ok<PurgeReport>)
          .value
          .byCategory['auditEvent']!;
      expect(stats.purged, 1);
    });

    // ── VRTV-76: cutoff plumbing ──────────────────────────────
    //
    // Prior to VRTV-76 the Postgres audit adapter embedded the
    // default policy window (7 years) as the cutoff, ignoring the
    // handler's effective policy. These tests pin the new contract:
    // the handler computes `cutoff = now - policy.window` and
    // passes it to the adapter via the port's `findExpired`
    // parameter.

    test('passes policy-derived cutoff to the adapter (7-year default)',
        () async {
      final port =
          _FakePurgeable(category: RetentionCategory.auditEvent);
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: InMemoryLegalHoldAdapter(),
        archive: _FakeArchive(),
      );

      await handler.handle(PurgeExpiredRecordsCommand(now: now));

      // 7-year default window (see DefaultRetentionPolicies.auditEvent).
      final expected = now
          .subtract(DefaultRetentionPolicies.auditEvent.window)
          .toUtc();
      expect(port.lastCutoff, isNotNull);
      expect(port.lastCutoff!.toUtc(), expected);
    });

    test('honours an extended 10-year tenant override for cutoff',
        () async {
      // This is the exact bug VRTV-76 was filed for: an operator sets
      // `ADUANEXT_RETENTION_AUDIT_YEARS=10`, expects 10 years of
      // retention, but before this fix the adapter still used 7 years
      // because it re-derived the cutoff from the const default.
      final tenYearWindow = const Duration(days: 365 * 10);
      final extendedPolicy = DefaultRetentionPolicies.auditEvent
          .withTenantOverride(tenYearWindow);
      final policies = <RetentionCategory, RetentionPolicy>{
        ...DefaultRetentionPolicies.all,
        RetentionCategory.auditEvent: extendedPolicy,
      };
      final port =
          _FakePurgeable(category: RetentionCategory.auditEvent);
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: InMemoryLegalHoldAdapter(),
        archive: _FakeArchive(),
        policies: policies,
      );

      await handler.handle(PurgeExpiredRecordsCommand(now: now));

      final expected = now.subtract(tenYearWindow).toUtc();
      expect(port.lastCutoff, isNotNull);
      expect(port.lastCutoff!.toUtc(), expected,
          reason:
              'Handler must pass the tenant-overridden 10-year window, '
              'not the 7-year default — VRTV-76 regression');
      // Sanity: ensure the observed cutoff differs from the default
      // one so we know the override ACTUALLY propagated (not just a
      // happy coincidence of identical timestamps).
      final defaultCutoff = now
          .subtract(DefaultRetentionPolicies.auditEvent.window)
          .toUtc();
      expect(port.lastCutoff!.toUtc(), isNot(defaultCutoff));
    });

    test('normalizes the cutoff to UTC before passing to the adapter',
        () async {
      // The handler is fed a local-time command; adapters expect UTC
      // cutoffs because server_timestamp is TIMESTAMPTZ.
      final localNow = DateTime(2026, 4, 13, 3, 0, 0); // local
      final port =
          _FakePurgeable(category: RetentionCategory.auditEvent);
      final handler = PurgeExpiredRecordsHandler(
        purgeables: [port],
        legalHold: InMemoryLegalHoldAdapter(),
        archive: _FakeArchive(),
      );

      await handler.handle(PurgeExpiredRecordsCommand(now: localNow));

      expect(port.lastCutoff, isNotNull);
      expect(port.lastCutoff!.isUtc, isTrue);
    });
  });

  group('LegalHold + InMemoryLegalHoldAdapter', () {
    test('cannot place two active holds on the same key', () async {
      final holds = InMemoryLegalHoldAdapter();
      final hold = LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'A',
        reason: 'first',
        setByActorId: 'admin',
        setAt: DateTime.utc(2026, 1, 1),
      );
      await holds.place(hold);
      await expectLater(holds.place(hold), throwsStateError);
    });

    test('release then place again is allowed', () async {
      final holds = InMemoryLegalHoldAdapter();
      await holds.place(LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'A',
        reason: 'first',
        setByActorId: 'admin',
        setAt: DateTime.utc(2026, 1, 1),
      ));
      await holds.release(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'A',
        releasedByActorId: 'admin',
        releasedAt: DateTime.utc(2026, 6, 1),
      );
      await holds.place(LegalHold(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'A',
        reason: 'second',
        setByActorId: 'admin',
        setAt: DateTime.utc(2026, 7, 1),
      ));
      final history = await holds.historyFor(
        tenantId: 't1',
        entityType: 'Declaration',
        entityId: 'A',
      );
      expect(history, hasLength(2));
    });
  });

  group('RetentionPolicy', () {
    test('legal minimum is enforced', () {
      final policy = DefaultRetentionPolicies.auditEvent;
      expect(
        () => policy.withTenantOverride(const Duration(days: 30)),
        throwsArgumentError,
      );
    });

    test('tenant override above the floor wins', () {
      final extended = DefaultRetentionPolicies.auditEvent
          .withTenantOverride(const Duration(days: 365 * 10));
      expect(extended.window.inDays, 365 * 10);
    });

    test('hasExpired is half-open at expiresAt', () {
      const policy = RetentionPolicy(
        category: RetentionCategory.userSessionLog,
        legalMinimum: Duration(days: 30),
        platformDefault: Duration(days: 30),
      );
      final created = DateTime.utc(2026, 1, 1);
      expect(
        policy.hasExpired(
          createdAt: created,
          now: created.add(const Duration(days: 30)),
        ),
        isFalse,
      );
      expect(
        policy.hasExpired(
          createdAt: created,
          now: created.add(const Duration(days: 31)),
        ),
        isTrue,
      );
    });
  });
}

/// Test double for [RetentionPurgeablePort].
class _FakePurgeable implements RetentionPurgeablePort {
  @override
  final RetentionCategory category;
  final List<ExpiredRecord> expired = [];
  final List<ExpiredRecord> purged = [];
  final List<ExpiredRecord> tombstones = [];
  final Set<String> failOn = {};

  _FakePurgeable({required this.category});

  /// Most recent [cutoff] passed in by the handler. Tests assert on
  /// this to verify the plumbing — i.e. that the handler is deriving
  /// the cutoff from the effective policy, not a hardcoded constant.
  DateTime? lastCutoff;

  @override
  Future<List<ExpiredRecord>> findExpired({
    required DateTime cutoff,
    int batchSize = 100,
  }) async {
    lastCutoff = cutoff;
    final selected = expired.take(batchSize).toList();
    expired.removeRange(0, selected.length);
    return selected;
  }

  @override
  Future<List<int>> serializeForArchive({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    if (failOn.contains(entityId)) {
      throw StateError('serialize bomb on $entityId');
    }
    return [
      ...'{"tenant":"$tenantId","entity":"$entityType/$entityId"}'.codeUnits,
    ];
  }

  @override
  Future<void> purge(ExpiredRecord record) async {
    purged.add(record);
  }

  @override
  Future<void> recordTombstone(ExpiredRecord record) async {
    tombstones.add(record);
  }
}

/// Test double for [StorageBackendPort].
class _FakeArchive implements StorageBackendPort {
  final List<_Write> writes = [];

  @override
  Future<void> putBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String> metadata = const {},
  }) async {
    writes.add(_Write(path, bytes, contentType, Map.of(metadata)));
  }

  @override
  Future<bool> exists(String path) async =>
      writes.any((w) => w.path == path);
}

class _Write {
  final String path;
  final Uint8List bytes;
  final String contentType;
  final Map<String, String> metadata;
  _Write(this.path, this.bytes, this.contentType, this.metadata);
}
