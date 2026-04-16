/// End-to-end-ish tests for the `/api/v1/dispatches/*` routes.
///
/// These exercise the full pipeline: auth middleware → role guard →
/// rate limiter → submit handler → fake adapters. We use
/// `InMemoryAuthorizationAdapter` for per-request auth, in-process
/// fake [AuthProviderPort] / [CustomsGatewayPort] / [SigningPort], and
/// the real [InMemoryAuditLogAdapter] for the audit chain.
library;

import 'dart:convert';

import 'package:aduanext_adapters/audit.dart';
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
  final importerUser = User(
    id: 'u-importer',
    email: 'andrea@pyme.cr',
    memberships: {
      TenantMembership(
        userId: 'u-importer',
        tenantId: 't-agency',
        role: Role.importer,
        since: DateTime.utc(2026, 1, 1),
      ),
    },
  );

  PortFactory portFactoryForAll() {
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
        case 'ok-importer':
          return InMemoryAuthorizationAdapter(
            user: importerUser,
            selectedTenantId: selectedTenantId,
          );
        default:
          throw const AuthenticationException(
            'unknown test token',
            vendorCode: 'invalid',
          );
      }
    };
  }

  Handler buildPipeline({
    required _FakeAuthProvider auth,
    required _FakeCustomsGateway gateway,
    required _FakeSigningPort signing,
    required AuditLogPort audit,
    TokenBucketRegistry? rateLimiter,
  }) {
    final endpoints = DispatchEndpoints(
      deps: DispatchEndpointDeps(
        authProvider: auth,
        customsGateway: gateway,
        signing: signing,
        pkcs11Signing: null,
        auditLog: audit,
      ),
    );
    final routes = defaultRouteTable(
      dispatchEndpoints: endpoints,
      submitRateLimiter: rateLimiter,
    );
    final router = Router();
    registerProtectedRoutes(router, routes);
    return const Pipeline()
        .addMiddleware(authMiddleware(portFactoryForAll()))
        .addHandler(router.call);
  }

  Request submitRequest({
    required String token,
    String tenant = 't-agency',
    String declarationId = 'dec-1',
    Map<String, dynamic>? credsOverride,
    Map<String, dynamic>? declarationOverride,
    String? bodyOverride,
  }) {
    final body = bodyOverride ??
        jsonEncode({
          'declarationId': declarationId,
          'declaration': declarationOverride ?? _validDeclaration(),
          'credentials': credsOverride ?? _validSoftwareCreds(),
        });
    return Request(
      'POST',
      Uri.parse('http://localhost/api/v1/dispatches/submit'),
      headers: {
        'authorization': 'Bearer $token',
        'x-tenant-id': tenant,
        'content-type': 'application/json',
      },
      body: body,
    );
  }

  // ── Tests ─────────────────────────────────────────────────────────

  group('POST /api/v1/dispatches/submit — happy path', () {
    test('software creds + valid declaration → 200 accepted', () async {
      final auth = _FakeAuthProvider();
      final gateway = _FakeCustomsGateway(
        validateValid: true,
        submitSuccess: true,
        registrationNumber: 'CR-2026-001',
      );
      final signing = _FakeSigningPort(success: true);
      final audit = InMemoryAuditLogAdapter();
      final pipeline = buildPipeline(
        auth: auth,
        gateway: gateway,
        signing: signing,
        audit: audit,
      );

      final response = await pipeline(submitRequest(token: 'ok-agent'));
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['declarationId'], 'dec-1');
      expect(body['status'], 'accepted');
      expect(body['customsRegistrationNumber'], 'CR-2026-001');

      // Audit trail: should carry the full 5-step chain.
      final events =
          await audit.queryByEntity('Declaration', 'dec-1');
      final actions = events.map((e) => e.action).toList();
      expect(actions, contains('submit.requested'));
      expect(actions, contains('submit.authenticated'));
      expect(actions, contains('submit.validated'));
      expect(actions, contains('submit.signed'));
      expect(actions, contains('submit.accepted'));
    });
  });

  group('POST /api/v1/dispatches/submit — validation failures', () {
    test('ATENA validation error → 422 ATENA_VALIDATION_FAILED', () async {
      final audit = InMemoryAuditLogAdapter();
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(
          validateValid: false,
          validationErrors: [
            const ValidationError(
                code: 'E001', message: 'HS code missing', field: 'items[0]'),
          ],
        ),
        signing: _FakeSigningPort(success: true),
        audit: audit,
      );
      final response = await pipeline(submitRequest(token: 'ok-agent'));
      expect(response.statusCode, 422);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'ATENA_VALIDATION_FAILED');
      final details = body['details'] as Map<String, dynamic>;
      expect(details['errors'], hasLength(1));
      expect((details['errors'] as List)[0]['code'], 'E001');
    });

    test('auth-provider rejection → 502 ATENA_AUTH_FAILED', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(rejectWith: 'INVALID_GRANT'),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(token: 'ok-agent'));
      expect(response.statusCode, 502);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'ATENA_AUTH_FAILED');
      expect((body['details'] as Map)['idpErrorCode'], 'INVALID_GRANT');
    });

    test('signing failure → 500 SIGNING_FAILED', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(
          validateValid: true,
          submitSuccess: true,
        ),
        signing: _FakeSigningPort(success: false, error: 'cert-expired'),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(token: 'ok-agent'));
      expect(response.statusCode, 500);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'SIGNING_FAILED');
    });

    test('gateway reject at submit → 502 ATENA_SUBMISSION_FAILED',
        () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(
          validateValid: true,
          submitSuccess: false,
          submitErrorMessage: 'duplicate declaration',
        ),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(token: 'ok-agent'));
      expect(response.statusCode, 502);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'ATENA_SUBMISSION_FAILED');
    });
  });

  group('POST /api/v1/dispatches/submit — auth + role', () {
    test('no Bearer token → 401 MISSING_TOKEN', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/dispatches/submit'),
          headers: const {'x-tenant-id': 't-agency'},
          body: '{}',
        ),
      );
      expect(response.statusCode, 401);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'MISSING_TOKEN');
    });

    test('importer user (not agent) → role-guard allows path, '
        'handler rejects at requireRole(Role.agent) → 403', () async {
      // The route's role-guard admits agent OR importer. The handler
      // then enforces Role.agent (only licensed customs agents may
      // sign + submit). An importer should be bounced at the handler
      // step with a 403 INSUFFICIENT_ROLE-ish response.
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(token: 'ok-importer'));
      expect(response.statusCode, 403);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      // Auth middleware's INSUFFICIENT_ROLE vocabulary.
      expect(body['code'], 'INSUFFICIENT_ROLE');
    });
  });

  group('POST /api/v1/dispatches/submit — body validation', () {
    test('malformed JSON → 400 MALFORMED_REQUEST', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final request = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/dispatches/submit'),
        headers: const {
          'authorization': 'Bearer ok-agent',
          'x-tenant-id': 't-agency',
          'content-type': 'application/json',
        },
        body: '{not: valid json',
      );
      final response = await pipeline(request);
      expect(response.statusCode, 400);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'MALFORMED_REQUEST');
    });

    test('missing credentials block → 400 MALFORMED_REQUEST', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(
        token: 'ok-agent',
        bodyOverride: jsonEncode({
          'declarationId': 'dec-1',
          'declaration': _validDeclaration(),
        }),
      ));
      expect(response.statusCode, 400);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'MALFORMED_REQUEST');
    });

    test('unknown credentials.type → 422 PRE_VALIDATION_FAILED', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(
        token: 'ok-agent',
        credsOverride: {
          'type': 'biometric', // not supported
          'atenaIdType': '02',
          'atenaIdNumber': '310100975830',
          'atenaPassword': 'secret',
          'p12Base64': 'aGVsbG8=',
          'p12Pin': '1234',
        },
      ));
      expect(response.statusCode, 422);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'PRE_VALIDATION_FAILED');
    });

    test('empty p12Pin → 422 PRE_VALIDATION_FAILED', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(
        token: 'ok-agent',
        credsOverride: {
          'type': 'software',
          'atenaIdType': '02',
          'atenaIdNumber': '310100975830',
          'atenaPassword': 'secret',
          'p12Base64': 'aGVsbG8=',
          'p12Pin': '',
        },
      ));
      expect(response.statusCode, 422);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'PRE_VALIDATION_FAILED');
    });

    test('body larger than 2MB → 413 PAYLOAD_TOO_LARGE', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      // Build a 3 MB body of valid JSON so we hit the byte cap, not
      // the JSON parser.
      final padding = 'x' * (3 * 1024 * 1024);
      final body = jsonEncode({
        'declarationId': 'dec-big',
        'declaration': _validDeclaration(),
        'credentials': _validSoftwareCreds(),
        'pad': padding,
      });
      final response = await pipeline(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/dispatches/submit'),
          headers: {
            'authorization': 'Bearer ok-agent',
            'x-tenant-id': 't-agency',
            'content-type': 'application/json',
          },
          body: body,
        ),
      );
      expect(response.statusCode, 413);
      final bodyJson = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(bodyJson['code'], 'PAYLOAD_TOO_LARGE');
    });

    test('hardware credentials without pkcs11 port → 503 '
        'HARDWARE_UNAVAILABLE', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(submitRequest(
        token: 'ok-agent',
        credsOverride: {
          'type': 'hardware',
          'atenaIdType': '02',
          'atenaIdNumber': '310100975830',
          'atenaPassword': 'secret',
          'pkcs11ModulePath': '/usr/lib/x64-athena/ASEP11.so',
          'slotId': 0,
          'pin': '1234',
        },
      ));
      expect(response.statusCode, 503);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'HARDWARE_UNAVAILABLE');
    });
  });

  group('POST /api/v1/dispatches/submit — rate limit', () {
    test('11th submit in one minute → 429 RATE_LIMITED', () async {
      final registry = TokenBucketRegistry(
        capacity: 10,
        refillRate: 10,
        refillInterval: const Duration(minutes: 1),
        clock: () => DateTime.utc(2026, 1, 1, 0, 0, 0), // frozen
      );
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(
          validateValid: true,
          submitSuccess: true,
          registrationNumber: 'CR-2026-001',
        ),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
        rateLimiter: registry,
      );

      for (var i = 0; i < 10; i++) {
        final r = await pipeline(submitRequest(
          token: 'ok-agent',
          declarationId: 'dec-$i',
        ));
        expect(r.statusCode, 200, reason: 'request ${i + 1}');
      }
      final rejected = await pipeline(submitRequest(
        token: 'ok-agent',
        declarationId: 'dec-11',
      ));
      expect(rejected.statusCode, 429);
      final body = jsonDecode(await rejected.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'RATE_LIMITED');
      expect(rejected.headers['retry-after'], isNotNull);
    });
  });

  group('Placeholder endpoints (rectify / get / list)', () {
    test('GET /api/v1/dispatches/:id → 501 NOT_IMPLEMENTED', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(Request(
        'GET',
        Uri.parse('http://localhost/api/v1/dispatches/dec-1'),
        headers: const {
          'authorization': 'Bearer ok-agent',
          'x-tenant-id': 't-agency',
        },
      ));
      expect(response.statusCode, 501);
      final body = jsonDecode(await response.readAsString())
          as Map<String, dynamic>;
      expect(body['code'], 'NOT_IMPLEMENTED');
    });

    test('GET /api/v1/dispatches → 501', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(Request(
        'GET',
        Uri.parse('http://localhost/api/v1/dispatches'),
        headers: const {
          'authorization': 'Bearer ok-agent',
          'x-tenant-id': 't-agency',
        },
      ));
      expect(response.statusCode, 501);
    });

    test('POST /api/v1/dispatches/:id/rectify → 501', () async {
      final pipeline = buildPipeline(
        auth: _FakeAuthProvider(),
        gateway: _FakeCustomsGateway(),
        signing: _FakeSigningPort(success: true),
        audit: InMemoryAuditLogAdapter(),
      );
      final response = await pipeline(Request(
        'POST',
        Uri.parse('http://localhost/api/v1/dispatches/dec-1/rectify'),
        headers: const {
          'authorization': 'Bearer ok-agent',
          'x-tenant-id': 't-agency',
        },
        body: '{}',
      ));
      expect(response.statusCode, 501);
    });
  });
}

