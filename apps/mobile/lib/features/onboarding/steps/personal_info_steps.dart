/// Onboarding steps 1-3: Identidad, Patente DGA, Caucion.
///
/// Grouped because they share the "personal record keeping" theme and
/// keeping them in a single file keeps the PR under the 15-file cap.
/// Each step is a standalone ConsumerWidget that drives
/// `onboardingDraftProvider` — the wizard shell composes them.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_provider.dart';
import '../onboarding_state.dart';

// ── Step 1: Identidad ─────────────────────────────────────────────

class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  final _cedula = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).identity;
    if (existing != null) {
      _cedula.text = existing.cedula;
      _name.text = existing.legalName;
      _email.text = existing.email;
      _phone.text = existing.phone;
      _address.text = existing.address;
    }
  }

  @override
  void dispose() {
    _cedula.dispose();
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _update() {
    ref.read(onboardingDraftProvider.notifier).setIdentity(
          IdentityDraft(
            cedula: _cedula.text.trim(),
            legalName: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Identidad',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Los datos deben coincidir con tu cedula fisica y el registro DGA.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _cedula,
          decoration: const InputDecoration(labelText: 'Cedula fisica'),
          onChanged: (_) => _update(),
          key: const Key('identity-cedula'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
          onChanged: (_) => _update(),
          key: const Key('identity-name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Correo electronico'),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _update(),
          key: const Key('identity-email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(labelText: 'Telefono'),
          keyboardType: TextInputType.phone,
          onChanged: (_) => _update(),
          key: const Key('identity-phone'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Direccion'),
          minLines: 2,
          maxLines: 3,
          onChanged: (_) => _update(),
          key: const Key('identity-address'),
        ),
      ],
    );
  }
}

// ── Step 2: Patente DGA ───────────────────────────────────────────

class PatentStep extends ConsumerStatefulWidget {
  const PatentStep({super.key});

  @override
  ConsumerState<PatentStep> createState() => _PatentStepState();
}

class _PatentStepState extends ConsumerState<PatentStep> {
  final _number = TextEditingController();
  DateTime? _issuedAt;
  String? _documentName;
  bool _verifying = false;
  DgaVerification? _verification;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).patent;
    if (existing != null) {
      _number.text = existing.patentNumber;
      _issuedAt = existing.issuedAt;
      _documentName = existing.uploadedDocumentName;
      _verification = existing.verification;
    }
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final result = await ref
        .read(dgaRegistryProvider)
        .verify(_number.text.trim());
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _verification = result;
    });
    _save();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _issuedAt = picked);
      _save();
    }
  }

  void _save() {
    ref.read(onboardingDraftProvider.notifier).setPatent(
          PatentDraft(
            patentNumber: _number.text.trim(),
            issuedAt: _issuedAt,
            uploadedDocumentName: _documentName,
            verification: _verification,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Patente DGA', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Verificamos tu patente contra el registro DGA. Si el registro '
          'no esta disponible, puedes subir el PDF para revision manual.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _number,
          decoration: const InputDecoration(
            labelText: 'Numero de patente (ej. DGA-1234)',
          ),
          onChanged: (_) => _save(),
          key: const Key('patent-number'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _issuedAt == null
                      ? 'Fecha de emision'
                      : _issuedAt!.toIso8601String().split('T').first,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: _number.text.trim().isEmpty || _verifying
                  ? null
                  : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verificar en DGA'),
            ),
          ],
        ),
        if (_verification != null) ...[
          const SizedBox(height: 16),
          Card(
            color: _verification!.verified
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _verification!.verified
                        ? Icons.verified
                        : Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_verification!.detail)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(
            _documentName ?? 'Subir PDF de la patente (opcional)',
          ),
          onPressed: () {
            // File-picker wiring lives in a separate iteration — the
            // onboarding flow is usable without a real upload because
            // the stub DGA verification is enough for the MVP demo.
            setState(() => _documentName = 'patente_sample.pdf');
            _save();
          },
        ),
      ],
    );
  }
}

// ── Step 3: Caucion ───────────────────────────────────────────────

class BondStep extends ConsumerStatefulWidget {
  const BondStep({super.key});

  @override
  ConsumerState<BondStep> createState() => _BondStepState();
}

class _BondStepState extends ConsumerState<BondStep> {
  final _amount = TextEditingController();
  BondType? _type;
  DateTime? _expiresAt;
  String? _documentName;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).bond;
    if (existing != null) {
      _amount.text =
          existing.amountCrc == 0 ? '' : existing.amountCrc.toString();
      _type = existing.type;
      _expiresAt = existing.expiresAt;
      _documentName = existing.uploadedDocumentName;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    ref.read(onboardingDraftProvider.notifier).setBond(
          BondDraft(
            amountCrc: amount,
            type: _type,
            expiresAt: _expiresAt,
            uploadedDocumentName: _documentName,
          ),
        );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountValue = int.tryParse(_amount.text.trim()) ?? 0;
    final belowFloor = amountValue < AgentProfile.bondLegalMinimumCrc &&
        amountValue > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Caucion', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'LGA Art. 58 exige un minimo de CRC '
          '${AgentProfile.bondLegalMinimumCrc}. '
          'Puedes extender pero no reducir.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amount,
          decoration: InputDecoration(
            labelText: 'Monto (CRC)',
            errorText: belowFloor ? 'Por debajo del minimo legal' : null,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            setState(() {});
            _save();
          },
          key: const Key('bond-amount'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BondType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Tipo de caucion'),
          items: BondType.values
              .map((t) =>
                  DropdownMenuItem(value: t, child: Text(_labelFor(t))))
              .toList(),
          onChanged: (v) {
            setState(() => _type = v);
            _save();
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.date_range),
          label: Text(
            _expiresAt == null
                ? 'Fecha de vencimiento'
                : _expiresAt!.toIso8601String().split('T').first,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(_documentName ?? 'Subir documento de caucion'),
          onPressed: () {
            setState(() => _documentName = 'caucion.pdf');
            _save();
          },
        ),
      ],
    );
  }

  String _labelFor(BondType t) => switch (t) {
        BondType.certifiedCheque => 'Cheque certificado',
        BondType.insFidelityBond => 'Bono de fidelidad INS',
        BondType.trustGuarantee => 'Fideicomiso de garantia',
        BondType.standbyCredit => 'Carta de credito stand-by',
        BondType.cashDeposit => 'Deposito en Tesoreria',
      };
}
