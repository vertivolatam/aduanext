/// Molecule: Incoterm 2020 picker.
///
/// Dropdown over [incoterms2020]. Emits the 3-letter code that
/// ATENA expects in the `incoterm` field.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/incoterms.dart';

class IncotermPicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;
  final String label;

  /// When provided, filter the list to incoterms compatible with the
  /// selected transport mode. `'4'` (aereo) hides sea-only incoterms.
  final String? transportModeCode;

  const IncotermPicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
    this.transportModeCode,
    this.label = 'Incoterm',
  });

  Iterable<Incoterm> get _visible {
    if (transportModeCode == null) return incoterms2020;
    // Codes 1 (maritimo) and 8 (navegacion interior) allow sea-only
    // incoterms; everything else only allows `any`-applicability ones.
    final seaModes = {'1', '8'};
    if (seaModes.contains(transportModeCode)) return incoterms2020;
    return incoterms2020.where((i) => i.applicability == 'any');
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible.toList();
    final currentValid =
        selectedCode != null && visible.any((i) => i.code == selectedCode);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValid ? selectedCode : null,
          isExpanded: true,
          hint: const Text('Selecciona un incoterm'),
          items: [
            for (final i in visible)
              DropdownMenuItem<String>(
                value: i.code,
                child: Row(
                  children: [
                    Text(
                      i.code,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        i.title,
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
