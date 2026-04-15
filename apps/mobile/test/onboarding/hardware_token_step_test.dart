/// Widget tests for the Firma Digital step — hardware-token branch.
///
/// Exercises the three runtime paths of the helper probe:
///   * present  — the active state renders, slot enumeration runs,
///     picking a slot persists a `HardwareTokenDraft` into the
///     onboarding state.
///   * missing  — the "proximamente" chip stays up and the install
///     prompt is visible.
///   * retry    — after pressing "reintentar" the probe re-runs and
///     the UI flips to the active state.
///
/// The probe + port are faked via `helperProbeProvider` and
/// `pkcs11SigningPortProvider` so no real subprocess is spawned and
/// no real middleware is loaded in the test sandbox.
library;

import 'dart:typed_data';

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/features/onboarding/onboarding_provider.dart';
import 'package:aduanext_mobile/features/onboarding/onboarding_state.dart';
import 'package:aduanext_mobile/features/onboarding/steps/credentials_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ────────────────────────────────────────────────────────

/// Fake [Pkcs11SigningPort] — returns a canned list of slots on
/// every enumeration call. Throws a configurable exception when
/// asked to, so tests can cover the error paths.
class _FakePkcs11Port implements Pkcs11SigningPort {
  final List<TokenSlot> _slots;
  final Pkcs11Exception? _throws;
  int enumerateCalls = 0;

  _FakePkcs11Port({
    List<TokenSlot> slots = const [],
    Pkcs11Exception? throws,
  })  : _slots = slots,
        _throws = throws;

  @override
  Future<List<TokenSlot>> enumerateSlots(String pkcs11ModulePath) async {
    enumerateCalls++;
    if (_throws != null) throw _throws;
    return _slots;
  }

  @override
  Future<SignResult> signWithToken({
    required String pkcs11ModulePath,
    required int slotId,
    required String pin,
    required Uint8List dataToSign,
    required SignatureAlgorithm algorithm,
  }) {
    throw UnimplementedError('not used by onboarding tests');
  }
}

Widget _harness({
  required Future<int> Function(String) probe,
  Pkcs11SigningPort? port,
}) {
  return ProviderScope(
    overrides: [
      helperProbeProvider.overrideWithValue(probe),
      pkcs11SigningPortProvider.overrideWithValue(port),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 720, child: SignatureStep()),
        ),
      ),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────

void main() {
  group('SignatureStep hardware-token branch', () {
    testWidgets(
      'helper missing shows the "proximamente" chip + install prompt',
      (tester) async {
        // Probe always fails.
        await tester.pumpWidget(_harness(probe: (_) async => 1));
        await tester.pump(); // kick the post-frame callback
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('hardware-token-card-missing')),
          findsOneWidget,
        );
        expect(find.text('Proximamente'), findsOneWidget);
        expect(
          find.byKey(const Key('install-helper-retry')),
          findsOneWidget,
        );
      },
    );

    testWidgets('helper present surfaces the active card', (tester) async {
      await tester.pumpWidget(_harness(probe: (_) async => 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hardware-token-card-present')),
        findsOneWidget,
      );
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('retry button re-runs the probe', (tester) async {
      var helperInstalled = false;
      var detectionRuns = 0;
      Future<int> probe(String path) async {
        // Count one "detection run" per call to the first candidate.
        if (path == '/usr/local/bin/aduanext-pkcs11-helper') {
          detectionRuns++;
        }
        return helperInstalled ? 0 : 1;
      }

      await tester.pumpWidget(_harness(probe: probe));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hardware-token-card-missing')),
        findsOneWidget,
      );
      expect(detectionRuns, 1);

      // Simulate the user installing the helper, then hitting retry.
      helperInstalled = true;
      await tester.tap(find.byKey(const Key('install-helper-retry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hardware-token-card-present')),
        findsOneWidget,
      );
      expect(detectionRuns, 2);
    });

    testWidgets(
      'picking a token persists HardwareTokenDraft without a PIN',
      (tester) async {
        final port = _FakePkcs11Port(slots: const [
          TokenSlot(
            slotId: 3,
            tokenLabel: 'BCCR Firma Digital',
            tokenSerial: 'SERIAL-1234',
            manufacturer: 'Athena',
            model: 'IDProtect',
            hasCert: true,
            certCommonName: 'Maria Perez',
          ),
        ]);
        final container = ProviderContainer(overrides: [
          helperProbeProvider.overrideWithValue((_) async => 0),
          pkcs11SigningPortProvider.overrideWithValue(port),
        ]);
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SizedBox(width: 720, child: SignatureStep()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enumerate slots.
        await tester.tap(find.byKey(const Key('enumerate-slots')));
        await tester.pumpAndSettle();
        expect(port.enumerateCalls, 1);

        // Pick a token — opens the dialog then taps the slot row.
        await tester.tap(find.byKey(const Key('pick-token')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('token-slot-3')), findsOneWidget);
        await tester.tap(find.byKey(const Key('token-slot-3')));
        await tester.pumpAndSettle();

        final sig =
            container.read(onboardingDraftProvider).signature;
        expect(sig, isNotNull);
        expect(sig!.mode, SignatureMode.hardwareToken);
        expect(sig.pinProvided, isFalse); // PIN never collected here
        expect(sig.hardwareToken, isNotNull);
        expect(sig.hardwareToken!.slotId, 3);
        expect(sig.hardwareToken!.tokenSerial, 'SERIAL-1234');
        expect(sig.isComplete, isTrue);

        expect(
          find.byKey(const Key('hardware-selection-summary')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'InvalidPin-like Pkcs11 exceptions surface Spanish copy',
      (tester) async {
        final port = _FakePkcs11Port(
          throws: const TokenNotPresentException('no token'),
        );
        await tester.pumpWidget(
          _harness(probe: (_) async => 0, port: port),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('enumerate-slots')));
        await tester.pumpAndSettle();
        final msg = tester
            .widget<Text>(find.byKey(const Key('slots-error')))
            .data!;
        expect(msg, contains('token'));
        expect(msg.toLowerCase(), contains('sinpe'));
      },
    );
  });

  group('SignatureStep software .p12 branch still works', () {
    testWidgets('uploading and entering a PIN marks the step complete',
        (tester) async {
      final container = ProviderContainer(overrides: [
        helperProbeProvider.overrideWithValue((_) async => 1),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(width: 720, child: SignatureStep()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Subir certificado .p12'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('signature-pin')),
        '1234',
      );
      await tester.pump();

      final sig =
          container.read(onboardingDraftProvider).signature!;
      expect(sig.mode, SignatureMode.softwareP12);
      expect(sig.uploadedP12Name, 'certificado_firma.p12');
      expect(sig.pinProvided, isTrue);
      expect(sig.isComplete, isTrue);
    });
  });
}
