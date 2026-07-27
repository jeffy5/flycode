import 'package:flutter/material.dart';
import 'package:flycode/l10n/app_localizations.dart';

enum AppLanguage { system, zh, en }

extension AppLanguageX on AppLanguage {
  Locale? toLocale() {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.zh:
        return const Locale('zh');
      case AppLanguage.en:
        return const Locale('en');
    }
  }

  String get storageValue {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.zh:
        return 'zh';
      case AppLanguage.en:
        return 'en';
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case AppLanguage.system:
        return l10n.languageFollowSystem;
      case AppLanguage.zh:
        return l10n.languageSimplifiedChinese;
      case AppLanguage.en:
        return l10n.languageEnglish;
    }
  }

  static AppLanguage fromStorageValue(String? value) {
    switch (value) {
      case 'zh':
        return AppLanguage.zh;
      case 'en':
        return AppLanguage.en;
      default:
        return AppLanguage.system;
    }
  }
}
