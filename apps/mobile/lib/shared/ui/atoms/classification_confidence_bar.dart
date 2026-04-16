/// Atom: horizontal confidence bar for AI classification suggestions.
///
/// Renders a 0-100% filled bar with tone coloring that matches the
/// risk score / status semaphore palette:
///
///   * >= 85 — verde  (high confidence)
///   * 60-84 — amber  (review required)
///   * <  60 — rojo   (low confidence, strong human override)
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import 'declaration_status_semaphore.dart';

class ClassificationConfidenceBar extends StatelessWidget {
  final int confidence;

  /// Width of the bar — callers pick based on layout (320 on the
  /// full card, 100 on the inline item row).
  final double width;

  const ClassificationConfidenceBar({
    super.key,
    required this.confidence,
    this.width = 160,
  });

  static StatusTone toneForConfidence(int c) {
    if (c >= 85) return StatusTone.verde;
    if (c >= 60) return StatusTone.amber;
    return StatusTone.rojo;
  }

  @override
  Widget build(BuildContext context) {
    final tone = toneForConfidence(confidence);
    final colors = StatusToneColors.of(tone);
    final clamped = confidence.clamp(0, 100);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confianza',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AduaNextTheme.textSecondary,
              ),
            ),
            Text(
              '$clamped%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AduaNextTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AduaNextTheme.borderSubtle),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clamped / 100,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.foreground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
