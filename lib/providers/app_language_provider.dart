import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_language.dart' as app_language;
import 'hydrated_state.dart';
import 'local_preferences_repository.dart';

part 'app_language_provider.g.dart';

@Riverpod(keepAlive: true, name: 'appLanguageProvider')
class AppLanguageNotifier extends _$AppLanguageNotifier {
  late final HydratedValueController<app_language.AppLanguage> _hydration =
      HydratedValueController<app_language.AppLanguage>(
        readState: () => state,
        writeState: (value) => state = value,
        load: () =>
            ref.read(localPreferencesRepositoryProvider).loadAppLanguage(),
        persist: (value) =>
            ref.read(localPreferencesRepositoryProvider).saveAppLanguage(value),
        isMounted: () => ref.mounted,
      );

  @override
  app_language.AppLanguage build() {
    _hydration.startRestore();
    return app_language.AppLanguage.system;
  }

  Future<void> setLanguage(app_language.AppLanguage language) async {
    if (state == language && !_hydration.isHydrating) return;
    await _hydration.setValue(language);
  }
}
