import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de la aplicación ChangaYa — Material 3.
///
/// Usa [ColorScheme.fromSeed] con el color semilla de ChangaYa.
/// Se exportan [lightTheme] y [darkTheme] para usar en [MaterialApp.router].
abstract final class AppTheme {
  /// Color primario de ChangaYa — azul Formosa.
  static const Color _seedColor = Color(0xFF1565C0);

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------------

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text theme con Google Fonts
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }
}
