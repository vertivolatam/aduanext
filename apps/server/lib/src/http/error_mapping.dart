/// Error mapping from application-layer [SubmitDeclarationFailure]s to
/// HTTP (status, code) tuples per the stable client contract.
///
/// Also carries the additional [ErrorCodes] values used by the dispatch
/// endpoints (the base set in `error_responses.dart` only knows about
/// auth + generic errors — submit has its own vocabulary).
///
/// Contract audit table (mirrored in `docs/site/content/docs/api/dispatches.md`):
///
/// | Failure                              | Status | Code                     |
/// | ------------------------------------ | ------ | ------------------------ |
/// | MissingFieldFailure                  | 422    | PRE_VALIDATION_FAILED    |
/// | InvalidDeclarationStructureFailure   | 422    | PRE_VALIDATION_FAILED    |
/// | PreValidationFailedFailure           | 422    | PRE_VALIDATION_FAILED    |
/// | AuthenticationFailedFailure          | 502    | ATENA_AUTH_FAILED        |
/// | DeclarationValidationFailedFailure   | 422    | ATENA_VALIDATION_FAILED  |
/// | SigningFailedFailure                 | 500    | SIGNING_FAILED           |
/// | GatewayRejectedSubmissionFailure     | 502    | ATENA_SUBMISSION_FAILED  |
/// | (unknown Failure subclass)           | 500    | INTERNAL_ERROR           |
///
/// NEVER leak [Failure.toString()] to the wire — it may contain the
/// failure's nested `reason` which in turn may embed transport-level
/// diagnostics. Use only [Failure.message] (curated + human-readable).
library;

import 'package:aduanext_application/aduanext_application.dart';

import 'error_responses.dart';

/// SCREAMING_SNAKE codes specific to the dispatch endpoints. Kept
/// separate from [ErrorCodes] so the base module stays tiny and the
/// submit-specific vocabulary is documented in one place.
class DispatchErrorCodes {
  DispatchErrorCodes._();

  static const preValidationFailed = 'PRE_VALIDATION_FAILED';
  static const atenaAuthFailed = 'ATENA_AUTH_FAILED';
  static const atenaValidationFailed = 'ATENA_VALIDATION_FAILED';
  static const signingFailed = 'SIGNING_FAILED';
  static const atenaSubmissionFailed = 'ATENA_SUBMISSION_FAILED';

  /// Request body could not be parsed as JSON / was malformed.
  static const malformedRequest = 'MALFORMED_REQUEST';

  /// Request body exceeded [maxRequestBodyBytes].
  static const payloadTooLarge = 'PAYLOAD_TOO_LARGE';

  /// Client tripped the per-tenant rate limiter.
  static const rateLimited = 'RATE_LIMITED';

  /// Hardware credentials supplied but the server cannot fulfil them
  /// (PKCS#11 helper binary not configured or not present at boot).
  static const hardwareUnavailable = 'HARDWARE_UNAVAILABLE';

  /// Dispatch retrieve / rectify targeted an id that does not exist or
  /// is not visible to the caller's tenant.
  static const dispatchNotFound = 'DISPATCH_NOT_FOUND';

  /// Feature-flagged endpoint disabled (rectify / list have placeholders
  /// returning 501 until their read model lands).
  static const notImplemented = 'NOT_IMPLEMENTED';
}

/// Carrier for the (status, code, message) triple that the boundary
/// converts into a JSON response.
class MappedError {
  final int status;
  final String code;
  final String error;
  final String message;

  /// Optional structured details — ONLY populated for
  /// [DeclarationValidationFailedFailure] (errors + warnings list) and
  /// [PreValidationFailedFailure] (rule report summary). NEVER contains
  /// stack traces or adapter diagnostics.
  final Map<String, dynamic>? details;

  const MappedError({
    required this.status,
    required this.code,
    required this.error,
    required this.message,
    this.details,
  });
}

/// Map a submit-declaration [Failure] to the HTTP response tuple.
///
/// The function deliberately accepts the generic `Failure` supertype so
/// the boundary can thread arbitrary command-layer failures through —
/// any subtype not enumerated below collapses to INTERNAL_ERROR (500)
/// with a generic message. This keeps new failure variants from
/// leaking partial diagnostics through a default toString.
MappedError mapSubmitFailure(Failure failure) {
  if (failure is MissingFieldFailure) {
    return MappedError(
      status: 422,
      code: DispatchErrorCodes.preValidationFailed,
      error: 'validation_failed',
      message: failure.message,
    );
  }
  if (failure is InvalidDeclarationStructureFailure) {
    return MappedError(
      status: 422,
      code: DispatchErrorCodes.preValidationFailed,
      error: 'validation_failed',
      message: failure.message,
    );
  }
  if (failure is PreValidationFailedFailure) {
    return MappedError(
      status: 422,
      code: DispatchErrorCodes.preValidationFailed,
      error: 'validation_failed',
      message: failure.message,
      // NB: the opaque `report` field is a `ValidationReport` from the
      // validation feature slice; the `summary` is always a curated
      // one-liner. We do NOT serialise the full report here because
      // the DTO lives in application-layer code which the HTTP layer
      // does not depend on. Clients can re-call the /validate endpoint
      // (out of scope of this issue) for the full breakdown.
      details: {'summary': failure.summary},
    );
  }
  if (failure is AuthenticationFailedFailure) {
    return MappedError(
      status: 502,
      code: DispatchErrorCodes.atenaAuthFailed,
      error: 'authentication_failed',
      // The failure.reason is already adapter-curated (see AuthProviderPort
      // doc). idpErrorCode is a stable vendor code — safe to surface.
      message: failure.message,
      details: failure.idpErrorCode != null
          ? {'idpErrorCode': failure.idpErrorCode}
          : null,
    );
  }
  if (failure is DeclarationValidationFailedFailure) {
    return MappedError(
      status: 422,
      code: DispatchErrorCodes.atenaValidationFailed,
      error: 'validation_failed',
      message: failure.message,
      details: {
        'errors': failure.errors
            .map((e) => {
                  'code': e.code,
                  'message': e.message,
                  if (e.field != null) 'field': e.field,
                })
            .toList(),
        'warnings': failure.warnings
            .map((w) => {'code': w.code, 'message': w.message})
            .toList(),
      },
    );
  }
  if (failure is SigningFailedFailure) {
    return MappedError(
      status: 500,
      code: DispatchErrorCodes.signingFailed,
      error: 'signing_failed',
      // `reason` is typed — never carries a PIN (enforced at the
      // Pkcs11Exception construction site and verified by VRTV-70's
      // regression test). It's a curated string; safe to surface.
      message: failure.message,
    );
  }
  if (failure is GatewayRejectedSubmissionFailure) {
    return MappedError(
      status: 502,
      code: DispatchErrorCodes.atenaSubmissionFailed,
      error: 'submission_failed',
      message: failure.message,
      // rawResponse may contain ATENA's vendor payload — we do NOT
      // forward it verbatim (it may leak gateway internals). Clients
      // that need it should hit the audit trail.
    );
  }
  return const MappedError(
    status: 500,
    code: ErrorCodes.internalError,
    error: 'internal_error',
    message: 'The server encountered an unexpected error',
  );
}
