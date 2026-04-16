/// Atom: monospace chip that renders an HS code.
///
/// Formats the wire string (e.g. `8539500000`) into dotted groups
/// (`8539.50.0000`) using the same convention as the RIMM mockup.
/// Accepts either the raw digits or an already-formatted code.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/aduanext_theme.dart';

class HsCodeChip extends StatelessWidget {
  final String code;

  /// When `true` renders the chip with the primary accent tint —
  /// used for the "recomendado" suggestion. Default is neutral.
  final bool accent;

  /// Size hint: `.large` is used in the suggestion-card title,
  /// `.small` on inline DUA form items.
  final HsCodeChipSize size;

  const HsCodeChip({
    super.key,
    required this.code,
    this.accent = false,
    this.size = HsCodeChipSize.large,
  });

  /// Format the code into the CR / SAC dotted convention:
  ///
  ///   * 6 digits  → `XXXX.XX`            (international sub-heading)
  ///   * 8 digits  → `XXXX.XX.XX`         (Central American SAC)
  ///   * 10 digits → `XXXX.XX.XXXX`       (CR national — 4-2-4)
  ///   * 12 digits → `XXXX.XX.XXXX.XX`    (national precision level 2)
  ///
  /// Already-dotted codes pass through unchanged. Inputs <4 digits
  /// return as-is.
  static String format(String raw) {
    if (raw.contains('.')) return raw;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 4)}.${digits.substring(4)}';
    }
    if (digits.length <= 10) {
      // 7-10 digits: 4-2-rest.
      return '${digits.substring(0, 4)}.${digits.substring(4, 6)}'
          '.${digits.substring(6)}';
    }
    // 11-12 digits: 4-2-4-rest.
    return '${digits.substring(0, 4)}.${digits.substring(4, 6)}'
        '.${digits.substring(6, 10)}.${digits.substring(10)}';
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = switch (size) {
      HsCodeChipSize.small => 11.0,
      HsCodeChipSize.large => 14.0,
    };
    return Text(
      format(code),
      style: GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: accent ? AduaNextTheme.primary : AduaNextTheme.textPrimary,
      ),
    );
  }
}

enum HsCodeChipSize { small, large }
