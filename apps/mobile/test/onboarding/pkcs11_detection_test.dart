/// Unit tests for the helper-binary probe.
library;

import 'package:aduanext_mobile/features/onboarding/pkcs11_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('helperCandidatePaths', () {
    test('includes the env override first when set', () {
      final paths = helperCandidatePaths(environment: {
        'PKCS11_HELPER_PATH': '/custom/aduanext-helper',
      });
      expect(paths.first, '/custom/aduanext-helper');
      expect(paths, contains('/usr/local/bin/aduanext-pkcs11-helper'));
      expect(paths, contains('/opt/aduanext/pkcs11-helper'));
    });

    test('omits the env entry when empty', () {
      final paths =
          helperCandidatePaths(environment: {'PKCS11_HELPER_PATH': ''});
      expect(paths.first, '/usr/local/bin/aduanext-pkcs11-helper');
    });
  });

  group('detectHelperBinary', () {
    test('returns the first candidate whose probe exits 0', () async {
      final probed = <String>[];
      Future<int> probe(String path) async {
        probed.add(path);
        return path == '/opt/aduanext/pkcs11-helper' ? 0 : 1;
      }

      final resolved = await detectHelperBinary(
        probe: probe,
        environment: const <String, String>{},
      );
      expect(resolved, '/opt/aduanext/pkcs11-helper');
      expect(probed.first, '/usr/local/bin/aduanext-pkcs11-helper');
    });

    test('returns null when every probe fails', () async {
      final resolved = await detectHelperBinary(
        probe: (_) async => 1,
        environment: const <String, String>{},
      );
      expect(resolved, isNull);
    });
  });

  group('probeForOnboarding', () {
    test('missing when probes all fail', () async {
      final r = await probeForOnboarding(
        probe: (_) async => -1,
        environment: const <String, String>{},
      );
      expect(r.state, HelperDetection.missing);
      expect(r.resolvedPath, isNull);
    });

    test('present reports the resolved path', () async {
      final r = await probeForOnboarding(
        probe: (p) async => p == '/usr/local/bin/aduanext-pkcs11-helper'
            ? 0
            : 1,
        environment: const <String, String>{},
      );
      expect(r.state, HelperDetection.present);
      expect(r.resolvedPath, '/usr/local/bin/aduanext-pkcs11-helper');
    });
  });
}
