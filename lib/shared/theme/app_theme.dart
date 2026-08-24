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
    final brightness = ThemeData.estimateBrightnessForColor(surface);
    final onSurface = _foregroundFor(surface);
    final onBackground = _foregroundFor(background);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: _foregroundFor(primary),
      secondary: secondary,
      onSecondary: _foregroundFor(secondary),
      surface: surface,
      onSurface: onSurface,
      outline: primary,
      outlineVariant: primary.withValues(alpha: 0.48),
      error: const Color(0xFFFF6B7A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : onSurface.withValues(alpha: 0.72),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : onSurface.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: secondary.withValues(alpha: 0.42),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: primary.withValues(alpha: 0.78),
            width: 1.2,
          ),
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
