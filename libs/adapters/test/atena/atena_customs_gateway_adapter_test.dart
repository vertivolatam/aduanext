/// Unit tests for [AtenaCustomsGatewayAdapter].
///
/// Exercises every public method through the in-process gRPC harness and
/// covers the CodeRabbit error-translation fixes from PR #4:
/// - C6: getDeclarationStatus registrationKey validation (4 segments AND
///       numeric number/year).
/// - C7: getDeclarationStatus throws on missing/unknown status (no silent
///       DRAFT fallback).
/// - C8/C12: jsonDecode FormatException / TypeError wrapped in
///   CustomsGatewayException.
/// - C13: uploadDocument throws when `path` field missing / empty (no raw
///       JSON fallback).
/// - C14: validateDeclaration returns valid:false with MALFORMED_RESPONSE on
///       FormatException / TypeError in payload parsing.
library;

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_adapters/src/generated/hacienda.pb.dart';
import 'package:aduanext_domain/domain.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

import '../helpers/declaration_fixture.dart';
import '../helpers/fake_services.dart';
import '../helpers/in_process_grpc_server.dart';

void main() {
  group('AtenaCustomsGatewayAdapter', () {
    late FakeApiService fake;
    late InProcessGrpcTestHarness harness;
    late AtenaCustomsGatewayAdapter adapter;

    setUp(() async {
      fake = FakeApiService();
      harness = await InProcessGrpcTestHarness.start([fake]);
      adapter = AtenaCustomsGatewayAdapter(
        channelManager: harness.channelManager,
      );
    });

    tearDown(() async {
      await harness.stop();
    });

    // -------------------------------------------------------------------------
    // validateDeclaration
    // -------------------------------------------------------------------------
    group('validateDeclaration', () {
      test('parses errors/warnings from a well-formed response', () async {
        fake.onValidateDeclaration = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload:
                  '{"errors":[{"code":"E1","message":"m1","field":"f1"}],'
                  '"warnings":[{"code":"W1","message":"w1"}]}',
            );

        final result = await adapter.validateDeclaration(
          buildMinimalDeclaration(),
        );
        expect(result.valid, isFalse);
        expect(result.errors.single.code, 'E1');
        expect(result.errors.single.field, 'f1');
        expect(result.warnings.single.code, 'W1');
      });

      test('valid:true when payload has no errors', () async {
        fake.onValidateDeclaration = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"errors":[],"warnings":[]}',
            );
        final result = await adapter.validateDeclaration(
          buildMinimalDeclaration(),
        );
        expect(result.valid, isTrue);
      });

      test('returns GRPC_ERROR when response.error is set', () async {
        fake.onValidateDeclaration = (_) =>
            ApiResponse(httpStatus: 500, error: 'sidecar error');
        final result = await adapter.validateDeclaration(
          buildMinimalDeclaration(),
        );
        expect(result.valid, isFalse);
        expect(result.errors.single.code, 'GRPC_ERROR');
      });

      test(
        'C14 regression: malformed JSON yields valid:false with '
        'MALFORMED_RESPONSE code (NOT silently true)',
        () async {
          fake.onValidateDeclaration = (_) => ApiResponse(
                httpStatus: 200, // <-- the dangerous 2xx + broken body case
                jsonPayload: 'not-json',
              );
          final result = await adapter.validateDeclaration(
            buildMinimalDeclaration(),
          );
          expect(result.valid, isFalse);
          expect(result.errors.single.code, 'MALFORMED_RESPONSE');
          expect(
            result.errors.single.message,
            contains('Malformed validation response JSON'),
          );
        },
      );

      test('wraps GrpcError as CustomsGatewayException', () async {
        fake.onValidateDeclaration = (_) =>
            throw GrpcError.unavailable('down');
        await expectLater(
          adapter.validateDeclaration(buildMinimalDeclaration()),
          throwsA(isA<CustomsGatewayException>()),
        );
      });

      test(
        'serializes every optional field and sub-entity (rich fixture)',
        () async {
          // This test drives every branch of _declarationToJson including
          // shipping, transit, sadValuation, items (with full procedure,
          // valuation, attachedDocuments, containers, vins, itemTaxes),
          // invoices, and globalTaxes. We assert on the request seen by the
          // fake server which is the exact string the adapter produced.
          fake.onValidateDeclaration = (_) => ApiResponse(
                httpStatus: 200,
                jsonPayload: '{"errors":[],"warnings":[]}',
              );
          final result =
              await adapter.validateDeclaration(buildRichDeclaration());
          expect(result.valid, isTrue);

          final payload = fake.lastValidateDeclaration!.jsonPayload;
          // Spot-check header, transit, and nested lists are present.
          expect(payload, contains('"id":7'));
          expect(payload, contains('"consigneeName":"Consignee Inc"'));
          expect(payload, contains('"beneficiaryName":"Beneficiary Co"'));
          expect(payload, contains('"transit"'));
          expect(payload, contains('"shipping"'));
          expect(payload, contains('"sadValuation"'));
          expect(payload, contains('"invoices"'));
          expect(payload, contains('"globalTaxes"'));
          expect(payload, contains('"containers"'));
          expect(payload, contains('"attachedDocuments"'));
          expect(payload, contains('"vins":["WVWXYZ1234567890"]'));
          expect(payload, contains('"itemTaxes"'));
          expect(payload, contains('"previousDocument"'));
          expect(payload, contains('"ignoredWarnings":["W1","W2"]'));
        },
      );
    });

    // -------------------------------------------------------------------------
    // submitDeclaration / liquidateDeclaration
    // -------------------------------------------------------------------------
    group('liquidateDeclaration / submitDeclaration', () {
      test('parses DeclarationResult on 2xx JSON response', () async {
        fake.onLiquidateDeclaration = (_) => ApiResponse(
              httpStatus: 201,
              jsonPayload:
                  '{"customsRegistrationNumber":"1234","assessmentSerial":"S",'
                  '"assessmentNumber":77,"assessmentDate":"2026-04-13"}',
            );
        final result = await adapter.liquidateDeclaration(
          buildMinimalDeclaration(),
        );
        expect(result.success, isTrue);
        expect(result.registrationNumber, '1234');
        expect(result.assessmentNumber, 77);
      });

      test(
        'malformed JSON still produces a DeclarationResult marked success on '
        '2xx (no crash) but with null registration fields',
        () async {
          fake.onLiquidateDeclaration = (_) =>
              ApiResponse(httpStatus: 200, jsonPayload: 'broken');
          final result = await adapter.liquidateDeclaration(
            buildMinimalDeclaration(),
          );
          expect(result.success, isTrue);
          expect(result.registrationNumber, isNull);
          expect(result.rawResponse, 'broken');
        },
      );

      test('response with error field yields success:false', () async {
        fake.onLiquidateDeclaration = (_) =>
            ApiResponse(httpStatus: 400, error: 'validation failed');
        final result = await adapter.liquidateDeclaration(
          buildMinimalDeclaration(),
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, 'validation failed');
      });

      test('submitDeclaration delegates to liquidate', () async {
        fake.onLiquidateDeclaration = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"customsRegistrationNumber":"Y"}',
            );
        final result =
            await adapter.submitDeclaration(buildMinimalDeclaration());
        expect(result.success, isTrue);
        expect(result.registrationNumber, 'Y');
      });

      test('wraps GrpcError as CustomsGatewayException', () async {
        fake.onLiquidateDeclaration = (_) =>
            throw GrpcError.internal('boom');
        await expectLater(
          adapter.liquidateDeclaration(buildMinimalDeclaration()),
          throwsA(
            isA<CustomsGatewayException>()
                .having((e) => e.grpcCode, 'grpcCode', 'INTERNAL'),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // rectifyDeclaration
    // -------------------------------------------------------------------------
    group('rectifyDeclaration', () {
      test('returns success:false when validateRectification has error',
          () async {
        fake.onValidateRectification = (_) =>
            ApiResponse(httpStatus: 400, error: 'bad rectification');
        final result = await adapter.rectifyDeclaration(
          buildMinimalDeclaration(),
          buildMinimalDeclaration(),
        );
        expect(result.success, isFalse);
        expect(result.errorMessage, 'bad rectification');
      });

      test('calls rectifyDeclaration when validation passes', () async {
        fake.onValidateRectification = (_) =>
            ApiResponse(httpStatus: 200, jsonPayload: '{"ok":true}');
        fake.onRectifyDeclaration = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"customsRegistrationNumber":"R1"}',
            );
        final result = await adapter.rectifyDeclaration(
          buildMinimalDeclaration(),
          buildMinimalDeclaration(),
        );
        expect(result.success, isTrue);
        expect(result.registrationNumber, 'R1');
      });

      test('wraps GrpcError', () async {
        fake.onValidateRectification = (_) =>
            throw GrpcError.unknown('mystery');
        await expectLater(
          adapter.rectifyDeclaration(
            buildMinimalDeclaration(),
            buildMinimalDeclaration(),
          ),
          throwsA(isA<CustomsGatewayException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getDeclarationStatus
    // -------------------------------------------------------------------------
    group('getDeclarationStatus', () {
      test('parses known status code into enum', () async {
        fake.onGetDeclaration = (_) => GetDeclarationResponse(
              httpStatus: 200,
              jsonPayload: '{"status":"REGISTERED"}',
            );
        final status =
            await adapter.getDeclarationStatus('001-A-123-2026');
        expect(status, DeclarationStatus.registered);
        final req = fake.lastGetDeclaration!;
        expect(req.customsOfficeCode, '001');
        expect(req.serial, 'A');
        expect(req.number, 123);
        expect(req.year, 2026);
      });

      test('C6 regression: rejects 3-segment registrationKey', () async {
        await expectLater(
          adapter.getDeclarationStatus('001-A-123'),
          throwsA(
            isA<CustomsGatewayException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('4 segments'),
                contains('001-A-123'),
              ),
            ),
          ),
        );
      });

      test('C6 regression: rejects non-numeric number/year segments',
          () async {
        await expectLater(
          adapter.getDeclarationStatus('001-A-XXX-2026'),
          throwsA(
            isA<CustomsGatewayException>().having(
              (e) => e.message,
              'message',
              contains('numeric number/year'),
            ),
          ),
        );
        await expectLater(
          adapter.getDeclarationStatus('001-A-123-YYYY'),
          throwsA(
            isA<CustomsGatewayException>().having(
              (e) => e.message,
              'message',
              contains('numeric number/year'),
            ),
          ),
        );
      });

      test(
        'C7 regression: throws on missing status field (no DRAFT fallback)',
        () async {
          fake.onGetDeclaration = (_) => GetDeclarationResponse(
                httpStatus: 200,
                jsonPayload: '{"somethingElse":"X"}',
              );
          await expectLater(
            adapter.getDeclarationStatus('001-A-123-2026'),
            throwsA(
              isA<CustomsGatewayException>().having(
                (e) => e.message,
                'message',
                contains('Declaration status missing'),
              ),
            ),
          );
        },
      );

      test(
        'C7 regression: throws on unknown status code (no silent DRAFT '
        'fallback)',
        () async {
          fake.onGetDeclaration = (_) => GetDeclarationResponse(
                httpStatus: 200,
                jsonPayload: '{"status":"GALACTIC_UNKNOWN"}',
              );
          await expectLater(
            adapter.getDeclarationStatus('001-A-123-2026'),
            throwsA(
              isA<CustomsGatewayException>().having(
                (e) => e.message,
                'message',
                contains('Unknown declaration status'),
              ),
            ),
          );
        },
      );

      test(
        'C12 regression: malformed JSON yields CustomsGatewayException',
        () async {
          fake.onGetDeclaration = (_) => GetDeclarationResponse(
                httpStatus: 200,
                jsonPayload: '<<not json>>',
              );
          await expectLater(
            adapter.getDeclarationStatus('001-A-123-2026'),
            throwsA(
              isA<CustomsGatewayException>().having(
                (e) => e.message,
                'message',
                contains('Malformed JSON'),
              ),
            ),
          );
        },
      );

      test('response.error bubbles up to CustomsGatewayException', () async {
        fake.onGetDeclaration = (_) => GetDeclarationResponse(
              httpStatus: 404,
              error: 'declaration not found',
            );
        await expectLater(
          adapter.getDeclarationStatus('001-A-123-2026'),
          throwsA(
            isA<CustomsGatewayException>()
                .having((e) => e.httpStatus, 'httpStatus', 404),
          ),
        );
      });

      test('wraps GrpcError', () async {
        fake.onGetDeclaration = (_) =>
            throw GrpcError.unavailable('sidecar');
        await expectLater(
          adapter.getDeclarationStatus('001-A-123-2026'),
          throwsA(
            isA<CustomsGatewayException>()
                .having((e) => e.grpcCode, 'grpcCode', 'UNAVAILABLE'),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // uploadAttachment
    // -------------------------------------------------------------------------
    group('uploadAttachment', () {
      test('returns path on success', () async {
        fake.onUploadDocument = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"path":"/uploads/invoice-001.pdf"}',
            );
        final path = await adapter.uploadAttachment(
          declarationId: 'DECL-1',
          docCode: '380',
          docReference: 'INV-001',
          fileBytes: [1, 2, 3],
          fileName: 'invoice.pdf',
        );
        expect(path, '/uploads/invoice-001.pdf');
        final req = fake.lastUploadDocument!;
        expect(req.declarationId, 'DECL-1');
        expect(req.contentType, 'application/pdf');
      });

      test('content-type inference handles known extensions', () async {
        fake.onUploadDocument = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"path":"/uploads/x"}',
            );
        for (final (name, expected) in const [
          ('a.pdf', 'application/pdf'),
          ('a.xml', 'application/xml'),
          ('a.jpg', 'image/jpeg'),
          ('a.JPEG', 'image/jpeg'),
          ('a.png', 'image/png'),
          ('a.zip', 'application/zip'),
          ('a.bin', 'application/octet-stream'),
        ]) {
          await adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: name,
          );
          expect(fake.lastUploadDocument?.contentType, expected,
              reason: name);
        }
      });

      test('C13 regression: throws when response path is missing', () async {
        fake.onUploadDocument = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"notPath":"x"}',
            );
        await expectLater(
          adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: 'a.pdf',
          ),
          throwsA(
            isA<CustomsGatewayException>().having(
              (e) => e.message,
              'message',
              contains('missing required "path"'),
            ),
          ),
        );
      });

      test('C13 regression: throws when response path is empty', () async {
        fake.onUploadDocument = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: '{"path":""}',
            );
        await expectLater(
          adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: 'a.pdf',
          ),
          throwsA(isA<CustomsGatewayException>()),
        );
      });

      test('malformed JSON response is wrapped with Malformed JSON message',
          () async {
        fake.onUploadDocument = (_) => ApiResponse(
              httpStatus: 200,
              jsonPayload: 'not-json',
            );
        await expectLater(
          adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: 'a.pdf',
          ),
          throwsA(
            isA<CustomsGatewayException>().having(
              (e) => e.message,
              'message',
              contains('Malformed JSON'),
            ),
          ),
        );
      });

      test('response.error surfaces as CustomsGatewayException', () async {
        fake.onUploadDocument = (_) =>
            ApiResponse(httpStatus: 502, error: 'upstream down');
        await expectLater(
          adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: 'a.pdf',
          ),
          throwsA(
            isA<CustomsGatewayException>()
                .having((e) => e.httpStatus, 'httpStatus', 502),
          ),
        );
      });

      test('wraps GrpcError', () async {
        fake.onUploadDocument = (_) =>
            throw GrpcError.cancelled('abort');
        await expectLater(
          adapter.uploadAttachment(
            declarationId: 'D',
            docCode: '1',
            docReference: 'R',
            fileBytes: [0],
            fileName: 'a.pdf',
          ),
          throwsA(
            isA<CustomsGatewayException>()
                .having((e) => e.grpcCode, 'grpcCode', 'CANCELLED'),
          ),
        );
      });
    });
  });
}
