/// Onboarding steps 4-5: Firma Digital, ATENA Credenciales.
///
/// Grouped under "credentials" theme. The Firma Digital step supports
/// two paths:
///
///   * **Software `.p12`** — always available, MVP default, works on
///     every platform including Flutter Web.
///   * **Hardware token (PKCS#11)** — activated at runtime when the
///     [helperProbeProvider] reports the AduaNext helper binary is
///     installed (VRTV-69 + VRTV-70). On Flutter Web this branch is
///     unavailable by construction (`Process.run` is desktop-only);
///     the UI shows a graceful downgrade pointing at the desktop
///     installer.
///
/// PIN handling:
///   * `.p12` PIN is entered here but never stored in state (only a
///     `pinProvided` flag is kept for the review step).
///   * Hardware-token PIN is NOT collected at onboarding time. Per
///     BCCR guidance and our own security policy the PIN must be
///     entered fresh per signing operation — storing it client-side
///     would defeat the purpose of the hardware token.
library;

import 'package:aduanext_domain/aduanext_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_provider.dart';
import '../onboarding_state.dart';
import '../pkcs11_detection.dart';
import 'hardware_token_picker.dart';

// ── Step 4: Firma Digital ─────────────────────────────────────────

class SignatureStep extends ConsumerStatefulWidget {
  const SignatureStep({super.key});

  @override
  ConsumerState<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends ConsumerState<SignatureStep> {
  final _pin = TextEditingController();
  String? _uploadedName;

  /// Result of the on-entry helper probe. `null` while detecting.
  HelperDetection? _detection;

  /// Slots returned by the helper on the most recent enumeration.
  /// `null` means we have not enumerated yet (or the helper is missing).
  List<TokenSlot>? _slots;

  /// Friendly message when slot enumeration fails. The user can retry.
  String? _slotsError;

  /// The module path currently pointed at by the slot-enumeration
  /// flow. Users can edit this when their middleware lives outside
  /// the default location.
  String _modulePath = _defaultModulePath;

  /// Conservative default for Linux BCCR installs. Users on macOS /
  /// Windows edit the field to point at their middleware.
  static const String _defaultModulePath =
      '/usr/lib/x64-athena/ASEP11.so';

  @override
  void initState() {
    super.initState();
    final existing = ref.read(onboardingDraftProvider).signature;
    if (existing != null) {
      _uploadedName = existing.uploadedP12Name;
      if (existing.hardwareToken != null) {
        _modulePath = existing.hardwareToken!.pkcs11ModulePath;
      }
    }
    // Kick off helper detection in the background. We don't block the
    // step on this because the software `.p12` path is always usable.
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectHelper());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _detectHelper() async {
    final probe = ref.read(helperProbeProvider);
    final result = await probeForOnboarding(probe: probe);
    if (!mounted) return;
    setState(() => _detection = result.state);
  }

  Future<void> _enumerateSlots() async {
    final port = ref.read(pkcs11SigningPortProvider);
    if (port == null) {
      setState(() {
        _slotsError = 'El puerto PKCS#11 no esta disponible en esta '
            'plataforma. Usa la app de escritorio para continuar con '
            'token USB.';
      });
      return;
    }
    setState(() {
      _slotsError = null;
      _slots = null;
    });
    try {
      final slots = await port.enumerateSlots(_modulePath);
      if (!mounted) return;
      setState(() => _slots = slots);
    } on HelperBinaryNotFoundException {
      if (!mounted) return;
      setState(() => _slotsError = 'Instala el helper de AduaNext.');
    } on ModuleLoadException {
      if (!mounted) return;
      setState(() => _slotsError =
          'No se pudo cargar el middleware de Firma Digital.');
    } on TokenNotPresentException {
      if (!mounted) return;
      setState(() => _slotsError =
          'No se detecto ningun token conectado. Conecta el token '
          'SINPE y reintenta.');
    } on Pkcs11Exception catch (e) {
      if (!mounted) return;
      setState(() => _slotsError = 'Error PKCS#11: ${e.message}');
    }
  }

  void _saveSoftware() {
    ref.read(onboardingDraftProvider.notifier).setSignature(
          SignatureDraft(
            mode: SignatureMode.softwareP12,
            uploadedP12Name: _uploadedName,
            pinProvided: _pin.text.isNotEmpty,
          ),
        );
  }

  void _saveHardware(HardwareTokenDraft token) {
    ref.read(onboardingDraftProvider.notifier).setSignature(
          SignatureDraft(
            mode: SignatureMode.hardwareToken,
            uploadedP12Name: null,
            pinProvided: false,
            hardwareToken: token,
          ),
        );
  }

  Future<void> _openTokenPicker() async {
    if (_slots == null || _slots!.isEmpty) {
      await _enumerateSlots();
      if (_slots == null || _slots!.isEmpty) return;
    }
    if (!mounted) return;
    final selected = await showDialog<TokenSlot>(
      context: context,
      builder: (_) => TokenPickerDialog(slots: _slots!),
    );
    if (selected == null) return;
    _saveHardware(
      HardwareTokenDraft(
        pkcs11ModulePath: _modulePath,
        slotId: selected.slotId,
        tokenLabel: selected.tokenLabel,
        tokenSerial: selected.tokenSerial,
        certCommonName: selected.certCommonName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingDraftProvider).signature;
    final hardwareChosen = draft?.mode == SignatureMode.hardwareToken &&
        draft?.hardwareToken != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Firma Digital', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Para el MVP utilizamos un archivo PKCS#12 (.p12). Para '
          'DUAs en produccion, BCCR exige el token USB SINPE (Firma '
          'Digital). Cuando el helper PKCS#11 este instalado, esta '
          'pantalla detecta tu token automaticamente.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _SoftwareP12Card(
          uploadedName: _uploadedName,
          pinController: _pin,
          onUploaded: (name) {
            setState(() => _uploadedName = name);
            _saveSoftware();
          },
          onPinChanged: (_) => _saveSoftware(),
        ),
        const SizedBox(height: 16),
        _HardwareTokenCard(
          detection: _detection,
          slots: _slots,
          slotsError: _slotsError,
          hardwareChosen: hardwareChosen,
          hardwareDraft: draft?.hardwareToken,
          modulePath: _modulePath,
          onModulePathChanged: (v) => setState(() => _modulePath = v),
          onEnumerate: _enumerateSlots,
          onPick: _openTokenPicker,
          onRetryDetection: _detectHelper,
        ),
      ],
    );
  }
}

