/// Atom: single tariff-rate cell for the suggestion card footer grid.
///
/// Renders "DAI" / "IVA" / "ISC" label + percentage below. When the
/// rate is >0 and notable (e.g. DAI > 3%), it tints amber to draw
/// the agent's attention.
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';

class TariffRateCell extends StatelessWidget {
  final String label;
  final double percent;

  /// Threshold at which the number renders amber to flag a notable
  /// cost. `null` means "never tint" — most IVA/ISC cells stay neutral
  /// because 13% IVA is the default on every import.
  final double? tintAbove;

  const TariffRateCell({
    super.key,
    required this.label,
    required this.percent,
    this.tintAbove,
  });

  @override
  Widget build(BuildContext context) {
    final tinted = tintAbove != null && percent > tintAbove!;
    final valueColor = tinted
        ? AduaNextTheme.statusValidando
        : AduaNextTheme.textPrimary;
    final formatted = percent == percent.floor()
        ? '${percent.toStringAsFixed(0)}%'
        : '${percent.toStringAsFixed(1)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AduaNextTheme.textSecondary,
          ),
        ),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 11,
            fontWeight: tinted ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
