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

import 'dart:typed_data';

import 'package:aduanext_adapters/audit.dart';
import 'package:aduanext_adapters/authorization.dart';
import 'package:aduanext_application/aduanext_application.dart';
import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SubmitDeclarationHandler', () {
    late InMemoryAuditLogAdapter auditLog;
    late _FakeAuthProvider auth;
    late _FakeCustomsGateway gateway;
    late _FakeSigning signing;
    late InMemoryAuthorizationAdapter authorization;
    late SubmitDeclarationHandler handler;

    final fixedNow = DateTime.utc(2026, 4, 14, 10, 0, 0);

    User buildUser(Role role) => User(
          id: 'user-42',
          email: 'agent@example.cr',
          memberships: {
            TenantMembership(
              userId: 'user-42',
              tenantId: 'tenant-1',
              role: role,
              since: DateTime.utc(2026, 1, 1),
            ),
          },
        );

    setUp(() {
      auditLog = InMemoryAuditLogAdapter(now: () => fixedNow);
      auth = _FakeAuthProvider();
      gateway = _FakeCustomsGateway();
      signing = _FakeSigning();
      authorization = InMemoryAuthorizationAdapter(
        user: buildUser(Role.agent),
        selectedTenantId: 'tenant-1',
        now: () => fixedNow,
      );
      handler = SubmitDeclarationHandler(
        authProvider: auth,
        customsGateway: gateway,
        signing: signing,
        auditLog: auditLog,
        authorization: authorization,
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
          authorization: authorization,
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

    // -------------------------------------------------------------------------
    // Authorization (VRTV-55)
    // -------------------------------------------------------------------------
    test(
      'authorization.requireTenant throws AuthorizationException when the '
      'user has no membership in the requested tenant',
      () async {
        final otherAuthorization = InMemoryAuthorizationAdapter(
          user: User(
            id: 'user-42',
            email: 'agent@example.cr',
            memberships: {
              TenantMembership(
                userId: 'user-42',
                tenantId: 'tenant-OTHER',
                role: Role.agent,
                since: DateTime.utc(2026, 1, 1),
              ),
            },
          ),
          selectedTenantId: 'tenant-OTHER',
          now: () => fixedNow,
        );
        final otherHandler = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: otherAuthorization,
          clock: () => fixedNow,
        );
        await expectLater(
          otherHandler.handle(_buildCommand(tenantId: 'tenant-1')),
          throwsA(
            isA<AuthorizationException>()
                .having((e) => e.code, 'code', 'tenant-denied'),
          ),
        );
        // No audit written — we fail before Audit #1.
        expect(await auditLog.queryByEntity('Declaration', 'DECL-1'), isEmpty);
      },
    );

    test(
      'authorization.requireRole throws AuthorizationException when the user '
      'is a member of the tenant but only holds Role.importer',
      () async {
        final importerAuthorization = InMemoryAuthorizationAdapter(
          user: buildUser(Role.importer),
          selectedTenantId: 'tenant-1',
          now: () => fixedNow,
        );
        final importerHandler = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: importerAuthorization,
          clock: () => fixedNow,
        );
        await expectLater(
          importerHandler.handle(_buildCommand()),
          throwsA(
            isA<AuthorizationException>()
                .having((e) => e.code, 'code', 'role-denied')
                .having((e) => e.requiredRole, 'requiredRole', Role.agent),
          ),
        );
      },
    );

    test(
      'happy path with Role.supervisor (outranks agent) writes '
      'actorRole=supervisor in every audit event',
      () async {
        final supervisorAuthorization = InMemoryAuthorizationAdapter(
          user: buildUser(Role.supervisor),
          selectedTenantId: 'tenant-1',
          now: () => fixedNow,
        );
        final supHandler = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: supervisorAuthorization,
          clock: () => fixedNow,
        );
        gateway.submissionResult = const DeclarationResult(
          success: true,
          registrationNumber: 'CR-001-001-0001-2026',
        );
        final result = await supHandler.handle(_buildCommand());
        expect(result.isOk, isTrue);
        final events =
            await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events, hasLength(5));
        for (final e in events) {
          expect(e.payload['actorRole'], 'supervisor',
              reason: 'Every audit event must carry the actor\'s role '
                  '(LGA Art. 28-30 attributability).');
        }
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
          authorization: authorization,
          clock: () => fixedNow,
        );
        await expectLater(
          brokenHandler.handle(_buildCommand()),
          throwsA(isA<StateError>()),
        );
      },
    );

    // -------------------------------------------------------------------------
    // Pre-validation integration (VRTV-42)
    // -------------------------------------------------------------------------
    test(
      'pre-validation errors short-circuit with PreValidationFailedFailure '
      'and log submit.pre-validation-failed',
      () async {
        final preHandler = PreValidateDeclarationHandler(
          rules: [_AlwaysFailsRule()],
        );
        final handlerWithPre = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: authorization,
          preValidate: preHandler,
          clock: () => fixedNow,
        );
        final result = await handlerWithPre.handle(_buildCommand());
        expect(result.isErr, isTrue);
        final fail = (result as Err<DeclarationResult>).failure
            as PreValidationFailedFailure;
        expect(fail.summary, contains('always-fails'));

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.pre-validation-failed',
        ]);
      },
    );

    test(
      'pre-validation warnings log submit.pre-validated-with-warnings and '
      'let the submission proceed',
      () async {
        final preHandler = PreValidateDeclarationHandler(
          rules: [_WarnsOnceRule()],
        );
        final handlerWithPre = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: authorization,
          preValidate: preHandler,
          clock: () => fixedNow,
        );
        gateway.submissionResult = const DeclarationResult(
          success: true,
          registrationNumber: 'CR-OK',
        );
        final result = await handlerWithPre.handle(_buildCommand());
        expect(result.isOk, isTrue);

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), [
          'submit.requested',
          'submit.authenticated',
          'submit.pre-validated-with-warnings',
          'submit.validated',
          'submit.signed',
          'submit.accepted',
        ]);
      },
    );

    test(
      'clean pre-validation logs submit.pre-validated (no warnings)',
      () async {
        final preHandler = PreValidateDeclarationHandler(
          rules: [_AlwaysPassesRule()],
        );
        final handlerWithPre = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          auditLog: auditLog,
          authorization: authorization,
          preValidate: preHandler,
          clock: () => fixedNow,
        );
        gateway.submissionResult = const DeclarationResult(
          success: true,
          registrationNumber: 'CR-OK',
        );
        final result = await handlerWithPre.handle(_buildCommand());
        expect(result.isOk, isTrue);
        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        expect(events.map((e) => e.action), containsAll(['submit.pre-validated']));
      },
    );

    // -------------------------------------------------------------------------
    // Hardware-token branch (VRTV-71)
    // -------------------------------------------------------------------------
    group('hardware-token signing', () {
      late _FakePkcs11Signing pkcs11;
      late SubmitDeclarationHandler handlerWithPkcs11;

      const hwCreds = HardwareTokenCredentials(
        pkcs11ModulePath: '/usr/lib/softhsm/libsofthsm2.so',
        slotId: 7,
        pin: 'SENTINEL_1234',
      );

      setUp(() {
        pkcs11 = _FakePkcs11Signing();
        gateway.submissionResult = const DeclarationResult(
          success: true,
          registrationNumber: 'CR-HW-OK',
        );
        handlerWithPkcs11 = SubmitDeclarationHandler(
          authProvider: auth,
          customsGateway: gateway,
          signing: signing,
          pkcs11Signing: pkcs11,
          auditLog: auditLog,
          authorization: authorization,
          clock: () => fixedNow,
        );
      });

      test('routes to Pkcs11SigningPort when command has HardwareTokenCredentials', () async {
        final result = await handlerWithPkcs11.handle(
          _buildCommand(signingCredentials: hwCreds),
        );
        expect(result.isOk, isTrue);

        // The hardware port WAS consulted with the right slot/pin.
        expect(pkcs11.lastSlotId, 7);
        expect(pkcs11.lastPinSeen, 'SENTINEL_1234');
      });

      test('records credentialType=hardware + tokenSerial (NOT pin) in submit.signed audit', () async {
        await handlerWithPkcs11.handle(
          _buildCommand(signingCredentials: hwCreds),
        );

        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        final signed = events.firstWhere((e) => e.action == 'submit.signed');
        expect(signed.payload['credentialType'], 'hardware');
        expect(signed.payload['tokenSerial'], 'HW-TOKEN-SERIAL-123');
        expect(signed.payload['signerCommonName'], 'MARIA PEREZ (FIRMA)');
        // CRITICAL regression: the PIN must NEVER appear in any audit
        // payload, including the submit.signed event.
        for (final e in events) {
          final payloadStr = e.payload.toString();
          expect(payloadStr, isNot(contains('SENTINEL_1234')),
              reason: 'Audit payload must never contain the PIN');
        }
      });

      test('software-path submissions record credentialType=software', () async {
        final result = await handlerWithPkcs11.handle(
          _buildCommand(
            signingCredentials: const SoftwareCertCredentials(),
          ),
        );
        expect(result.isOk, isTrue);
        final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
        final signed = events.firstWhere((e) => e.action == 'submit.signed');
        expect(signed.payload['credentialType'], 'software');
        expect(signed.payload.containsKey('tokenSerial'), isFalse);
        // The hardware port was NOT consulted.
        expect(pkcs11.lastSlotId, isNull);
      });

      test(
        'hardware creds without a Pkcs11SigningPort wired fail-closed '
        '(no silent software fallback)',
        () async {
          final handlerMissingPort = SubmitDeclarationHandler(
            authProvider: auth,
            customsGateway: gateway,
            signing: signing,
            // pkcs11Signing intentionally omitted
            auditLog: auditLog,
            authorization: authorization,
            clock: () => fixedNow,
          );
          final result = await handlerMissingPort.handle(
            _buildCommand(signingCredentials: hwCreds),
          );
          expect(result.isErr, isTrue);
          final failure =
              (result as Err<DeclarationResult>).failure as SigningFailedFailure;
          expect(failure.reason, contains('not wired'));

          // The submit.signing-failed audit event MUST carry
          // credentialType=hardware so ops can tell from the trail that
          // this was a misconfiguration, not a transient signing error.
          final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
          final failed =
              events.firstWhere((e) => e.action == 'submit.signing-failed');
          expect(failed.payload['credentialType'], 'hardware');
        },
      );

      test(
        'InvalidPinException propagates as SigningFailedFailure and logs '
        'pkcs11ErrorKind=InvalidPinException',
        () async {
          pkcs11.throwOnSign =
              const InvalidPinException('user PIN is incorrect');
          final result = await handlerWithPkcs11.handle(
            _buildCommand(signingCredentials: hwCreds),
          );
          expect(result.isErr, isTrue);
          final failure =
              (result as Err<DeclarationResult>).failure as SigningFailedFailure;
          expect(failure.reason, contains('incorrect'));

          final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
          final failed =
              events.firstWhere((e) => e.action == 'submit.signing-failed');
          expect(failed.payload['pkcs11ErrorKind'], 'InvalidPinException');
          // PIN must still not appear in the audit payload.
          expect(failed.payload.toString(),
              isNot(contains('SENTINEL_1234')));
        },
      );

      test(
        'PinLockedException propagates and is distinguishable in audit',
        () async {
          pkcs11.throwOnSign = const PinLockedException('user PIN is locked');
          final result = await handlerWithPkcs11.handle(
            _buildCommand(signingCredentials: hwCreds),
          );
          expect(result.isErr, isTrue);
          final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
          final failed =
              events.firstWhere((e) => e.action == 'submit.signing-failed');
          expect(failed.payload['pkcs11ErrorKind'], 'PinLockedException');
        },
      );

      test(
        'TokenNotPresentException propagates cleanly',
        () async {
          pkcs11.throwOnSign =
              const TokenNotPresentException('no token in slot');
          final result = await handlerWithPkcs11.handle(
            _buildCommand(signingCredentials: hwCreds),
          );
          expect(result.isErr, isTrue);
          final events = await auditLog.queryByEntity('Declaration', 'DECL-1');
          final failed =
              events.firstWhere((e) => e.action == 'submit.signing-failed');
          expect(
              failed.payload['pkcs11ErrorKind'], 'TokenNotPresentException');
        },
      );
    });
  });
}

