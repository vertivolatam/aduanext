/// Handler for [SubmitDeclarationCommand] — the North Star use case.
///
/// Choreography:
///
///   Audit #1: submit.requested
///   ├── authenticate(credentials)
///   Audit #2: submit.authenticated      (on success)
///   ├── validateDeclaration (dry-run)
///   │   └── Audit #3a: submit.validation-failed  (on validation errors)
///   Audit #3: submit.validated           (on pass)
///   ├── signing.sign(payload)
///   │   └── Audit #4a: submit.signing-failed
///   Audit #4: submit.signed
///   └── submitDeclaration
///       ├── Audit #5a: submit.gateway-rejected
///       └── Audit #5:  submit.accepted
///
/// Audit append failures propagate as exceptions (SRD rule #4 —
/// never swallow). The boundary layer is responsible for translating
/// infrastructure failures into HTTP responses.
library;

import 'package:aduanext_domain/aduanext_domain.dart';

import '../shared/command.dart';
import '../shared/result.dart';
import '../validation/pre_validate_declaration_query.dart';
import 'submit_declaration_command.dart';
import 'submit_declaration_failure.dart';

/// Deterministic serializer for the payload that gets signed.
///
/// We keep this as a constructor argument (not a Port) because:
/// * it has zero I/O — it's a pure function from Declaration to String;
/// * the exact wire format (JSON today, XAdES-EPES over JSON tomorrow)
///   is an infrastructure concern that must match what the adapter
///   sends to ATENA — callers are expected to wire the same serializer
///   used by the [CustomsGatewayPort] adapter.
typedef DeclarationPayloadSerializer = String Function(Declaration d);

