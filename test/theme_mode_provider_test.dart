import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/local_preferences_repository.dart';
import 'package:flycode/providers/shared_preferences_provider.dart';
import 'package:flycode/theme/app_theme_mode.dart';
import 'package:flycode/theme/theme_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('late restore does not override a newer user theme selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_theme_mode_v1': 'dark',
    });

    final restoreGate = Completer<SharedPreferences>();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => restoreGate.future),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), AppThemeMode.system);

    await container
        .read(themeModeProvider.notifier)
        .setMode(AppThemeMode.light);
    expect(container.read(themeModeProvider), AppThemeMode.light);

    restoreGate.complete(await SharedPreferences.getInstance());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), AppThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_theme_mode_v1'), 'light');
  });

  test(
    'restore reads persisted theme mode through repository boundary',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_theme_mode_v1': 'dark',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), AppThemeMode.dark);
    },
  );

  test('setMode persists through repository provider', () async {
    final repository = _FakeLocalPreferencesRepository();
    final container = ProviderContainer(
      overrides: [
        localPreferencesRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).setMode(AppThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(themeModeProvider), AppThemeMode.dark);
    expect(repository.savedModes, <AppThemeMode>[AppThemeMode.dark]);
  });
}

class _FakeLocalPreferencesRepository extends LocalPreferencesRepository {
  _FakeLocalPreferencesRepository() : super(preferencesLoader: _unusedLoader);

  final List<AppThemeMode> savedModes = <AppThemeMode>[];

  @override
  Future<AppThemeMode> loadThemeMode() async {
    return AppThemeMode.system;
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    savedModes.add(mode);
  }
}

Future<SharedPreferences> _unusedLoader() {
  throw UnimplementedError();
}