// ─────────────────────────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────────────────────────

class _FakeAuthProvider implements AuthProviderPort {
  /// When set, [authenticate] raises an [AuthenticationException] with
  /// this vendor code. Otherwise it returns a dummy token.
  final String? rejectWith;

  _FakeAuthProvider({this.rejectWith});

  @override
  Future<AuthToken> authenticate(Credentials credentials) async {
    if (rejectWith != null) {
      throw AuthenticationException('rejected', vendorCode: rejectWith);
    }
    return AuthToken(
      accessToken: 'fake',
      expiresInSeconds: 3600,
      issuedAt: DateTime.utc(2026, 1, 1),
    );
  }

  @override
  Future<AuthToken> refreshToken() async => throw UnimplementedError();

  @override
  Future<bool> get isAuthenticated async => rejectWith == null;

  @override
  Future<void> invalidate() async {}
}

class _FakeCustomsGateway implements CustomsGatewayPort {
  final bool validateValid;
  final bool submitSuccess;
  final List<ValidationError> validationErrors;
  final String? registrationNumber;
  final String? submitErrorMessage;

  _FakeCustomsGateway({
    this.validateValid = true,
    this.submitSuccess = true,
    this.validationErrors = const [],
    this.registrationNumber,
    this.submitErrorMessage,
  });

