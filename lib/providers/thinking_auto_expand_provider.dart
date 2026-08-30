import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hydrated_state.dart';
import 'shared_preferences_provider.dart';

const _kThinkingAutoExpandKey = 'thinking_auto_expand_v1';

final thinkingAutoExpandProvider =
    NotifierProvider<ThinkingAutoExpandNotifier, bool>(
      ThinkingAutoExpandNotifier.new,
    );

class ThinkingAutoExpandNotifier extends Notifier<bool> {
  late final HydratedValueController<bool> _hydration =
      HydratedValueController<bool>(
        readState: () => state,
        writeState: (value) => state = value,
        load: () => readThinkingAutoExpandFromStorage(
          () => ref.read(sharedPreferencesProvider.future),
        ),
        persist: _persist,
        isMounted: () => ref.mounted,
      );

  @override
  bool build() {
    _hydration.startRestore();
    return false;
  }

  Future<void> setAutoExpand(bool value) async {
    if (state == value && !_hydration.isHydrating) return;
    await _hydration.setValue(value, waitForHydration: true);
  }

  Future<void> _persist(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kThinkingAutoExpandKey, value);
  }
}

Future<bool> readThinkingAutoExpandFromStorage(
  Future<SharedPreferences> Function() preferencesLoader,
) async {
  final prefs = await preferencesLoader();
  return prefs.getBool(_kThinkingAutoExpandKey) ?? false;
}
