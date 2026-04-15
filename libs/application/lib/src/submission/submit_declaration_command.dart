/// Command: SubmitDeclaration — orchestrates the full "prepare, sign,
/// transmit" flow for a DUA (North Star use case).
///
/// Maps to SOP-B05 and closes the 4-step choreography required by the
/// ATENA DUA API:
///
///   1. authenticate(credentials)
///   2. validateDeclaration (dry-run)
///   3. sign(payload)
///   4. submitDeclaration (= liquidate in ATENA)
///
/// Each step must be audited (SRD priority rule #4) with a dedicated
/// event in the per-entity chain — see [SubmitDeclarationHandler].
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:meta/meta.dart';

import '../shared/command.dart';
import 'signing_credentials.dart';

/// Submit a [Declaration] to the customs gateway.
///
/// This is a write-through command: if the handler returns `Ok`, the
/// declaration has been successfully registered in ATENA (or the
/// country-specific equivalent) and the audit trail is complete.
@immutable
class SubmitDeclarationCommand extends Command<DeclarationResult> {
  /// Stable agent identifier — logged as `actorId` in every audit event
  /// emitted by the handler.
  final String agentId;

  /// Tenant scope — multi-tenant isolation.
  final String tenantId;

  /// Declaration payload exactly as it should be sent to the customs
  /// authority. Field names match the ATENA JSON schema (SRD rule #7).
  final Declaration declaration;

  /// Credentials for authenticating with the customs authority.
  ///
  /// We intentionally keep these on the command (not a session store)
  /// because the "logged-in" state is established per-submission in the
  /// ATENA ROPC flow — there is no long-lived session cookie. The
  /// handler invokes [AuthProviderPort.authenticate] at the start of
  /// the flow and does NOT cache the token.
  final Credentials credentials;

  /// Stable identifier for this declaration in our system. Used as the
  /// [AuditEvent.entityId] so every event for this submission lives in
  /// the same per-entity chain, even before ATENA assigns a registration
  /// number.
  ///
  /// Typically the database primary key of the draft declaration row.
  final String declarationId;

  /// How to obtain the digital signature. Defaults to
  /// [SoftwareCertCredentials] so existing call sites (tests, sandbox)
  /// that don't know about hardware tokens keep working unchanged.
  /// Hardware paths provide [HardwareTokenCredentials] with the slot +
  /// PIN selected by the agent at submission time.
  final SigningCredentials signingCredentials;

  const SubmitDeclarationCommand({
    required this.agentId,
    required this.tenantId,
    required this.declarationId,
    required this.declaration,
    required this.credentials,
    this.signingCredentials = const SoftwareCertCredentials(),
  });
}
