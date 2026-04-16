/// REST endpoints for DUA dispatch — the North Star loop wire-up.
///
/// Responsibilities:
/// * Parse + validate the request body (body-size gate, JSON decode,
///   [parseSubmitDispatchRequest]).
/// * Build a request-scoped [SubmitDeclarationHandler] using the
///   container's singletons + the per-request [AuthorizationPort].
/// * Invoke the handler, map [SubmitDeclarationFailure] to HTTP, and
///   catch infrastructure exceptions (`AuthorizationException`,
///   unexpected throws) per the hybrid error model.
/// * Emit structured logs at the dispatch-request boundary — without
///   PINs / p12 bytes / bearer tokens (the security reviewers will
///   grep for these, so the fields actually logged are spelled out
///   below).
///
/// Logged fields per submit request:
/// * `dispatch.submit.received` — declarationId, tenantId, actorId,
///   credentialType (`software` | `hardware`).
/// * `dispatch.submit.success` — declarationId, customsRegistrationNumber.
/// * `dispatch.submit.failure` — declarationId, errorCode (never the
///   underlying reason verbatim — that lives only in the audit log).
///
/// The rectify / get / list endpoints are intentionally thin —
/// they expose the routing surface expected by the Flutter client
/// (VRTV-45 dashboard) but return 501 until the read model lands.
/// Tracked as separate issues so we don't grow this PR beyond
/// "closes the North Star loop".
library;

import 'dart:async';
import 'dart:convert';

import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'dispatch_payload.dart';
import 'error_mapping.dart';
import 'error_responses.dart';
import 'request_context.dart';

/// Hard cap on the submit body size (2 MiB). Declarations + base64
/// cert bytes sit around 200-400 KB in practice; 2 MiB leaves
/// headroom without inviting abuse.
const int maxRequestBodyBytes = 2 * 1024 * 1024;

/// Dependencies the dispatch endpoints need beyond the per-request
/// [AuthorizationPort]. The AppContainer constructs one of these and
/// hands it to the endpoint handlers; the endpoints then build a
/// fresh [SubmitDeclarationHandler] per request (the handler's
/// authorization dependency is request-scoped).
class DispatchEndpointDeps {
  final AuthProviderPort authProvider;
  final CustomsGatewayPort customsGateway;
  final SigningPort? signing;
  final Pkcs11SigningPort? pkcs11Signing;
  final AuditLogPort auditLog;
  final PreValidateDeclarationHandler? preValidate;

  const DispatchEndpointDeps({
    required this.authProvider,
    required this.customsGateway,
    required this.auditLog,
    this.signing,
    this.pkcs11Signing,
    this.preValidate,
  });
}

/// Collects the dispatch endpoint handlers so they can be registered
/// on the router in one place.
class DispatchEndpoints {
  final DispatchEndpointDeps _deps;
  final Logger _log;

  DispatchEndpoints({
    required DispatchEndpointDeps deps,
    Logger? logger,
  })  : _deps = deps,
        _log = logger ?? Logger('aduanext.dispatch');

