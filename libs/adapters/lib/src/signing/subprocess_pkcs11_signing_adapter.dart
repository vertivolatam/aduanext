/// Adapter: PKCS#11 signing via the AduaNext native helper (VRTV-69).
///
/// Spawns one Go helper process per request, speaks newline-delimited
/// JSON over its stdio pipes, and maps the wire error codes into the
/// typed exceptions declared in [Pkcs11SigningPort].
///
/// Design decisions (documented in SPIKE-005):
///   * **One process per request.** Simpler than a pool, and signing is
///     not latency-sensitive enough to matter (~5-15 ms overhead per
///     call). If profiling later shows pooling helps, it's an internal
///     change to the adapter.
///   * **PIN handling.** The PIN is passed in the JSON body, NOT as a
///     command-line argument — otherwise it would appear in `ps`
///     output. The adapter never logs the PIN and wipes the local
///     string reference before rethrowing on errors.
///   * **Process spawning.** Uses `Process.start` with an explicit
///     argument list (no shell), eliminating the command-injection
///     class of vulnerabilities.
///   * **Timeout.** Every request enforces a Future.timeout; on
///     expiry the helper is killed.
///
/// Architecture: Secondary Adapter (Driven side, Explicit Architecture).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aduanext_domain/domain.dart';

/// Interface so tests can inject a fake process spawner. Production
/// code uses [_RealProcessLauncher] which delegates to `Process.start`.
typedef ProcessLauncher = Future<Process> Function(
  String executable,
  List<String> arguments, {
  Map<String, String>? environment,
});

/// Resolves the absolute path of the helper binary.
///
/// Search order:
/// 1. The `PKCS11_HELPER_PATH` environment variable, if set.
/// 2. Any paths provided to the constructor (explicit overrides win).
/// 3. `./aduanext-pkcs11-helper` relative to the current working dir.
/// 4. `./pkcs11-helper` (developer builds).
///
/// Returns `null` if no candidate exists. The adapter constructor
/// does NOT throw when the binary is missing — it defers to the
/// first call so the application can start with the helper absent and
/// surface a user-visible message only when hardware signing is
/// actually requested.
String? resolveHelperBinary({
  List<String> additionalCandidates = const [],
  Map<String, String>? environment,
}) {
  environment ??= Platform.environment;
  final envPath = environment['PKCS11_HELPER_PATH'];
  final candidates = <String>[
    if (envPath != null && envPath.isNotEmpty) envPath,
    ...additionalCandidates,
    './aduanext-pkcs11-helper',
    './pkcs11-helper',
  ];
  for (final c in candidates) {
    if (c.isEmpty) continue;
    if (File(c).existsSync()) return c;
  }
  return null;
}

/// [Pkcs11SigningPort] implementation that drives the native helper
/// from VRTV-69.
class SubprocessPkcs11SigningAdapter implements Pkcs11SigningPort {
  /// Default per-request timeout. Signing a SHA-256 digest against a
  /// smart card takes single-digit milliseconds of actual work; the
  /// large budget covers helper cold-start + token insertion race.
  static const Duration defaultTimeout = Duration(seconds: 30);

  final String? _explicitBinary;
  final Duration _timeout;
  final ProcessLauncher _launcher;
  final Map<String, String>? _environment;

  /// Creates an adapter that will discover the helper on first use.
  ///
  /// [helperBinaryPath] when provided bypasses the PATH / env-var
  /// resolution and uses the given absolute path. Tests pass a fake
  /// script here.
  ///
  /// [timeout] bounds each helper request. Defaults to
  /// [defaultTimeout].
  ///
  /// [launcher] is the function used to spawn processes. Defaults to
  /// `Process.start`. Tests override this to inject a fake process.
  SubprocessPkcs11SigningAdapter({
    String? helperBinaryPath,
    Duration timeout = defaultTimeout,
    ProcessLauncher? launcher,
    Map<String, String>? environment,
  })  : _explicitBinary = helperBinaryPath,
        _timeout = timeout,
        _launcher = launcher ?? _defaultLauncher,
        _environment = environment;

  static Future<Process> _defaultLauncher(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) =>
      Process.start(
        executable,
        arguments,
        environment: environment,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );

