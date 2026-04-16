/// Step 1: General — Exportador / Consignatario / Aduana.
///
/// Minimal MVP: exporter cedula (code) + legal name + customs office.
/// Consignatario autocomplete lands with VRTV-90 when the backend
/// `/api/v1/companies` endpoint is wired.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dua_form_notifier.dart';
import '../widgets/aduana_picker.dart';

class StepGeneral extends ConsumerStatefulWidget {
  const StepGeneral({super.key});

  @override
  ConsumerState<StepGeneral> createState() => _StepGeneralState();
}

class _StepGeneralState extends ConsumerState<StepGeneral> {
  late final TextEditingController _exporterCode;
  late final TextEditingController _exporterName;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(duaFormProvider);
    _exporterCode = TextEditingController(text: draft.exporterCode);
    _exporterName = TextEditingController(text: draft.exporterName);
  }

  @override
  void dispose() {
    _exporterCode.dispose();
    _exporterName.dispose();
    super.dispose();
  }

  void _onExporterCodeChanged(String v) {
    ref.read(duaFormProvider.notifier).setGeneral(exporterCode: v.trim());
  }

  void _onExporterNameChanged(String v) {
    ref.read(duaFormProvider.notifier).setGeneral(exporterName: v);
  }

  void _onCustomsChanged(String code) {
    ref.read(duaFormProvider.notifier).setGeneral(customsOfficeCode: code);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(duaFormProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Datos del exportador',
            subtitle:
                'Debe coincidir con la patente DGA registrada en onboarding.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exporterCode,
            decoration: const InputDecoration(
              labelText: 'Cedula juridica exportador',
              hintText: '3-101-XXXXXX',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Z\-]')),
            ],
            onChanged: _onExporterCodeChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exporterName,
            decoration: const InputDecoration(
              labelText: 'Razon social exportador',
              border: OutlineInputBorder(),
            ),
            onChanged: _onExporterNameChanged,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Aduana de despacho',
            subtitle:
                'Oficina donde se presentara fisicamente el DUA para revision.',
          ),
          const SizedBox(height: 12),
          AduanaPicker(
            selectedCode: draft.customsOfficeCode,
            onChanged: _onCustomsChanged,
          ),
          const SizedBox(height: 24),
          if (draft.step1Complete)
            const _CompletionBanner(
              message:
                  'Paso 1 completo. Pulsa Siguiente para continuar con Envio.',
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final String message;
  const _CompletionBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
