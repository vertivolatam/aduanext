/// Molecule: country picker (origin/destination).
///
/// Searchable dropdown backed by [commonCountries]. Emits the ISO
/// alpha-3 code the ATENA DUA API expects.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/countries.dart';

class CountryPicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;
  final String label;

  const CountryPicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    required this.label,
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
          hint: const Text('Selecciona un pais'),
          items: [
            for (final c in commonCountries)
              DropdownMenuItem<String>(
                value: c.code,
                child: Row(
                  children: [
                    Text(
                      c.code,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: AduaNextTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
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