class _SoftwareP12Card extends StatelessWidget {
  final String? uploadedName;
  final TextEditingController pinController;
  final ValueChanged<String> onUploaded;
  final ValueChanged<String> onPinChanged;

  const _SoftwareP12Card({
    required this.uploadedName,
    required this.pinController,
    required this.onUploaded,
    required this.onPinChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Text('Archivo .p12', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(uploadedName ?? 'Subir certificado .p12'),
              onPressed: () => onUploaded('certificado_firma.p12'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN del certificado',
              ),
              obscureText: true,
              onChanged: onPinChanged,
              key: const Key('signature-pin'),
            ),
            const SizedBox(height: 8),
            Text(
              'El PIN no se almacena: solo se envia al backend en el '
              'momento de la firma.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareTokenCard extends StatelessWidget {
  final HelperDetection? detection;
  final List<TokenSlot>? slots;
  final String? slotsError;
  final bool hardwareChosen;
  final HardwareTokenDraft? hardwareDraft;
  final String modulePath;
  final ValueChanged<String> onModulePathChanged;
  final VoidCallback onEnumerate;
  final VoidCallback onPick;
  final VoidCallback onRetryDetection;

  const _HardwareTokenCard({
    required this.detection,
    required this.slots,
    required this.slotsError,
    required this.hardwareChosen,
    required this.hardwareDraft,
    required this.modulePath,
    required this.onModulePathChanged,
    required this.onEnumerate,
    required this.onPick,
    required this.onRetryDetection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Detecting — show spinner.
    if (detection == null) {
      return Card(
        key: const Key('hardware-token-card-detecting'),
        color: theme.colorScheme.surfaceContainerHighest,
        child: const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Token USB SINPE (PKCS#11)'),
          subtitle: Text('Detectando tokens disponibles...'),
        ),
      );
    }

    // Not available on web — graceful downgrade.
    if (detection == HelperDetection.notAvailableOnWeb) {
      return Card(
        key: const Key('hardware-token-card-web'),
        color: theme.colorScheme.surfaceContainerHighest,
        child: ListTile(
          leading: const Icon(Icons.desktop_windows_outlined),
          title: const Text('Token USB SINPE (PKCS#11)'),
          subtitle: const Text(
            'Firma Digital con token USB requiere la app de escritorio. '
            'En el navegador usa el archivo .p12.',
          ),
          trailing: const Chip(label: Text('Solo escritorio')),
        ),
      );
    }

    // Helper missing — keep proximamente chip + install link.
    if (detection == HelperDetection.missing) {
      return Card(
        key: const Key('hardware-token-card-missing'),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.usb_off_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Token USB SINPE (PKCS#11)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  const Chip(label: Text('Proximamente')),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Instala el helper de AduaNext para habilitar la firma '
                'con tu token Firma Digital. Guia de instalacion en la '
                'documentacion oficial.',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('install-helper-retry'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ya instale el helper — reintentar'),
                  onPressed: onRetryDetection,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Present — active state.
    return Card(
      key: const Key('hardware-token-card-present'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.usb),
                const SizedBox(width: 8),
                Text(
                  'Token USB SINPE (PKCS#11)',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(
                  label: const Text('Disponible'),
                  backgroundColor: Colors.green.shade200,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('pkcs11-module-path'),
              initialValue: modulePath,
              decoration: const InputDecoration(
                labelText: 'Ruta del modulo PKCS#11',
                helperText:
                    'Ej. /usr/lib/x64-athena/ASEP11.so (BCCR Linux)',
              ),
              onChanged: onModulePathChanged,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('enumerate-slots'),
                  icon: const Icon(Icons.search),
                  label: const Text('Detectar tokens'),
                  onPressed: onEnumerate,
                ),
                FilledButton.icon(
                  key: const Key('pick-token'),
                  icon: const Icon(Icons.check),
                  label: const Text('Seleccionar token'),
                  onPressed:
                      (slots != null && slots!.isNotEmpty) ? onPick : null,
                ),
              ],
            ),
            if (slotsError != null) ...[
              const SizedBox(height: 12),
              Text(
                slotsError!,
                key: const Key('slots-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (slots != null && slots!.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'No se detecto ningun token conectado. Conecta el '
                'token SINPE y presiona "Detectar tokens".',
                key: Key('no-slots-message'),
              ),
            ],
            if (hardwareChosen && hardwareDraft != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seleccionado: ${hardwareDraft!.tokenLabel} '
                      '(serie ${hardwareDraft!.tokenSerial})',
                      key: const Key('hardware-selection-summary'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El PIN se te pedira en el momento de firmar cada DUA; '
                'no se guarda nunca.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
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