  /// POST /api/v1/dispatches/submit
  Future<Response> submit(Request request) async {
    final ctx = request.requestContext;

    // ── 1. Size gate ─────────────────────────────────────────────
    //
    // Prefer the declared Content-Length as a cheap bail-out; enforce
    // the same cap while streaming the body so a missing/lying header
    // doesn't let us through.
    final declaredLen = request.contentLength;
    if (declaredLen != null && declaredLen > maxRequestBodyBytes) {
      _log.fine(
        'dispatch.submit.rejected tenant=${ctx.selectedTenantId} '
        'reason=content_length_exceeds_limit declared=$declaredLen',
      );
      return errorResponse(
        status: 413,
        error: 'payload_too_large',
        code: DispatchErrorCodes.payloadTooLarge,
        message: 'Request body exceeds $maxRequestBodyBytes bytes',
        requestId: ctx.requestId,
      );
    }

    final String rawBody;
    try {
      rawBody = await _readBodyWithCap(request, maxRequestBodyBytes);
    } on _BodyTooLargeException {
      return errorResponse(
        status: 413,
        error: 'payload_too_large',
        code: DispatchErrorCodes.payloadTooLarge,
        message: 'Request body exceeds $maxRequestBodyBytes bytes',
        requestId: ctx.requestId,
      );
    }

    // ── 2. JSON decode ───────────────────────────────────────────
    final Object? decoded;
    try {
      decoded = rawBody.isEmpty ? null : jsonDecode(rawBody);
    } on FormatException catch (e) {
      return errorResponse(
        status: 400,
        error: 'malformed_request',
        code: DispatchErrorCodes.malformedRequest,
        // `e.message` from jsonDecode is short and does not echo the
        // body content itself (it only carries the parser state). Safe
        // to surface.
        message: 'Request body is not valid JSON: ${e.message}',
        requestId: ctx.requestId,
      );
    }

    // ── 3. Parse into typed DTO ─────────────────────────────────
    final SubmitDispatchRequest parsed;
    try {
      parsed = parseSubmitDispatchRequest(decoded);
    } on DispatchPayloadException catch (e) {
      return errorResponse(
        status: e.malformed ? 400 : 422,
        error: e.malformed ? 'malformed_request' : 'validation_failed',
        code: e.malformed
            ? DispatchErrorCodes.malformedRequest
            : DispatchErrorCodes.preValidationFailed,
        message: e.message,
        requestId: ctx.requestId,
      );
    }

    // ── 4. Fail-fast for hardware creds when no helper is wired ──
    //
    // The SubmitDeclarationHandler also checks this (VRTV-71), but
    // bailing here skips an audit round-trip for a mis-configured
    // server and returns an actionable error code to the UI.
    if (parsed.signingCredentials is HardwareTokenCredentials &&
        _deps.pkcs11Signing == null) {
      return errorResponse(
        status: 503,
        error: 'hardware_unavailable',
        code: DispatchErrorCodes.hardwareUnavailable,
        message:
            'Hardware-token signing is not configured on this server',
        requestId: ctx.requestId,
      );
    }

    // Similarly fail-fast for software creds when no software signer
    // is configured — this keeps the container's null state legible
    // on the wire rather than manifesting as a SigningFailedFailure
    // with an opaque "signing port null" message.
    if (parsed.signingCredentials is SoftwareCertCredentials &&
        _deps.signing == null) {
      return errorResponse(
        status: 503,
        error: 'software_signing_unavailable',
        code: DispatchErrorCodes.signingFailed,
        message:
            'Software certificate signing is not configured on this '
            'server; the HACIENDA_P12_PATH + HACIENDA_P12_PIN '
            'environment variables must be set',
        requestId: ctx.requestId,
      );
    }

    final tenantId = ctx.selectedTenantId;
    if (tenantId == null || tenantId.isEmpty) {
      // Guard would have caught this upstream; defence in depth.
      return errorResponse(
        status: 400,
        error: 'tenant_required',
        code: ErrorCodes.wrongTenant,
        message: 'Missing X-Tenant-Id header',
        requestId: ctx.requestId,
      );
    }

    final actorId = ctx.user.id;
    _log.info(
      'dispatch.submit.received '
      'declarationId=${parsed.declarationId} '
      'tenantId=$tenantId actorId=$actorId '
      'credentialType=${_credentialTypeOf(parsed.signingCredentials)} '
      'requestId=${ctx.requestId}',
    );

    // ── 5. Build a request-scoped handler ───────────────────────
    //
    // The handler needs the per-request AuthorizationPort so its
    // `requireRole(Role.agent)` + `requireTenant(tenantId)` checks
    // enforce against the caller's JWT. Every other dep is a
    // singleton from the container.
    final handler = SubmitDeclarationHandler(
      authProvider: _deps.authProvider,
      customsGateway: _deps.customsGateway,
      // The dispatch contract enforces that software creds require a
      // signing port above; the `!` is guarded.
      signing: _deps.signing ?? _NullSigningPort(),
      pkcs11Signing: _deps.pkcs11Signing,
      auditLog: _deps.auditLog,
      authorization: ctx.authorization,
      preValidate: _deps.preValidate,
    );

    final command = SubmitDeclarationCommand(
      agentId: actorId,
      tenantId: tenantId,
      declarationId: parsed.declarationId,
      declaration: parsed.declaration,
      credentials: parsed.authCredentials,
      signingCredentials: parsed.signingCredentials,
    );

    // ── 6. Execute + translate outcome ──────────────────────────
    final Result<DeclarationResult> outcome;
    try {
      outcome = await handler.handle(command);
    } on AuthorizationException catch (e) {
      // Role-guard already validated that the caller holds ≥
      // Role.agent, but `requireTenant` inside the handler re-checks
      // the tenant scope with the Declaration's tenantId (which
      // currently mirrors X-Tenant-Id but may diverge in the future
      // for delegated submissions). If that check fails we translate
      // per the same vocabulary the auth middleware uses.
      _log.warning(
        'dispatch.submit.authz_failed '
        'requestId=${ctx.requestId} code=${e.code}',
      );
      final (status, code) = switch (e.code) {
        'tenant-denied' || 'tenant-not-selected' => (
            403,
            ErrorCodes.wrongTenant
          ),
        'role-denied' => (403, ErrorCodes.insufficientRole),
        'unauthenticated' => (401, ErrorCodes.missingToken),
        _ => (403, ErrorCodes.insufficientRole),
      };
      return errorResponse(
        status: status,
        error: 'authorization_failed',
        code: code,
        message: e.message,
        requestId: ctx.requestId,
      );
    } catch (e, st) {
      _log.severe(
        'dispatch.submit.unexpected requestId=${ctx.requestId} '
        'declarationId=${parsed.declarationId}',
        e,
        st,
      );
      return errorResponse(
        status: 500,
        error: 'internal_error',
        code: ErrorCodes.internalError,
        message: 'An unexpected error occurred while submitting the '
            'declaration',
        requestId: ctx.requestId,
      );
    }

    return switch (outcome) {
      Ok<DeclarationResult>(:final value) =>
        _successResponse(parsed, value, ctx.requestId),
      Err<DeclarationResult>(:final failure) => _failureResponse(
          parsed,
          failure,
          ctx.requestId,
        ),
    };
  }

