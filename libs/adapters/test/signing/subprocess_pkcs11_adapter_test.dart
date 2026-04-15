/// Unit + integration tests for [SubprocessPkcs11SigningAdapter].
///
/// Unit tests drive a fake Dart helper script that mimics the Go
/// helper's wire protocol. They cover every error-code mapping, the
/// happy path, the PIN-never-in-exception regression, and the timeout
/// behaviour.
///
/// The optional integration test at the bottom is gated on the
/// PKCS11_HELPER_PATH + SOFTHSM2_MODULE env vars. It exercises the
/// REAL Go helper from VRTV-69 against the SoftHSM2 fixture. CI sets
/// these vars in the pkcs11-ci workflow; local runs skip silently.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:aduanext_adapters/adapters.dart';
import 'package:aduanext_domain/domain.dart';
import 'package:test/test.dart';

// Path to the fake helper script. Relative to the adapters package
// root so `dart test` resolves it correctly.
const _fakeHelperScript = 'test/signing/fake_pkcs11_helper.dart';

/// Native compiled binary of the fake helper. Built once per test
/// run by [setUpAll] and reused. Using `dart compile exe` avoids the
/// `dart run` preamble ("Running build hooks…") which would
/// otherwise leak into stdout and confuse JSON parsing.
late String _fakeHelperBinary;

Future<void> _compileFakeHelper() async {
  final out = '${Directory.systemTemp.path}/fake_pkcs11_helper_${DateTime.now().microsecondsSinceEpoch}';
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['compile', 'exe', '-o', out, _fakeHelperScript],
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw StateError('Failed to compile fake helper: ${result.stderr}');
  }
  _fakeHelperBinary = out;
}

SubprocessPkcs11SigningAdapter _buildAdapterWith(
  String scenario, {
  Duration timeout = const Duration(seconds: 5),
}) {
  return SubprocessPkcs11SigningAdapter(
    helperBinaryPath: _fakeHelperBinary,
    timeout: timeout,
    environment: {'FAKE_HELPER_SCENARIO': scenario},
  );
}

