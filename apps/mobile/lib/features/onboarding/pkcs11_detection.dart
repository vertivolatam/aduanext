/// PKCS#11 helper-binary detection for the onboarding wizard.
///
/// Runs on step entry, picks up the same environment variable +
/// install locations as `SubprocessPkcs11SigningAdapter` in
/// `libs/adapters`, and reports:
///
///   * "Web"  — we're on Flutter Web, which cannot spawn subprocesses
///     (`Process.run` is desktop/mobile-only). The UI shows a graceful
///     downgrade explaining that the installer is desktop-only and
///     pointing at the software `.p12` upload path.
///   * "Present" — the helper answered `--version` successfully. The
///     wizard proceeds to enumerate slots.
///   * "Missing" — neither the env var nor any known location resolved
///     to a runnable binary. The wizard keeps the "proximamente" chip
///     and links to the install doc.
///
/// This file is intentionally dependency-free — it only uses
/// `dart:io` (guarded by `kIsWeb`) + `package:flutter/foundation.dart`
/// for the platform guard, so it stays cheap to unit-test.
library;

import 'dart:async';
import 'dart:io' show Process, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Outcome of a single helper probe.
enum HelperDetection {
  /// Running on Flutter Web — cannot detect; UI must offer the `.p12`
  /// fallback and link to the desktop-app install page.
  notAvailableOnWeb,

  /// Helper binary runnable; proceed to slot enumeration.
  present,

  /// Helper not found on any candidate path. UI keeps the
  /// "proximamente" chip and surfaces the install doc.
  missing,
}

/// Signature of the probe command. The default implementation shells
/// out via `Process.run`; tests inject a fake.
typedef HelperProbe = Future<int> Function(String executable);

/// Production-default probe: `Process.run(path, ['--version'])`.
///
/// Returns a non-zero exit code on failure (including
/// `ProcessException`, which is caught and mapped to -1) so callers
/// can treat the probe as a pure function.
Future<int> defaultHelperProbe(String executable) async {
  try {
    final result = await Process.run(executable, const ['--version']);
    return result.exitCode;
  } catch (_) {
    return -1;
  }
}

/// Resolves the set of candidate paths for the helper binary.
///
/// Order of precedence (matches
/// `SubprocessPkcs11SigningAdapter.resolveHelperBinary` as of
/// VRTV-70):
///
///   1. `PKCS11_HELPER_PATH` env var (explicit override).
///   2. `/usr/local/bin/aduanext-pkcs11-helper` (canonical Linux install).
///   3. `/opt/aduanext/pkcs11-helper` (packaged install root).
///   4. `./aduanext-pkcs11-helper` (developer cwd).
///   5. `aduanext-pkcs11-helper` (rely on `PATH` lookup).
List<String> helperCandidatePaths({Map<String, String>? environment}) {
  if (kIsWeb) return const <String>[];
  final env = environment ?? Platform.environment;
  final envPath = env['PKCS11_HELPER_PATH'];
  return <String>[
    if (envPath != null && envPath.isNotEmpty) envPath,
    '/usr/local/bin/aduanext-pkcs11-helper',
    '/opt/aduanext/pkcs11-helper',
    './aduanext-pkcs11-helper',
    'aduanext-pkcs11-helper',
  ];
}

/// Probes each candidate in order and returns the first path for
/// which [probe] reports exit code `0`. Returns `null` when every
/// candidate fails.
///
/// On Flutter Web this short-circuits to `null` without invoking the
/// probe — subprocess APIs do not exist there.
Future<String?> detectHelperBinary({
  HelperProbe probe = defaultHelperProbe,
  Map<String, String>? environment,
}) async {
  if (kIsWeb) return null;
  final candidates = helperCandidatePaths(environment: environment);
  for (final path in candidates) {
    final code = await probe(path);
    if (code == 0) return path;
  }
  return null;
}

/// High-level detection result for the UI.
///
/// Returns [HelperDetection.notAvailableOnWeb] on Web,
/// [HelperDetection.present] + resolved path when a probe succeeds,
/// or [HelperDetection.missing] otherwise.
Future<({HelperDetection state, String? resolvedPath})>
    probeForOnboarding({
  HelperProbe probe = defaultHelperProbe,
  Map<String, String>? environment,
}) async {
  if (kIsWeb) {
    return (state: HelperDetection.notAvailableOnWeb, resolvedPath: null);
  }
  final path = await detectHelperBinary(
    probe: probe,
    environment: environment,
  );
  if (path != null) {
    return (state: HelperDetection.present, resolvedPath: path);
  }
  return (state: HelperDetection.missing, resolvedPath: null);
}