  /// POST /api/v1/dispatches/{id}/rectify
  ///
  /// Placeholder — rectification flow (VRTV-48) is not yet wired to a
  /// use case. We accept the route so the Flutter client can discover
  /// it via the OpenAPI spec; it consistently returns 501 until the
  /// use case lands.
  Future<Response> rectify(Request request) async {
    final ctx = request.requestContext;
    final id = request.params['id'] ?? 'unknown';
    _log.fine(
      'dispatch.rectify.not_implemented requestId=${ctx.requestId} '
      'dispatchId=$id',
    );
    return errorResponse(
      status: 501,
      error: 'not_implemented',
      code: DispatchErrorCodes.notImplemented,
      message: 'Dispatch rectification is not yet implemented '
          '(tracked as VRTV-48)',
      requestId: ctx.requestId,
    );
  }

  /// GET /api/v1/dispatches/{id}
  ///
  /// Placeholder — the read model for dispatches lives alongside the
  /// dashboard issue (VRTV-45) and is not in scope for this PR. The
  /// route is registered so it returns a stable 501 instead of a
  /// 404 with a generic router message.
  Future<Response> get(Request request) async {
    final ctx = request.requestContext;
    final id = request.params['id'] ?? 'unknown';
    _log.fine(
      'dispatch.get.not_implemented requestId=${ctx.requestId} '
      'dispatchId=$id',
    );
    return errorResponse(
      status: 501,
      error: 'not_implemented',
      code: DispatchErrorCodes.notImplemented,
      message: 'Dispatch retrieval is not yet implemented '
          '(tracked as VRTV-45)',
      requestId: ctx.requestId,
    );
  }