class _AlwaysFailsRule implements ValidationRule<Declaration> {
  @override
  String get code => 'always-fails';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration _) async => Fail(
        ruleCode: code,
        severity: defaultSeverity,
        message: 'always-fails rule triggered',
      );
}

class _WarnsOnceRule implements ValidationRule<Declaration> {
  @override
  String get code => 'warns-once';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.warning;

  @override
  Future<RuleResult> evaluate(Declaration _) async => Fail(
        ruleCode: code,
        severity: defaultSeverity,
        message: 'soft warning',
      );
}

class _AlwaysPassesRule implements ValidationRule<Declaration> {
  @override
  String get code => 'always-passes';

  @override
  RuleSeverity get defaultSeverity => RuleSeverity.error;

  @override
  Future<RuleResult> evaluate(Declaration _) async => Pass(ruleCode: code);
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
  SigningCredentials signingCredentials = const SoftwareCertCredentials(),
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
    signingCredentials: signingCredentials,
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

class _FakePkcs11Signing implements Pkcs11SigningPort {
  /// If set, signWithToken throws this exception instead of returning a
  /// success. Used to test the typed-exception mapping branch.
  Pkcs11Exception? throwOnSign;

  /// Capture of the last signWithToken call for assertions.
  String? lastPinSeen;
  int? lastSlotId;

  SignResult result = SignResult(
    signatureBytes: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    signerCertificateDer:
        Uint8List.fromList(List<int>.generate(16, (i) => i + 100)),
    signerCommonName: 'MARIA PEREZ (FIRMA)',
    tokenSerial: 'HW-TOKEN-SERIAL-123',
    signedAt: DateTime.utc(2026, 4, 14, 10, 30),
  );

  @override
  Future<List<TokenSlot>> enumerateSlots(String pkcs11ModulePath) async {
    return const [];
  }

  @override
  Future<SignResult> signWithToken({
    required String pkcs11ModulePath,
    required int slotId,
    required String pin,
    required Uint8List dataToSign,
    required SignatureAlgorithm algorithm,
  }) async {
    lastPinSeen = pin;
    lastSlotId = slotId;
    final ex = throwOnSign;
    if (ex != null) throw ex;
    return result;
  }
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

  @override
  Future<VerificationResult> verifySignatureDetailed(String signedContent) async {
    return VerificationResult.success(
      signerCommonName: 'TEST SIGNER',
      verifiedAt: DateTime.utc(2026, 4, 14),
    );
  }
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
