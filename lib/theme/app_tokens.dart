import 'package:flutter/material.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final Color card;
  final Color border;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color success;
  final Color successForeground;
  final Color info;
  final Color infoForeground;
  final Color warning;
  final Color warningForeground;
  final Color errorSoft;
  final Color errorSoftForeground;
  final double radiusXs;
  final double radiusM;
  final double radiusL;
  final double radiusPill;
  final double pageHorizontalPadding;

  const AppThemeTokens({
    required this.card,
    required this.border,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.success,
    required this.successForeground,
    required this.info,
    required this.infoForeground,
    required this.warning,
    required this.warningForeground,
    required this.errorSoft,
    required this.errorSoftForeground,
    required this.radiusXs,
    required this.radiusM,
    required this.radiusL,
    required this.radiusPill,
    required this.pageHorizontalPadding,
  });

  static const AppThemeTokens light = AppThemeTokens(
    card: Color(0xFFF4F4F5),
    border: Color(0xFFD4D4D8),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF52525B),
    success: Color(0xFFCCFBF1),
    successForeground: Color(0xFF0F766E),
    info: Color(0xFFEDE9FE),
    infoForeground: Color(0xFF5B21B6),
    warning: Color(0xFFFCE7F3),
    warningForeground: Color(0xFF9D174D),
    errorSoft: Color(0xFFFEE2E2),
    errorSoftForeground: Color(0xFF991B1B),
    radiusXs: 14,
    radiusM: 24,
    radiusL: 24,
    radiusPill: 999,
    pageHorizontalPadding: 16,
  );

  static const AppThemeTokens dark = AppThemeTokens(
    card: Color(0xFF1A182E),
    border: Color(0xFF2B283D),
    mutedForeground: Color(0xFF888799),
    accent: Color(0xFF131124),
    accentForeground: Color(0xFFF2F3F0),
    success: Color(0xFF3B4748),
    successForeground: Color(0xFFA1E5A1),
    info: Color(0xFF404562),
    infoForeground: Color(0xFFB2CCFF),
    warning: Color(0xFF53484F),
    warningForeground: Color(0xFFFFD9B2),
    errorSoft: Color(0xFF53424F),
    errorSoftForeground: Color(0xFFFFBFB2),
    radiusXs: 14,
    radiusM: 24,
    radiusL: 24,
    radiusPill: 999,
    pageHorizontalPadding: 16,
  );

  @override
  ThemeExtension<AppThemeTokens> copyWith({
    Color? card,
    Color? border,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? success,
    Color? successForeground,
    Color? info,
    Color? infoForeground,
    Color? warning,
    Color? warningForeground,
    Color? errorSoft,
    Color? errorSoftForeground,
    double? radiusXs,
    double? radiusM,
    double? radiusL,
    double? radiusPill,
    double? pageHorizontalPadding,
  }) {
    return AppThemeTokens(
      card: card ?? this.card,
      border: border ?? this.border,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      success: success ?? this.success,
      successForeground: successForeground ?? this.successForeground,
      info: info ?? this.info,
      infoForeground: infoForeground ?? this.infoForeground,
      warning: warning ?? this.warning,
      warningForeground: warningForeground ?? this.warningForeground,
      errorSoft: errorSoft ?? this.errorSoft,
      errorSoftForeground: errorSoftForeground ?? this.errorSoftForeground,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusM: radiusM ?? this.radiusM,
      radiusL: radiusL ?? this.radiusL,
      radiusPill: radiusPill ?? this.radiusPill,
      pageHorizontalPadding:
          pageHorizontalPadding ?? this.pageHorizontalPadding,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      card: Color.lerp(card, other.card, t) ?? card,
      border: Color.lerp(border, other.border, t) ?? border,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ??
          mutedForeground,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t) ??
          accentForeground,
      success: Color.lerp(success, other.success, t) ?? success,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t) ??
          successForeground,
      info: Color.lerp(info, other.info, t) ?? info,
      infoForeground:
          Color.lerp(infoForeground, other.infoForeground, t) ?? infoForeground,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t) ??
          warningForeground,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t) ?? errorSoft,
      errorSoftForeground:
          Color.lerp(errorSoftForeground, other.errorSoftForeground, t) ??
          errorSoftForeground,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t) ?? radiusXs,
      radiusM: lerpDouble(radiusM, other.radiusM, t) ?? radiusM,
      radiusL: lerpDouble(radiusL, other.radiusL, t) ?? radiusL,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t) ?? radiusPill,
      pageHorizontalPadding:
          lerpDouble(pageHorizontalPadding, other.pageHorizontalPadding, t) ??
          pageHorizontalPadding,
    );
  }
}

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}

extension AppThemeTokensBuildContextX on BuildContext {
  AppThemeTokens get tokens {
    final tokens = Theme.of(this).extension<AppThemeTokens>();
    if (tokens != null) return tokens;
    return AppThemeTokens.light;
  }
}
