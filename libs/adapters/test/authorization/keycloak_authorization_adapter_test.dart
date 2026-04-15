/// Unit tests for [KeycloakAuthorizationAdapterFactory] and its
/// collaborators [JwksCache] + [KeycloakClaimsMapper].
///
/// Covers the acceptance criteria for VRTV-60:
/// * valid JWT → User populated correctly
/// * expired JWT → AuthenticationException
/// * invalid signature → AuthenticationException
/// * missing required claims → MalformedTokenException
/// * JWKS endpoint down + cached key → OK (grace period)
/// * JWKS endpoint down + no cache → AuthenticationException
///
/// Tests sign JWTs with an in-memory RSA keypair — no Keycloak round-trip.
library;

import 'package:aduanext_adapters/authorization.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;
import 'package:test/test.dart';

import 'mock_jwks_client.dart';
import 'rsa_test_keys.dart';

void main() {
  // Keygen is expensive — generate once per test file.
  final keypair = generateRsaTestKeypair(kid: 'kc-key-1');
  final otherKeypair = generateRsaTestKeypair(
    kid: 'kc-key-rotated',
    seed: 0xC0FFEE,
  );
  final jwksBody = buildJwksBody([keypair]);

  const issuer = 'https://keycloak.aduanext.local/realms/aduanext';
  const audience = 'aduanext-server';

  String signToken({
    required Map<String, dynamic> payload,
    required String kid,
    jwt.RSAPrivateKey? signingKey,
    Duration? expiresIn = const Duration(hours: 1),
    Duration? notBefore,
    String? overrideIssuer,
    String? overrideAudience,
  }) {
    final token = jwt.JWT(
      payload,
      issuer: overrideIssuer ?? issuer,
      audience: jwt.Audience.one(overrideAudience ?? audience),
      header: {'kid': kid, 'alg': 'RS256', 'typ': 'JWT'},
    );
    return token.sign(
      signingKey ?? jwt.RSAPrivateKey.raw(keypair.privateKey),
      algorithm: jwt.JWTAlgorithm.RS256,
      expiresIn: expiresIn,
      notBefore: notBefore,
    );
  }

  Map<String, dynamic> validClaims({String tenantId = 't-abc'}) => {
        'sub': 'user-123',
        'email': 'andrea@example.cr',
        'aduanext_tenant_ids': [tenantId],
        'aduanext_roles': {
          tenantId: ['agent'],
        },
        'aduanext_membership_since': {tenantId: '2026-01-01T00:00:00Z'},
      };

  KeycloakAuthorizationAdapterFactory buildFactory({
    MockJwksClient? client,
    DateTime Function()? now,
    Duration ttl = const Duration(minutes: 15),
    Duration grace = const Duration(minutes: 30),
  }) {
    final cache = JwksCache(
      jwksUri: Uri.parse('https://keycloak.test/jwks.json'),
      ttl: ttl,
      gracePeriod: grace,
      httpClient: client ?? MockJwksClient(body: jwksBody),
      now: now,
    );
    return KeycloakAuthorizationAdapterFactory(
      jwksCache: cache,
      expectedIssuer: issuer,
      expectedAudience: audience,
      now: now,
    );
  }

  group('happy path', () {
    test('valid JWT → User populated + role enforced', () async {
      final factory = buildFactory();
      final token = signToken(
        payload: validClaims(),
        kid: 'kc-key-1',
      );

      final port = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't-abc',
      );

      expect(port.currentUser().id, 'user-123');
      expect(port.currentUser().email, 'andrea@example.cr');
      expect(port.currentTenantId(), 't-abc');
      expect(port.hasRole(Role.agent), isTrue);
      expect(port.hasRole(Role.admin), isFalse);
      port.requireRole(Role.agent); // does not throw
      port.requireTenant('t-abc');
    });

    test('multi-tenant membership: admin in t1, fiscalizador in t2',
        () async {
      final factory = buildFactory();
      final token = signToken(
        kid: 'kc-key-1',
        payload: {
          'sub': 'u-multi',
          'email': 'agent@example.cr',
          'aduanext_tenant_ids': ['t1', 't2'],
          'aduanext_roles': {
            't1': ['admin'],
            't2': ['fiscalizador'],
          },
          'aduanext_membership_since': {
            't1': '2026-01-01T00:00:00Z',
            't2': '2026-01-01T00:00:00Z',
          },
        },
      );

      final portT1 = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't1',
      );
      expect(portT1.hasRole(Role.admin), isTrue);

      final portT2 = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't2',
      );
      expect(portT2.hasRole(Role.agent), isFalse);
      expect(portT2.hasRole(Role.fiscalizador), isTrue);
    });

    test('no tenant selected → currentTenantId throws tenant-not-selected',
        () async {
      final factory = buildFactory();
      final token = signToken(payload: validClaims(), kid: 'kc-key-1');
      final port = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: null,
      );
      expect(
        port.currentTenantId,
        throwsA(isA<AuthorizationException>()
            .having((e) => e.code, 'code', 'tenant-not-selected')),
      );
    });
  });

  group('authentication failures', () {
    test('missing bearer token → AuthenticationException', () async {
      final factory = buildFactory();
      await expectLater(
        factory.forRequest(bearerToken: null, selectedTenantId: 't'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'missing-token')),
      );
    });

    test('expired JWT → AuthenticationException(expired)', () async {
      final factory = buildFactory();
      final token = signToken(
        payload: validClaims(),
        kid: 'kc-key-1',
        expiresIn: const Duration(seconds: -1),
      );
      await expectLater(
        factory.forRequest(bearerToken: token, selectedTenantId: 't-abc'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'expired')),
      );
    });

    test('invalid signature → AuthenticationException(invalid)', () async {
      final factory = buildFactory();
      // Sign with the OTHER keypair but claim kid of the real one.
      final badToken = signToken(
        payload: validClaims(),
        kid: 'kc-key-1',
        signingKey: jwt.RSAPrivateKey.raw(otherKeypair.privateKey),
      );
      await expectLater(
        factory.forRequest(
          bearerToken: badToken,
          selectedTenantId: 't-abc',
        ),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'invalid')),
      );
    });

    test('unknown kid → AuthenticationException(unknown-kid)', () async {
      final factory = buildFactory();
      final token = signToken(
        payload: validClaims(),
        kid: 'does-not-exist',
        signingKey: jwt.RSAPrivateKey.raw(otherKeypair.privateKey),
      );
      await expectLater(
        factory.forRequest(
          bearerToken: token,
          selectedTenantId: 't-abc',
        ),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'unknown-kid')),
      );
    });

    test('wrong issuer → AuthenticationException', () async {
      final factory = buildFactory();
      final token = signToken(
        payload: validClaims(),
        kid: 'kc-key-1',
        overrideIssuer: 'https://attacker.example/realms/evil',
      );
      await expectLater(
        factory.forRequest(
          bearerToken: token,
          selectedTenantId: 't-abc',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('wrong audience → AuthenticationException', () async {
      final factory = buildFactory();
      final token = signToken(
        payload: validClaims(),
        kid: 'kc-key-1',
        overrideAudience: 'some-other-client',
      );
      await expectLater(
        factory.forRequest(
          bearerToken: token,
          selectedTenantId: 't-abc',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('malformed JWT (not three segments) → AuthenticationException',
        () async {
      final factory = buildFactory();
      await expectLater(
        factory.forRequest(
          bearerToken: 'not-a-jwt',
          selectedTenantId: 't',
        ),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'malformed')),
      );
    });
  });

  group('malformed claims', () {
    test('missing aduanext_tenant_ids → MalformedTokenException', () async {
      final factory = buildFactory();
      final token = signToken(
        kid: 'kc-key-1',
        payload: {
          'sub': 'u',
          'email': 'a@b',
          'aduanext_roles': {'t1': ['agent']},
          'aduanext_membership_since': {'t1': '2026-01-01T00:00:00Z'},
        },
      );
      await expectLater(
        factory.forRequest(bearerToken: token, selectedTenantId: 't1'),
        throwsA(isA<MalformedTokenException>()),
      );
    });

    test('unrecognised role code → MalformedTokenException', () async {
      final factory = buildFactory();
      final token = signToken(
        kid: 'kc-key-1',
        payload: {
          'sub': 'u',
          'email': 'a@b',
          'aduanext_tenant_ids': ['t1'],
          'aduanext_roles': {
            't1': ['galactic-overlord'],
          },
          'aduanext_membership_since': {'t1': '2026-01-01T00:00:00Z'},
        },
      );
      await expectLater(
        factory.forRequest(bearerToken: token, selectedTenantId: 't1'),
        throwsA(isA<MalformedTokenException>()),
      );
    });

    test('multiple role codes → highest rank wins', () async {
      final factory = buildFactory();
      final token = signToken(
        kid: 'kc-key-1',
        payload: {
          'sub': 'u',
          'email': 'a@b',
          'aduanext_tenant_ids': ['t1'],
          'aduanext_roles': {
            't1': ['importer', 'supervisor', 'agent'],
          },
          'aduanext_membership_since': {'t1': '2026-01-01T00:00:00Z'},
        },
      );
      final port = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't1',
      );
      expect(port.currentMembership()?.role, Role.supervisor);
    });
  });

  group('JWKS caching + grace', () {
    test('JWKS endpoint down + fresh cache → OK', () async {
      final client = MockJwksClient(body: jwksBody);
      var nowTicks = DateTime.utc(2026, 4, 14, 12, 0, 0);
      DateTime now() => nowTicks;
      final factory = buildFactory(client: client, now: now);

      // First call warms the cache.
      final token1 = signToken(payload: validClaims(), kid: 'kc-key-1');
      await factory.forRequest(
        bearerToken: token1,
        selectedTenantId: 't-abc',
      );
      expect(client.callCount, 1);

      // Break the endpoint, advance to within TTL. Cached key should be used.
      client.alwaysFail = true;
      nowTicks = nowTicks.add(const Duration(minutes: 5));

      final token2 = signToken(payload: validClaims(), kid: 'kc-key-1');
      final port = await factory.forRequest(
        bearerToken: token2,
        selectedTenantId: 't-abc',
      );
      expect(port.currentUser().id, 'user-123');
      // Still 1 — no refetch because cache was fresh.
      expect(client.callCount, 1);
    });

    test('JWKS endpoint down + stale cache within grace → OK', () async {
      final client = MockJwksClient(body: jwksBody);
      var nowTicks = DateTime.utc(2026, 4, 14, 12, 0, 0);
      DateTime now() => nowTicks;
      final factory = buildFactory(
        client: client,
        now: now,
        ttl: const Duration(minutes: 15),
        grace: const Duration(minutes: 30),
      );

      // Warm cache.
      final token = signToken(payload: validClaims(), kid: 'kc-key-1');
      await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't-abc',
      );

      // Advance beyond TTL but within grace. Break endpoint BEFORE refetch.
      nowTicks = nowTicks.add(const Duration(minutes: 20));
      client.alwaysFail = true;

      final port = await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't-abc',
      );
      expect(port.currentUser().id, 'user-123');
    });

    test('JWKS endpoint down + no cache → AuthenticationException',
        () async {
      final client = MockJwksClient(
        body: jwksBody,
        alwaysFail: true,
      );
      final factory = buildFactory(client: client);
      final token = signToken(payload: validClaims(), kid: 'kc-key-1');
      await expectLater(
        factory.forRequest(bearerToken: token, selectedTenantId: 't-abc'),
        throwsA(isA<AuthenticationException>().having(
          (e) => e.vendorCode,
          'vendorCode',
          'jwks-unavailable',
        )),
      );
    });

    test('JWKS endpoint down + stale cache OUTSIDE grace → '
        'AuthenticationException', () async {
      final client = MockJwksClient(body: jwksBody);
      var nowTicks = DateTime.utc(2026, 4, 14, 12, 0, 0);
      DateTime now() => nowTicks;
      final factory = buildFactory(
        client: client,
        now: now,
        ttl: const Duration(minutes: 15),
        grace: const Duration(minutes: 30),
      );

      final token = signToken(payload: validClaims(), kid: 'kc-key-1');
      await factory.forRequest(
        bearerToken: token,
        selectedTenantId: 't-abc',
      );

      // ttl + grace = 45 min; advance 60 min, break endpoint.
      nowTicks = nowTicks.add(const Duration(minutes: 60));
      client.alwaysFail = true;

      await expectLater(
        factory.forRequest(bearerToken: token, selectedTenantId: 't-abc'),
        throwsA(isA<AuthenticationException>()
            .having((e) => e.vendorCode, 'vendorCode', 'jwks-unavailable')),
      );
    });

    test('kid missing from fresh cache triggers refetch-on-miss', () async {
      // Warm the cache with one key; then a request arrives with a kid
      // that isn't cached. The cache MUST refetch (key rotation case)
      // rather than fail outright.
      final rotatedBody = buildJwksBody([otherKeypair]);
      final client = MockJwksClient(body: rotatedBody);
      var nowTicks = DateTime.utc(2026, 4, 14, 12, 0, 0);
      DateTime now() => nowTicks;
      final factory = buildFactory(client: client, now: now);

      // Warm cache by asking for a key that does exist in rotatedBody.
      final warmupToken = signToken(
        payload: validClaims(),
        kid: 'kc-key-rotated',
        signingKey: jwt.RSAPrivateKey.raw(otherKeypair.privateKey),
      );
      await factory.forRequest(
        bearerToken: warmupToken,
        selectedTenantId: 't-abc',
      );
      expect(client.callCount, 1);

      // Now ask for kc-key-1 — not in the cache. Endpoint still returns
      // rotatedBody so the refetch happens but ultimately fails with
      // unknown-kid (the real Keycloak would return the new JWKS).
      final missToken = signToken(payload: validClaims(), kid: 'kc-key-1');
      await expectLater(
        factory.forRequest(
          bearerToken: missToken,
          selectedTenantId: 't-abc',
        ),
        throwsA(isA<AuthenticationException>().having(
          (e) => e.vendorCode,
          'vendorCode',
          'unknown-kid',
        )),
      );
      // Second fetch triggered by refetch-on-miss.
      expect(client.callCount, 2);

      // After real rotation, the JWKS now carries both keys.
      client.body = buildJwksBody([keypair, otherKeypair]);
      // Force TTL expiry so the cache refreshes on next call.
      nowTicks = nowTicks.add(const Duration(hours: 1));
      final port = await factory.forRequest(
        bearerToken: missToken,
        selectedTenantId: 't-abc',
      );
      expect(port.currentUser().id, 'user-123');
    });
  });
}
