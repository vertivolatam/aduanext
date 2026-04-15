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

    test('verifySignature() returns valid bool on success', () async {
      fake.onVerifySignature = (_) =>
          VerifySignatureResponse(valid: true);
      final adapter = build();
      expect(await adapter.verifySignature('<Signed/>'), isTrue);

      fake.onVerifySignature = (_) =>
          VerifySignatureResponse(valid: false);
      expect(await adapter.verifySignature('<Signed/>'), isFalse);
    });

    test('verifySignature() throws SigningException on response.error',
        () async {
      fake.onVerifySignature = (_) =>
          VerifySignatureResponse(error: 'cert not trusted');
      final adapter = build();
      await expectLater(
        adapter.verifySignature('<Signed/>'),
        throwsA(
          isA<SigningException>().having(
            (e) => e.message,
            'message',
            contains('cert not trusted'),
          ),
        ),
      );
    });

    test('verifySignature() wraps GrpcError', () async {
      fake.onVerifySignature = (_) =>
          throw GrpcError.deadlineExceeded('slow');
      final adapter = build();
      await expectLater(
        adapter.verifySignature('<Signed/>'),
        throwsA(
          isA<SigningException>()
              .having((e) => e.grpcCode, 'grpcCode', 'DEADLINE_EXCEEDED'),
        ),
      );
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
