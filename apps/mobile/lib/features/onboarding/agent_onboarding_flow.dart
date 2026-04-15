/// `AgentOnboardingFlow` — the 7-step wizard shell for SOP-A01.
///
/// Steps:
///   1. Identidad
///   2. Patente DGA
///   3. Caucion
///   4. Firma Digital
///   5. ATENA Credenciales
///   6. Plan
///   7. Confirmacion
///
/// Each step is an independent widget driven by `onboardingDraftProvider`.
/// The shell handles the stepper header, navigation buttons, and the
/// "resume where you left off" behaviour. No backend round-trips happen
/// until step 7's "Confirmar" button — until then, all state is
/// Riverpod-local and survives widget rebuilds but not a full browser
/// reload (hydration is tracked in a separate iteration).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_provider.dart';
import 'onboarding_state.dart';
import 'steps/credentials_steps.dart';
import 'steps/final_steps.dart';
import 'steps/personal_info_steps.dart';

class AgentOnboardingFlow extends ConsumerWidget {
  const AgentOnboardingFlow({super.key});

  static const _stepTitles = <String>[
    'Identidad',
    'Patente DGA',
    'Caucion',
    'Firma Digital',
    'ATENA',
    'Plan',
    'Confirmacion',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    // currentStep is 1-indexed in the state (0 is "welcome"); clamp so
    // the stepper is in range [0, 6].
    final idx = (draft.currentStep - 1).clamp(0, _stepTitles.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding — Agente Aduanero'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (draft.currentStep <= 1) {
              context.go('/onboarding');
            } else {
              notifier.previous();
            }
          },
        ),
      ),
      body: Column(
        children: [
          _StepHeader(index: idx, titles: _stepTitles),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _StepBody(index: idx),
              ),
            ),
          ),
          _StepFooter(
            index: idx,
            canAdvance: _canAdvance(idx, draft),
            lastStep: _stepTitles.length - 1,
          ),
        ],
      ),
    );
  }

  bool _canAdvance(int index, OnboardingDraft draft) {
    return switch (index) {
      0 => draft.identity?.isComplete ?? false,
      1 => draft.patent?.isComplete ?? false,
      2 => draft.bond?.isComplete ?? false,
      3 => draft.signature?.isComplete ?? false,
      4 => draft.atena?.isComplete ?? false,
      5 => draft.plan?.isComplete ?? false,
      _ => true,
    };
  }
}

class _StepHeader extends StatelessWidget {
  final int index;
  final List<String> titles;
  const _StepHeader({required this.index, required this.titles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: titles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final active = i == index;
          final done = i < index;
          return Chip(
            avatar: CircleAvatar(
              backgroundColor: done
                  ? theme.colorScheme.primary
                  : active
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.surfaceContainerHighest,
              child: done
                  ? const Icon(Icons.check, size: 16)
                  : Text('${i + 1}'),
            ),
            label: Text(titles[i]),
            side: BorderSide(
              color: active
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: active ? 2 : 0,
            ),
          );
        },
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  final int index;
  const _StepBody({required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (index) {
      0 => const IdentityStep(),
      1 => const PatentStep(),
      2 => const BondStep(),
      3 => const SignatureStep(),
      4 => const AtenaCredentialsStep(),
      5 => const PlanStep(),
      _ => const ConfirmationStep(),
    };
  }
}

class _StepFooter extends ConsumerWidget {
  final int index;
  final bool canAdvance;
  final int lastStep;
  const _StepFooter({
    required this.index,
    required this.canAdvance,
    required this.lastStep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final isLast = index == lastStep;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (index > 0)
              TextButton(
                onPressed: notifier.previous,
                child: const Text('Anterior'),
              ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: canAdvance
                  ? () {
                      if (isLast) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Solicitud enviada. Recibiras un correo cuando sea aprobada.',
                            ),
                          ),
                        );
                        notifier.reset();
                      } else {
                        notifier.next();
                      }
                    }
                  : null,
              child: Text(isLast ? 'Confirmar y enviar' : 'Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}
