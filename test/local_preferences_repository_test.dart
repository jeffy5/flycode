import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/l10n/app_language.dart';
import 'package:flycode/models/server_config.dart';
import 'package:flycode/providers/local_preferences_repository.dart';
import 'package:flycode/theme/app_theme_mode.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loadServerConfig falls back to default on invalid json', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'server_config': 'not-json',
    });

    final repository = _makeRepository();

    expect(await repository.loadServerConfig(), ServerConfig.defaultValue());
  });

  test(
    'saveServerConfig and clearServerConfig update persisted value',
    () async {
      final repository = _makeRepository();
      final config = ServerConfig(
        baseUrl: 'http://server.test',
        username: 'user',
        password: 'pass',
      );

      await repository.saveServerConfig(config);
      expect(await repository.loadServerConfig(), config);

      await repository.clearServerConfig();
      expect(await repository.loadServerConfig(), ServerConfig.defaultValue());
    },
  );

  test('app language and theme mode use typed mapping', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language_v1': 'zh',
      'app_theme_mode_v1': 'dark',
    });

    final repository = _makeRepository();

    expect(await repository.loadAppLanguage(), AppLanguage.zh);
    expect(await repository.loadThemeMode(), AppThemeMode.dark);

    await repository.saveAppLanguage(AppLanguage.en);
    await repository.saveThemeMode(AppThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language_v1'), 'en');
    expect(prefs.getString('app_theme_mode_v1'), 'light');
  });

  test(
    'loadServerSetupCompleted returns persisted flag when present',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'server_setup_completed_v1': true,
      });

      final repository = _makeRepository();

      expect(await repository.loadServerSetupCompleted(), isTrue);
    },
  );

  test('loadServerSetupCompleted migrates legacy server config key', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'server_config': '{"baseUrl":"http://legacy.test"}',
    });

    final repository = _makeRepository();

    expect(await repository.loadServerSetupCompleted(), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('server_setup_completed_v1'), isTrue);
  });
}

LocalPreferencesRepository _makeRepository() {
  return LocalPreferencesRepository(
    preferencesLoader: SharedPreferences.getInstance,
  );
}
