import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../models/server_config.dart';
import '../theme/app_theme_mode.dart';
import 'shared_preferences_provider.dart';

part 'local_preferences_repository.g.dart';

const String _kServerConfigKey = 'server_config';
const String _kAppLanguageKey = 'app_language_v1';
const String _kThemeModeKey = 'app_theme_mode_v1';
const String _kServerSetupCompletedKey = 'server_setup_completed_v1';

@Riverpod(keepAlive: true)
LocalPreferencesRepository localPreferencesRepository(Ref ref) {
  return LocalPreferencesRepository(
    preferencesLoader: () => ref.read(sharedPreferencesProvider.future),
  );
}

class LocalPreferencesRepository {
  LocalPreferencesRepository({
    required Future<SharedPreferences> Function() preferencesLoader,
  }) : _preferencesLoader = preferencesLoader;

  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<ServerConfig> loadServerConfig() async {
    final prefs = await _preferencesLoader();
    final jsonString = prefs.getString(_kServerConfigKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ServerConfig.fromJson(json);
      } catch (_) {}
    }
    return ServerConfig.defaultValue();
  }

  Future<void> saveServerConfig(ServerConfig config) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(_kServerConfigKey, jsonEncode(config.toJson()));
  }

  Future<void> clearServerConfig() async {
    final prefs = await _preferencesLoader();
    await prefs.remove(_kServerConfigKey);
  }

  Future<AppLanguage> loadAppLanguage() async {
    final prefs = await _preferencesLoader();
    return AppLanguageX.fromStorageValue(prefs.getString(_kAppLanguageKey));
  }

  Future<void> saveAppLanguage(AppLanguage language) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(_kAppLanguageKey, language.storageValue);
  }

  Future<AppThemeMode> loadThemeMode() async {
    final prefs = await _preferencesLoader();
    return AppThemeModeX.fromStorageValue(prefs.getString(_kThemeModeKey));
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    final prefs = await _preferencesLoader();
    await prefs.setString(_kThemeModeKey, mode.storageValue);
  }

  Future<bool> loadServerSetupCompleted() async {
    final prefs = await _preferencesLoader();

    final completed = prefs.getBool(_kServerSetupCompletedKey);
    if (completed != null) {
      return completed;
    }

    final hasLegacyConfig =
        prefs.containsKey(_kServerConfigKey) &&
        (prefs.getString(_kServerConfigKey)?.isNotEmpty ?? false);
    if (hasLegacyConfig) {
      await prefs.setBool(_kServerSetupCompletedKey, true);
      return true;
    }

    return false;
  }

  Future<void> saveServerSetupCompleted(bool completed) async {
    final prefs = await _preferencesLoader();
    await prefs.setBool(_kServerSetupCompletedKey, completed);
  }
}
