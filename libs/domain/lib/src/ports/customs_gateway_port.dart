/// Port: Customs Gateway — abstracts any country's customs system.
///
/// The domain layer uses this interface exclusively.
/// Each country provides its own adapter:
///   - Costa Rica: AtenaCustomsGatewayAdapter → ATENA API via gRPC sidecar
///   - Guatemala:  SatGtCustomsGatewayAdapter → SAT-GT API (future)
///   - Honduras:   SarahCustomsGatewayAdapter → SARAH system (future)
///
/// Architecture: Explicit Architecture (Herberto Graca)
/// https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/
library;

import '../entities/declaration.dart';
import '../value_objects/declaration_status.dart';

/// Result of submitting a declaration to the customs system.
class DeclarationResult {
  final bool success;
  final String? registrationNumber;
  final String? assessmentSerial;
  final int? assessmentNumber;
  final String? assessmentDate;
  final String? errorMessage;
  final String? rawResponse;

  const DeclarationResult({
    required this.success,
    this.registrationNumber,
    this.assessmentSerial,
    this.assessmentNumber,
    this.assessmentDate,
    this.errorMessage,
    this.rawResponse,
  });
}

/// Result of validating a declaration before submission.
class ValidationResult {
  final bool valid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  const ValidationResult({
    required this.valid,
    this.errors = const [],
    this.warnings = const [],
  });
}

class ValidationError {
  final String code;
  final String message;
  final String? field;

  const ValidationError({
    required this.code,
    required this.message,
    this.field,
  });
}

class ValidationWarning {
  final String code;
  final String message;

  const ValidationWarning({required this.code, required this.message});
}

/// Port: Customs Gateway — country-agnostic interface to any customs system.
abstract class CustomsGatewayPort {
  /// Submit a declaration to the customs system.
  Future<DeclarationResult> submitDeclaration(Declaration declaration);

  /// Validate a declaration before submission (dry-run).
  Future<ValidationResult> validateDeclaration(Declaration declaration);

  /// Get the current status of a registered declaration.
  Future<DeclarationStatus> getDeclarationStatus(String registrationKey);

  /// Liquidate (assess taxes for) a validated declaration.
  Future<DeclarationResult> liquidateDeclaration(Declaration declaration);

  /// Rectify an already-submitted declaration.
  Future<DeclarationResult> rectifyDeclaration(
    Declaration original,
    Declaration corrected,
  );

  /// Upload a supporting document for a declaration.
  Future<String> uploadAttachment({
    required String declarationId,
    required String docCode,
    required String docReference,
    required List<int> fileBytes,
    required String fileName,
  });
}
