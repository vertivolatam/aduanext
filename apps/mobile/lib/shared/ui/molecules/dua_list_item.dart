/// Molecule: one row in the dashboard DUA list.
///
/// Renders the card the user sees for every DUA:
///   * declarationId + [DeclarationStatusSemaphore] + [RiskScoreBadge]
///   * commercial description (1 line, ellipsized)
///   * right-side status message (e.g. "Retiro disponible", "En ATENA
///     desde hace 4h")
///   * optional footer slot — the dashboard passes either the
///     [DuaTimeline] (expanded) or a rejected panel (VRTV-85).
///
/// Layout follows the monitoring mockup exactly: a rounded card with
/// tone-colored left border on highlighted rows, and a footer section
/// that renders with a darker background.
library;

import 'package:flutter/material.dart';

import '../../api/dispatch_dto.dart';
import '../../theme/aduanext_theme.dart';
import '../atoms/declaration_status_semaphore.dart';
import '../atoms/risk_score_badge.dart';

class DuaListItem extends StatelessWidget {
  final DispatchSummary dispatch;

  /// Right-side hint text under the status pill. Null hides the slot.
  final String? rightHint;

  /// Additional hint below [rightHint] — typically the customs office
  /// name. Null hides the line.
  final String? rightSubtitle;

  /// Footer below the main row — the dashboard embeds either the
  /// [DuaTimeline] or a rejected-error panel here. Null hides it.
  final Widget? footer;

  /// Tap handler on the main row (navigates to DuaDetailPage).
  final VoidCallback? onTap;

  /// Highlight the row with a colored left border — used for the
  /// "active" card or the rejected card per the mockup. Defaults to
  /// no highlight (neutral outline).
  final StatusTone? highlightTone;

  const DuaListItem({
    super.key,
    required this.dispatch,
    this.rightHint,
    this.rightSubtitle,
    this.footer,
    this.onTap,
    this.highlightTone,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = highlightTone ?? toneForStatus(dispatch.status);
    final highlightColors = StatusToneColors.of(highlight);

    // Whether the border should be tinted — only for non-neutral rows
    // (levante / rejected / etc.). Neutral (gris) rows use the default
    // subtle border from the theme so the list reads cleanly.
    final tinted = highlightTone != null ||
        highlight == StatusTone.verde ||
        highlight == StatusTone.rojo;

    final border = Border.all(
      color: tinted ? highlightColors.border : AduaNextTheme.borderSubtle,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AduaNextTheme.surfaceCard,
            borderRadius: BorderRadius.circular(10),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: _buildLeft(context)),
                    if (rightHint != null || rightSubtitle != null) ...[
                      const SizedBox(width: 8),
                      _buildRight(context),
                    ],
                  ],
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeft(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              dispatch.declarationId,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AduaNextTheme.textPrimary,
              ),
            ),
            DeclarationStatusSemaphore(status: dispatch.status),
            if (dispatch.riskScore != null)
              RiskScoreBadge(score: dispatch.riskScore),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dispatch.commercialDescription,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AduaNextTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRight(BuildContext context) {
    final tone = toneForStatus(dispatch.status);
    final colors = StatusToneColors.of(tone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rightHint != null)
          Text(
            rightHint!,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone == StatusTone.gris
                  ? AduaNextTheme.textSecondary
                  : colors.foreground,
            ),
          ),
        if (rightSubtitle != null)
          Text(
            rightSubtitle!,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              color: AduaNextTheme.textSecondary,
            ),
          ),
      ],
    );
  }
}
