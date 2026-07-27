import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF8B5CF6),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFE4E4E7),
      onSecondary: Color(0xFF18181B),
      error: Color(0xFFCC3314),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF18181B),
    );
    return _build(colorScheme: colorScheme, tokens: AppThemeTokens.light);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF8B5CF6),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF403F51),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFCC3314),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFF131124),
      onSurface: Color(0xFFE8E8EA),
    );
    return _build(colorScheme: colorScheme, tokens: AppThemeTokens.dark);
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppThemeTokens tokens,
  }) {
    final textTheme = _textTheme(colorScheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Inter',
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border.withValues(alpha: 0.5),
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusM),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.mutedForeground,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusXs),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusXs),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.mutedForeground,
        textColor: colorScheme.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) {
    const fallback = TextTheme();
    return fallback.copyWith(
      displayLarge: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
      bodySmall: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
      labelLarge: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
      labelMedium: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
      labelSmall: TextStyle(fontFamily: 'Inter', color: colorScheme.onSurface),
    );
  }
}
