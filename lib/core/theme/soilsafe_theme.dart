import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class SoilSafeColors {
  static const Color primaryGreen = Color(0xFF7CC47F);
  static const Color cream = Color(0xFFF4FFE6);
}

abstract final class SoilSafeTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SoilSafeColors.primaryGreen,
      primary: SoilSafeColors.primaryGreen,
      surface: SoilSafeColors.cream,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SoilSafeColors.cream,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SoilSafeColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SoilSafeColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SoilSafeColors.primaryGreen,
          side: const BorderSide(color: SoilSafeColors.primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }
}
