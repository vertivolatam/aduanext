/// Atom: 0-100 risk score badge.
///
/// Used on DUA list rows, the DUA detail header, and the classifier.
/// Color follows the 4-band mapping used by the VRTV-42 pre-validation
/// engine:
///
///   * 0–24  → low (verde)
///   * 25–49 → medium (amber)
///   * 50–74 → high (orange)
///   * 75+   → critical (rojo)
///
/// When [score] is null the badge renders `—` — the pre-validation
/// engine hasn't run yet.
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import 'declaration_status_semaphore.dart' show StatusTone, StatusToneColors;

class RiskScoreBadge extends StatelessWidget {
  final int? score;

  /// Render without the "Risk:" prefix — used when the badge sits
  /// next to an explicit header label.
  final bool compact;

  const RiskScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  static StatusTone toneForScore(int score) {
    if (score >= 75) return StatusTone.rojo;
    if (score >= 50) return StatusTone.amber;
    if (score >= 25) return StatusTone.amber;
    return StatusTone.verde;
  }

  @override
  Widget build(BuildContext context) {
    final tone = score == null ? StatusTone.gris : toneForScore(score!);
    final colors = StatusToneColors.of(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tone == StatusTone.gris
              ? AduaNextTheme.borderSubtle
              : colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        score == null
            ? (compact ? '—' : 'Risk: —')
            : (compact ? '$score' : 'Risk: $score'),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: tone == StatusTone.gris
              ? AduaNextTheme.textSecondary
              : colors.foreground,
        ),
      ),
    );
  }
}
