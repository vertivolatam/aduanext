/// Step 7: Revisión — read-only summary + pre-validation + submit.
///
/// Reads the draft, runs the local pre-validation engine, and renders
/// the risk score + findings. "Firmar y transmitir" opens the signing
/// credential dialog; the collected [SigningCredential] never persists
/// past the submit call.
///
/// Actual submit wire-up to `POST /api/v1/dispatches/submit` (VRTV-79)
/// is stubbed here with a simulated latency — the command handler on
/// the server side will be wired when the endpoint lands.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/countries.dart';
import '../data/customs_offices.dart';
import '../dua_form_notifier.dart';
import '../dua_form_state.dart';
import '../pre_validation.dart';
import '../widgets/risk_score_bar.dart';
import '../widgets/signing_credential_dialog.dart';

class StepRevision extends ConsumerStatefulWidget {
  const StepRevision({super.key});

  @override
  ConsumerState<StepRevision> createState() => _StepRevisionState();
}

class _StepRevisionState extends ConsumerState<StepRevision> {
  bool _submitting = false;
  String? _submittedAt;

  Future<void> _submit(PreValidationResult validation) async {
    if (validation.hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Corrige los errores antes de transmitir — la pre-validacion '
            'detecta problemas bloqueantes.',
          ),
        ),
      );
      return;
    }

    // 1) Collect credentials (ephemeral — only in the dialog scope).
    final credential = await showDialog<SigningCredential?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SigningCredentialDialog(),
    );
    if (credential == null || !mounted) return;

    // 2) Final confirmation — submit is irreversible.
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar transmision'),
        content: const Text(
          'Una vez transmitida, la DUA no puede editarse. ATENA retornara '
          'numero de registro oficial.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Transmitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 3) Submit (stubbed — VRTV-79 wires the real endpoint).
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submittedAt = DateTime.now().toIso8601String();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'DUA transmitida (stub). Integracion con /api/v1/dispatches/submit '
          'pendiente en VRTV-79.',
        ),
      ),
    );

    // After success: disable form by resetting and navigating back.
    // Real wire-up would navigate to `/dispatches/:id` once VRTV-85 ships
    // the returned declarationId through the submit response.
    await ref.read(duaFormProvider.notifier).resetToFresh();
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(duaFormProvider);
    final validation = preValidate(draft);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Revisión final',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Verifica cada seccion antes de firmar y transmitir. Una vez '
            'enviada, la DUA se registra en ATENA y no puede editarse.',
            style: TextStyle(color: AduaNextTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AduaNextTheme.surfacePanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AduaNextTheme.borderSubtle),
            ),
            child: RiskScoreBar(score: validation.riskScore),
          ),
          const SizedBox(height: 16),
          _FindingsList(findings: validation.findings),
          const SizedBox(height: 16),
          _SummaryCard(draft: draft),
          const SizedBox(height: 20),
          if (_submittedAt != null)
            _SubmittedBanner(at: _submittedAt!)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(duaFormProvider.notifier).persistNow(),
                  icon: const Icon(Icons.save, size: 14),
                  label: const Text('Guardar borrador'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _submit(validation),
                  icon: _submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 14),
                  label: Text(
                      _submitting ? 'Transmitiendo…' : 'Firmar y transmitir'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FindingsList extends StatelessWidget {
  final List<PreValidationFinding> findings;
  const _FindingsList({required this.findings});

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AduaNextTheme.statusLevanteBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AduaNextTheme.statusLevante),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle,
                size: 16, color: AduaNextTheme.statusLevante),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pre-validacion OK. Listo para firmar y transmitir.',
                style: TextStyle(color: AduaNextTheme.statusLevante),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'HALLAZGOS DE PRE-VALIDACION',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AduaNextTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        for (final f in findings) _FindingCard(finding: f),
      ],
    );
  }
}

class _FindingCard extends StatelessWidget {
  final PreValidationFinding finding;
  const _FindingCard({required this.finding});

  @override
  Widget build(BuildContext context) {
    final (bg, border, icon) = switch (finding.severity) {
      PreValidationSeverity.error => (
          AduaNextTheme.stepperRojoBg,
          AduaNextTheme.stepperRojo,
          Icons.error_outline,
        ),
      PreValidationSeverity.warning => (
          AduaNextTheme.stepperAmarilloBg,
          AduaNextTheme.stepperAmarillo,
          Icons.warning_amber_rounded,
        ),
      PreValidationSeverity.info => (
          AduaNextTheme.surfaceCard,
          AduaNextTheme.borderSubtle,
          Icons.info_outline,
        ),
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: border),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: border),
                ),
                if (finding.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    finding.description!,
                    style: const TextStyle(
                        fontSize: 11, color: AduaNextTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (finding.riskWeight > 0)
            Text(
              '+${finding.riskWeight}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: border,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DuaDraft draft;
  const _SummaryCard({required this.draft});

  String _customsOfficeName(String code) {
    return crCustomsOffices
        .firstWhere(
          (o) => o.code == code,
          orElse: () =>
              CustomsOffice(code: code, name: code, region: ''),
        )
        .name;
  }

  String _countryName(String? code) {
    if (code == null) return '—';
    return commonCountries
        .firstWhere(
          (c) => c.code == code,
          orElse: () => Country(code: code, name: code),
        )
        .name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RESUMEN DE LA DECLARACION',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: AduaNextTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _KV(k: 'Exportador', v: '${draft.exporterName} (${draft.exporterCode})'),
          _KV(k: 'Aduana', v: _customsOfficeName(draft.customsOfficeCode)),
          _KV(k: 'Incoterm', v: draft.incotermCode ?? '—'),
          _KV(k: 'Origen', v: _countryName(draft.countryOfOriginCode)),
          _KV(k: 'Destino', v: _countryName(draft.countryOfDestinationCode)),
          _KV(k: 'Items', v: '${draft.items.length}'),
          _KV(
            k: 'FOB total',
            v: '${draft.totalFob.toStringAsFixed(2)} ${draft.invoiceCurrencyCode ?? ''}',
          ),
          _KV(
            k: 'CIF total',
            v: '${draft.totalCif.toStringAsFixed(2)} ${draft.invoiceCurrencyCode ?? ''}',
          ),
          _KV(k: 'Facturas', v: '${draft.invoices.length}'),
          _KV(
            k: 'Documentos',
            v:
                '${draft.documents.where((d) => d.attached).length}/${draft.documents.length} adjuntos',
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: const TextStyle(
                fontSize: 11,
                color: AduaNextTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  final String at;
  const _SubmittedBanner({required this.at});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AduaNextTheme.statusLevanteBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.statusLevante),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 20, color: AduaNextTheme.statusLevante),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'DUA transmitida (stub) a las $at. Regresando al dashboard...',
              style: const TextStyle(color: AduaNextTheme.statusLevante),
            ),
          ),
        ],
      ),
    );
  }
}
