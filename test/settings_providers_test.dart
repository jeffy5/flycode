import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/l10n/app_language.dart';
import 'package:flycode/models/server_config.dart';
import 'package:flycode/providers/app_language_provider.dart';
import 'package:flycode/providers/local_preferences_repository.dart';
import 'package:flycode/providers/onboarding_provider.dart';
import 'package:flycode/providers/server_config_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'serverConfigProvider restore, save, and clear use repository boundary',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'server_config': '{"baseUrl":"http://restore.test","username":"user"}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(serverConfigProvider.future),
        ServerConfig(baseUrl: 'http://restore.test', username: 'user'),
      );

      await container
          .read(serverConfigProvider.notifier)
          .save(ServerConfig(baseUrl: 'http://saved.test'));
      expect(
        container.read(serverConfigProvider).value,
        ServerConfig(baseUrl: 'http://saved.test'),
      );

      await container.read(serverConfigProvider.notifier).clear();
      expect(
        container.read(serverConfigProvider).value,
        ServerConfig.defaultValue(),
      );
    },
  );

  test('appLanguageProvider restores asynchronously from repository', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language_v1': 'en',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguage.system);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(appLanguageProvider), AppLanguage.en);
  });

  test(
    'appLanguageProvider late restore does not override newer selection',
    () async {
      final repository = _DelayedLocalPreferencesRepository(
        restoredLanguage: AppLanguage.en,
      );
      final container = ProviderContainer(
        overrides: [
          localPreferencesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appLanguageProvider), AppLanguage.system);

      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.zh);
      expect(container.read(appLanguageProvider), AppLanguage.zh);

      repository.completeRestore();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(appLanguageProvider), AppLanguage.zh);
      expect(repository.savedLanguages, <AppLanguage>[AppLanguage.zh]);
    },
  );

  test(
    'onboarding controller invalidates completed provider after saving',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(serverSetupCompletedProvider.future),
        isFalse,
      );

      await container
          .read(onboardingControllerProvider)
          .markServerSetupCompleted();

      expect(await container.read(serverSetupCompletedProvider.future), isTrue);
    },
  );

  test(
    'onboarding provider delegates legacy migration to repository',
    () async {
      final repository = _TrackingLocalPreferencesRepository();
      final container = ProviderContainer(
        overrides: [
          localPreferencesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(serverSetupCompletedProvider.future), isTrue);
      expect(repository.loadServerSetupCompletedCalls, 1);

      await container
          .read(onboardingControllerProvider)
          .markServerSetupCompleted();
      expect(repository.savedServerSetupCompleted, <bool>[true]);
    },
  );
}

class _TrackingLocalPreferencesRepository extends LocalPreferencesRepository {
  _TrackingLocalPreferencesRepository()
    : super(preferencesLoader: _unusedLoader);

  int loadServerSetupCompletedCalls = 0;
  final List<bool> savedServerSetupCompleted = <bool>[];

  @override
  Future<bool> loadServerSetupCompleted() async {
    loadServerSetupCompletedCalls += 1;
    return true;
  }

  @override
  Future<void> saveServerSetupCompleted(bool completed) async {
    savedServerSetupCompleted.add(completed);
  }
}

class _DelayedLocalPreferencesRepository extends LocalPreferencesRepository {
  _DelayedLocalPreferencesRepository({required this.restoredLanguage})
    : super(preferencesLoader: _unusedLoader);

  final AppLanguage restoredLanguage;
  final Completer<AppLanguage> _restoreCompleter = Completer<AppLanguage>();
  final List<AppLanguage> savedLanguages = <AppLanguage>[];

  void completeRestore() {
    if (!_restoreCompleter.isCompleted) {
      _restoreCompleter.complete(restoredLanguage);
    }
  }

  @override
  Future<AppLanguage> loadAppLanguage() {
    return _restoreCompleter.future;
  }

  @override
  Future<void> saveAppLanguage(AppLanguage language) async {
    savedLanguages.add(language);
  }
}

Future<SharedPreferences> _unusedLoader() {
  throw UnimplementedError();
}
