/// Draft state for the freelance-agent onboarding wizard.
///
/// Each step updates a slice of this struct; the wizard never attempts
/// to build a final [AgentProfile] until the user reaches the
/// confirmation step and every slice is non-null. Intermediate state
/// is legal — the UI can resume halfway through.
///
/// NO secrets live here (PINs, passwords). Those go directly to the
/// backend over TLS and are never retained in memory longer than the
/// field lifetime.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

@immutable
class IdentityDraft {
  final String cedula;
  final String legalName;
  final String email;
  final String phone;
  final String address;
  const IdentityDraft({
    required this.cedula,
    required this.legalName,
    required this.email,
    required this.phone,
    required this.address,
  });

  bool get isComplete =>
      cedula.isNotEmpty &&
      legalName.isNotEmpty &&
      email.contains('@') &&
      phone.isNotEmpty &&
      address.isNotEmpty;
}

@immutable
class PatentDraft {
  final String patentNumber;
  final DateTime? issuedAt;
  final String? uploadedDocumentName;
  final DgaVerification? verification;
  const PatentDraft({
    required this.patentNumber,
    required this.issuedAt,
    required this.uploadedDocumentName,
    required this.verification,
  });

  bool get isComplete =>
      patentNumber.isNotEmpty &&
      issuedAt != null &&
      verification != null;
}

/// Outcome of querying the (stubbed) DGA public registry.
@immutable
class DgaVerification {
  /// `true` iff the registry knows the patente and it is still active.
  final bool verified;

  /// Free-form detail ("registered since 2024-03-12", "not found",
  /// "registry unavailable — manual upload required").
  final String detail;

  /// Source of the result — distinguishes a real API hit from our
  /// stub fallback so audit logs don't lie about it.
  final DgaVerificationSource source;

  const DgaVerification({
    required this.verified,
    required this.detail,
    required this.source,
  });
}

enum DgaVerificationSource {
  /// Hit the real DGA registry. Does not exist yet — placeholder for
  /// when SIECA publishes the API.
  registryApi,

  /// Fell back to the local stub — DGA has no public API today.
  localStub,

  /// User uploaded the patente PDF for manual review.
  manualUpload,
}

@immutable
class BondDraft {
  final int amountCrc;
  final BondType? type;
  final DateTime? expiresAt;
  final String? uploadedDocumentName;
  const BondDraft({
    required this.amountCrc,
    required this.type,
    required this.expiresAt,
    required this.uploadedDocumentName,
  });

  /// LGA Art. 58 — bond must be ≥ 20 000 000 CRC.
  bool get meetsLegalFloor =>
      amountCrc >= AgentProfile.bondLegalMinimumCrc;

  bool get isComplete =>
      meetsLegalFloor &&
      type != null &&
      expiresAt != null &&
      uploadedDocumentName != null;
}

@immutable
class SignatureDraft {
  /// Always `software` on Flutter Web today — hardware detection lands
  /// with VRTV-70 once the PKCS#11 helper + adapter ship.
  final SignatureMode mode;

  /// File name of the uploaded `.p12` (for display only; bytes + PIN
  /// go straight to the backend).
  final String? uploadedP12Name;

  /// `true` iff the user entered a PIN. The PIN itself is NOT
  /// retained — we only track whether it was provided so the review
  /// step can show "PIN provided" without echoing the secret.
  final bool pinProvided;

  const SignatureDraft({
    required this.mode,
    required this.uploadedP12Name,
    required this.pinProvided,
  });

  bool get isComplete =>
      mode == SignatureMode.softwareP12 &&
      uploadedP12Name != null &&
      pinProvided;
}

enum SignatureMode {
  /// Upload a PKCS#12 `.p12` file — the only path available in the
  /// MVP. Produces a `SoftwareP12Ref`.
  softwareP12,

  /// Future: hardware token detected via PKCS#11 (VRTV-70). UI shows
  /// the option as disabled with a tooltip today.
  hardwareToken,
}

@immutable
class AtenaCredentialsDraft {
  final String username;
  final String clientId;

  /// `true` iff the user has supplied a password in-session. We never
  /// retain the password in state — only the fact it was entered.
  final bool passwordProvided;

  const AtenaCredentialsDraft({
    required this.username,
    required this.clientId,
    required this.passwordProvided,
  });

  bool get isComplete =>
      username.isNotEmpty && clientId.isNotEmpty && passwordProvided;
}

@immutable
class PlanDraft {
  final AgentPlan plan;
  const PlanDraft({required this.plan});
  bool get isComplete => true;
}

/// The full onboarding draft. Fields are nullable because a user can
/// leave and come back mid-flow.
@immutable
class OnboardingDraft {
  final IdentityDraft? identity;
  final PatentDraft? patent;
  final BondDraft? bond;
  final SignatureDraft? signature;
  final AtenaCredentialsDraft? atena;
  final PlanDraft? plan;

  /// Wizard cursor — 0 = welcome, 1 = identity, ..., 7 = confirmation.
  final int currentStep;

  const OnboardingDraft({
    this.identity,
    this.patent,
    this.bond,
    this.signature,
    this.atena,
    this.plan,
    this.currentStep = 0,
  });

  OnboardingDraft copyWith({
    IdentityDraft? identity,
    PatentDraft? patent,
    BondDraft? bond,
    SignatureDraft? signature,
    AtenaCredentialsDraft? atena,
    PlanDraft? plan,
    int? currentStep,
  }) {
    return OnboardingDraft(
      identity: identity ?? this.identity,
      patent: patent ?? this.patent,
      bond: bond ?? this.bond,
      signature: signature ?? this.signature,
      atena: atena ?? this.atena,
      plan: plan ?? this.plan,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get isReadyToSubmit =>
      (identity?.isComplete ?? false) &&
      (patent?.isComplete ?? false) &&
      (bond?.isComplete ?? false) &&
      (signature?.isComplete ?? false) &&
      (atena?.isComplete ?? false) &&
      (plan?.isComplete ?? false);
}
