/// Onboarding steps 4-5: Firma Digital, ATENA Credenciales.
///
/// Grouped under "credentials" theme. The Firma Digital step is
/// software-only until VRTV-70 ships the PKCS#11 port; the hardware
/// token option shows a disabled card with a tooltip so the user knows
/// the feature is coming.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_provider.dart';
import '../onboarding_state.dart';

// ── Step 4: Firma Digital ─────────────────────────────────────────

class SignatureStep extends ConsumerStatefulWidget {
  const SignatureStep({super.key});

  @override
  ConsumerState<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends ConsumerState<SignatureStep> {
  final _pin = TextEditingController();
  String? _uploadedName;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).signature;
    if (existing != null) {
      _uploadedName = existing.uploadedP12Name;
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(onboardingDraftProvider.notifier).setSignature(
          SignatureDraft(
            mode: SignatureMode.softwareP12,
            uploadedP12Name: _uploadedName,
            pinProvided: _pin.text.isNotEmpty,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Firma Digital', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Para el MVP utilizamos un archivo PKCS#12 (.p12). La '
          'integracion con tokens USB SINPE (Firma Digital BCCR) llega '
          'con VRTV-70 y sera requerida para DUAs reales en produccion.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Archivo .p12',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: Text(_uploadedName ?? 'Subir certificado .p12'),
                  onPressed: () {
                    setState(
                      () => _uploadedName = 'certificado_firma.p12',
                    );
                    _save();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pin,
                  decoration: const InputDecoration(
                    labelText: 'PIN del certificado',
                  ),
                  obscureText: true,
                  onChanged: (_) => _save(),
                  key: const Key('signature-pin'),
                ),
                const SizedBox(height: 8),
                Text(
                  'El PIN no se almacena: solo se envia al backend en '
                  'el momento de la firma.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: const Icon(Icons.usb_off_outlined),
            title: const Text('Token USB SINPE (PKCS#11)'),
            subtitle: const Text(
              'Disponible cuando VRTV-70 este listo. '
              'Requerido para produccion.',
            ),
            trailing: const Chip(label: Text('Proximamente')),
            enabled: false,
          ),
        ),
      ],
    );
  }
}

// ── Step 5: ATENA Credenciales ────────────────────────────────────

class AtenaCredentialsStep extends ConsumerStatefulWidget {
  const AtenaCredentialsStep({super.key});

  @override
  ConsumerState<AtenaCredentialsStep> createState() =>
      _AtenaCredentialsStepState();
}

class _AtenaCredentialsStepState
    extends ConsumerState<AtenaCredentialsStep> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _clientId = 'DECLARACION';

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).atena;
    if (existing != null) {
      _username.text = existing.username;
      _clientId = existing.clientId;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(onboardingDraftProvider.notifier).setAtena(
          AtenaCredentialsDraft(
            username: _username.text.trim(),
            clientId: _clientId,
            passwordProvided: _password.text.isNotEmpty,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Credenciales ATENA',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Las credenciales se almacenan cifradas. Las usamos '
          'exclusivamente para las llamadas al SIAA vIA Keycloak.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _username,
          decoration: const InputDecoration(
            labelText: 'Usuario ATENA',
          ),
          onChanged: (_) => _save(),
          key: const Key('atena-username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          decoration: const InputDecoration(
            labelText: 'Contrasena ATENA',
          ),
          obscureText: true,
          onChanged: (_) => _save(),
          key: const Key('atena-password'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _clientId,
          decoration: const InputDecoration(labelText: 'Cliente ATENA'),
          items: const [
            DropdownMenuItem(
              value: 'DECLARACION',
              child: Text('DECLARACION (uso general)'),
            ),
            DropdownMenuItem(
              value: 'URIMM',
              child: Text('URIMM (consultas arancelarias)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() => _clientId = v);
              _save();
            }
          },
        ),
      ],
    );
  }
}
