/// Atom: single dot on a DUA timeline.
///
/// Three visual states:
///   * [TimelineDotState.past] — filled with tone color; the step has
///     occurred.
///   * [TimelineDotState.current] — filled + outer ring; the DUA is
///     currently here.
///   * [TimelineDotState.future] — gray placeholder; not yet reached.
///
/// The dot paints itself; layout (horizontal line between dots, label
/// under the dot) is the organism's job.
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import 'declaration_status_semaphore.dart' show StatusTone, StatusToneColors;

enum TimelineDotState { past, current, future }

class TimelineDot extends StatelessWidget {
  final TimelineDotState state;

  /// Tone for past/current dots. Unused when `state == future` (future
  /// dots are always neutral gray per the mockup).
  final StatusTone tone;

  /// Larger surface for the current dot (10px vs 8px) per mockup.
  final bool prominent;

  const TimelineDot({
    super.key,
    required this.state,
    this.tone = StatusTone.verde,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case TimelineDotState.past:
        final colors = StatusToneColors.of(tone);
        return Container(
          width: prominent ? 10 : 8,
          height: prominent ? 10 : 8,
          decoration: BoxDecoration(
            color: colors.foreground,
            shape: BoxShape.circle,
          ),
        );
      case TimelineDotState.current:
        final colors = StatusToneColors.of(tone);
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors.foreground,
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.foreground.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        );
      case TimelineDotState.future:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AduaNextTheme.borderSubtle,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

/// Connector line between two timeline dots. [StatusTone.gris] renders
/// the default gray line for the unreached tail.
class TimelineConnector extends StatelessWidget {
  final StatusTone tone;
  final double thickness;

  const TimelineConnector({
    super.key,
    this.tone = StatusTone.gris,
    this.thickness = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StatusToneColors.of(tone);
    return Container(
      height: thickness,
      color: tone == StatusTone.gris
          ? AduaNextTheme.borderSubtle
          : colors.foreground,
    );
  }
}
