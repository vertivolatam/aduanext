/// Organism: horizontal DUA timeline.
///
/// Renders 7 key states from the DUA lifecycle:
///   Registro → Aceptada → Validada → Pagada → Levante → Confirmada
///
/// Each state becomes a [TimelineDot] + label + optional date,
/// connected by [TimelineConnector] lines. The connector/dot tone
/// follows:
///
///   * Past state → verde
///   * Current state → current tone (from `DispatchSummary.status`)
///   * Future state → gris
///
/// Two layout modes:
///
///   * [TimelineVariant.expanded] — dots + labels + dates beneath each
///     (mockup: card #1, Levante granted). ~70-80px tall.
///   * [TimelineVariant.compact] — dots only (mockup: card #2, in
///     validation). ~20px tall.
library;

// Hide `Container` — it's an ATENA manifest entity in the domain
// package and collides with Flutter's widget.
import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/dispatch_dto.dart';
import '../../theme/aduanext_theme.dart';
import '../atoms/declaration_status_semaphore.dart';
import '../atoms/timeline_dot.dart';

enum TimelineVariant { expanded, compact }

/// A single state on the timeline — the 6 keys from the mockup plus
/// a 7th terminal state for Confirmada. The order matches how a
/// non-rejected DUA walks the ATENA state machine.
class TimelineStep {
  final DeclarationStatus status;
  final String label;

  const TimelineStep(this.status, this.label);

  static const List<TimelineStep> defaultSteps = [
    TimelineStep(DeclarationStatus.registered, 'Registro'),
    TimelineStep(DeclarationStatus.accepted, 'Aceptada'),
    TimelineStep(DeclarationStatus.validating, 'Validada'),
    TimelineStep(DeclarationStatus.paymentPending, 'Pagada'),
    TimelineStep(DeclarationStatus.levante, 'Levante'),
    TimelineStep(DeclarationStatus.confirmed, 'Confirmada'),
  ];
}

class DuaTimeline extends StatelessWidget {
  final DispatchSummary dispatch;
  final TimelineVariant variant;
  final List<TimelineStep> steps;

  const DuaTimeline({
    super.key,
    required this.dispatch,
    this.variant = TimelineVariant.expanded,
    this.steps = TimelineStep.defaultSteps,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentStepIndex();

    // Each step becomes: dot + optional label/date block below.
    // Separators are flex-grown connectors so the row scales with
    // available width.
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final state = _stateFor(i, currentIndex);
      final tone = _toneFor(state, step.status);

      children.add(_DotWithLabel(
        step: step,
        state: state,
        tone: tone,
        showLabel: variant == TimelineVariant.expanded,
        timestamp: dispatch.stateTimestamps[step.status.code],
      ));

      if (i < steps.length - 1) {
        // The connector from step i to i+1 is painted in the *current*
        // step's tone if i is strictly before the current; otherwise
        // gray (we haven't reached it yet).
        final connectorTone = i < currentIndex ? StatusTone.verde : StatusTone.gris;
        children.add(Expanded(
          child: TimelineConnector(tone: connectorTone),
        ));
      }
    }

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );

    return Container(
      color: AduaNextTheme.surfacePanel,
      padding: variant == TimelineVariant.expanded
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: body,
    );
  }

  int _currentStepIndex() {
    // Find the last step whose status appears in `stateTimestamps`.
    // If none do, the DUA is pre-registered (draft) — return -1 so
    // every step renders as "future".
    for (var i = steps.length - 1; i >= 0; i--) {
      if (dispatch.stateTimestamps.containsKey(steps[i].status.code)) {
        return i;
      }
    }
    return -1;
  }

  TimelineDotState _stateFor(int index, int currentIndex) {
    if (index < currentIndex) return TimelineDotState.past;
    if (index == currentIndex) return TimelineDotState.current;
    return TimelineDotState.future;
  }

  StatusTone _toneFor(TimelineDotState state, DeclarationStatus status) {
    if (state == TimelineDotState.future) return StatusTone.gris;
    if (state == TimelineDotState.current) return toneForStatus(dispatch.status);
    return StatusTone.verde;
  }
}

class _DotWithLabel extends StatelessWidget {
  final TimelineStep step;
  final TimelineDotState state;
  final StatusTone tone;
  final bool showLabel;
  final DateTime? timestamp;

  const _DotWithLabel({
    required this.step,
    required this.state,
    required this.tone,
    required this.showLabel,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return TimelineDot(
        state: state,
        tone: tone,
        prominent: state == TimelineDotState.current,
      );
    }

    // expanded variant — dot + date/label block
    final labelColor = state == TimelineDotState.future
        ? AduaNextTheme.textSecondary
        : StatusToneColors.of(tone).foreground;

    final dateStr = timestamp == null ? '—' : DateFormat('MMM d').format(timestamp!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TimelineDot(
          state: state,
          tone: tone,
          prominent: state == TimelineDotState.current,
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 8,
            color: labelColor,
            fontWeight: state == TimelineDotState.current
                ? FontWeight.w700
                : FontWeight.normal,
          ),
        ),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 8,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
