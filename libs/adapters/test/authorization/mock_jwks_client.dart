/// Minimal mock [http.Client] that lets tests script the JWKS response —
/// body, status, number of failures before success — without touching
/// any real HTTP stack.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MockJwksClient extends http.BaseClient {
  String body;
  int statusCode;
  int callCount = 0;

  /// If >0, the first N calls return 503 before switching to [body].
  int failuresBeforeSuccess;

  /// If true, EVERY call throws a SocketException-like error — use to
  /// simulate the endpoint being completely down.
  bool alwaysFail;

  MockJwksClient({
    required this.body,
    this.statusCode = 200,
    this.failuresBeforeSuccess = 0,
    this.alwaysFail = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount += 1;
    if (alwaysFail) {
      throw Exception('Simulated JWKS endpoint outage');
    }
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      return http.StreamedResponse(
        const Stream.empty(),
        503,
        request: request,
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode(body)]),
      statusCode,
      request: request,
    );
  }
}
