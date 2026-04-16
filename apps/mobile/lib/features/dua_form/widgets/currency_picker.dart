/// Molecule: invoice currency picker.
///
/// Dropdown over [invoiceCurrencies]. Emits the ISO 4217 code.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/currencies.dart';

class CurrencyPicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;
  final String label;

  const CurrencyPicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.label = 'Moneda',
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode == null || selectedCode!.isEmpty
              ? null
              : selectedCode,
          isExpanded: true,
          hint: const Text('Selecciona moneda'),
          items: [
            for (final c in invoiceCurrencies)
              DropdownMenuItem<String>(
                value: c.code,
                child: Row(
                  children: [
                    Text(
                      c.code,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AduaNextTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