  @override
  Future<ValidationResult> validateDeclaration(Declaration declaration) async {
    return ValidationResult(
      valid: validateValid,
      errors: validateValid ? const [] : validationErrors,
    );
  }

  @override
  Future<DeclarationResult> submitDeclaration(Declaration declaration) async {
    return DeclarationResult(
      success: submitSuccess,
      registrationNumber: submitSuccess ? registrationNumber : null,
      errorMessage: submitSuccess ? null : submitErrorMessage,
    );
  }

  @override
  Future<DeclarationStatus> getDeclarationStatus(String registrationKey) =>
      throw UnimplementedError();

  @override
  Future<DeclarationResult> liquidateDeclaration(Declaration declaration) =>
      throw UnimplementedError();

  @override
  Future<DeclarationResult> rectifyDeclaration(
    Declaration original,
    Declaration corrected,
  ) =>
      throw UnimplementedError();

  @override
  Future<String> uploadAttachment({
    required String declarationId,
    required String docCode,
    required String docReference,
    required List<int> fileBytes,
    required String fileName,
  }) =>
      throw UnimplementedError();
}

class _FakeSigningPort
    with DetailedVerificationBooleanWrapper
    implements SigningPort {
  final bool success;
  final String? error;

  _FakeSigningPort({this.success = true, this.error});

  @override
  Future<SigningResult> sign(String content) async {
    if (success) {
      return SigningResult(
        success: true,
        signedContent: 'signed($content)',
        signerCommonName: 'CN=Test',
      );
    }
    return SigningResult(success: false, errorMessage: error ?? 'fail');
  }

  @override
  Future<SigningResult> signAndEncode(String content) => sign(content);

  @override
  Future<VerificationResult> verifySignatureDetailed(String _) async =>
      VerificationResult.success(
        signerCommonName: 'CN=Test',
        verifiedAt: DateTime.utc(2026, 1, 1),
      );
}

