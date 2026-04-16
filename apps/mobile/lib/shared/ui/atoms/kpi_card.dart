/// Atom: single KPI tile for the dashboard header.
///
/// Matches the mockup (08-monitoring-dashboard.html): a compact card
/// with an uppercase label, a large number, and an optional tint that
/// hints at the status tone (green for levante, amber for in-process,
/// red for attention-required).
///
/// The widget is stateless — consumers pass the count (or null for a
/// loading skeleton) and a [StatusTone]; the card handles layout.
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import 'declaration_status_semaphore.dart' show StatusTone, StatusToneColors;

/// Visual variant for a KPI. [neutral] uses the default surface card
/// chrome (for "Activas" totals); the tone variants paint a tinted
/// background so the dashboard signals attention without an icon.
class KpiCard extends StatelessWidget {
  final String label;

  /// Null while loading — renders a shimmery `---` so the row height
  /// stays stable during fetches.
  final int? value;

  /// Tone of the tile. Defaults to [StatusTone.gris] which renders
  /// as the standard surface card.
  final StatusTone tone;

  /// Optional tap handler — when set, the card applies an InkWell so
  /// the KPI can filter the list below.
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.tone = StatusTone.gris,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StatusToneColors.of(tone);
    final isNeutral = tone == StatusTone.gris;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isNeutral ? AduaNextTheme.surfaceCard : colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNeutral ? AduaNextTheme.borderSubtle : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color:
                  isNeutral ? AduaNextTheme.textSecondary : colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '---',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: value == null
                  ? AduaNextTheme.textSecondary
                  : (isNeutral
                      ? AduaNextTheme.textPrimary
                      : colors.foreground),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }
}
