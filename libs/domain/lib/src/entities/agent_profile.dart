/// AgentProfile — the compliance-visible profile of a licensed customs
/// agent (auxiliar de funcion publica, LGA Art. 28).
///
/// Attached one-to-one to a `User` when they complete SOP-A01
/// (freelance agent onboarding). Carries the data that has to be
/// verifiable at audit time: patente DGA, caucion, digital-signing
/// material reference.
///
/// Kept deliberately narrow — NO payment data, NO credentials in
/// plaintext, NO token PINs. Those live in their own dedicated
/// encrypted-at-rest stores.
library;

import 'package:meta/meta.dart';

/// Kind of caucion (bond) the agent has on file. LGA + RLGA recognise
/// several instruments; we enumerate the legally-acceptable ones so
/// the onboarding UI + downstream compliance reports can distinguish
/// them without free-text parsing.
enum BondType {
  /// Cheque certificado a favor de la DGA.
  certifiedCheque,

  /// Bono de fidelidad emitido por INS.
  insFidelityBond,

  /// Fideicomiso de garantia.
  trustGuarantee,

  /// Carta de credito stand-by.
  standbyCredit,

  /// Efectivo depositado en Tesoreria Nacional.
  cashDeposit,
}

/// Reference to the signing material the agent will use to sign DUAs.
///
/// A real production agent MUST use a hardware-backed BCCR Firma
/// Digital token (PKCS#11 — tracked under VRTV-56 / VRTV-69-71). This
/// domain model carries both the software-`.p12` and the hardware-slot
/// variants so the UI can degrade gracefully until the PKCS#11 path
/// ships.
sealed class SigningMaterialRef {
  const SigningMaterialRef();
}

/// Software-backed signing — acceptable for dev / education / MVP.
/// NEVER for real DUA submission (BCCR + Hacienda reject it).
class SoftwareP12Ref extends SigningMaterialRef {
  /// Opaque storage id — the bytes + PIN live in a sealed-secret
  /// vault, NEVER in the domain.
  final String storageId;

  /// Certificate fingerprint for audit logs (SHA-256 hex).
  final String certificateFingerprint;

  /// When the certificate expires (UTC).
  final DateTime certificateExpiresAt;

  const SoftwareP12Ref({
    required this.storageId,
    required this.certificateFingerprint,
    required this.certificateExpiresAt,
  });
}

/// Hardware-backed signing via a PKCS#11 token.
class HardwareTokenRef extends SigningMaterialRef {
  /// Opaque slot id reported by the PKCS#11 helper (VRTV-69).
  final int slotId;

  /// Human-readable label reported by the token
  /// (e.g. "BCCR IDPrime MD 830").
  final String tokenLabel;

  /// Certificate fingerprint for audit logs.
  final String certificateFingerprint;

  /// When the certificate expires (UTC).
  final DateTime certificateExpiresAt;

  const HardwareTokenRef({
    required this.slotId,
    required this.tokenLabel,
    required this.certificateFingerprint,
    required this.certificateExpiresAt,
  });
}

@immutable
class AgentProfile {
  /// Matches `User.id` one-to-one.
  final String userId;

  /// Matches `Tenant.id` — a freelance agent's own tenant (TenantType.
  /// freelanceAgent) is created by the onboarding flow.
  final String tenantId;

  /// Cedula fisica (Costa Rican national id). Format varies — kept as
  /// free-form string since we do not normalise here.
  final String cedula;

  /// Full legal name as registered with DGA.
  final String legalName;

  /// DGA patent number. Stable over the lifetime of the agent's
  /// licence.
  final String patentNumber;

  /// Date the DGA issued the patent (UTC).
  final DateTime patentIssuedAt;

  /// Optional storage id of the uploaded patent PDF (fallback when the
  /// DGA public registry call is unavailable).
  final String? patentDocumentStorageId;

  /// Caucion amount (in CRC — Costa Rican colones — to match Hacienda
  /// reporting). Legal floor: 20 000 000 CRC per LGA Art. 58.
  final int bondAmountCrc;

  final BondType bondType;

  /// When the caucion lapses (UTC).
  final DateTime bondExpiresAt;

  /// Storage id of the uploaded caucion document. Required — the
  /// onboarding flow rejects submissions without a document.
  final String bondDocumentStorageId;

  /// ATENA username (Keycloak) — encrypted-at-rest in the real store.
  /// The domain holds a reference, never the plaintext.
  final String atenaUsernameStorageId;

  /// ATENA client id (`DECLARACION` or `URIMM`).
  final String atenaClientId;

  /// Signing material reference — software .p12 OR hardware token.
  final SigningMaterialRef signingMaterial;

  /// Plan the agent selected during onboarding. Stable enum so billing
  /// can reconcile without free-text parsing.
  final AgentPlan plan;

  const AgentProfile({
    required this.userId,
    required this.tenantId,
    required this.cedula,
    required this.legalName,
    required this.patentNumber,
    required this.patentIssuedAt,
    required this.bondAmountCrc,
    required this.bondType,
    required this.bondExpiresAt,
    required this.bondDocumentStorageId,
    required this.atenaUsernameStorageId,
    required this.atenaClientId,
    required this.signingMaterial,
    required this.plan,
    this.patentDocumentStorageId,
  });

  /// `true` iff the caucion is active at [now].
  bool isBondActiveAt(DateTime now) =>
      now.toUtc().isBefore(bondExpiresAt.toUtc());

  /// Legal floor for the bond, CAUCA / LGA Art. 58 (20 000 000 CRC).
  static const int bondLegalMinimumCrc = 20000000;
}

/// AduaNext subscription plans for freelance agents.
enum AgentPlan {
  /// USD 60 / month — solo freelance.
  solo(monthlyUsd: 60),

  /// USD 300 / month — small practice (up to 5 concurrent agents).
  smallPractice(monthlyUsd: 300),

  /// USD 1200 / month — agency (unlimited agents in one tenant).
  agency(monthlyUsd: 1200);

  final int monthlyUsd;
  const AgentPlan({required this.monthlyUsd});
}
