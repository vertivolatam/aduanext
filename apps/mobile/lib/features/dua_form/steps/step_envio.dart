/// Step 2: Envio — Incoterm / Pais origen-destino / Medio de transporte.
///
/// Depends only on `duaFormProvider`. Cascades: selecting a non-sea
/// transport mode filters the incoterm list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_notifier.dart';
import '../widgets/country_picker.dart';
import '../widgets/incoterm_picker.dart';
import '../widgets/transport_mode_picker.dart';

class StepEnvio extends ConsumerWidget {
  const StepEnvio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(duaFormProvider);
    final notifier = ref.read(duaFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Terminos y rutas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Define el Incoterm, paises y medio de transporte. El incoterm '
            'filtra las opciones segun el medio elegido (p.ej. aereo '
            'descarta FOB/CIF).',
            style: TextStyle(color: AduaNextTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          TransportModePicker(
            selectedCode: draft.transportModeCode,
            onChanged: (c) => notifier.setShipping(transportModeCode: c),
          ),
          const SizedBox(height: 20),
          IncotermPicker(
            selectedCode: draft.incotermCode,
            transportModeCode: draft.transportModeCode,
            onChanged: (c) => notifier.setShipping(incotermCode: c),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CountryPicker(
                  label: 'Pais de origen',
                  selectedCode: draft.countryOfOriginCode,
                  onChanged: (c) =>
                      notifier.setShipping(countryOfOriginCode: c),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CountryPicker(
                  label: 'Pais de destino',
                  selectedCode: draft.countryOfDestinationCode,
                  onChanged: (c) =>
                      notifier.setShipping(countryOfDestinationCode: c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (draft.step2Complete)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AduaNextTheme.statusLevanteBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AduaNextTheme.statusLevante),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: AduaNextTheme.statusLevante),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paso 2 completo. Pulsa Siguiente para agregar items.',
                      style: TextStyle(color: AduaNextTheme.statusLevante),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
