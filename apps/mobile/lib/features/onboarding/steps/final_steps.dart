/// Onboarding steps 6-7: Plan, Confirmacion.
///
/// Payment integration (Stripe / SINPE recurring) is explicitly out of
/// scope per VRTV-59. The Plan step records the selection; the
/// Confirmation step shows a review + a "send application" button
/// that today just resets the state and surfaces a success snackbar.
/// A real payment form + backend call lands in a follow-up issue.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_provider.dart';
import '../onboarding_state.dart';

// ── Step 6: Plan ──────────────────────────────────────────────────

class PlanStep extends ConsumerWidget {
  const PlanStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Plan', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Elegi el plan que mejor se ajuste a tu operacion. Podes '
          'cambiar cuando quieras desde Configuracion.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...AgentPlan.values.map(
          (p) => _PlanCard(
            plan: p,
            selected: draft.plan?.plan == p,
            onSelect: () => notifier.setPlan(PlanDraft(plan: p)),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El cobro real (Stripe / SINPE recurrente) se habilita '
                    'en una iteracion posterior. Hoy solo registramos tu '
                    'seleccion para el onboarding.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final AgentPlan plan;
  final bool selected;
  final VoidCallback onSelect;
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFor(plan),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _descriptionFor(plan),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                'USD ${plan.monthlyUsd}/mes',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _labelFor(AgentPlan p) => switch (p) {
        AgentPlan.solo => 'Solo',
        AgentPlan.smallPractice => 'Pequena practica',
        AgentPlan.agency => 'Agencia',
      };

  static String _descriptionFor(AgentPlan p) => switch (p) {
        AgentPlan.solo => 'Freelance. DUAs ilimitadas.',
        AgentPlan.smallPractice => 'Hasta 5 agentes. Auditoria incluida.',
        AgentPlan.agency => 'Agentes ilimitados. Soporte prioritario.',
      };
}

// ── Step 7: Confirmacion ──────────────────────────────────────────

class ConfirmationStep extends ConsumerWidget {
  const ConfirmationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingDraftProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirmacion', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Revisa los datos antes de enviar la solicitud. Vamos a '
          'auditar cada paso con SHA-256 hash chain.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _ReviewTile(
          label: 'Identidad',
          value: draft.identity == null
              ? 'Sin datos'
              : '${draft.identity!.legalName} (${draft.identity!.cedula})',
          complete: draft.identity?.isComplete ?? false,
        ),
        _ReviewTile(
          label: 'Patente',
          value: draft.patent?.patentNumber ?? 'Sin datos',
          complete: draft.patent?.isComplete ?? false,
        ),
        _ReviewTile(
          label: 'Caucion',
          value: draft.bond == null
              ? 'Sin datos'
              : 'CRC ${draft.bond!.amountCrc}',
          complete: draft.bond?.isComplete ?? false,
        ),
        _ReviewTile(
          label: 'Firma Digital',
          value: draft.signature?.uploadedP12Name ?? 'Sin datos',
          complete: draft.signature?.isComplete ?? false,
        ),
        _ReviewTile(
          label: 'ATENA',
          value: draft.atena?.username ?? 'Sin datos',
          complete: draft.atena?.isComplete ?? false,
        ),
        _ReviewTile(
          label: 'Plan',
          value: draft.plan == null
              ? 'Sin datos'
              : 'USD ${draft.plan!.plan.monthlyUsd}/mes',
          complete: draft.plan?.isComplete ?? false,
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Al confirmar, tu solicitud entra en cola de revision. '
              'Recibiras un correo con el resultado en 24-48 horas. '
              'Una vez aprobada, se generara tu tenant y tu primera DUA '
              'de prueba.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String label;
  final String value;
  final bool complete;
  const _ReviewTile({
    required this.label,
    required this.value,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        complete ? Icons.check_circle : Icons.error_outline,
        color: complete
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
      ),
      title: Text(label),
      subtitle: Text(value),
      dense: true,
    );
  }
}