// ─────────────────────────────────────────────────────────────────
// Test data builders
// ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _validDeclaration() => {
      'typeOfDeclaration': 'EX',
      'generalProcedureCode': '1',
      'officeOfDispatchExportCode': '001',
      'exporterCode': '310100580824',
      'declarantCode': '310100975830',
      'officeOfEntryCode': '002',
      'shipping': {
        'countryOfExportCode': 'CR',
        'countryOfDestinationCode': 'US',
        'deliveryTermsCode': 'FOB',
      },
      'sadValuation': {
        'invoiceRegime': 'SINGLE_INVOICE',
        'invoiceAmountInForeignCurrency': 10000.0,
        'invoiceCurrencyCode': 'USD',
      },
      'items': [
        {
          'rank': 1,
          'commodityCode': '08011100',
          'commercialDescription':
              'Coffee beans, green arabica, Costa Rica origin',
          'itemGrossMass': 1000.0,
          'netMass': 990.0,
          'packageNumber': 20,
          'itemPackageTypeCode': 'BX',
          'procedure': {
            'itemCountryOfOriginCode': 'CR',
            'extendedProcedureCode': '1000',
            'nationalProcedureCode': '000',
          },
          'itemValuation': {
            'itemInvoiceAmountInForeignCurrency': 10000.0,
            'itemInvoiceCurrencyCode': 'USD',
          },
        },
      ],
    };

Map<String, dynamic> _validSoftwareCreds() => {
      'type': 'software',
      'atenaIdType': '02',
      'atenaIdNumber': '310100975830',
      'atenaPassword': 's3cr3t',
      'p12Base64': 'aGVsbG8=', // not actually used — container's bundle is
      'p12Pin': '1234',
    };