class SubmitDeclarationHandler
    implements CommandHandler<SubmitDeclarationCommand, DeclarationResult> {
  final AuthProviderPort authProvider;
  final CustomsGatewayPort customsGateway;
  final SigningPort signing;
  final AuditLogPort auditLog;

  /// Request-scoped authorization context. Required: we enforce
  /// role + tenant checks BEFORE any business logic and persist the
  /// actor's role + membership in the audit payload (LGA Art. 28-30 —
  /// every action must be attributable).
  final AuthorizationPort authorization;

  /// Optional pre-submission rule engine (VRTV-42). When provided, the
  /// 9-rule pipeline runs BEFORE the ATENA dry-run `validateDeclaration`
  /// — this saves a gateway round-trip for defects we can catch locally
  /// (HS code format, required fields, incoterm/transport consistency,
  /// ...). Errors short-circuit with [PreValidationFailedFailure];
  /// warnings are logged but do not block.
  final PreValidateDeclarationHandler? preValidate;

  /// Pure function converting the [Declaration] into the exact bytes
  /// that will be signed. Defaults to a stable JSON serialization so
  /// call sites that don't yet have the adapter's serializer wired can
  /// still exercise the handler (notably tests).
  final DeclarationPayloadSerializer serializePayload;

  /// Clock (overridable for tests).
  final DateTime Function() _clock;

  SubmitDeclarationHandler({
    required this.authProvider,
    required this.customsGateway,
    required this.signing,
    required this.auditLog,
    required this.authorization,
    this.preValidate,
    DeclarationPayloadSerializer? serializePayload,
    DateTime Function()? clock,
  })  : serializePayload =
            serializePayload ?? _defaultJsonSerializer,
        _clock = clock ?? DateTime.now;

  @override
  Future<Result<DeclarationResult>> handle(
    SubmitDeclarationCommand command,
  ) async {
    // ── Validate command ───────────────────────────────────────────────
    if (command.agentId.isEmpty) {
      return const Result.err(MissingFieldFailure(fieldName: 'agentId'));
    }
    if (command.tenantId.isEmpty) {
      return const Result.err(MissingFieldFailure(fieldName: 'tenantId'));
    }
    if (command.declarationId.isEmpty) {
      return const Result.err(
          MissingFieldFailure(fieldName: 'declarationId'));
    }
    final structural = _validateStructure(command.declaration);
    if (structural != null) {
      return Result.err(InvalidDeclarationStructureFailure(structural));
    }

    // ── Authorize (role + tenant) ──────────────────────────────────────
    //
    // Must hold at least Role.agent in command.tenantId to submit a DUA.
    // LGA Art. 28-30 requires the acting auxiliar de funcion publica to
    // be identified and licensed; an importer with only the `importer`
    // role CANNOT submit — they must delegate to a contracted agent.
    // An AuthorizationException propagates to the boundary unchanged.
    authorization.requireTenant(command.tenantId);
    authorization.requireRole(Role.agent);
    final actorRole = authorization.currentMembership()?.role;

    // ── Audit #1: submit.requested ─────────────────────────────────────
    await _audit(
      command,
      'submit.requested',
      actorRole: actorRole,
      payload: {
        'declarationId': command.declarationId,
        'exporterCode': command.declaration.exporterCode,
        'declarantCode': command.declaration.declarantCode,
        'itemCount': command.declaration.items.length,
      },
    );

    // ── Step 1: authenticate ───────────────────────────────────────────
    try {
      await authProvider.authenticate(command.credentials);
    } on AuthenticationException catch (e) {
      // Auth denial is a business failure per the hybrid error model —
      // the agent needs to re-enter credentials, not the operator.
      await _audit(
        command,
        'submit.authentication-failed',
        actorRole: actorRole,
        payload: {
          'declarationId': command.declarationId,
          'reason': e.message,
          if (e.vendorCode != null) 'idpErrorCode': e.vendorCode,
        },
      );
      return Result.err(AuthenticationFailedFailure(
        reason: e.message,
        idpErrorCode: e.vendorCode,
      ));
    }

    // ── Audit #2: submit.authenticated ─────────────────────────────────
    await _audit(
      command,
      'submit.authenticated',
      actorRole: actorRole,
      payload: {
        'declarationId': command.declarationId,
      },
    );

    // ── Step 1.5: pre-validate (VRTV-42) ──────────────────────────────
    //
    // When a rule engine is wired, run it BEFORE the ATENA dry-run so
    // we avoid a round-trip for defects we can catch locally. The
    // engine's output lands in the audit trail either way — errors
    // short-circuit the submission; warnings keep going.
    final preValidateHandler = preValidate;
    if (preValidateHandler != null) {
      final report = await preValidateHandler.handle(
        PreValidateDeclarationQuery(declaration: command.declaration),
      );
      if (!report.isSubmittable) {
        await _audit(
          command,
          'submit.pre-validation-failed',
          actorRole: actorRole,
          payload: {
            'declarationId': command.declarationId,
            ...report.toAuditSummary(),
          },
        );
        final first = report.errors.first;
        return Result.err(PreValidationFailedFailure(
          report: report,
          summary:
              '${report.errors.length} error(s) + ${report.warnings.length} warning(s); '
              'first: ${first.ruleCode} — ${first.message}',
        ));
      }
      await _audit(
        command,
        report.isClean
            ? 'submit.pre-validated'
            : 'submit.pre-validated-with-warnings',
        actorRole: actorRole,
        payload: {
          'declarationId': command.declarationId,
          ...report.toAuditSummary(),
        },
      );
    }

    // ── Step 2: validate declaration (dry-run) ─────────────────────────
    final validation =
        await customsGateway.validateDeclaration(command.declaration);
    if (!validation.valid) {
      await _audit(
        command,
        'submit.validation-failed',
        actorRole: actorRole,
        payload: {
          'declarationId': command.declarationId,
          'errors': validation.errors
              .map((e) => {
                    'code': e.code,
                    'message': e.message,
                    if (e.field != null) 'field': e.field,
                  })
              .toList(),
          'warnings': validation.warnings
              .map((w) => {'code': w.code, 'message': w.message})
              .toList(),
        },
      );
      return Result.err(DeclarationValidationFailedFailure(
        errors: validation.errors,
        warnings: validation.warnings,
      ));
    }

    // ── Audit #3: submit.validated ─────────────────────────────────────
    await _audit(
      command,
      'submit.validated',
      actorRole: actorRole,
      payload: {
        'declarationId': command.declarationId,
        'warningCount': validation.warnings.length,
      },
    );

    // ── Step 3: sign ───────────────────────────────────────────────────
    final payloadToSign = serializePayload(command.declaration);
    final signingResult = await signing.sign(payloadToSign);
    if (!signingResult.success) {
      await _audit(
        command,
        'submit.signing-failed',
        actorRole: actorRole,
        payload: {
          'declarationId': command.declarationId,
          'reason': signingResult.errorMessage ?? 'unknown',
        },
      );
      return Result.err(SigningFailedFailure(
        signingResult.errorMessage ?? 'unknown signing error',
      ));
    }

    // ── Audit #4: submit.signed ────────────────────────────────────────
    //
    // We log ONLY the size of the signed bytes — the signed content
    // itself is the privileged artifact and must not be duplicated in
    // the audit trail (the adapter persists it separately when needed).
    final signedBytesLength = signingResult.signedContent?.length ?? 0;
    await _audit(
      command,
      'submit.signed',
      actorRole: actorRole,
      payload: {
        'declarationId': command.declarationId,
        'signedBytesLength': signedBytesLength,
      },
    );

    // ── Step 4: submit ─────────────────────────────────────────────────
    final submission =
        await customsGateway.submitDeclaration(command.declaration);
    if (!submission.success) {
      await _audit(
        command,
        'submit.gateway-rejected',
        actorRole: actorRole,
        payload: {
          'declarationId': command.declarationId,
          'reason': submission.errorMessage ?? 'unknown',
        },
      );
      return Result.err(GatewayRejectedSubmissionFailure(
        reason: submission.errorMessage ?? 'unknown gateway error',
        rawResponse: submission.rawResponse,
      ));
    }

    // ── Audit #5: submit.accepted ──────────────────────────────────────
    await _audit(
      command,
      'submit.accepted',
      actorRole: actorRole,
      payload: {
        'declarationId': command.declarationId,
        if (submission.registrationNumber != null)
          'registrationNumber': submission.registrationNumber,
        if (submission.assessmentNumber != null)
          'assessmentNumber': submission.assessmentNumber,
        if (submission.assessmentSerial != null)
          'assessmentSerial': submission.assessmentSerial,
        if (submission.assessmentDate != null)
          'assessmentDate': submission.assessmentDate,
      },
    );

    return Result.ok(submission);
  }

  /// Cheap structural guardrail — stops obvious junk before we burn a
  /// gateway round-trip. Full field-level validation is VRTV-42.
  String? _validateStructure(Declaration d) {
    if (d.exporterCode.isEmpty) return 'exporterCode is empty';
    if (d.declarantCode.isEmpty) return 'declarantCode is empty';
    if (d.officeOfDispatchExportCode.isEmpty) {
      return 'officeOfDispatchExportCode is empty';
    }
    if (d.officeOfEntryCode.isEmpty) return 'officeOfEntryCode is empty';
    if (d.items.isEmpty) return 'items list is empty';
    for (final (i, item) in d.items.indexed) {
      if (item.commercialDescription.trim().length < 5) {
        return 'items[$i].commercialDescription must be at least 5 characters';
      }
      if (item.procedure.itemCountryOfOriginCode.isEmpty) {
        return 'items[$i].procedure.itemCountryOfOriginCode is empty';
      }
      if (item.procedure.extendedProcedureCode.isEmpty) {
        return 'items[$i].procedure.extendedProcedureCode is empty';
      }
    }
    return null;
  }

  Future<void> _audit(
    SubmitDeclarationCommand command,
    String action, {
    required Map<String, dynamic> payload,
    Role? actorRole,
  }) {
    // Stitch the actor's role into every audit payload per LGA Art. 28-30
    // (every logged action must be attributable to a specific role —
    // agent / supervisor / admin — not just a user id).
    final enriched = <String, dynamic>{
      if (actorRole != null) 'actorRole': actorRole.code,
      ...payload,
    };
    return auditLog.append(
      AuditEvent.draft(
        entityType: 'Declaration',
        entityId: command.declarationId,
        action: action,
        actorId: command.agentId,
        tenantId: command.tenantId,
        payload: enriched,
        clientTimestamp: _clock().toUtc(),
      ),
    );
  }
}

/// Default payload serializer — stable, sorted-key JSON of the subset
/// of fields that uniquely identify a Declaration submission.
///
/// This is NOT the wire format sent to ATENA (that lives in the
/// CustomsGatewayPort adapter). It's the canonical "what I signed"
/// payload; tests use it, and call sites that wire the adapter's real
/// serializer must override [SubmitDeclarationHandler.serializePayload].
String _defaultJsonSerializer(Declaration d) {
  final buf = StringBuffer('{')
    ..write('"declarantCode":"${d.declarantCode}",')
    ..write('"exporterCode":"${d.exporterCode}",')
    ..write('"generalProcedureCode":"${d.generalProcedureCode}",')
    ..write('"itemCount":${d.items.length},')
    ..write('"officeOfDispatchExportCode":"${d.officeOfDispatchExportCode}",')
    ..write('"officeOfEntryCode":"${d.officeOfEntryCode}",')
    ..write('"typeOfDeclaration":"${d.typeOfDeclaration}"')
    ..write('}');
  return buf.toString();
}
