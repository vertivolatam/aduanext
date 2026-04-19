/// In-memory [DeclarationRepositoryPort] — for tests and dev runs.
///
/// Stores declarations in a single map keyed by id. Concurrency is
/// serialized via a single-slot [Future] chain so racing `updateStatus`
/// calls observe a consistent stored status (mirrors the semantics of
/// the Postgres adapter's `UPDATE ... WHERE status = ?` precondition).
library;

import 'dart:async';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

/// Pure-memory implementation of [DeclarationRepositoryPort].
class InMemoryDeclarationRepositoryAdapter
    implements DeclarationRepositoryPort {
  final Map<String, _StoredDeclaration> _byId = {};

  /// Serialization lock — ensures updateStatus calls don't interleave.
  Future<void> _writeLock = Future<void>.value();

  /// Seed the adapter with a declaration. Used by tests to avoid
  /// hand-crafting an entity before each assertion.
  void seed(String id, Declaration declaration) {
    _byId[id] = _StoredDeclaration(declaration);
  }

  @override
  Future<Declaration?> getById(String declarationId) async {
    final stored = _byId[declarationId];
    return stored?.current;
  }

  @override
  Future<void> updateStatus({
    required String declarationId,
    required DeclarationStatus expectedPreviousStatus,
    required DeclarationStatus newStatus,
    String? registrationNumber,
    String? assessmentSerial,
    int? assessmentNumber,
    String? assessmentDate,
  }) {
    final completer = Completer<void>();
    _writeLock = _writeLock.then((_) async {
      try {
        final stored = _byId[declarationId];
        if (stored == null) {
          throw StateError(
            'declaration $declarationId not found in repository',
          );
        }
        final current = stored.current.status;
        if (current != expectedPreviousStatus) {
          throw ConcurrentDeclarationUpdateException(
            declarationId: declarationId,
            expectedPreviousStatus: expectedPreviousStatus,
            actualStoredStatus: current,
          );
        }
        stored.current = _withStatus(
          stored.current,
          newStatus: newStatus,
          registrationNumber: registrationNumber,
          assessmentSerial: assessmentSerial,
          assessmentNumber: assessmentNumber,
          assessmentDate: assessmentDate,
        );
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  @override
  Future<List<Declaration>> list(DeclarationListFilter filter) async {
    final filtered = _byId.values
        .map((s) => s.current)
        .where((d) {
          if (filter.statusFilter != null &&
              !filter.statusFilter!.contains(d.status)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    final start = filter.offset.clamp(0, filtered.length);
    final end = (start + filter.limit).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  /// Test-only: size of the store.
  @visibleForTesting
  int get length => _byId.length;
}

class _StoredDeclaration {
  Declaration current;
  _StoredDeclaration(this.current);
}

/// Returns a copy of [d] with the given fields replaced. Kept private
/// because the Declaration entity does not expose a `copyWith` — we
/// only need this narrow update path for the state-machine handler.
Declaration _withStatus(
  Declaration d, {
  required DeclarationStatus newStatus,
  String? registrationNumber,
  String? assessmentSerial,
  int? assessmentNumber,
  String? assessmentDate,
}) {
  return Declaration(
    id: d.id,
    version: d.version,
    typeOfDeclaration: d.typeOfDeclaration,
    generalProcedureCode: d.generalProcedureCode,
    typeOfTransitDocumentCode: d.typeOfTransitDocumentCode,
    officeOfDispatchExportCode: d.officeOfDispatchExportCode,
    declarationFlow: d.declarationFlow,
    exporterCode: d.exporterCode,
    consigneeCode: d.consigneeCode,
    consigneeName: d.consigneeName,
    consigneeAddress: d.consigneeAddress,
    declarantCode: d.declarantCode,
    declarantReferenceNumber: d.declarantReferenceNumber,
    shippingAgentCode: d.shippingAgentCode,
    cargoHandlerCode: d.cargoHandlerCode,
    consignmentReference: d.consignmentReference,
    comments: d.comments,
    beneficiaryCode: d.beneficiaryCode,
    beneficiaryName: d.beneficiaryName,
    beneficiaryAddress: d.beneficiaryAddress,
    natureOfTransactionCode1: d.natureOfTransactionCode1,
    natureOfTransactionCode2: d.natureOfTransactionCode2,
    documentsReceived: d.documentsReceived,
    identityOfMeansOfTransportAtBorder: d.identityOfMeansOfTransportAtBorder,
    nationalityOfMeansOfTransportAtBorderCode:
        d.nationalityOfMeansOfTransportAtBorderCode,
    modeOfTransportAtBorderCode: d.modeOfTransportAtBorderCode,
    identityOfMeansOfTransportAtDepartureOrArrival:
        d.identityOfMeansOfTransportAtDepartureOrArrival,
    nationalityOfMeansOfTransportAtArrivalDepartureCode:
        d.nationalityOfMeansOfTransportAtArrivalDepartureCode,
    officeOfEntryCode: d.officeOfEntryCode,
    inlandModeOfTransportCode: d.inlandModeOfTransportCode,
    locationOfGoodsCode: d.locationOfGoodsCode,
    bankCode: d.bankCode,
    bankBranchCode: d.bankBranchCode,
    bankAccountNumber: d.bankAccountNumber,
    warehouseCode: d.warehouseCode,
    previousCompanyCode: d.previousCompanyCode,
    originWarehouseForTransferCode: d.originWarehouseForTransferCode,
    shipping: d.shipping,
    transit: d.transit,
    sadValuation: d.sadValuation,
    items: d.items,
    invoices: d.invoices,
    globalTaxes: d.globalTaxes,
    ignoredWarnings: d.ignoredWarnings,
    customsRegistrationNumber: registrationNumber ?? d.customsRegistrationNumber,
    customsRegistrationSerial: d.customsRegistrationSerial,
    customsRegistrationDate: d.customsRegistrationDate,
    customsRegistrationYear: d.customsRegistrationYear,
    assessmentSerial: assessmentSerial ?? d.assessmentSerial,
    assessmentNumber: assessmentNumber ?? d.assessmentNumber,
    assessmentDate: assessmentDate ?? d.assessmentDate,
    assessmentYear: d.assessmentYear,
    status: newStatus,
    paymentStatus: d.paymentStatus,
    totalNumberOfItems: d.totalNumberOfItems,
    totalNumberOfPackages: d.totalNumberOfPackages,
    totalNumberOfContainers: d.totalNumberOfContainers,
    totalNumberOfAttachedDocuments: d.totalNumberOfAttachedDocuments,
    totalGrossMass: d.totalGrossMass,
    totalNetMass: d.totalNetMass,
    totalGlobalTaxes: d.totalGlobalTaxes,
    guaranteeAmount: d.guaranteeAmount,
    totalAssessedAmount: d.totalAssessedAmount,
    totalPaidAmount: d.totalPaidAmount,
    totalAmountToBePaid: d.totalAmountToBePaid,
  );
}