void main() {
  setUpAll(() async {
    await _compileFakeHelper();
  });

  tearDownAll(() async {
    try {
      await File(_fakeHelperBinary).delete();
    } catch (_) {}
  });

  group('resolveHelperBinary', () {
    test('returns PKCS11_HELPER_PATH when it exists', () async {
      final tmp = await File('${Directory.systemTemp.path}/fake-helper-${DateTime.now().microsecondsSinceEpoch}')
          .create();
      try {
        final resolved = resolveHelperBinary(
          environment: {'PKCS11_HELPER_PATH': tmp.path},
        );
        expect(resolved, tmp.path);
      } finally {
        await tmp.delete();
      }
    });

    test('returns null when nothing is found', () {
      final resolved = resolveHelperBinary(
        environment: {'PKCS11_HELPER_PATH': '/nonexistent/path'},
        additionalCandidates: ['/also/nonexistent'],
      );
      expect(resolved, isNull);
    });

    test('prefers env var over additional candidates', () async {
      final env = await File('${Directory.systemTemp.path}/env-helper-${DateTime.now().microsecondsSinceEpoch}')
          .create();
      final extra = await File('${Directory.systemTemp.path}/extra-helper-${DateTime.now().microsecondsSinceEpoch}')
          .create();
      try {
        final resolved = resolveHelperBinary(
          environment: {'PKCS11_HELPER_PATH': env.path},
          additionalCandidates: [extra.path],
        );
        expect(resolved, env.path);
      } finally {
        await env.delete();
        await extra.delete();
      }
    });
  });

  group('SubprocessPkcs11SigningAdapter (fake helper)', () {
    test('enumerateSlots happy path parses full slot metadata', () async {
      final adapter = _buildAdapterWith('happy');
      final slots = await adapter.enumerateSlots('/fake/module.so');
      expect(slots, hasLength(2));
      final first = slots.first;
      expect(first.slotId, 7);
      expect(first.tokenLabel, 'BCCR IDPrime MD 830');
      expect(first.tokenSerial, 'ABC123');
      expect(first.manufacturer, 'Gemalto');
      expect(first.hasCert, isTrue);
      expect(first.certCommonName, 'MARIA PEREZ (FIRMA)');
      expect(first.certNotAfter?.isUtc, isTrue);
      expect(slots[1].hasCert, isFalse);
    });

    test('signWithToken happy path decodes signature + cert + serial', () async {
      final adapter = _buildAdapterWith('happy');
      final result = await adapter.signWithToken(
        pkcs11ModulePath: '/fake/module.so',
        slotId: 7,
        pin: 'secret-1234',
        dataToSign: Uint8List.fromList('payload'.codeUnits),
        algorithm: SignatureAlgorithm.rsaPkcs1Sha256,
      );
      expect(result.signatureBytes, hasLength(32));
      expect(result.signerCertificateDer, hasLength(16));
      expect(result.signerCommonName, 'MARIA PEREZ (FIRMA)');
      expect(result.tokenSerial, 'ABC123');
      expect(result.signedAt.isUtc, isTrue);
    });

    test('INVALID_PIN maps to InvalidPinException', () async {
      final adapter = _buildAdapterWith('bad_pin');
      await expectLater(
        () => adapter.signWithToken(
          pkcs11ModulePath: '/fake/module.so',
          slotId: 7,
          pin: 'wrong',
          dataToSign: Uint8List.fromList([1, 2, 3]),
          algorithm: SignatureAlgorithm.rsaPkcs1Sha256,
        ),
        throwsA(isA<InvalidPinException>()),
      );
    });

    test('PIN_LOCKED maps to PinLockedException', () async {
      final adapter = _buildAdapterWith('pin_locked');
      await expectLater(
        () => adapter.signWithToken(
          pkcs11ModulePath: '/fake/module.so',
          slotId: 7,
          pin: 'x',
          dataToSign: Uint8List.fromList([1]),
          algorithm: SignatureAlgorithm.rsaPkcs1Sha256,
        ),
        throwsA(isA<PinLockedException>()),
      );
    });

    test('TOKEN_NOT_PRESENT maps to TokenNotPresentException', () async {
      final adapter = _buildAdapterWith('token_missing');
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<TokenNotPresentException>()),
      );
    });

    test('MODULE_LOAD maps to ModuleLoadException', () async {
      final adapter = _buildAdapterWith('bad_module');
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<ModuleLoadException>()),
      );
    });

    test('UNSUPPORTED_MECHANISM maps to UnsupportedMechanismException', () async {
      final adapter = _buildAdapterWith('unsupported_mech');
      await expectLater(
        () => adapter.signWithToken(
          pkcs11ModulePath: '/fake/module.so',
          slotId: 7,
          pin: 'x',
          dataToSign: Uint8List.fromList([1]),
          algorithm: SignatureAlgorithm.rsaPssSha256,
        ),
        throwsA(isA<UnsupportedMechanismException>()),
      );
    });

    test('crashed helper maps to HelperProtocolException', () async {
      final adapter = _buildAdapterWith('crash');
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<HelperProtocolException>()),
      );
    });

    test('non-JSON stdout maps to HelperProtocolException', () async {
      final adapter = _buildAdapterWith('garbage');
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<HelperProtocolException>()),
      );
    });

    test('hung helper is killed by the timeout', () async {
      final adapter = _buildAdapterWith(
        'hang',
        timeout: const Duration(milliseconds: 500),
      );
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<HelperProtocolException>()),
      );
    });

    test('REGRESSION: PIN never appears in the thrown exception text', () async {
      const sentinelPin = 'SENTINEL_PIN_c5b72a';
      final adapter = _buildAdapterWith('echo_pin');
      try {
        await adapter.signWithToken(
          pkcs11ModulePath: '/fake/module.so',
          slotId: 7,
          pin: sentinelPin,
          dataToSign: Uint8List.fromList([9, 9, 9]),
          algorithm: SignatureAlgorithm.rsaPkcs1Sha256,
        );
        fail('should have thrown');
      } on Pkcs11Exception catch (e) {
        expect(
          e.toString(),
          isNot(contains(sentinelPin)),
          reason: 'PIN must never be included in exception messages',
        );
      }
    });
  });

  group('SubprocessPkcs11SigningAdapter binary resolution', () {
    test('missing explicit binary path throws HelperBinaryNotFoundException',
        () async {
      final adapter = SubprocessPkcs11SigningAdapter(
        helperBinaryPath: '/definitely/not/a/real/binary/xyz',
      );
      await expectLater(
        () => adapter.enumerateSlots('/fake/module.so'),
        throwsA(isA<HelperBinaryNotFoundException>()),
      );
    });
  });

  // --------------------------------------------------------------------------
  // OPT-IN integration test against the REAL Go helper + SoftHSM2.
  //
  // Gated on PKCS11_HELPER_PATH and SOFTHSM2_MODULE. CI's pkcs11-ci workflow
  // exports both; `dart test` on a developer workstation without SoftHSM2
  // simply sees the skip and moves on.
  // --------------------------------------------------------------------------
  group('real Go helper + SoftHSM2', () {
    final helperPath = Platform.environment['PKCS11_HELPER_PATH'];
    final modulePath = Platform.environment['SOFTHSM2_MODULE'];
    final pin = Platform.environment['SOFTHSM2_USER_PIN'] ?? '1234';
    final slotIdStr = Platform.environment['SOFTHSM2_SLOT_ID'];

    final skip = helperPath == null ||
            modulePath == null ||
            slotIdStr == null
        ? 'requires PKCS11_HELPER_PATH + SOFTHSM2_MODULE + SOFTHSM2_SLOT_ID'
        : null;

    test('enumerateSlots sees the SoftHSM2 test token', () async {
      final adapter = SubprocessPkcs11SigningAdapter(
        helperBinaryPath: helperPath!,
      );
      final slots = await adapter.enumerateSlots(modulePath!);
      expect(slots, isNotEmpty);
      final matching = slots.where((s) => s.slotId == int.parse(slotIdStr!));
      expect(matching, hasLength(1));
      expect(matching.first.hasCert, isTrue);
    }, skip: skip);

    test('signWithToken roundtrips against SoftHSM2', () async {
      final adapter = SubprocessPkcs11SigningAdapter(
        helperBinaryPath: helperPath!,
      );
      final result = await adapter.signWithToken(
        pkcs11ModulePath: modulePath!,
        slotId: int.parse(slotIdStr!),
        pin: pin,
        dataToSign: Uint8List.fromList('AduaNext Dart integration test'.codeUnits),
        algorithm: SignatureAlgorithm.rsaPkcs1Sha256,
      );
      expect(result.signatureBytes, isNotEmpty);
      expect(result.signerCertificateDer, isNotEmpty);
      expect(result.tokenSerial, isNotEmpty);
    }, skip: skip);
  });
}
