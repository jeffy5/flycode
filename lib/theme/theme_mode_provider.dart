import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/hydrated_state.dart';
import '../providers/local_preferences_repository.dart';
import 'app_theme_mode.dart';

part 'theme_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeMode extends _$ThemeMode {
  late final HydratedValueController<AppThemeMode> _hydration =
      HydratedValueController<AppThemeMode>(
        readState: () => state,
        writeState: (value) => state = value,
        load: () =>
            ref.read(localPreferencesRepositoryProvider).loadThemeMode(),
        persist: (value) =>
            ref.read(localPreferencesRepositoryProvider).saveThemeMode(value),
        isMounted: () => ref.mounted,
      );

  @override
  AppThemeMode build() {
    _hydration.startRestore();
    return AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (state == mode && !_hydration.isHydrating) return;
    await _hydration.setValue(mode);
  }
}
