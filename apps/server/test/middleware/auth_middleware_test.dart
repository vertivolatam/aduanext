/// Integration tests for the auth + role-guard pipeline.
///
/// We do NOT spin up a real Keycloak — the middleware is provider-
/// agnostic by construction. Tests inject a `PortFactory` callback that
/// returns either the in-memory adapter (happy path) or throws an
/// AuthenticationException (failure cases). This exercises the middleware
/// contract without a JWT round-trip.
library;

import 'dart:convert';

import 'package:aduanext_adapters/authorization.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_server/aduanext_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

void main() {
  // ── Fixtures ──────────────────────────────────────────────────────
  final agentUser = User(
    id: 'u-agent',
    email: 'maria@agency.cr',
    memberships: {
      TenantMembership(
        userId: 'u-agent',
        tenantId: 't-agency',
        role: Role.agent,
        since: DateTime.utc(2026, 1, 1),
      ),
    },
  );
  final adminUser = User(
    id: 'u-admin',
    email: 'admin@agency.cr',
    memberships: {
      TenantMembership(
        userId: 'u-admin',
        tenantId: 't-agency',
        role: Role.admin,
        since: DateTime.utc(2026, 1, 1),
      ),
    },
  );
  final fiscalUser = User(
    id: 'u-fiscal',
    email: 'inspector@dga.cr',
    memberships: {
      TenantMembership(
        userId: 'u-fiscal',
        tenantId: 't-agency',
        role: Role.fiscalizador,
        since: DateTime.utc(2026, 1, 1),
      ),
    },
  );

  /// Build an auth pipeline that resolves [token] → [user] / fail.
  /// The token strings encode "what should happen":
  ///   "ok-agent"   → returns agentUser
  ///   "ok-admin"   → returns adminUser
  ///   "ok-fiscal"  → returns fiscalUser
  ///   "expired"    → throws AuthenticationException(expired)
  ///   "bad-sig"    → throws AuthenticationException(invalid)
  ///   "wrong-tenant" → returns agentUser but for a DIFFERENT tenant
  PortFactory portFactoryFor() {
    return ({
      required String? bearerToken,
      required String? selectedTenantId,
    }) async {
      switch (bearerToken) {
        case 'ok-agent':
          return InMemoryAuthorizationAdapter(
            user: agentUser,
            selectedTenantId: selectedTenantId,
          );
        case 'ok-admin':
          return InMemoryAuthorizationAdapter(
            user: adminUser,
            selectedTenantId: selectedTenantId,
          );
        case 'ok-fiscal':
          return InMemoryAuthorizationAdapter(
            user: fiscalUser,
            selectedTenantId: selectedTenantId,
          );
        case 'expired':
          throw const AuthenticationException(
            'JWT is expired',
            vendorCode: 'expired',
          );
        case 'bad-sig':
          throw const AuthenticationException(
            'Bad signature',
            vendorCode: 'invalid',
          );
        default:
          throw const AuthenticationException(
            'Unrecognised test token',
            vendorCode: 'invalid',
          );
      }
    };
  }

  /// A handler that echoes the request context as JSON — useful for
  /// asserting the middleware actually attached one.
  Response echoHandler(Request request) {
    final ctx = request.requestContext;
    return Response.ok(
      jsonEncode({
        'user': ctx.user.id,
        'tenant': ctx.selectedTenantId,
        'request_id': ctx.requestId,
      }),
      headers: const {'content-type': 'application/json'},
    );
  }

  /// Build a pipeline: authMiddleware → router with a single route
  /// that requires [allowed] roles and dispatches to [echoHandler].
  Handler buildPipeline({
    required PortFactory factory,
    required Set<Role> allowed,
  }) {
    final router = Router();
    registerProtectedRoutes(router, [
      ProtectedRoute(
        method: 'POST',
        path: '/api/test/echo',
        allowed: allowed,
        handler: echoHandler,
      ),
    ]);
    return const Pipeline()
        .addMiddleware(authMiddleware(factory))
        .addHandler(router.call);
  }

  Map<String, String> bearer(String token, {String? tenant}) => {
        'authorization': 'Bearer $token',
        if (tenant != null) 'x-tenant-id': tenant,
      };

  // ── Tests ─────────────────────────────────────────────────────────

  group('authentication', () {
    test('valid JWT + matching tenant → 200 with context echo', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-agent', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['user'], 'u-agent');
      expect(body['tenant'], 't-agency');
      expect(body['request_id'], startsWith('req_'));
    });

    test('missing Authorization header → 401 MISSING_TOKEN', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: const {'x-tenant-id': 't-agency'},
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'MISSING_TOKEN');
    });

    test('Authorization header without Bearer prefix → 401 MISSING_TOKEN',
        () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: const {'authorization': 'Basic abc'},
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'MISSING_TOKEN');
    });

    test('expired JWT → 401 EXPIRED_TOKEN', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('expired', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'EXPIRED_TOKEN');
    });

    test('invalid signature → 401 INVALID_TOKEN', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('bad-sig', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'INVALID_TOKEN');
    });

    test('upstream X-Request-Id is preserved in error responses',
        () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: const {'x-request-id': 'req_inbound_123'},
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['request_id'], 'req_inbound_123');
    });
  });

  group('role guard', () {
    test('user with insufficient role → 403 INSUFFICIENT_ROLE', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.admin},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-agent', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 403);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'INSUFFICIENT_ROLE');
      expect(body['message'], contains('admin'));
    });

    test('user with role hierarchy outranking required → 200', () async {
      // Admin satisfies Role.agent via Role.satisfies.
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-admin', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 200);
    });

    test('wrong tenant (not a member) → 403 WRONG_TENANT', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-agent', tenant: 't-someone-else'),
        ),
      );
      expect(response.statusCode, 403);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'WRONG_TENANT');
    });

    test('missing X-Tenant-Id → 400 WRONG_TENANT', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-agent'),
        ),
      );
      expect(response.statusCode, 400);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'WRONG_TENANT');
    });

    test('fiscalizador hitting agent-only route → 403', () async {
      final handler = buildPipeline(
        factory: portFactoryFor(),
        allowed: const {Role.agent, Role.supervisor},
      );
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/test/echo'),
          headers: bearer('ok-fiscal', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 403);
    });

    test('roleGuard rejects empty allowed set at construction', () {
      expect(() => roleGuard(const <Role>{}), throwsArgumentError);
    });
  });

  group('default route table', () {
    test('exposes the 5 documented routes', () {
      final routes = defaultRouteTable();
      final paths = routes.map((r) => '${r.method} ${r.path}').toSet();
      expect(paths, containsAll([
        'POST /api/dispatches/submit',
        'POST /api/classifications/confirm',
        'GET /api/dispatches/<id>',
        'POST /api/dispatches/<id>/rectify',
        'GET /api/audit/export',
      ]));
    });

    test('every route declares at least one allowed role', () {
      for (final route in defaultRouteTable()) {
        expect(
          route.allowed,
          isNotEmpty,
          reason: '${route.method} ${route.path} has no allowed roles',
        );
      }
    });

    test('placeholder handlers respond 501 not implemented (after auth)',
        () async {
      final routes = defaultRouteTable();
      final router = Router();
      registerProtectedRoutes(router, routes);
      final handler = const Pipeline()
          .addMiddleware(authMiddleware(portFactoryFor()))
          .addHandler(router.call);

      // /api/audit/export requires admin OR fiscalizador. Use admin.
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/api/audit/export'),
          headers: bearer('ok-admin', tenant: 't-agency'),
        ),
      );
      expect(response.statusCode, 501);
    });
  });
}
