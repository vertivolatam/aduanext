/// Port: PKCS#11 Hardware-Token Signing.
///
/// Abstracts signing operations that require a PKCS#11-backed private
/// key — specifically the Costa Rican BCCR Firma Digital USB smart cards
/// (Gemalto IDPrime MD 830 / MD 840 and equivalents). Unlike
/// [SigningPort], the private key never leaves the hardware; every sign
/// call crosses the token boundary.
///
/// The reference adapter is `SubprocessPkcs11SigningAdapter` in
/// libs/adapters, which drives the Go helper binary produced by
/// VRTV-69 over a newline-delimited JSON stdio protocol. Any other
/// transport (FFI, Java bridge, browser-side extension) that can
/// provide the same semantics is a valid adapter.
///
/// Architecture: Secondary Port (Driven side, Explicit Architecture).
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Supported signing mechanisms. The enum values correspond to the
/// PKCS#11 mechanism names exactly so callers can reason about them
/// without a translation layer.
///
/// Only the mechanisms used by BCCR-compliant XAdES-BES / XAdES-EPES
/// are included. Adding more is a one-line change on both sides of
/// the port; gate on real-world need.
enum SignatureAlgorithm {
  /// RSA PKCS#1 v1.5 with SHA-256 digest applied inside the token.
  rsaPkcs1Sha256,

  /// RSA-PSS with SHA-256. Some newer BCCR-issued certificates use PSS.
  rsaPssSha256,

  /// Raw PKCS#1 v1.5 over a pre-computed SHA-256 digest supplied by
  /// the caller. Used by the XAdES SignedInfo canonicalization path
  /// where the digest is computed in Dart and only the final
  /// RSA-encrypt-against-private-key happens on the token.
  rsaPkcs1PrehashedSha256;

  /// Wire-level name, matching the PKCS#11 constant. This is what the
  /// subprocess adapter sends to the Go helper.
  String get wireName {
    switch (this) {
      case SignatureAlgorithm.rsaPkcs1Sha256:
        return 'CKM_SHA256_RSA_PKCS';
      case SignatureAlgorithm.rsaPssSha256:
        return 'CKM_SHA256_RSA_PKCS_PSS';
      case SignatureAlgorithm.rsaPkcs1PrehashedSha256:
        return 'CKM_RSA_PKCS';
    }
  }
}

/// A PKCS#11 slot that currently has a token inserted.
///
/// Field naming mirrors the Go helper's wire format. All optional
/// fields may be empty / null when a middleware cannot read them
/// (uninitialized tokens, missing cert, etc.); the caller renders
/// gracefully degraded UI in that case.
@immutable
class TokenSlot {
  final int slotId;
  final String tokenLabel;
  final String tokenSerial;
  final String manufacturer;
  final String model;

  /// `true` iff a CKO_CERTIFICATE object exists on the token. The UI
  /// typically grays out slots where this is false because BCCR tokens
  /// without a provisioned cert cannot sign a DUA.
  final bool hasCert;

  /// Subject CN of the first certificate on the token. Used for the
  /// human-readable token picker label ("Maria Perez, …").
  final String? certCommonName;

  final String? certSubject;
  final String? certIssuer;
  final DateTime? certNotBefore;
  final DateTime? certNotAfter;

  const TokenSlot({
    required this.slotId,
    required this.tokenLabel,
    required this.tokenSerial,
    required this.manufacturer,
    required this.model,
    required this.hasCert,
    this.certCommonName,
    this.certSubject,
    this.certIssuer,
    this.certNotBefore,
    this.certNotAfter,
  });

  /// Audit-friendly map. The PIN is NEVER a field on this value object
  /// so there is nothing to redact.
  Map<String, Object?> toAuditPayload() => {
        'slotId': slotId,
        'tokenLabel': tokenLabel,
        'tokenSerial': tokenSerial,
        'manufacturer': manufacturer,
        'model': model,
        'hasCert': hasCert,
        if (certCommonName != null) 'certCommonName': certCommonName,
        if (certNotBefore != null) 'certNotBefore': certNotBefore!.toIso8601String(),
        if (certNotAfter != null) 'certNotAfter': certNotAfter!.toIso8601String(),
      };
}

/// The raw output of a [Pkcs11SigningPort.signWithToken] call.
///
/// The XAdES envelope is built *outside* this port — callers take the
/// raw signature bytes + signer certificate and hand them to the
/// existing XAdES builder in the sidecar. This keeps the port small
/// and easy to stub.
@immutable
class SignResult {
  /// Raw signature bytes as produced by the token. For
  /// `rsaPkcs1Sha256` this is the RSASSA-PKCS1-v1_5 signature over the
  /// SHA-256 digest of `dataToSign`; for `rsaPkcs1PrehashedSha256` it
  /// is the RSA encryption of the caller-supplied DigestInfo.
  final Uint8List signatureBytes;

