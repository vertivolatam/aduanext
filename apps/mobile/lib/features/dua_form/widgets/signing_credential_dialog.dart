/// Organism: modal dialog that collects signing credentials right
/// before submit.
///
/// Two modes:
///   * Software .p12 — prompts the agent to pick a .p12 file
///     (stubbed by filename for MVP) + a PIN. Neither is persisted.
///   * Hardware token — passes through to the VRTV-72 helper.
///     For MVP we display a "detectar token" button that simulates
///     the probe and emits a fake token id.
///
/// Anti-pattern guard: PIN and .p12 bytes NEVER leak into app state
/// after the dialog closes. The caller receives a [SigningCredential]
/// only for the duration of the submit call.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';

enum SigningMode { software, hardware }

class SigningCredential {
  final SigningMode mode;
  final String? softwareP12Name;
  final String? softwarePin;
  final String? hardwareTokenId;

  const SigningCredential._({
    required this.mode,
    this.softwareP12Name,
    this.softwarePin,
    this.hardwareTokenId,
  });

  factory SigningCredential.software({
    required String p12Name,
    required String pin,
  }) =>
      SigningCredential._(
        mode: SigningMode.software,
        softwareP12Name: p12Name,
        softwarePin: pin,
      );

  factory SigningCredential.hardware({required String tokenId}) =>
      SigningCredential._(
        mode: SigningMode.hardware,
        hardwareTokenId: tokenId,
      );
}

class SigningCredentialDialog extends StatefulWidget {
  const SigningCredentialDialog({super.key});

  @override
  State<SigningCredentialDialog> createState() =>
      _SigningCredentialDialogState();
}

class _SigningCredentialDialogState extends State<SigningCredentialDialog> {
  SigningMode _mode = SigningMode.software;
  final _p12 = TextEditingController();
  final _pin = TextEditingController();
  bool _obscure = true;
  String? _detectedToken;

  @override
  void dispose() {
    _p12.dispose();
    // Explicitly zero-out the PIN controller's text — defense in depth
    // so a heap scrape after close won't find the PIN lingering.
    _pin.text = '';
    _pin.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_mode == SigningMode.software) {
      return _p12.text.trim().isNotEmpty && _pin.text.isNotEmpty;
    }
    return _detectedToken != null;
  }

  Future<void> _detectToken() async {
    // Stub detection — VRTV-72 wires the real helper probe.
    setState(() => _detectedToken = null);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _detectedToken = 'TOKEN-STUB-001');
  }

  void _confirm() {
    if (!_canConfirm) return;
    if (_mode == SigningMode.software) {
      Navigator.of(context).pop(SigningCredential.software(
        p12Name: _p12.text.trim(),
        pin: _pin.text,
      ));
    } else {
      Navigator.of(context).pop(SigningCredential.hardware(
        tokenId: _detectedToken!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firmar y transmitir'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'La clave de firma NO se almacena. Solo se usa durante esta '
              'transmision.',
              style: TextStyle(
                fontSize: 11,
                color: AduaNextTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<SigningMode>(
              segments: const [
                ButtonSegment(
                  value: SigningMode.software,
                  label: Text('Software (.p12)'),
                  icon: Icon(Icons.vpn_key, size: 14),
                ),
                ButtonSegment(
                  value: SigningMode.hardware,
                  label: Text('Hardware token'),
                  icon: Icon(Icons.usb, size: 14),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            if (_mode == SigningMode.software) ..._softwareFields() else
              ..._hardwareFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _canConfirm ? _confirm : null,
          icon: const Icon(Icons.send, size: 14),
          label: const Text('Firmar y transmitir'),
        ),
      ],
    );
  }

  List<Widget> _softwareFields() => [
        TextField(
          controller: _p12,
          decoration: const InputDecoration(
            labelText: 'Archivo .p12 (nombre)',
            hintText: 'firma-juan-perez.p12',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pin,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'PIN',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                  size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ];

  List<Widget> _hardwareFields() => [
        ElevatedButton.icon(
          onPressed: _detectToken,
          icon: const Icon(Icons.search, size: 14),
          label: const Text('Detectar token'),
        ),
        const SizedBox(height: 12),
        if (_detectedToken != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AduaNextTheme.statusLevanteBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AduaNextTheme.statusLevante),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AduaNextTheme.statusLevante),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Token detectado: $_detectedToken',
                    style: const TextStyle(
                        color: AduaNextTheme.statusLevante, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          const Text(
            'Conecta el token y pulsa Detectar.',
            style: TextStyle(
              fontSize: 11,
              color: AduaNextTheme.textSecondary,
            ),
          ),
      ];
}
