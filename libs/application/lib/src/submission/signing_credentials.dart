/// Sealed class describing WHERE the signing key material lives for a
/// [SubmitDeclarationCommand].
///
/// The software path ([SoftwareCertCredentials]) is the legacy flow —
/// the sidecar holds a PKCS#12 bundle in memory (set up at container
/// boot) and the handler does NOT receive per-call credentials. It is
/// still the default because the majority of education / sandbox flows
/// use software certs.
///
/// The hardware path ([HardwareTokenCredentials]) targets production
/// BCCR Firma Digital USB tokens. The key NEVER leaves the token; the
/// caller selects a slot at the onboarding UI, provides a PIN per
/// submission, and the handler delegates to [Pkcs11SigningPort].
library;

import 'package:meta/meta.dart';

@immutable
sealed class SigningCredentials {
  const SigningCredentials();
}

/// Use the sidecar's preconfigured PKCS#12 bundle.
///
/// This is the zero-argument case — all the key material lives on the
/// server side (loaded by `AppContainer` from `HACIENDA_P12_PATH` +
/// `HACIENDA_P12_PIN` at boot). Kept as a typed variant (rather than
/// `SigningCredentials?`) so the handler can pattern-match.
@immutable
final class SoftwareCertCredentials extends SigningCredentials {
  const SoftwareCertCredentials();
}

/// Use a PKCS#11-backed hardware token.
///
/// * [pkcs11ModulePath] — absolute path to the middleware shared library
///   (e.g. `/usr/lib/x64-athena/ASEP11.so` on Linux). The app
///   configures this at startup and the onboarding UI surfaces it; it
///   is NOT derived from user input.
/// * [slotId] — the PKCS#11 slot the token is inserted in. Obtained
///   from `Pkcs11SigningPort.enumerateSlots` at the onboarding step.
/// * [pin] — user PIN. Never logged, never audited. Handler MUST NOT
///   retain it beyond the scope of a single command.
@immutable
final class HardwareTokenCredentials extends SigningCredentials {
  final String pkcs11ModulePath;
  final int slotId;
  final String pin;

  const HardwareTokenCredentials({
    required this.pkcs11ModulePath,
    required this.slotId,
    required this.pin,
  });
}