  /// GET /api/v1/dispatches
  ///
  /// Placeholder — see [get].
  Future<Response> list(Request request) async {
    final ctx = request.requestContext;
    _log.fine(
      'dispatch.list.not_implemented requestId=${ctx.requestId}',
    );
    return errorResponse(
      status: 501,
      error: 'not_implemented',
      code: DispatchErrorCodes.notImplemented,
      message: 'Dispatch listing is not yet implemented '
          '(tracked as VRTV-45)',
      requestId: ctx.requestId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  Response _successResponse(
    SubmitDispatchRequest parsed,
    DeclarationResult result,
    String requestId,
  ) {
    _log.info(
      'dispatch.submit.success requestId=$requestId '
      'declarationId=${parsed.declarationId} '
      'customsRegistrationNumber=${result.registrationNumber}',
    );
    final body = SubmitDispatchResponse(
      declarationId: parsed.declarationId,
      status: 'accepted',
      customsRegistrationNumber: result.registrationNumber,
      assessmentSerial: result.assessmentSerial,
      assessmentNumber: result.assessmentNumber,
      assessmentDate: result.assessmentDate,
    );
    return Response.ok(
      jsonEncode(body.toJson()),
      headers: const {'content-type': 'application/json'},
    );
  }

  Response _failureResponse(
    SubmitDispatchRequest parsed,
    Failure failure,
    String requestId,
  ) {
    final mapped = mapSubmitFailure(failure);
    _log.info(
      'dispatch.submit.failure requestId=$requestId '
      'declarationId=${parsed.declarationId} '
      'code=${mapped.code} status=${mapped.status}',
    );
    return Response(
      mapped.status,
      body: jsonEncode({
        'error': mapped.error,
        'code': mapped.code,
        'message': mapped.message,
        'request_id': requestId,
        if (mapped.details != null) 'details': mapped.details,
      }),
      headers: const {'content-type': 'application/json'},
    );
  }

  static String _credentialTypeOf(SigningCredentials c) => switch (c) {
        SoftwareCertCredentials() => 'software',
        HardwareTokenCredentials() => 'hardware',
      };
}

/// Read the full request body while enforcing [cap]. Throws
/// [_BodyTooLargeException] as soon as the running total exceeds the
/// cap so we don't buffer a pathological body in memory.
Future<String> _readBodyWithCap(Request request, int cap) async {
  final completer = Completer<String>();
  final buffer = <int>[];
  late final StreamSubscription<List<int>> sub;
  sub = request.read().listen(
    (chunk) {
      buffer.addAll(chunk);
      if (buffer.length > cap) {
        sub.cancel();
        if (!completer.isCompleted) {
          completer.completeError(const _BodyTooLargeException());
        }
      }
    },
    onError: (Object e, StackTrace st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete(utf8.decode(buffer, allowMalformed: false));
      }
    },
    cancelOnError: true,
  );
  return completer.future;
}

class _BodyTooLargeException implements Exception {
  const _BodyTooLargeException();
}

/// Stand-in [SigningPort] that returns a failure result. The dispatch
/// endpoint short-circuits software submissions when `signing == null`
/// (see [DispatchEndpoints.submit]) so the `sign` path is never
/// actually invoked; it exists only because
/// [SubmitDeclarationHandler] requires a non-nullable `signing`
/// parameter. Replacing the handler's field with a nullable would
/// ripple into VRTV-38 tests — leave it alone.
///
/// Every verify method throws because the dispatch endpoint never
/// invokes them; if it ever does, we prefer a loud error over a
/// silently-passing "unverified=true" that could be misread as a good
/// signature.
class _NullSigningPort
    with DetailedVerificationBooleanWrapper
    implements SigningPort {
  @override
  Future<SigningResult> sign(String content) async {
    return const SigningResult(
      success: false,
      errorMessage: 'Software signing is not configured on this server',
    );
  }

  @override
  Future<SigningResult> signAndEncode(String content) => sign(content);

  @override
  Future<VerificationResult> verifySignatureDetailed(
    String signedContent,
  ) async {
    throw StateError(
      '_NullSigningPort.verifySignatureDetailed must not be called '
      '— the dispatch endpoint short-circuits before signing',
    );
  }
}
