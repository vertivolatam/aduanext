/// Step 4: Valoración — currency, exchange rate, CIF calculator.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../dua_form_notifier.dart';
import '../widgets/cif_calculator.dart';
import '../widgets/currency_picker.dart';

class StepValoracion extends ConsumerStatefulWidget {
  const StepValoracion({super.key});

  @override
  ConsumerState<StepValoracion> createState() => _StepValoracionState();
}

class _StepValoracionState extends ConsumerState<StepValoracion> {
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(duaFormProvider);
    _rate = TextEditingController(
      text: draft.exchangeRate == null ? '' : draft.exchangeRate!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(duaFormProvider);
    final notifier = ref.read(duaFormProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Moneda y tipo de cambio',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Valores monetarios se convierten a CRC con el tipo de cambio '
            'RIMM del dia. Para CRC, la moneda y el tipo de cambio son 1:1.',
            style: TextStyle(color: AduaNextTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CurrencyPicker(
                  selectedCode: draft.invoiceCurrencyCode,
                  onChanged: (code) =>
                      notifier.setValuation(invoiceCurrencyCode: code),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _rate,
                  decoration: InputDecoration(
                    labelText: 'Tipo de cambio RIMM',
                    hintText: '1.00',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Refrescar desde RIMM',
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () {
                        // Stub — real RIMM pull lands with VRTV-81.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Refresco RIMM proximamente (VRTV-81).'),
                          ),
                        );
                      },
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (v) => notifier.setValuation(
                      exchangeRate: double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Calculo CIF',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          CifCalculator(
            fobAmount: draft.totalFob,
            freightAmount: draft.freightAmount,
            insuranceAmount: draft.insuranceAmount,
            currencyLabel: draft.invoiceCurrencyCode ?? '',
            onFreightChanged: (v) => notifier.setValuation(freightAmount: v),
            onInsuranceChanged: (v) =>
                notifier.setValuation(insuranceAmount: v),
          ),
          const SizedBox(height: 16),
          if (draft.totalCif > 0 && (draft.exchangeRate ?? 0) > 0)
            _CrcEquivalent(
              cif: draft.totalCif,
              rate: draft.exchangeRate!,
              currencyCode: draft.invoiceCurrencyCode ?? '',
            ),
        ],
      ),
    );
  }
}

class _CrcEquivalent extends StatelessWidget {
  final double cif;
  final double rate;
  final String currencyCode;
  const _CrcEquivalent({
    required this.cif,
    required this.rate,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final crc = cif * rate;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AduaNextTheme.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AduaNextTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Equivalente CIF en CRC',
              style: TextStyle(
                fontSize: 11,
                color: AduaNextTheme.textSecondary,
              ),
            ),
          ),
          Text(
            '${cif.toStringAsFixed(2)} $currencyCode × $rate',
            style: const TextStyle(
                fontSize: 11, color: AduaNextTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Text(
            '₡${crc.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AduaNextTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
