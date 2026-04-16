/// Molecule: 0-100 horizontal risk bar for Step 7 Revisión.
///
/// Matches the risk_score_badge atom's band convention:
///   * <=30 → verde
///   * 31-60 → amarillo
///   * >60  → rojo
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/aduanext_theme.dart';

class RiskScoreBar extends StatelessWidget {
  final int score;
  const RiskScoreBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    Color tint;
    String label;
    if (clamped <= 30) {
      tint = AduaNextTheme.stepperVerde;
      label = 'Bajo';
    } else if (clamped <= 60) {
      tint = AduaNextTheme.stepperAmarillo;
      label = 'Medio';
    } else {
      tint = AduaNextTheme.stepperRojo;
      label = 'Alto';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'RIESGO ESTIMADO',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: AduaNextTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$clamped',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
            const Text(
              '/100',
              style: TextStyle(
                fontSize: 12,
                color: AduaNextTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: clamped / 100.0,
            backgroundColor: AduaNextTheme.surfaceCard,
            valueColor: AlwaysStoppedAnimation<Color>(tint),
          ),
        ),
      ],
    );
  }
}
