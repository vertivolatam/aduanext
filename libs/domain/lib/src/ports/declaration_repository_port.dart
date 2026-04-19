/// Port: Declaration Repository — load + persist [Declaration] aggregates.
///
/// The `SubmitDeclarationHandler` does NOT need this port today (it is
/// called with a Declaration already in memory), but the state-machine
/// handler (VRTV-40) does: given only a `declarationId`, it has to look
/// up the current status, apply the transition, and persist the new
/// status + registration metadata.
///
/// We keep the API deliberately narrow — only the operations the
/// application layer actually performs. Adapters (Postgres, SQLite,
/// in-memory) implement this contract; queries like "list by tenant"
/// live here so presentation layers can consume the same port.
library;

import '../entities/declaration.dart';
import '../value_objects/declaration_status.dart';

/// Filter parameters for [DeclarationRepositoryPort.list].
class DeclarationListFilter {
  /// Tenant scope — required for multi-tenant isolation. Adapters MUST
  /// enforce this at the storage layer (Postgres RLS) as defense in
  /// depth; do NOT rely on the application layer alone.
  final String tenantId;

  /// Optional subset of statuses. `null` returns every status.
  final Set<DeclarationStatus>? statusFilter;

  final int limit;
  final int offset;

  const DeclarationListFilter({
    required this.tenantId,
    this.statusFilter,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Port: Declaration Repository.
abstract class DeclarationRepositoryPort {
  /// Load a declaration by id, or `null` if none exists in the current
  /// tenant scope. Adapters enforce tenant isolation.
  Future<Declaration?> getById(String declarationId);

  /// Update only the [status] (and optional registration metadata). Used
  /// by the state-machine handler — the full declaration is not
  /// re-persisted, since every other field is immutable once submitted.
  ///
  /// Adapters MUST perform this as a conditional update: if the current
  /// stored status does not match [expectedPreviousStatus], they MUST
  /// throw [ConcurrentDeclarationUpdateException]. This prevents lost
  /// writes when two concurrent gateway pushes race for the same entity.
  Future<void> updateStatus({
    required String declarationId,
    required DeclarationStatus expectedPreviousStatus,
    required DeclarationStatus newStatus,
    String? registrationNumber,
    String? assessmentSerial,
    int? assessmentNumber,
    String? assessmentDate,
  });

  /// List declarations matching [filter], ordered by id (stable).
  Future<List<Declaration>> list(DeclarationListFilter filter);
}

/// Thrown by [DeclarationRepositoryPort.updateStatus] when the optimistic
/// precondition (`expectedPreviousStatus`) does not match the stored row.
/// Application layer should surface this as a conflict to the caller,
/// not retry blindly.
class ConcurrentDeclarationUpdateException implements Exception {
  final String declarationId;
  final DeclarationStatus expectedPreviousStatus;
  final DeclarationStatus actualStoredStatus;

  const ConcurrentDeclarationUpdateException({
    required this.declarationId,
    required this.expectedPreviousStatus,
    required this.actualStoredStatus,
  });

  @override
  String toString() =>
      'ConcurrentDeclarationUpdateException(id=$declarationId, '
      'expected=${expectedPreviousStatus.code}, '
      'actual=${actualStoredStatus.code})';
}
