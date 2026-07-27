import 'package:flutter/material.dart';
import 'package:flycode/l10n/app_localizations.dart';

enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case AppThemeMode.system:
        return l10n.themeModeSystem;
      case AppThemeMode.light:
        return l10n.themeModeLight;
      case AppThemeMode.dark:
        return l10n.themeModeDark;
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }

  static AppThemeMode fromStorageValue(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
}
