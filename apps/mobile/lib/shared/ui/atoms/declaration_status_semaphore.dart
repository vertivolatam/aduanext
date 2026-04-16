/// Atom: visual status pill for a DUA.
///
/// Four visual states — one per canal selectividad / terminal status:
///   * **verde** (levante / confirmed / final_confirmed / departure_full)
///     — ready to ship / done.
///   * **amber** (validating / payment_pending / document_review /
///     physical_inspection / lpco_pending / confirmation_window) —
///     in progress; ATENA is working on it.
///   * **rojo** (rejected / annulled / cancelled) — needs agent
///     attention.
///   * **gris** (draft / registered / accepted / everything else) —
///     quiescent or pre-submission.
///
/// Color tokens live in `AduaNextTheme`. A `StatusTone` helper is
/// exported so downstream organisms (timeline, KPI row) can pick the
/// matching color without re-classifying.
library;

// `aduanext_domain` exports a `Container` class (an ATENA manifest
// entity); hide it so we can use Flutter's `Container` widget without
// renaming every call site.
import 'package:aduanext_domain/aduanext_domain.dart' hide Container;
import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';

enum StatusTone { verde, amber, rojo, gris }

/// Classifies a domain [DeclarationStatus] into one of the four UI
/// tones. Kept as a top-level function so the widget, timeline dot,
/// and KPI row all share the same mapping.
StatusTone toneForStatus(DeclarationStatus status) {
  switch (status) {
    case DeclarationStatus.levante:
    case DeclarationStatus.levanteTransit:
    case DeclarationStatus.arrivedAtPort:
    case DeclarationStatus.departureFull:
    case DeclarationStatus.confirmed:
    case DeclarationStatus.finalConfirmed:
    case DeclarationStatus.ducaSentToSieca:
      return StatusTone.verde;

    case DeclarationStatus.validating:
    case DeclarationStatus.paymentPending:
    case DeclarationStatus.documentReview:
    case DeclarationStatus.physicalInspection:
    case DeclarationStatus.lpcoPending:
    case DeclarationStatus.confirmationWindow:
    case DeclarationStatus.t1Mobilization:
    case DeclarationStatus.departurePartial:
      return StatusTone.amber;

    case DeclarationStatus.rejected:
    case DeclarationStatus.annulled:
    case DeclarationStatus.cancelled:
      return StatusTone.rojo;

    case DeclarationStatus.draft:
    case DeclarationStatus.registered:
    case DeclarationStatus.accepted:
      return StatusTone.gris;
  }
}

/// Foreground + background color pair for a [StatusTone]. Exposed so
/// other widgets (timeline, KPI cards) can reuse the same palette.
class StatusToneColors {
  final Color foreground;
  final Color background;
  final Color border;

  const StatusToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  static StatusToneColors of(StatusTone tone) {
    switch (tone) {
      case StatusTone.verde:
        return const StatusToneColors(
          foreground: AduaNextTheme.statusLevante,
          background: AduaNextTheme.statusLevanteBg,
          border: AduaNextTheme.stepperVerde,
        );
      case StatusTone.amber:
        return const StatusToneColors(
          foreground: AduaNextTheme.statusValidando,
          background: AduaNextTheme.statusValidandoBg,
          border: AduaNextTheme.stepperAmarillo,
        );
      case StatusTone.rojo:
        return const StatusToneColors(
          foreground: AduaNextTheme.statusRechazada,
          background: AduaNextTheme.statusRechazadaBg,
          border: AduaNextTheme.stepperRojo,
        );
      case StatusTone.gris:
        return const StatusToneColors(
          foreground: AduaNextTheme.textSecondary,
          background: AduaNextTheme.surfaceCard,
          border: AduaNextTheme.borderSubtle,
        );
    }
  }
}

/// The pill itself. Small atom — call sites wrap it in `Padding` or
/// align it inside cards as needed.
class DeclarationStatusSemaphore extends StatelessWidget {
  final DeclarationStatus status;

  /// Defaults to the domain-provided `displayName` (Spanish). Pass an
  /// override when the surface demands a shorter label (e.g. "Levante"
  /// instead of "Levante autorizado" on narrow cards).
  final String? labelOverride;

  /// Shrinks the pill — used inside dense list rows.
  final bool compact;

  const DeclarationStatusSemaphore({
    super.key,
    required this.status,
    this.labelOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = toneForStatus(status);
    final colors = StatusToneColors.of(tone);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        labelOverride ?? status.displayName,
        style: TextStyle(
          color: colors.foreground,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
