import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0816);
  static const Color surface = Color(0xFF171321);
  static const Color primary = Color(0xFF7C4DFF);
  static const Color secondary = Color(0xFF9D7BFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B2C8);

  static ThemeData fromPalette({
    required Color background,
    required Color surface,
    required Color primary,
    required Color secondary,
  }) {
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: const Color(0xFFFF6B7A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: primary.withValues(alpha: 0.12)),
        ),
      ),
      dividerColor: primary.withValues(alpha: 0.18),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _foregroundFor(primary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: _foregroundFor(primary),
      ),
    );
  }

  static ThemeData darkTheme() => fromPalette(
        background: background,
        surface: surface,
        primary: primary,
        secondary: secondary,
      );

  static Color _foregroundFor(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : const Color(0xFF111018);
}
