/// JWKS cache — fetches Keycloak's JWKS endpoint once per TTL window
/// and exposes RSA public keys keyed by `kid`.
///
/// Design notes:
/// * TTL default 15 min per VRTV-60 spec; overridable for tests.
/// * Refetch-on-miss: if a requested [kid] is not in the cached set, we
///   force a refresh before giving up. This protects against key rotation
///   happening mid-TTL.
/// * Degraded mode: if a refresh fails AND we still hold a cached copy
///   younger than [gracePeriod] beyond its TTL, we return the stale set
///   so in-flight requests do not cascade-fail during a brief JWKS outage.
///   If no cache is available at all, the fetch exception propagates.
/// * Thread safety (isolate-local): we dedupe concurrent refreshes with
///   a single pending `Future`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/asymmetric/api.dart';

/// A single JWKS entry — RSA public key + source kid.
class JwksKey {
  final String kid;
  final String kty; // RSA, EC, ...
  final String alg; // RS256, ES256, ...
  final String use; // sig, enc
  final RSAPublicKey rsaPublicKey;

  const JwksKey({
    required this.kid,
    required this.kty,
    required this.alg,
    required this.use,
    required this.rsaPublicKey,
  });
}

/// Thrown when the JWKS endpoint is reachable but returns an unusable
/// payload (HTTP >= 400, malformed JSON, no RSA keys). Callers should
/// surface this as `AuthenticationException` when no cache fallback
/// applies — never as a generic 500.
class JwksFetchException implements Exception {
  final String message;
  const JwksFetchException(this.message);
  @override
  String toString() => 'JwksFetchException: $message';
}

/// Cached JWKS fetcher.
class JwksCache {
  final Uri jwksUri;
  final Duration ttl;
  final Duration gracePeriod;
  final http.Client _client;
  final DateTime Function() _now;

  Map<String, JwksKey>? _keys;
  DateTime? _fetchedAt;
  Future<Map<String, JwksKey>>? _inflight;

  JwksCache({
    required this.jwksUri,
    this.ttl = const Duration(minutes: 15),
    this.gracePeriod = const Duration(minutes: 30),
    http.Client? httpClient,
    DateTime Function()? now,
  })  : _client = httpClient ?? http.Client(),
        _now = now ?? DateTime.now;

  /// Returns the key for [kid], fetching/refetching as needed.
  /// Returns `null` if the kid is not present in the live JWKS.
  Future<JwksKey?> keyForKid(String kid) async {
    final fresh = _fresh();
    if (fresh != null && fresh.containsKey(kid)) return fresh[kid];

    // Miss or stale — force a refresh, then look up again.
    Map<String, JwksKey> keys;
    try {
      keys = await _refresh();
    } on JwksFetchException {
      // Grace fallback: if we still have some cached keys and the last
      // fetch is within ttl + gracePeriod, honour them. Otherwise rethrow.
      final cached = _keys;
      final fetchedAt = _fetchedAt;
      if (cached != null &&
          fetchedAt != null &&
          _now().isBefore(fetchedAt.add(ttl + gracePeriod))) {
        keys = cached;
      } else {
        rethrow;
      }
    }
    return keys[kid];
  }

  /// Returns the cached map iff it is within its TTL.
  Map<String, JwksKey>? _fresh() {
    final keys = _keys;
    final fetchedAt = _fetchedAt;
    if (keys == null || fetchedAt == null) return null;
    if (_now().isAfter(fetchedAt.add(ttl))) return null;
    return keys;
  }

  /// Force a refresh. Dedupes concurrent callers.
  Future<Map<String, JwksKey>> _refresh() {
    final pending = _inflight;
    if (pending != null) return pending;
    final future = _fetch();
    _inflight = future;
    return future.whenComplete(() => _inflight = null);
  }

  Future<Map<String, JwksKey>> _fetch() async {
    final http.Response resp;
    try {
      resp = await _client.get(jwksUri);
    } catch (e) {
      throw JwksFetchException('JWKS fetch failed: $e');
    }
    if (resp.statusCode >= 400) {
      throw JwksFetchException(
        'JWKS endpoint returned HTTP ${resp.statusCode}',
      );
    }
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw const JwksFetchException('JWKS payload is not valid JSON');
    }
    final rawKeys = body['keys'];
    if (rawKeys is! List) {
      throw const JwksFetchException('JWKS payload has no `keys` array');
    }
    final parsed = <String, JwksKey>{};
    for (final entry in rawKeys) {
      if (entry is! Map) continue;
      final kty = entry['kty'] as String?;
      final kid = entry['kid'] as String?;
      final use = entry['use'] as String? ?? 'sig';
      final alg = entry['alg'] as String? ?? 'RS256';
      if (kty == null || kty != 'RSA') continue;
      if (kid == null) continue;
      if (use != 'sig') continue;
      final n = entry['n'] as String?;
      final e = entry['e'] as String?;
      if (n == null || e == null) continue;
      parsed[kid] = JwksKey(
        kid: kid,
        kty: kty,
        alg: alg,
        use: use,
        rsaPublicKey: _rsaFromJwk(n, e),
      );
    }
    if (parsed.isEmpty) {
      throw const JwksFetchException(
        'JWKS payload contained no usable RSA signing keys',
      );
    }
    _keys = parsed;
    _fetchedAt = _now();
    return parsed;
  }

  /// Constructs an [RSAPublicKey] from the JWK `n` (modulus) and `e`
  /// (exponent) base64url-encoded big-endian integers.
  static RSAPublicKey _rsaFromJwk(String nB64, String eB64) {
    final modulus = _decodeBase64UrlBigInt(nB64);
    final exponent = _decodeBase64UrlBigInt(eB64);
    return RSAPublicKey(modulus, exponent);
  }

  static BigInt _decodeBase64UrlBigInt(String input) {
    final padded = input.padRight(
      input.length + ((4 - input.length % 4) % 4),
      '=',
    );
    final bytes = base64Url.decode(padded);
    return _bytesToBigInt(Uint8List.fromList(bytes));
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }

  /// Release the inner [http.Client] if we own it. Callers that injected
  /// their own client are responsible for closing it.
  void close() => _client.close();
}
