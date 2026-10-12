import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ────────────────────────────────────────────────
  static const Color primary     = Color(0xFF1A73E8);   // Melbet blue
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accent      = Color(0xFFFFB300);   // Gold accent
  static const Color success     = Color(0xFF00C853);
  static const Color warning     = Color(0xFFFF6D00);
  static const Color error       = Color(0xFFD50000);
  static const Color info        = Color(0xFF00B0FF);

  // ── Dark Background Palette ─────────────────────────────────────
  static const Color bgDark      = Color(0xFF0A0E1A);
  static const Color bgCard      = Color(0xFF131929);
  static const Color bgSurface   = Color(0xFF1C2333);
  static const Color bgBorder    = Color(0xFF2A3448);

  // ── Text Colors ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textMuted     = Color(0xFF546E7A);

  // ── Deviation Colors ────────────────────────────────────────────
  static const Color deviationPositive = Color(0xFF00E676);
  static const Color deviationNegative = Color(0xFFFF1744);
  static const Color deviationZero     = Color(0xFF90A4AE);

  // ── Gradients ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF131929)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Theme Data ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 32),
        displayMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24),
        headlineLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        headlineSmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: GoogleFonts.poppins(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 13),
        bodySmall: GoogleFonts.poppins(color: textMuted, fontSize: 12),
        labelLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgCard,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: bgBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 13),
        errorStyle: GoogleFonts.poppins(color: error, fontSize: 11),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: bgBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
        side: const BorderSide(color: bgBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
