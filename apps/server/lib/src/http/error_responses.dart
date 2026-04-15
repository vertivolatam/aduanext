/// Standardized error JSON shape for the AduaNext HTTP API.
///
/// Stable contract — the Flutter Web client (and any future SDK
/// consumer) depends on the field names and the `code` enum. NEVER
/// rename a field or change a code without coordinating a client
/// release.
///
/// Example:
///
/// ```json
/// {
///   "error": "authorization_failed",
///   "code": "INSUFFICIENT_ROLE",
///   "message": "This action requires role: agent",
///   "request_id": "req_3b1c"
/// }
/// ```
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Stable error code enum surfaced in JSON. Values are SCREAMING_SNAKE
/// to match the convention agreed with frontend.
class ErrorCodes {
  ErrorCodes._();

  static const missingToken = 'MISSING_TOKEN';
  static const invalidToken = 'INVALID_TOKEN';
  static const expiredToken = 'EXPIRED_TOKEN';
  static const insufficientRole = 'INSUFFICIENT_ROLE';
  static const wrongTenant = 'WRONG_TENANT';
  static const userDisabled = 'USER_DISABLED';
  static const internalError = 'INTERNAL_ERROR';
}

/// Build a JSON [Response] with the standardized error shape.
Response errorResponse({
  required int status,
  required String error,
  required String code,
  required String message,
  required String requestId,
}) {
  return Response(
    status,
    body: jsonEncode({
      'error': error,
      'code': code,
      'message': message,
      'request_id': requestId,
    }),
    headers: const {'content-type': 'application/json'},
  );
}
