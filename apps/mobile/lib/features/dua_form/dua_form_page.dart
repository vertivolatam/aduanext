/// DUA form page scaffold.
///
/// Renders the frame from the stepper-semáforo mockup
/// (`06-stepper-semaforo.html`):
///
///   * Header: breadcrumb + title + risk badge + Guardar / Siguiente.
///   * Stepper semáforo: 7 bubbles with tone from the notifier.
///   * Body: per-step content (scaffolded placeholder here; full
///     content lands with VRTV-88 and VRTV-89).
///   * Footer: Guardar + Anterior / Siguiente buttons.
///
/// Autosave indicator in the header shows the last-persisted time.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/theme/aduanext_theme.dart';
import '../../shared/ui/atoms/risk_score_badge.dart';
import '../../shared/ui/organisms/stepper_semaforo.dart';
import 'dua_form_notifier.dart';
import 'dua_form_state.dart';
import 'steps.dart';

class DuaFormPage extends ConsumerWidget {
  const DuaFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(duaFormProvider);
    final notifier = ref.read(duaFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(draft: draft, notifier: notifier),
        StepperSemaforo(
          activeStep: draft.currentStep,
          toneBuilder: notifier.toneFor,
          onStepTap: notifier.goToStep,
        ),
        Expanded(
          child: _StepBody(step: draft.currentStep),
        ),
        _Footer(draft: draft, notifier: notifier),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DuaDraft draft;
  final DuaFormNotifier notifier;

  const _Header({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb — clickable "Exportaciones" → "DUA-XXXX".
          Row(
            children: [
              InkWell(
                onTap: () => context.go('/dashboard'),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 11,
                    color: AduaNextTheme.textSecondary,
                  ),
                ),
              ),
              const Text(
                ' → ',
                style: TextStyle(
                  fontSize: 11,
                  color: AduaNextTheme.textSecondary,
                ),
              ),
              Text(
                'Nueva DUA',
                style: const TextStyle(
                  fontSize: 11,
                  color: AduaNextTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                _titleFor(draft),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RiskScoreBadge(score: null),
                  const SizedBox(width: 8),
                  if (draft.savedAt != null)
                    Text(
                      'Guardado ${DateFormat.Hm().format(draft.savedAt!.toLocal())}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AduaNextTheme.textSecondary,
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await notifier.persistNow();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Borrador guardado')),
                      );
                    },
                    icon: const Icon(Icons.save, size: 14),
                    label: const Text('Guardar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _canAdvance(draft) ? notifier.goNext : null,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _titleFor(DuaDraft draft) {
    if (draft.items.isNotEmpty &&
        draft.items.first.commercialDescription.isNotEmpty) {
      return draft.items.first.commercialDescription;
    }
    return 'Preparación DUA';
  }

  /// Header Siguiente button enables only when a next step exists AND
  /// it's unlocked. Mirrors the footer button's logic so the two
  /// stay in sync.
  bool _canAdvance(DuaDraft draft) {
    final next = draft.currentStep.next;
    if (next == null) return false;
    return draft.isStepUnlocked(next);
  }
}

// ─── Step body (placeholder until VRTV-88/VRTV-89) ────────────────

class _StepBody extends StatelessWidget {
  final DuaFormStep step;
  const _StepBody({required this.step});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AduaNextTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AduaNextTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso ${step.ordinal}: ${step.displayName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _bodyFor(step),
              style: const TextStyle(color: AduaNextTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _bodyFor(DuaFormStep step) {
    switch (step) {
      case DuaFormStep.general:
        return 'Exportador, consignatario y aduana de despacho. '
            'Formulario completo en VRTV-88.';
      case DuaFormStep.shipping:
        return 'Incoterm, país de origen/destino, medio de transporte. '
            'Formulario completo en VRTV-88.';
      case DuaFormStep.items:
        return 'Líneas de mercancía con clasificador RIMM inline. '
            'Formulario completo en VRTV-88.';
      case DuaFormStep.valuation:
        return 'Factura, moneda, tipo de cambio y cálculo CIF. '
            'Formulario completo en VRTV-89.';
      case DuaFormStep.invoices:
        return 'Lista de facturas adjuntas al DUA. '
            'Formulario completo en VRTV-89.';
      case DuaFormStep.documents:
        return 'B/L, certificados y otros documentos requeridos. '
            'Subida de archivos en VRTV-89.';
      case DuaFormStep.review:
        return 'Resumen final con pre-validación (VRTV-42) y submit a '
            'ATENA (VRTV-79). Wire-up completo en VRTV-89.';
    }
  }
}

// ─── Footer ──────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final DuaDraft draft;
  final DuaFormNotifier notifier;

  const _Footer({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final prev = draft.currentStep.previous;
    final next = draft.currentStep.next;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AduaNextTheme.surfacePanel,
        border: Border(
          top: BorderSide(color: AduaNextTheme.borderSubtle),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: prev == null ? null : notifier.goPrev,
            icon: const Icon(Icons.arrow_back, size: 14),
            label: const Text('Anterior'),
          ),
          Text(
            'Paso ${draft.currentStep.ordinal} de ${DuaFormStep.values.length}',
            style: const TextStyle(
              fontSize: 11,
              color: AduaNextTheme.textSecondary,
            ),
          ),
          ElevatedButton.icon(
            onPressed: next == null
                ? null
                : (draft.isStepUnlocked(next) ? notifier.goNext : null),
            icon: const Icon(Icons.arrow_forward, size: 14),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}
