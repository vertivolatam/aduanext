/// Handler for `PurgeExpiredRecordsCommand`.
///
/// The handler is the retention worker's brain — given a clock and a
/// set of [RetentionPurgeablePort]s, it walks each and applies the
/// archive → purge → tombstone sequence per record, honouring legal
/// holds. Per-category errors are caught + counted; one bad record
/// MUST NOT abort the whole run (the next pass picks it up).
///
/// The handler does NOT log directly — it returns a [PurgeReport] and
/// lets the caller (worker scheduler) decide how to surface it
/// (structured logs, metrics, audit trail).
library;

import 'dart:typed_data';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:logging/logging.dart';

import '../shared/command.dart';
import '../shared/result.dart';
import 'purge_expired_records_command.dart';

class PurgeExpiredRecordsHandler
    implements
        CommandHandler<PurgeExpiredRecordsCommand, PurgeReport> {
  final List<RetentionPurgeablePort> _purgeables;
  final LegalHoldPort _holds;
  final StorageBackendPort _archive;
  final Map<RetentionCategory, RetentionPolicy> _policies;
  final Logger _log;

  PurgeExpiredRecordsHandler({
    required List<RetentionPurgeablePort> purgeables,
    required LegalHoldPort legalHold,
    required StorageBackendPort archive,
    Map<RetentionCategory, RetentionPolicy>? policies,
    Logger? logger,
  })  : _purgeables = List.unmodifiable(purgeables),
        _holds = legalHold,
        _archive = archive,
        _policies = policies ?? DefaultRetentionPolicies.all,
        _log = logger ?? Logger('aduanext.retention');

  @override
  Future<Result<PurgeReport>> handle(
    PurgeExpiredRecordsCommand command,
  ) async {
    final byCategory = <String, PurgeCategoryStats>{};

    for (final port in _purgeables) {
      final policy = _policies[port.category];
      if (policy == null) {
        _log.warning(
          'No policy registered for ${port.category}; skipping',
        );
        continue;
      }
      final stats = await _purgeCategory(port, command);
      byCategory[port.category.name] = stats;
    }

    return Result.ok(PurgeReport(byCategory: byCategory));
  }

  Future<PurgeCategoryStats> _purgeCategory(
    RetentionPurgeablePort port,
    PurgeExpiredRecordsCommand command,
  ) async {
    var candidates = 0;
    var archived = 0;
    var purged = 0;
    var heldByLegal = 0;
    var errors = 0;

    final List<ExpiredRecord> page;
    try {
      page = await port.findExpired(
        now: command.now,
        batchSize: command.batchSize,
      );
    } catch (e, st) {
      _log.severe(
        'findExpired failed for ${port.category}',
        e,
        st,
      );
      return PurgeCategoryStats(
        candidates: 0,
        archived: 0,
        purged: 0,
        heldByLegal: 0,
        errors: 1,
      );
    }

    candidates = page.length;
    for (final record in page) {
      final held = await _holds.isHeld(
        tenantId: record.tenantId,
        entityType: record.entityType,
        entityId: record.entityId,
        now: command.now,
      );
      if (held) {
        heldByLegal++;
        _log.fine(
          'Skipping ${record.entityType}/${record.entityId} — legal hold',
        );
        continue;
      }

      try {
        final bytes = await port.serializeForArchive(
          tenantId: record.tenantId,
          entityType: record.entityType,
          entityId: record.entityId,
        );
        final path = _archivePath(port.category, record);
        await _archive.putBytes(
          path: path,
          bytes: Uint8List.fromList(bytes),
          contentType: 'application/json',
          metadata: {
            'tenant_id': record.tenantId,
            'entity_type': record.entityType,
            'entity_id': record.entityId,
            'created_at': record.createdAt.toUtc().toIso8601String(),
            'expires_at': record.expiresAt.toUtc().toIso8601String(),
            'category': port.category.name,
          },
        );
        archived++;

        await port.purge(record);
        purged++;

        await port.recordTombstone(record);
      } catch (e, st) {
        errors++;
        _log.severe(
          'Purge failed for ${record.entityType}/${record.entityId}',
          e,
          st,
        );
      }
    }

    return PurgeCategoryStats(
      candidates: candidates,
      archived: archived,
      purged: purged,
      heldByLegal: heldByLegal,
      errors: errors,
    );
  }

  /// Build a stable archive path from the record. Layout:
  ///   `{category}/{tenant_id}/{year}/{entity_type}/{entity_id}.json`
  /// The tenant prefix lets us shard by tenant later (per-customer
  /// archive bucket). The year prefix limits per-folder fan-out.
  String _archivePath(RetentionCategory category, ExpiredRecord r) {
    final year = r.createdAt.toUtc().year.toString();
    return '${category.name}/${r.tenantId}/$year/'
        '${r.entityType}/${r.entityId}.json';
  }
}
