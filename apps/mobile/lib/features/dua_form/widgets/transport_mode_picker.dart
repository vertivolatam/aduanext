/// Molecule: transport mode picker.
///
/// Segmented chips (ChoiceChip) over [transportModes]. Emits the
/// 1-digit code ATENA expects in `codigoMedioTransporte`.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';
import '../data/transport_modes.dart';

class TransportModePicker extends StatelessWidget {
  final String? selectedCode;
  final ValueChanged<String> onChanged;

  const TransportModePicker({
    super.key,
    required this.selectedCode,
    required this.onChanged,
  });

  IconData _iconFor(String name) {
    switch (name) {
      case 'directions_boat':
        return Icons.directions_boat;
      case 'train':
        return Icons.train;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'flight':
        return Icons.flight;
      case 'local_post_office':
        return Icons.local_post_office;
      case 'factory':
        return Icons.factory;
      case 'waves':
        return Icons.waves;
      case 'agriculture':
        return Icons.agriculture;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEDIO DE TRANSPORTE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AduaNextTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in transportModes)
              ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(m.iconName), size: 14),
                    const SizedBox(width: 6),
                    Text(m.label),
                  ],
                ),
                selected: selectedCode == m.code,
                onSelected: (_) => onChanged(m.code),
              ),
          ],
        ),
      ],
    );
  }
}
