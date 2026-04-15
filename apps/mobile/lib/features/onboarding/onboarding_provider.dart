/// Riverpod providers for the onboarding wizard.
///
/// * [dgaRegistryProvider] — swappable `DgaRegistry`. Defaults to the
///   stub; tests override it with a fake.
/// * [onboardingDraftProvider] — the `OnboardingDraft` state notifier.
///   Exposes per-step setters so the UI doesn't have to rebuild the
///   whole draft every keystroke.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_state.dart';
import 'stub_dga_registry.dart';

final dgaRegistryProvider = Provider<DgaRegistry>(
  (_) => const StubDgaRegistry(),
);

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  (ref) => OnboardingDraftNotifier(),
);

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier() : super(const OnboardingDraft());

  void setIdentity(IdentityDraft v) =>
      state = state.copyWith(identity: v);

  void setPatent(PatentDraft v) => state = state.copyWith(patent: v);

  void setBond(BondDraft v) => state = state.copyWith(bond: v);

  void setSignature(SignatureDraft v) =>
      state = state.copyWith(signature: v);

  void setAtena(AtenaCredentialsDraft v) =>
      state = state.copyWith(atena: v);

  void setPlan(PlanDraft v) => state = state.copyWith(plan: v);

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  void next() => state = state.copyWith(currentStep: state.currentStep + 1);

  void previous() {
    if (state.currentStep <= 0) return;
    state = state.copyWith(currentStep: state.currentStep - 1);
  }

  void reset() => state = const OnboardingDraft();
}
