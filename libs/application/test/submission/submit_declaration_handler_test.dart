/// Tests for [SubmitDeclarationHandler] — the North Star use case.
///
/// We drive the handler through fake implementations of every Port
/// (no gRPC / no Postgres) so we can deterministically exercise:
///
/// - command validation (missing fields, structural problems);
/// - each branch of the 4-step choreography (auth fail, validation
///   fail, signing fail, gateway reject);
/// - the exact sequence + payload of audit events written to the chain.
library;

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SubmitDeclarationHandler', () {
    late InMemoryAuditLogAdapter auditLog;
    late _FakeAuthProvider auth;
    late _FakeCustomsGateway gateway;
    late _FakeSigning signing;
    late SubmitDeclarationHandler handler;

    final fixedNow = DateTime.utc(2026, 4, 14, 10, 0, 0);

    setUp(() {
      auditLog = InMemoryAuditLogAdapter(now: () => fixedNow);
      auth = _FakeAuthProvider();
      gateway = _FakeCustomsGateway();
      signing = _FakeSigning();
      handler = SubmitDeclarationHandler(
        authProvider: auth,
        customsGateway: gateway,
        signing: signing,
        auditLog: auditLog,
        clock: () => fixedNow,
      );
    });

    // -------------------------------------------------------------------------
    // Command validation
    // -------------------------------------------------------------------------
    test('returns MissingFieldFailure for empty agentId', () async {
      final result = await handler.handle(
        _buildCommand(agentId: ''),
      );
      expect(result, isA<Err<DeclarationResult>>());
      final err = (result as Err<DeclarationResult>).failure;
      expect(err, isA<MissingFieldFailure>());
      expect((err as MissingFieldFailure).fieldName, 'agentId');
      // No audit written — we bail before touching any Port.
      expect(await auditLog.queryByEntity('Declaration', 'DECL-1'), isEmpty);
    });

    test('returns MissingFieldFailure for empty tenantId', () async {
      final result = await handler.handle(_buildCommand(tenantId: ''));
      expect((result as Err<DeclarationResult>).failure,
          isA<MissingFieldFailure>());
    });

    test('returns MissingFieldFailure for empty declarationId', () async {
      final result = await handler.handle(_buildCommand(declarationId: ''));
      expect((result as Err<DeclarationResult>).failure,
          isA<MissingFieldFailure>());
    });

    test('returns InvalidDeclarationStructureFailure for no items',
        () async {
      final result = await handler.handle(_buildCommand(
        declaration: _buildDeclaration(items: const []),
      ));
      final err = (result as Err<DeclarationResult>).failure
          as InvalidDeclarationStructureFailure;
      expect(err.reason, contains('items list is empty'));
    });

    test(
      'returns InvalidDeclarationStructureFailure when commercial description '
      'is too short',
      () async {
        final result = await handler.handle(_buildCommand(
          declaration: _buildDeclaration(
            items: [_item(commercialDescription: 'x')],
          ),
        ));
        final err = (result as Err<DeclarationResult>).failure
            as InvalidDeclarationStructureFailure;
        expect(err.reason, contains('commercialDescription'));
      },
    );

    // -------------------------------------------------------------------------
    // Authentication branch
    // -------------------------------------------------------------------------
    test(
      'authentication failure returns AuthenticationFailedFailure and logs '
      'submit.requested + submit.authentication-failed',
      () async {
        auth.onAuthenticate = (_) =>
            throw const AuthenticationException('Invalid grant',
                vendorCode: 'INVALID_GRANT');
        final result = await handler.handle(_buildCommand());
        final err = (result as Err<DeclarationResult>).failure;
        expect(err, isA<AuthenticationFailedFailure>());
        expect((err as AuthenticationFailedFailure).idpErrorCode,
            'INVALID_GRANT');

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authentication-failed',
        ]);
      },
    );

    // -------------------------------------------------------------------------
    // Validation branch
    // -------------------------------------------------------------------------
    test(
      'validation failure returns DeclarationValidationFailedFailure and '
      'logs 3 events (requested, authenticated, validation-failed)',
      () async {
        gateway.validationResult = const ValidationResult(
          valid: false,
          errors: [
            ValidationError(
              code: 'E001',
              message: 'exporterCode not authorized',
              field: 'exporterCode',
            ),
          ],
          warnings: [
            ValidationWarning(code: 'W001', message: 'minor warning'),
          ],
        );
        final result = await handler.handle(_buildCommand());
        final err = (result as Err<DeclarationResult>).failure
            as DeclarationValidationFailedFailure;
        expect(err.errors, hasLength(1));
        expect(err.errors.single.code, 'E001');
        expect(err.warnings, hasLength(1));

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.validation-failed',
        ]);
        // The validation-failed event carries the verbatim errors from the
        // gateway so the UI can surface them field-by-field.
        final failedEvent = events[2];
        final failedErrors =
            (failedEvent.payload['errors'] as List<dynamic>).cast<Map>();
        expect(failedErrors.single['code'], 'E001');
        expect(failedErrors.single['field'], 'exporterCode');
      },
    );

    // -------------------------------------------------------------------------
    // Signing branch
    // -------------------------------------------------------------------------
    test(
      'signing failure returns SigningFailedFailure with 4 audit events',
      () async {
        signing.result = const SigningResult(
          success: false,
          errorMessage: 'cert expired',
        );
        final result = await handler.handle(_buildCommand());
        final err = (result as Err<DeclarationResult>).failure
            as SigningFailedFailure;
        expect(err.message, contains('cert expired'));

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.validated',
          'submit.signing-failed',
        ]);
      },
    );

    // -------------------------------------------------------------------------
    // Gateway-reject branch
    // -------------------------------------------------------------------------
    test(
      'gateway rejection returns GatewayRejectedSubmissionFailure with '
      '5 audit events ending in submit.gateway-rejected',
      () async {
        gateway.submissionResult = const DeclarationResult(
          success: false,
          errorMessage: 'exporterCode blacklisted at liquidation time',
          rawResponse: '{"error":"blacklisted"}',
        );
        final result = await handler.handle(_buildCommand());
        final err = (result as Err<DeclarationResult>).failure
            as GatewayRejectedSubmissionFailure;
        expect(err.reason, contains('blacklisted'));
        expect(err.rawResponse, contains('blacklisted'));

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.validated',
          'submit.signed',
          'submit.gateway-rejected',
        ]);
      },
    );

    // -------------------------------------------------------------------------
    // Happy path — the North Star
    // -------------------------------------------------------------------------
    test(
      'happy path returns DeclarationResult.ok and writes exactly 5 audit '
      'events (requested, authenticated, validated, signed, accepted)',
      () async {
        gateway.submissionResult = const DeclarationResult(
          success: true,
          registrationNumber: 'CR-001-001-0001-2026',
          assessmentSerial: 'A',
          assessmentNumber: 42,
          assessmentDate: '2026-04-14',
        );
        final result = await handler.handle(_buildCommand());
        expect(result.isOk, isTrue);
        final submission = (result as Ok<DeclarationResult>).value;
        expect(submission.registrationNumber, 'CR-001-001-0001-2026');

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.validated',
          'submit.signed',
          'submit.accepted',
        ]);
        // Every event shares the per-entity chain (sequence grows, each
        // points to the previous hash).
        for (final (i, e) in events.indexed) {
          expect(e.sequenceNumber, i);
          expect(e.actorId, 'agent-42');
          expect(e.tenantId, 'tenant-1');
          if (i > 0) {
            expect(e.previousHash, events[i - 1].eventHash,
                reason: 'Chain must be intact across the 5 events');
          }
        }
        final accepted = events.last;
        expect(accepted.payload['registrationNumber'],
            'CR-001-001-0001-2026');
        expect(accepted.payload['assessmentNumber'], 42);
      },
    );

    test(
      'custom serializePayload is used when provided — tests can verify the '
      'exact bytes we sign',
      () async {
        String? signedInput;
        final customHandler = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          serializePayload: (d) => 'canonical:${d.exporterCode}',
          clock: () => fixedNow,
        );
        signing.onSign = (input) {
          signedInput = input;
          return const SigningResult(success: true, signedContent: 'SIG');
        };
        gateway.submissionResult =
            const DeclarationResult(success: true);
        final result = await customHandler.handle(_buildCommand());
        expect(result.isOk, isTrue);
        expect(signedInput, 'canonical:310100580824');
      },
    );

    test(
      'audit append failure propagates as exception (NOT a Result.err) per '
      'SRD rule #4 — never swallow audit failures',
      () async {
        final failingAudit = _FailingAuditLogAdapter();
        final brokenHandler = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: failingAudit,
          clock: () => fixedNow,
        );
        await expectLater(
          brokenHandler.handle(_buildCommand()),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}

// -----------------------------------------------------------------------------
// Fakes + fixtures
// -----------------------------------------------------------------------------

SubmitDeclarationCommand _buildCommand({
  String agentId = 'agent-42',
  String tenantId = 'tenant-1',
  String declarationId = 'DECL-1',
  Declaration? declaration,
  Credentials? credentials,
}) {
  return SubmitDeclarationCommand(
    agentId: agentId,
    tenantId: tenantId,
    declarationId: declarationId,
    declaration: declaration ?? _buildDeclaration(),
    credentials: credentials ??
        const Credentials(
          idType: 'CED_FISICA',
          idNumber: '1-2345-6789',
          password: 'pw',
          clientId: 'atena-cli',
        ),
  );
}

Declaration _buildDeclaration({
  List<DeclarationItem>? items,
}) {
  return Declaration(
    typeOfDeclaration: 'EX',
    generalProcedureCode: '1',
    officeOfDispatchExportCode: '001',
    officeOfEntryCode: '002',
    exporterCode: '310100580824',
    declarantCode: '310100975830',
    natureOfTransactionCode1: '1',
    natureOfTransactionCode2: '1',
    documentsReceived: true,
    shipping: const Shipping(countryOfExportCode: 'CR'),
    sadValuation: const SadValuation(),
    items: items ?? [_item()],
  );
}

DeclarationItem _item({
  String commercialDescription = 'LED grow lights 600W full spectrum',
}) {
  return DeclarationItem(
    rank: 1,
    commercialDescription: commercialDescription,
    procedure: const ItemProcedure(
      itemCountryOfOriginCode: 'CR',
      extendedProcedureCode: '1000',
    ),
    itemValuation: const ItemValuation(),
  );
}

class _FakeAuthProvider implements AuthProviderPort {
  Future<AuthToken> Function(Credentials) onAuthenticate =
      _defaultAuthenticate;

  static Future<AuthToken> _defaultAuthenticate(Credentials _) async =>
      AuthToken(
        accessToken: 'fake.token',
        expiresInSeconds: 3600,
        issuedAt: DateTime.utc(2026, 4, 14),
      );

  @override
  Future<AuthToken> authenticate(Credentials credentials) =>
      Future.sync(() => onAuthenticate(credentials));

  @override
  Future<AuthToken> refreshToken() => throw UnimplementedError();

  @override
  Future<bool> get isAuthenticated async => true;

  @override
  Future<void> invalidate() async {}
}

class _FakeCustomsGateway implements CustomsGatewayPort {
  ValidationResult validationResult = const ValidationResult(valid: true);

  DeclarationResult submissionResult = const DeclarationResult(
    success: true,
    registrationNumber: 'CR-001-001-0001-2026',
  );

  @override
  Future<ValidationResult> validateDeclaration(Declaration _) async =>
      validationResult;

  @override
  Future<DeclarationResult> submitDeclaration(Declaration _) async =>
      submissionResult;

  @override
  Future<DeclarationResult> liquidateDeclaration(Declaration _) async =>
      submissionResult;

  @override
  Future<DeclarationStatus> getDeclarationStatus(String _) async =>
      DeclarationStatus.registered;

  @override
  Future<DeclarationResult> rectifyDeclaration(Declaration _, Declaration __) =>
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

class _FakeSigning implements SigningPort {
  SigningResult result =
      const SigningResult(success: true, signedContent: 'SIGNED-BYTES');

  SigningResult Function(String)? onSign;

  @override
  Future<SigningResult> sign(String content) async {
    if (onSign != null) return onSign!(content);
    return result;
  }

  @override
  Future<SigningResult> signAndEncode(String content) async => result;

  @override
  Future<bool> verifySignature(String signedContent) async => true;
}

class _FailingAuditLogAdapter implements AuditLogPort {
  @override
  Future<String> append(AuditEvent _) =>
      throw StateError('audit log unavailable');

  @override
  Future<List<AuditEvent>> queryByEntity(String _, String __) async =>
      const [];

  @override
  Future<bool> verifyChainIntegrity(String _, String __) async => true;
}