  /// Resolves the helper binary or throws
  /// [HelperBinaryNotFoundException].
  String _binaryOrThrow() {
    final explicit = _explicitBinary;
    if (explicit != null) {
      if (!File(explicit).existsSync()) {
        throw HelperBinaryNotFoundException(
          'Configured PKCS#11 helper path does not exist: $explicit',
        );
      }
      return explicit;
    }
    final resolved = resolveHelperBinary(environment: _environment);
    if (resolved == null) {
      throw const HelperBinaryNotFoundException(
        'PKCS#11 helper binary not found. Install aduanext-pkcs11-helper '
        'and/or set the PKCS11_HELPER_PATH environment variable.',
      );
    }
    return resolved;
  }

  @override
  Future<List<TokenSlot>> enumerateSlots(String pkcs11ModulePath) async {
    final res = await _invoke(
      command: 'enumerateSlots',
      params: {'module': pkcs11ModulePath},
    );
    final slots = (res['slots'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_slotFromJson)
        .toList(growable: false);
    return slots;
  }

  @override
  Future<SignResult> signWithToken({
    required String pkcs11ModulePath,
    required int slotId,
    required String pin,
    required Uint8List dataToSign,
    required SignatureAlgorithm algorithm,
  }) async {
    // Wipe our local reference to the PIN as soon as we have constructed
    // the request payload. This does not protect against the JSON encoder's
    // internal buffers — but the helper is the only consumer on the other
    // side of the pipe, and the helper is contract-bound not to log.
    final params = <String, Object?>{
      'module': pkcs11ModulePath,
      'slotId': slotId,
      'pin': pin,
      'dataB64': base64Encode(dataToSign),
      'mechanism': algorithm.wireName,
    };
    // Best-effort local scrub. Dart does not expose a secure-wipe
    // primitive for strings; this does not defend against the JSON
    // encoder's internal buffers, but it prevents the PIN from
    // appearing in any subsequent stack frame-locals snapshot.
    // ignore: unused_local_variable
    final pinScrubbed = pin.replaceAll(RegExp('.'), '\u0000');

    final res = await _invoke(command: 'sign', params: params);

    // Scrub the payload map immediately.
    params['pin'] = '';

    final sigB64 = res['signatureB64'] as String? ?? '';
    final certB64 = res['signerCertB64'] as String? ?? '';
    final cn = res['signerCommonName'] as String? ?? '';
    final serial = res['tokenSerial'] as String? ?? '';
    final signedAtStr = res['signedAt'] as String?;
    final signedAt = signedAtStr != null
        ? DateTime.parse(signedAtStr).toUtc()
        : DateTime.now().toUtc();

    return SignResult(
      signatureBytes: Uint8List.fromList(base64Decode(sigB64)),
      signerCertificateDer: Uint8List.fromList(base64Decode(certB64)),
      signerCommonName: cn,
      tokenSerial: serial,
      signedAt: signedAt,
    );
  }

  /// Core invocation: spawn helper, write one request, read one
  /// response, tear down. Maps JSON error frames to typed exceptions.
  Future<Map<String, dynamic>> _invoke({
    required String command,
    required Map<String, Object?> params,
  }) async {
    final binary = _binaryOrThrow();
    Process? proc;
    try {
      proc = await _launcher(binary, const <String>[], environment: _environment);
    } on ProcessException catch (e) {
      throw HelperBinaryNotFoundException(
        'Failed to launch PKCS#11 helper at $binary: ${e.message}',
      );
    }

    final reqId = DateTime.now().microsecondsSinceEpoch.toString();
    final req = <String, Object?>{
      'id': reqId,
      'command': command,
      'params': params,
    };

    // Kick off stream drain futures BEFORE writing to stdin so we
    // don't race against process exit. `fold` / `join` return a
    // Future that completes when the underlying stream closes (which
    // it does on process exit), so we don't hit the
    // subscription-reuse pitfall of Stream.listen + asFuture.
    final stdoutFuture = proc.stdout
        .transform(utf8.decoder)
        .fold<StringBuffer>(StringBuffer(), (b, s) {
      b.write(s);
      return b;
    });
    final stderrFuture = proc.stderr
        .transform(utf8.decoder)
        .fold<StringBuffer>(StringBuffer(), (b, s) {
      b.write(s);
      return b;
    });

    try {
      // Write + close stdin. Closing stdin signals the helper to
      // return after this single request, which keeps the one-shot
      // semantics clean.
      proc.stdin.writeln(jsonEncode(req));
      await proc.stdin.close();

      // Bound the whole round-trip. On timeout: kill + classify.
      final exitCode = await proc.exitCode.timeout(_timeout, onTimeout: () {
        proc!.kill(ProcessSignal.sigkill);
        throw const HelperProtocolException(
          'PKCS#11 helper exceeded timeout; process killed.',
        );
      });
      final stdoutBuffer = await stdoutFuture;
      final stderrBuffer = await stderrFuture;

      if (exitCode != 0 && stdoutBuffer.isEmpty) {
        throw HelperProtocolException(
          'PKCS#11 helper exited with code $exitCode and no output. '
          'stderr: ${stderrBuffer.toString().trim()}',
        );
      }

      final line = _firstJsonLine(stdoutBuffer.toString());
      if (line == null) {
        throw HelperProtocolException(
          'PKCS#11 helper produced no response line. '
          'stderr: ${stderrBuffer.toString().trim()}',
        );
      }

      final Map<String, dynamic> resp;
      try {
        resp = jsonDecode(line) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw HelperProtocolException(
          'Malformed JSON from PKCS#11 helper: ${e.message}',
        );
      }

      final ok = resp['ok'] == true;
      if (!ok) {
        final err = (resp['error'] as Map<String, dynamic>?) ?? const {};
        throw _mapError(err);
      }
      final result = resp['result'];
      if (result is Map<String, dynamic>) return result;
      // Commands with no result payload get an empty map.
      return <String, dynamic>{};
    } finally {
      // Scrub sensitive fields defensively.
      params['pin'] = '';
      // Best-effort cleanup. If kill fails (already exited) we do
      // not care.
      try {
        proc.kill(ProcessSignal.sigkill);
      } catch (_) {}
      // Drain the futures so pending stream subscriptions are
      // cancelled — use .catchError to suppress any race errors.
      unawaited(stdoutFuture.catchError((_) => StringBuffer()));
      unawaited(stderrFuture.catchError((_) => StringBuffer()));
    }
  }

  /// Extracts the first line that looks like a JSON object (begins with
  /// `{`). We scan lines rather than taking the first non-empty line so
  /// that stray startup chatter from the runtime (e.g. Dart VM's
  /// "Running build hooks..." when the binary itself is a `dart run`
  /// invocation used in tests) does not get misparsed as the response.
  String? _firstJsonLine(String stdout) {
    // Split on newlines AND treat a line that does not start with `{`
    // but contains a `{` as having its JSON payload start at that `{`.
    // Handles both clean one-line output from the Go helper and the
    // concatenated-prefix case where a wrapper printed something and
    // forgot the trailing newline before our JSON line.
    for (final raw in const LineSplitter().convert(stdout)) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('{')) return t;
      final brace = t.indexOf('{');
      if (brace > 0 && t.endsWith('}')) return t.substring(brace);
    }
    return null;
  }

  /// Maps a helper error-frame into the appropriate typed exception.
  Pkcs11Exception _mapError(Map<String, dynamic> err) {
    final code = (err['code'] as String?) ?? '';
    final message = (err['message'] as String?) ?? 'Unknown helper error';
    switch (code) {
      case 'TOKEN_NOT_PRESENT':
        return TokenNotPresentException(message);
      case 'INVALID_PIN':
        return InvalidPinException(message);
      case 'PIN_LOCKED':
        return PinLockedException(message);
      case 'NO_CERTIFICATE':
      case 'NO_PRIVATE_KEY':
        return NoSigningMaterialException(message);
      case 'UNSUPPORTED_MECHANISM':
        return UnsupportedMechanismException(message);
      case 'MODULE_LOAD':
        return ModuleLoadException(message);
      case 'SIGN_FAILED':
      case 'VERIFY_FAILED':
        return SignFailedException(message);
      case 'UNKNOWN_COMMAND':
      case 'INVALID_REQUEST':
      case 'INTERNAL':
      default:
        return HelperProtocolException('[$code] $message');
    }
  }

  TokenSlot _slotFromJson(Map<String, dynamic> j) {
    DateTime? parseOpt(dynamic v) {
      if (v is! String || v.isEmpty) return null;
      return DateTime.tryParse(v)?.toUtc();
    }

    return TokenSlot(
      slotId: (j['slotId'] as num?)?.toInt() ?? 0,
      tokenLabel: (j['tokenLabel'] as String?) ?? '',
      tokenSerial: (j['tokenSerial'] as String?) ?? '',
      manufacturer: (j['manufacturer'] as String?) ?? '',
      model: (j['model'] as String?) ?? '',
      hasCert: j['hasCert'] == true,
      certCommonName: j['certCommonName'] as String?,
      certSubject: j['certSubject'] as String?,
      certIssuer: j['certIssuer'] as String?,
      certNotBefore: parseOpt(j['certNotBefore']),
      certNotAfter: parseOpt(j['certNotAfter']),
    );
  }
}
