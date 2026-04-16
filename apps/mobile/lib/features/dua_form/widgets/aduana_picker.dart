/// Molecule: Costa Rica customs office picker.
///
/// Dropdown over the hardcoded top-10 offices from
/// [crCustomsOffices]. Emits the 3-digit code (ATENA
/// `codigoAduana` field).
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/customs_offices.dart';

class AduanaPicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;
  final String label;

  const AduanaPicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.label = 'Aduana de despacho',
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
          hint: const Text('Selecciona una aduana'),
          items: [
            for (final office in crCustomsOffices)
              DropdownMenuItem<String>(
                value: office.code,
                child: Row(
                  children: [
                    Text(office.code,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: AduaNextTheme.textSecondary,
                        )),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        office.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      office.region,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AduaNextTheme.textSecondary,
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
