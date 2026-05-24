import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeoBrutalismTheme {
  // Warna Utama
  static const Color primary = Color(0xFF705D00);
  static const Color primaryContainer = Color(0xFFFFD700); // Vibrant Yellow
  static const Color secondary = Color(0xFF006875);
  static const Color secondaryContainer = Color(0xFF7CEAFD); // Electric Cyan
  static const Color tertiary = Color(0xFF3B6A00);
  static const Color tertiaryContainer = Color(0xFFACEC6B); // Lively Green
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color background = Color(0xFFFBF9F1); // Off-White/Cream
  static const Color surface = Color(0xFFFBF9F1);
  static const Color onSurface = Color(0xFF1B1C17); // Deep Charcoal
  static const Color outline = Color(0xFF1B1C17); // Thick borders are black/deep charcoal
  static const Color onSurfaceVariant = Color(0xFF4D4732);
  static const Color surfaceDim = Color(0xFFDCDAD2);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E0);

  // Radius Geometri
  static const double cardRadius = 20.0;
  static const double buttonRadius = 12.0;
  static const double checkboxRadius = 6.0;

  // Stroke/Border Width
  static const double borderWidth = 4.0;
  static const double borderWidthThin = 2.0;

  // Shadow Offset
  static const Offset shadowOffset = Offset(6, 6);
  static const Offset shadowOffsetLarge = Offset(8, 8);
  static const Offset shadowOffsetFab = Offset(10, 10);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onSurface,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSurface,
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onSurface,
        error: error,
        onError: Colors.white,
        errorContainer: errorContainer,
        onErrorContainer: onSurface,
        surface: surface,
        onSurface: onSurface,
        outline: outline,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.1,
          letterSpacing: -0.96,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.hankenGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: onSurface,
          height: 1.2,
        ),
        labelSmall: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onSurface,
          height: 1.2,
        ),
      ),
    );
  }
}
