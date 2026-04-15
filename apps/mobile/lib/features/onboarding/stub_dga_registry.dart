/// Stub DGA registry — simulates the "verify patente" call.
///
/// DGA does NOT publish a public registry API today (reference:
/// `reference_pdcc_sieca.md`). The onboarding flow is designed to call
/// the real API once it exists; until then this stub returns a
/// deterministic `DgaVerification` per patent number so the UI is
/// testable end-to-end.
///
/// Policy:
/// * Patents starting with `DGA-` → verified (registry hit).
/// * Patents matching `^\d{4}-\d{4}$` → verified (legacy format).
/// * Anything else → "manual upload required".
///
/// When the real API lands, this file is replaced with a `HttpDgaRegistry`
/// that honours the same return type — the onboarding flow does not
/// change.
library;

import 'onboarding_state.dart';

abstract class DgaRegistry {
  Future<DgaVerification> verify(String patentNumber);
}

class StubDgaRegistry implements DgaRegistry {
  const StubDgaRegistry();

  static final _legacyFormat = RegExp(r'^\d{4}-\d{4}$');

  @override
  Future<DgaVerification> verify(String patentNumber) async {
    // 200 ms fake latency so the UI shows a loading spinner like the
    // real API would.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (patentNumber.startsWith('DGA-')) {
      return const DgaVerification(
        verified: true,
        detail:
            'Patente encontrada en el registro DGA (stub). Emitida y activa.',
        source: DgaVerificationSource.localStub,
      );
    }
    if (_legacyFormat.hasMatch(patentNumber)) {
      return const DgaVerification(
        verified: true,
        detail: 'Patente en formato legado — verificada por stub.',
        source: DgaVerificationSource.localStub,
      );
    }
    return const DgaVerification(
      verified: false,
      detail:
          'No encontrada. Suba el PDF de la patente para revision manual.',
      source: DgaVerificationSource.localStub,
    );
  }
}