  /// Signer certificate in DER encoding. Dart callers typically
  /// re-encode to PEM for the XAdES <X509Certificate> element.
  final Uint8List signerCertificateDer;

  /// Subject Common Name of the signer cert. Captured for audit.
  final String signerCommonName;

  /// Token serial number as reported by the middleware. Captured for
  /// audit so we can tell a signer which physical device was used.
  final String tokenSerial;

  /// Server-side timestamp of the sign operation.
  final DateTime signedAt;

  const SignResult({
    required this.signatureBytes,
    required this.signerCertificateDer,
    required this.signerCommonName,
    required this.tokenSerial,
    required this.signedAt,
  });
}

/// Base class for all PKCS#11-related exceptions surfaced through the
/// port. Adapters map wire-level error codes into the typed subclasses
/// below so the use-case layer can branch on them without string
/// matching.
sealed class Pkcs11Exception implements Exception {
  final String message;
  const Pkcs11Exception(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// No token is present in the requested slot (or the slot does not
/// exist). UI: "Please insert your Firma Digital token."
class TokenNotPresentException extends Pkcs11Exception {
  const TokenNotPresentException(super.message);
}

/// The user PIN was wrong. The caller should prompt for re-entry. The
/// token firmware counts consecutive failures — typically after three
/// the token transitions to the locked state, which surfaces as
/// [PinLockedException].
class InvalidPinException extends Pkcs11Exception {
  const InvalidPinException(super.message);
}

/// The PIN is locked. Recovery requires the Security Officer PIN,
/// which AduaNext never sees. UI: "PIN is locked. Contact BCCR."
class PinLockedException extends Pkcs11Exception {
  const PinLockedException(super.message);
}

/// The token does not expose a private key or certificate object that
/// this adapter can use. Usually means the token is blank or was
/// initialized outside the BCCR-provisioning flow.
class NoSigningMaterialException extends Pkcs11Exception {
  const NoSigningMaterialException(super.message);
}

/// The requested signing mechanism is not supported by the token. Rare
/// in practice (BCCR tokens support the required set) but possible on
/// third-party middleware.
class UnsupportedMechanismException extends Pkcs11Exception {
  const UnsupportedMechanismException(super.message);
}

/// The helper binary could not be located or launched. This is a
/// configuration problem, not a signing failure. UI: "Install the
/// AduaNext PKCS#11 helper from …".
class HelperBinaryNotFoundException extends Pkcs11Exception {
  const HelperBinaryNotFoundException(super.message);
}

/// The helper wrote something the adapter could not parse, or the
/// stdio pipe died unexpectedly. Indicates a bug or a crashed helper
/// process; callers should surface a generic error + suggest
/// retrying.
class HelperProtocolException extends Pkcs11Exception {
  const HelperProtocolException(super.message);
}

/// The PKCS#11 module could not be loaded (missing .so / wrong
/// architecture / C_Initialize failed). UI: "Firma Digital middleware
/// is not installed or is not the right version."
class ModuleLoadException extends Pkcs11Exception {
  const ModuleLoadException(super.message);
}

/// A generic sign failure not covered by the more specific cases. The
/// `message` carries the underlying `CKR_*` return code for the
/// support team.
class SignFailedException extends Pkcs11Exception {
  const SignFailedException(super.message);
}

/// Port: enumerate PKCS#11 slots + sign with the token private key.
///
/// Implementations MUST be safe to call concurrently (the typical
/// adapter spawns a fresh helper process per request); they MUST NOT
/// cache PINs across calls.
abstract class Pkcs11SigningPort {
  /// Lists every slot with a token currently inserted, against the
  /// provided module.
  ///
  /// [pkcs11ModulePath] is an absolute path to the middleware shared
  /// library (e.g. `/usr/lib/x64-athena/ASEP11.so` for BCCR Linux).
  /// Adapters MUST reject relative paths — the file-existence check
  /// is the caller's responsibility (typically done at app startup
  /// when computing the path from config).
  Future<List<TokenSlot>> enumerateSlots(String pkcs11ModulePath);

  /// Signs [dataToSign] with the private key of the token in the
  /// specified slot.
  ///
  /// [pin] is sent to the token for a single C_Login call. Adapters
  /// MUST NOT retain the PIN beyond the scope of this method and MUST
  /// NOT log it.
  ///
  /// Throws a subclass of [Pkcs11Exception] on failure.
  Future<SignResult> signWithToken({
    required String pkcs11ModulePath,
    required int slotId,
    required String pin,
    required Uint8List dataToSign,
    required SignatureAlgorithm algorithm,
  });
}
