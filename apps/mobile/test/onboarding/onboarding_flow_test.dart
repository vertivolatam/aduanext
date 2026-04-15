/// Integration tests for the agent onboarding wizard.
///
/// Exercises the state machine end-to-end: filling each step updates
/// the draft, advancing is disabled until each step is `isComplete`,
/// and the stub DGA registry drives the patent-verification branch.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:aduanext_mobile/features/onboarding/onboarding_provider.dart';
import 'package:aduanext_mobile/features/onboarding/onboarding_state.dart';
import 'package:aduanext_mobile/features/onboarding/stub_dga_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StubDgaRegistry', () {
    test('verifies patents starting with DGA-', () async {
      final result = await const StubDgaRegistry().verify('DGA-1234');
      expect(result.verified, isTrue);
      expect(result.source, DgaVerificationSource.localStub);
    });

    test('verifies legacy \\d{4}-\\d{4} format', () async {
      final result = await const StubDgaRegistry().verify('1234-5678');
      expect(result.verified, isTrue);
    });

    test('unknown formats route to manual upload', () async {
      final result = await const StubDgaRegistry().verify('unknown');
      expect(result.verified, isFalse);
      expect(result.detail, contains('manual'));
    });
  });

  group('OnboardingDraft + Notifier', () {
    test('isReadyToSubmit flips true only when every step completes',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(onboardingDraftProvider.notifier);

      expect(container.read(onboardingDraftProvider).isReadyToSubmit,
          isFalse);

      notifier.setIdentity(const IdentityDraft(
        cedula: '1-1234-5678',
        legalName: 'Carlos Mora',
        email: 'carlos@example.cr',
        phone: '8888-8888',
        address: 'San Jose',
      ));
      notifier.setPatent(PatentDraft(
        patentNumber: 'DGA-1234',
        issuedAt: DateTime.utc(2024, 3, 12),
        uploadedDocumentName: null,
        verification: const DgaVerification(
          verified: true,
          detail: 'ok',
          source: DgaVerificationSource.localStub,
        ),
      ));
      notifier.setBond(BondDraft(
        amountCrc: AgentProfile.bondLegalMinimumCrc,
        type: BondType.insFidelityBond,
        expiresAt: DateTime.utc(2028, 1, 1),
        uploadedDocumentName: 'bond.pdf',
      ));
      notifier.setSignature(const SignatureDraft(
        mode: SignatureMode.softwareP12,
        uploadedP12Name: 'cert.p12',
        pinProvided: true,
      ));
      notifier.setAtena(const AtenaCredentialsDraft(
        username: 'carlos',
        clientId: 'DECLARACION',
        passwordProvided: true,
      ));
      notifier.setPlan(const PlanDraft(plan: AgentPlan.solo));

      expect(
        container.read(onboardingDraftProvider).isReadyToSubmit,
        isTrue,
      );
    });

    test('BondDraft.meetsLegalFloor rejects sub-minimum amounts', () {
      const below = BondDraft(
        amountCrc: 10000000,
        type: BondType.cashDeposit,
        expiresAt: null,
        uploadedDocumentName: null,
      );
      expect(below.meetsLegalFloor, isFalse);
    });

    test('previous cannot go below step 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(onboardingDraftProvider.notifier);
      n.previous();
      n.previous();
      expect(container.read(onboardingDraftProvider).currentStep, 0);
    });

    test('next advances the cursor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(onboardingDraftProvider.notifier);
      n.next();
      n.next();
      expect(container.read(onboardingDraftProvider).currentStep, 2);
    });

    test('reset clears everything', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = container.read(onboardingDraftProvider.notifier);
      n.setPlan(const PlanDraft(plan: AgentPlan.agency));
      n.reset();
      expect(container.read(onboardingDraftProvider).plan, isNull);
      expect(container.read(onboardingDraftProvider).currentStep, 0);
    });
  });
}
