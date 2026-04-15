/// Unit tests for [HaciendaSigningAdapter].
///
/// Coverage:
/// - sign(), signAndEncode(), verifySignature() happy + error paths.
/// - Defensive copy of p12Bytes at construction (mutation after construction
///   must not affect the adapter's payload).
/// - Per-call CallOptions (deadline) — we can't observe the actual timeout
///   from the server side but we can assert that the adapter applies its
///   configured timeout by setting an absurdly small timeout and observing
///   a DEADLINE_EXCEEDED mapped to SigningException.
/// - Regression: GrpcError wrapping for all 3 RPCs.
library;

import 'dart:async';

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_adapters/src/generated/hacienda.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:test/test.dart';

import '../helpers/fake_services.dart';
import '../helpers/in_process_grpc_server.dart';

void main() {
  group('HaciendaSigningAdapter', () {
    late FakeSignerService fake;
    late InProcessGrpcTestHarness harness;

    const pin = 'pin-1234';
    final p12 = List<int>.generate(8, (i) => i);

    HaciendaSigningAdapter build({
      Duration timeout = HaciendaSigningAdapter.defaultSigningTimeout,
      List<int>? customP12,
    }) {
      return HaciendaSigningAdapter(
        channelManager: harness.channelManager,
        p12Bytes: customP12 ?? p12,
        p12Pin: pin,
        signingTimeout: timeout,
      );
    }

    setUp(() async {
      fake = FakeSignerService();
      harness = await InProcessGrpcTestHarness.start([fake]);
    });

    tearDown(() async {
      await harness.stop();
    });

    test('sign() returns success SigningResult on signedXml response',
        () async {
      fake.onSignXml = (_) => SignXmlResponse(signedXml: '<Signed/>');
      final adapter = build();
      final result = await adapter.sign('<Root/>');
      expect(result.success, isTrue);
      expect(result.signedContent, '<Signed/>');
      expect(fake.lastSignXml?.xml, '<Root/>');
      expect(fake.lastSignXml?.p12Pin, pin);
      expect(fake.lastSignXml?.p12Buffer, p12);
    });

    test('sign() returns failure SigningResult on response.error', () async {
      fake.onSignXml = (_) => SignXmlResponse(error: 'bad p12');
      final adapter = build();
      final result = await adapter.sign('<Root/>');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'bad p12');
    });

    test('sign() wraps GrpcError as SigningException', () async {
      fake.onSignXml = (_) => throw GrpcError.unavailable('no sidecar');
      final adapter = build();
      await expectLater(
        adapter.sign('<X/>'),
        throwsA(
          isA<SigningException>()
              .having((e) => e.grpcCode, 'grpcCode', 'UNAVAILABLE'),
        ),
      );
    });

    test('signAndEncode() happy path returns base64SignedXml', () async {
      fake.onSignAndEncode = (_) =>
          SignAndEncodeResponse(base64SignedXml: 'ZmFrZS1iYXNlNjQ=');
      final adapter = build();
      final result = await adapter.signAndEncode('<X/>');
      expect(result.success, isTrue);
      expect(result.signedContent, 'ZmFrZS1iYXNlNjQ=');
    });

    test('signAndEncode() error field is returned as failure', () async {
      fake.onSignAndEncode = (_) =>
          SignAndEncodeResponse(error: 'encode failure');
      final adapter = build();
      final result = await adapter.signAndEncode('<X/>');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'encode failure');
    });

    test('signAndEncode() wraps GrpcError', () async {
      fake.onSignAndEncode = (_) => throw GrpcError.internal('crash');
      final adapter = build();
      await expectLater(
        adapter.signAndEncode('<X/>'),
        throwsA(isA<SigningException>()),
      );
    });

    test(
      'verifySignatureDetailed() returns degraded result with '
      'structuralValid=true when the sidecar says valid',
      () async {
        fake.onVerifySignature = (_) => VerifySignatureResponse(
              valid: true,
              signerCn: 'PERSONA FISICA 123456',
            );
        final adapter = build();
        final r = await adapter.verifySignatureDetailed('<Signed/>');
        expect(r.structuralValid, isTrue);
        expect(r.degraded, isTrue,
            reason:
                'Sidecar only performs structural check today — result '
                'MUST be marked degraded so the UI warns the operator.');
        expect(r.valid, isFalse,
            reason: 'degraded results are NEVER overall-valid.');
        expect(r.signerCommonName, 'PERSONA FISICA 123456');
      },
    );

    test(
      'verifySignatureDetailed() returns degraded result with '
      'structuralValid=false when the sidecar says invalid',
      () async {
        fake.onVerifySignature = (_) => VerifySignatureResponse(valid: false);
        final adapter = build();
        final r = await adapter.verifySignatureDetailed('<Signed/>');
        expect(r.structuralValid, isFalse);
        expect(r.valid, isFalse);
        expect(r.degraded, isTrue);
      },
    );

    test(
      'verifySignatureDetailed() returns failure (not degraded) when the '
      'sidecar returns an explicit error',
      () async {
        fake.onVerifySignature = (_) =>
            VerifySignatureResponse(error: 'cert not trusted');
        final adapter = build();
        final r = await adapter.verifySignatureDetailed('<Signed/>');
        expect(r.valid, isFalse);
        expect(r.reason, contains('cert not trusted'));
        expect(r.degraded, isFalse);
      },
    );

    test(
      'verifySignature() boolean wrapper returns false whenever the detailed '
      'result is degraded (never promotes degraded results to true)',
      () async {
        fake.onVerifySignature = (_) => VerifySignatureResponse(valid: true);
        final adapter = build();
        expect(await adapter.verifySignature('<Signed/>'), isFalse,
            reason:
                'A degraded result carries valid=false — the Boolean wrapper '
                'must mirror that so callers never treat structural-only '
                'verification as legally binding.');
      },
    );

    test('verifySignatureDetailed() wraps GrpcError as SigningException',
        () async {
      fake.onVerifySignature = (_) =>
          throw GrpcError.deadlineExceeded('slow');
      final adapter = build();
      await expectLater(
        adapter.verifySignatureDetailed('<Signed/>'),
        throwsA(
          isA<SigningException>()
              .having((e) => e.grpcCode, 'grpcCode', 'DEADLINE_EXCEEDED'),
        ),
      );
    });

    test('toAuditPayload includes every field', () async {
      fake.onVerifySignature = (_) => VerifySignatureResponse(
            valid: true,
            signerCn: 'JANE DOE',
          );
      final adapter = build();
      final r = await adapter.verifySignatureDetailed('<Signed/>');
      final payload = r.toAuditPayload();
      expect(payload['valid'], isFalse);
      expect(payload['structuralValid'], isTrue);
      expect(payload['degraded'], isTrue);
      expect(payload['signerCommonName'], 'JANE DOE');
      expect(payload['ocspStatus'], 'skipped');
      expect(payload['verifiedAt'], isA<String>());
    });

    test(
      'defensive copy: mutating the p12Bytes list after construction does '
      'NOT affect the adapter payload',
      () async {
        final mutableKey = <int>[1, 2, 3, 4, 5];
        fake.onSignXml = (_) => SignXmlResponse(signedXml: 'ok');
        final adapter = build(customP12: mutableKey);

        // Mutate after construction.
        mutableKey[0] = 99;
        mutableKey.add(777);

        await adapter.sign('<X/>');

        expect(fake.lastSignXml?.p12Buffer, [1, 2, 3, 4, 5],
            reason: 'Adapter must hold an immutable copy of the key bytes.');
      },
    );

    test(
      'per-call deadline: a 1ms timeout triggers DEADLINE_EXCEEDED which is '
      'wrapped as SigningException',
      () async {
        fake.onSignXml = (_) async {
          // Sleep longer than the adapter's timeout.
          await Future<void>.delayed(const Duration(seconds: 2));
          return SignXmlResponse(signedXml: 'late');
        };
        final adapter = build(timeout: const Duration(milliseconds: 1));
        await expectLater(
          adapter.sign('<X/>'),
          throwsA(
            isA<SigningException>().having(
              (e) => e.grpcCode,
              'grpcCode',
              'DEADLINE_EXCEEDED',
            ),
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
