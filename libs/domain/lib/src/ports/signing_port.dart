/// Port: Digital Signing — abstracts document signing mechanisms.
///
/// Costa Rica uses XAdES-EPES with PKCS#12 certificates from BCCR.
/// Other countries may use different signing standards (CMS, PAdES, etc.).
library;

import 'package:meta/meta.dart';

/// Result of a signing operation.
class SigningResult {
  final bool success;
  final String? signedContent;
  final String? signerCommonName;
  final String? errorMessage;

  const SigningResult({
    required this.success,
    this.signedContent,
    this.signerCommonName,
    this.errorMessage,
  });
}

/// OCSP certificate revocation status (VRTV-58).
enum OcspStatus {
  /// OCSP returned `good` — certificate is not revoked.
  good,

  /// OCSP returned `revoked` — certificate is revoked.
  revoked,

  /// OCSP returned `unknown` — responder does not know about this cert.
  unknown,

  /// OCSP responder could not be reached or returned a non-conformant
  /// response. Caller decides whether to fail-closed (strict) or
  /// fail-open (warn-only).
  unreachable,

  /// OCSP was not attempted (e.g. for the root cert itself, or when
  /// `requireOcsp` is false and caching is empty).
  skipped,
}

/// Detailed outcome of a cryptographic signature verification. Carries
/// every intermediate check so the UI can explain *why* a signature is
/// (in)valid.
@immutable
class VerificationResult {
  /// `true` iff the signature is cryptographically valid AND the chain
  /// resolves to a trusted BCCR root AND (if required) OCSP returned
  /// `good` for every non-root certificate.
  final bool valid;

  /// The `<ds:Signature>` element parsed and its structure is intact.
  final bool structuralValid;

  /// The RSA signature over the canonicalized `<ds:SignedInfo>`
  /// matches using the embedded certificate's public key.
  final bool signatureValid;

  /// The signing certificate's chain terminates at a trusted BCCR
  /// root and each non-root cert is within its validity window.
  final bool chainValid;

  /// OCSP revocation status of the signing certificate.
  final OcspStatus ocspStatus;

  /// Common Name (CN) of the signing certificate, if present.
  final String? signerCommonName;

  /// Verification time applied (server clock at verification time).
  final DateTime? verifiedAt;

  /// If `valid` is false, a human-readable explanation.
  final String? reason;

  /// When true, the verifier performed a DEGRADED check — e.g. only
  /// structural verification because the full XAdES-EPES pipeline is
  /// not yet available in this environment. UIs MUST surface a
  /// prominent warning when this is true.
  final bool degraded;

  const VerificationResult({
    required this.valid,
    required this.structuralValid,
    required this.signatureValid,
    required this.chainValid,
    required this.ocspStatus,
    this.signerCommonName,
    this.verifiedAt,
    this.reason,
    this.degraded = false,
  });

  /// Convenience: a structurally-only valid result with `degraded=true`.
  /// Used by adapters whose sidecar does not yet perform the full
  /// cryptographic pipeline.
  factory VerificationResult.degraded({
    required bool structuralValid,
    String? signerCommonName,
    DateTime? verifiedAt,
    String? reason,
  }) {
    return VerificationResult(
      valid: false,
      structuralValid: structuralValid,
      signatureValid: false,
      chainValid: false,
      ocspStatus: OcspStatus.skipped,
      signerCommonName: signerCommonName,
      verifiedAt: verifiedAt,
      reason: reason ??
          'Full XAdES-EPES verification unavailable in this environment; '
              'only structural check was performed.',
      degraded: true,
    );
  }

  /// Convenience: everything passed.
  factory VerificationResult.success({
    required String signerCommonName,
    required DateTime verifiedAt,
    OcspStatus ocspStatus = OcspStatus.good,
  }) {
    return VerificationResult(
      valid: true,
      structuralValid: true,
      signatureValid: true,
      chainValid: true,
      ocspStatus: ocspStatus,
      signerCommonName: signerCommonName,
      verifiedAt: verifiedAt,
    );
  }

  /// Convenience: explicit failure with a reason.
  factory VerificationResult.failure({
    required String reason,
    bool structuralValid = false,
    bool signatureValid = false,
    bool chainValid = false,
    OcspStatus ocspStatus = OcspStatus.skipped,
    String? signerCommonName,
    DateTime? verifiedAt,
  }) {
    return VerificationResult(
      valid: false,
      structuralValid: structuralValid,
      signatureValid: signatureValid,
      chainValid: chainValid,
      ocspStatus: ocspStatus,
      signerCommonName: signerCommonName,
      verifiedAt: verifiedAt,
      reason: reason,
    );
  }

  /// JSON-friendly representation for audit trails.
  Map<String, dynamic> toAuditPayload() => {
        'valid': valid,
        'structuralValid': structuralValid,
        'signatureValid': signatureValid,
        'chainValid': chainValid,
        'ocspStatus': ocspStatus.name,
        if (signerCommonName != null) 'signerCommonName': signerCommonName,
        if (verifiedAt != null)
          'verifiedAt': verifiedAt!.toIso8601String(),
        if (reason != null) 'reason': reason,
        if (degraded) 'degraded': true,
      };
}

/// Port: Digital Signing — country-agnostic signing + verification.
abstract class SigningPort {
  /// Sign content with the configured digital certificate.
  Future<SigningResult> sign(String content);

  /// Sign content and return base64-encoded result.
  Future<SigningResult> signAndEncode(String content);

  /// Verify a signed document. Convenience boolean wrapper over
  /// [verifySignatureDetailed] — returns `true` iff the detailed
  /// result is fully valid (NOT just structurally). Callers that
  /// need to render *why* a signature failed should call
  /// [verifySignatureDetailed] directly.
  ///
  /// Every adapter gets this for free via the [SigningPortVerifyExtension]
  /// extension below — no per-adapter override needed unless an adapter
  /// wants to short-circuit the Boolean path with a cheaper check.
  Future<bool> verifySignature(String signedContent);

  /// Verify a signed document and return a [VerificationResult]
  /// carrying every intermediate check. Implementations MUST set
  /// `degraded=true` when they do not perform the full XAdES-EPES
  /// cryptographic pipeline; callers render a prominent warning in
  /// that case.
  Future<VerificationResult> verifySignatureDetailed(String signedContent);
}

/// Shared default implementation of [SigningPort.verifySignature] so
/// concrete adapters don't repeat the same "detailed.valid" one-liner.
///
/// Dart 3 doesn't let abstract classes ship default method bodies
/// that are inherited via `implements`, so we expose this mixin to
/// keep the contract DRY for the adapter side. Classes mixing it in
/// are still responsible for implementing [verifySignatureDetailed].
mixin DetailedVerificationBooleanWrapper {
  /// Subclasses provide this — the mixin just forwards.
  Future<VerificationResult> verifySignatureDetailed(String signedContent);

  Future<bool> verifySignature(String signedContent) async {
    final r = await verifySignatureDetailed(signedContent);
    return r.valid;
  }
}
