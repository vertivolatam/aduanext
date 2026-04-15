/// Shelf middleware that authenticates the incoming request and binds
/// a [RequestContext] to it before delegating downstream.
///
/// Contract:
/// * Looks for `Authorization: Bearer <jwt>`. Missing → 401
///   `MISSING_TOKEN`.
/// * Looks for `X-Tenant-Id: <tenant-id>` (optional — endpoints that do
///   not need tenant context simply do not call `requireTenant`).
/// * Calls the supplied factory to validate the JWT (signature, exp,
///   nbf, issuer, audience). Invalid signature → 401 `INVALID_TOKEN`;
///   expired → 401 `EXPIRED_TOKEN`; malformed claims → 401
///   `INVALID_TOKEN` (we keep the same code so the client never has to
///   distinguish — both mean "log in again").
/// * On success: attaches a [RequestContext] holding the user, the
///   selected tenant id, the request-scoped [AuthorizationPort], and a
///   correlation id (taken from `X-Request-Id` if present; otherwise
///   freshly generated).
///
/// The middleware is provider-agnostic: it accepts a [PortFactory]
/// callback so tests can wire an in-memory adapter and prod wires the
/// Keycloak adapter through the [AppContainer].
library;

import 'dart:math';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../http/error_responses.dart';
import '../http/request_context.dart';

final _log = Logger('aduanext.auth');

/// Build an [AuthorizationPort] from a Bearer token + tenant hint.
typedef PortFactory = Future<AuthorizationPort> Function({
  required String? bearerToken,
  required String? selectedTenantId,
});

/// Construct the middleware. The factory is request-scoped — it must
/// return a port whose `currentUser()` answers the JWT subject.
Middleware authMiddleware(PortFactory portFactory) {
  return (Handler inner) {
    return (Request request) async {
      final requestId = _resolveRequestId(request);

      final bearer = _extractBearer(request);
      final tenantId = request.headers['x-tenant-id'];

      if (bearer == null) {
        return errorResponse(
          status: 401,
          error: 'authentication_required',
          code: ErrorCodes.missingToken,
          message: 'Missing or malformed Authorization header',
          requestId: requestId,
        );
      }

      final AuthorizationPort port;
      try {
        port = await portFactory(
          bearerToken: bearer,
          selectedTenantId: tenantId,
        );
      } on AuthenticationException catch (e) {
        final code = switch (e.vendorCode) {
          'expired' => ErrorCodes.expiredToken,
          _ => ErrorCodes.invalidToken,
        };
        _log.fine('Auth rejected: ${e.message} (${e.vendorCode})');
        return errorResponse(
          status: 401,
          error: 'authentication_failed',
          code: code,
          message: e.message,
          requestId: requestId,
        );
      } catch (e, st) {
        _log.warning('Unexpected auth failure', e, st);
        return errorResponse(
          status: 401,
          error: 'authentication_failed',
          code: ErrorCodes.invalidToken,
          message: 'Token could not be processed',
          requestId: requestId,
        );
      }

      final context = RequestContext(
        user: port.currentUser(),
        selectedTenantId: tenantId,
        authorization: port,
        requestId: requestId,
      );

      return inner(request.withRequestContext(context));
    };
  };
}

String? _extractBearer(Request request) {
  final raw = request.headers['authorization'];
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  // Case-insensitive "Bearer " prefix.
  if (trimmed.length < 8 ||
      trimmed.substring(0, 7).toLowerCase() != 'bearer ') {
    return null;
  }
  final token = trimmed.substring(7).trim();
  return token.isEmpty ? null : token;
}

String _resolveRequestId(Request request) {
  final upstream = request.headers['x-request-id'];
  if (upstream != null && upstream.isNotEmpty) return upstream;
  return _generateRequestId();
}

final _rng = Random.secure();
String _generateRequestId() {
  // 8 bytes = 16 hex chars — enough entropy to avoid collisions in
  // logs without bloating the response. Prefix `req_` so log greps
  // are unambiguous.
  final bytes = List<int>.generate(8, (_) => _rng.nextInt(256));
  final hex =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return 'req_$hex';
}
