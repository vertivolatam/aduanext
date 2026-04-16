/// Molecule: one card in the RIMM suggestion list.
///
/// Layout (matches `07-rimm-classifier.html`):
///   * Header: HS code (mono, primary accent when "recomendado") +
///     short description + confidence bar.
///   * Footer: tariff-rate grid (DAI / IVA / ISC).
///   * Optional national-note box.
///
/// "RECOMENDADO" ribbon is stamped on the top-right of the highest-
/// confidence suggestion.
library;

import 'package:flutter/material.dart';

import '../../theme/aduanext_theme.dart';
import '../../../features/classifier/classification_dto.dart';
import '../atoms/classification_confidence_bar.dart';
import '../atoms/hs_code_chip.dart';
import '../atoms/tariff_rate_cell.dart';

class ClassificationSuggestionCard extends StatelessWidget {
  final ClassificationSuggestion suggestion;

  /// `true` when this is the top suggestion — paints the primary
  /// border + "RECOMENDADO" badge.
  final bool recommended;

  /// Called when the card is tapped. The drawer confirm button uses
  /// the currently-selected card, so tapping a card = "I pick this".
  final VoidCallback? onTap;

  /// Whether this card is the current selection — draws a thicker
  /// primary border.
  final bool selected;

  const ClassificationSuggestionCard({
    super.key,
    required this.suggestion,
    this.recommended = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = recommended || selected
        ? AduaNextTheme.primary
        : AduaNextTheme.borderSubtle;
    final borderWidth = recommended || selected ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AduaNextTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HsCodeChip(
                              code: suggestion.hsCode,
                              accent: recommended,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              suggestion.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AduaNextTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClassificationConfidenceBar(
                        confidence: suggestion.confidence,
                        width: 120,
                      ),
                    ],
                  ),
                  const Divider(
                    height: 16,
                    thickness: 1,
                    color: AduaNextTheme.borderSubtle,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TariffRateCell(
                        label: 'DAI',
                        percent: suggestion.rates.dai,
                        tintAbove: 3,
                      ),
                      const SizedBox(width: 12),
                      TariffRateCell(
                        label: 'IVA',
                        percent: suggestion.rates.iva,
                      ),
                      const SizedBox(width: 12),
                      TariffRateCell(
                        label: 'ISC',
                        percent: suggestion.rates.isc,
                        tintAbove: 0,
                      ),
                    ],
                  ),
                  if (suggestion.nationalNote != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AduaNextTheme.surfacePanel,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AduaNextTheme.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nota Nacional',
                            style: TextStyle(
                              fontSize: 9,
                              color: AduaNextTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            suggestion.nationalNote!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AduaNextTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (recommended)
              Positioned(
                top: 0,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AduaNextTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

