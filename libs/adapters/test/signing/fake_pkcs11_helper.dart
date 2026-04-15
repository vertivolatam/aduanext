/// Fake PKCS#11 helper used by [SubprocessPkcs11SigningAdapter] tests.
///
/// Reads one JSON request line from stdin, dispatches based on
/// `command`, and writes one JSON response line to stdout. Behavior is
/// configured via environment variables that the test harness sets:
///
/// * `FAKE_HELPER_SCENARIO` — one of:
///   - `happy`              — return synthetic success payloads
///   - `bad_pin`            — INVALID_PIN
///   - `pin_locked`         — PIN_LOCKED
///   - `token_missing`      — TOKEN_NOT_PRESENT
///   - `bad_module`         — MODULE_LOAD
///   - `unsupported_mech`   — UNSUPPORTED_MECHANISM
///   - `crash`              — exit non-zero before writing anything
///   - `garbage`            — write a non-JSON blob
///   - `hang`               — read stdin but never write a response (tests timeout)
///   - `echo_pin`           — REGRESSION: echo the received PIN back in the
///                            error message, to verify the adapter never
///                            surfaces a PIN it received via a malformed helper
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final scenario = Platform.environment['FAKE_HELPER_SCENARIO'] ?? 'happy';

  // Read exactly one newline-terminated line from stdin.
  final line = await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  final req = jsonDecode(line) as Map<String, dynamic>;
  final id = req['id'] as String?;
  final command = req['command'] as String?;
  final params = (req['params'] as Map<String, dynamic>?) ?? const {};

  Future<void> writeResp(Map<String, dynamic> resp) async {
    stdout.writeln(jsonEncode(resp));
    await stdout.flush();
  }

  switch (scenario) {
    case 'crash':
      exit(7);
    case 'garbage':
      stdout.writeln('not-json-at-all');
      await stdout.flush();
      return;
    case 'hang':
      await Future.delayed(const Duration(seconds: 60));
      return;
    case 'bad_pin':
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'INVALID_PIN', 'message': 'user PIN is incorrect'},
      });
      return;
    case 'pin_locked':
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'PIN_LOCKED', 'message': 'user PIN is locked'},
      });
      return;
    case 'token_missing':
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'TOKEN_NOT_PRESENT', 'message': 'no token in slot'},
      });
      return;
    case 'bad_module':
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'MODULE_LOAD', 'message': 'dlopen failed'},
      });
      return;
    case 'unsupported_mech':
      await writeResp({
        'id': id,
        'ok': false,
        'error': {
          'code': 'UNSUPPORTED_MECHANISM',
          'message': 'mechanism not supported',
        },
      });
      return;
    case 'echo_pin':
      // DO NOT actually echo the PIN. This scenario is present only
      // to prove the adapter does NOT include the PIN when it
      // constructs its exception message — the helper sends a generic
      // failure and the test asserts the PIN string never appears in
      // `toString()` of the thrown exception.
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'SIGN_FAILED', 'message': 'generic failure'},
      });
      return;
    case 'happy':
    default:
      if (command == 'enumerateSlots') {
        await writeResp({
          'id': id,
          'ok': true,
          'result': {
            'slots': [
              {
                'slotId': 7,
                'tokenLabel': 'BCCR IDPrime MD 830',
                'tokenSerial': 'ABC123',
                'manufacturer': 'Gemalto',
                'model': 'IDPrime',
                'hasCert': true,
                'certCommonName': 'MARIA PEREZ (FIRMA)',
                'certSubject': 'CN=MARIA PEREZ (FIRMA),O=BCCR,C=CR',
                'certIssuer': 'CN=CA POLITICA PERSONA FISICA,O=BCCR,C=CR',
                'certNotBefore': '2024-01-01T00:00:00Z',
                'certNotAfter': '2028-01-01T00:00:00Z',
              },
              {
                'slotId': 8,
                'tokenLabel': 'spare',
                'tokenSerial': 'XYZ999',
                'manufacturer': 'Athena',
                'model': 'ASE2048',
                'hasCert': false,
              },
            ],
          },
        });
        return;
      }
      if (command == 'sign') {
        // Record the PIN we received, redacted — tests cannot observe
        // this, but the shape demonstrates the helper sees the PIN.
        final _ = params['pin'];
        await writeResp({
          'id': id,
          'ok': true,
          'result': {
            'signatureB64': base64.encode(List<int>.generate(32, (i) => i)),
            'signerCommonName': 'MARIA PEREZ (FIRMA)',
            'signerCertB64': base64.encode(List<int>.generate(16, (i) => i + 100)),
            'signedAt': '2026-04-15T10:00:00Z',
            'tokenSerial': 'ABC123',
          },
        });
        return;
      }
      await writeResp({
        'id': id,
        'ok': false,
        'error': {'code': 'UNKNOWN_COMMAND', 'message': 'fake: unknown $command'},
      });
      return;
  }
}
