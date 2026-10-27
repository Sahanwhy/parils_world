import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Paril — Dark Romantic Theme
/// Palette: near-black background, charcoal cards, muted violet/rose accents,
/// warm off-white text. Material 3 with custom ThemeData.
class AppTheme {
  AppTheme._();

  // ── Colour tokens ──────────────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF0A0A12);
  static const Color backgroundSurface = Color(0xFF111120);
  static const Color cardColor = Color(0xFF1A1A2E);
  static const Color cardColorElevated = Color(0xFF1F1F35);

  static const Color accentViolet = Color(0xFF7B4FBF);
  static const Color accentVioletLight = Color(0xFF9B6FDF);
  static const Color accentRose = Color(0xFFBF4F7B);
  static const Color accentRoseLight = Color(0xFFDF6F9B);
  static const Color accentGlow = Color(0xFF4A3070);

  static const Color textPrimary = Color(0xFFF0EAF8);
  static const Color textSecondary = Color(0xFFB0A8C0);
  static const Color textMuted = Color(0xFF706880);

  static const Color dividerColor = Color(0xFF2A2A40);
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF6A9F7A);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A12), Color(0xFF0F0F20), Color(0xFF12101A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentViolet, accentRose],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E32), Color(0xFF181828)],
  );

  // ── Radii ──────────────────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 28.0;

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: accentViolet,
        onPrimary: textPrimary,
        primaryContainer: accentGlow,
        onPrimaryContainer: textPrimary,
        secondary: accentRose,
        onSecondary: textPrimary,
        secondaryContainer: const Color(0xFF3A1F2E),
        onSecondaryContainer: textPrimary,
        surface: backgroundSurface,
        onSurface: textPrimary,
        surfaceContainerHighest: cardColor,
        error: errorColor,
        onError: textPrimary,
        outline: dividerColor,
        outlineVariant: textMuted,
      ),
      scaffoldBackgroundColor: backgroundDeep,
      cardColor: cardColor,
      dividerColor: dividerColor,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.0,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w300,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(color: textSecondary),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: textMuted),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(color: textSecondary),
        labelSmall: textTheme.labelSmall?.copyWith(color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDeep,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentViolet,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentVioletLight,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: accentViolet, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentVioletLight,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accentViolet, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColorElevated,
        contentTextStyle: GoogleFonts.outfit(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundSurface,
        selectedItemColor: accentViolet,
        unselectedItemColor: textMuted,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundSurface,
        indicatorColor: accentGlow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              color: accentVioletLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.outfit(color: textMuted, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentVioletLight);
          }
          return const IconThemeData(color: textMuted);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 15,
        ),
      ),
    );
  }
}
