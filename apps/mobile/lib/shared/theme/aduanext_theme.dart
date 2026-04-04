import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AduaNext Dark Theme — based on UI Design Spec
/// docs/superpowers/specs/2026-04-03-ui-design.md
/// Font: Ubuntu (Google Fonts)
class AduaNextTheme {
  AduaNextTheme._();

  // Surface colors
  static const Color surfaceRail = Color(0xFF0A0A14);
  static const Color surfacePanel = Color(0xFF0F0F1E);
  static const Color surfaceContent = Color(0xFF12121E);
  static const Color surfaceCard = Color(0xFF1A1A2E);
  static const Color borderSubtle = Color(0xFF2A2A40);

  // Primary
  static const Color primary = Color(0xFF3B6FE0);
  static const Color primaryLight = Color(0xFF6B9FFF);

  // Text
  static const Color textPrimary = Color(0xFFE0E0F0);
  static const Color textSecondary = Color(0xFF666680);

  // Status colors (foreground on tinted background)
  static const Color statusLevante = Color(0xFF4CAF50);
  static const Color statusLevanteBg = Color(0xFF0D2E1A);
  static const Color statusValidando = Color(0xFFFF9800);
  static const Color statusValidandoBg = Color(0xFF2E1A00);
  static const Color statusRechazada = Color(0xFFEF5350);
  static const Color statusRechazadaBg = Color(0xFF2E0D0D);
  static const Color statusBorrador = Color(0xFF64B5F6);
  static const Color statusBorradorBg = Color(0xFF0D1A2E);

  // Stepper semaforo
  static const Color stepperVerde = Color(0xFF4CAF50);
  static const Color stepperVerdeBg = Color(0xFF1B5E20);
  static const Color stepperAmarillo = Color(0xFFFF9800);
  static const Color stepperAmarilloBg = Color(0xFF4A3800);
  static const Color stepperAzul = Color(0xFF3B6FE0);
  static const Color stepperRojo = Color(0xFFEF5350);
  static const Color stepperRojoBg = Color(0xFF3A1010);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.ubuntuTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.ubuntu().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        surface: surfaceContent,
        onSurface: textPrimary,
        secondary: primaryLight,
        outline: borderSubtle,
      ),
      scaffoldBackgroundColor: surfaceContent,
      cardColor: surfaceCard,
      dividerColor: borderSubtle,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfacePanel,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary),
        ),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textPrimary),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: textSecondary,
          fontSize: 10,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
