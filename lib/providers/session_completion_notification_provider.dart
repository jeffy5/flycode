import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flycode/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hydrated_state.dart';
import 'shared_preferences_provider.dart';

const _kSessionCompletionNotificationModeKey =
    'session_completion_notification_mode_v1';

enum SessionCompletionNotificationMode { none, backgroundOnly, always }

extension SessionCompletionNotificationModeX
    on SessionCompletionNotificationMode {
  String label(AppLocalizations l10n) {
    switch (this) {
      case SessionCompletionNotificationMode.none:
        return l10n.sessionCompletionNotificationModeNone;
      case SessionCompletionNotificationMode.backgroundOnly:
        return l10n.sessionCompletionNotificationModeBackgroundOnly;
      case SessionCompletionNotificationMode.always:
        return l10n.sessionCompletionNotificationModeAlways;
    }
  }

  String get storageValue {
    switch (this) {
      case SessionCompletionNotificationMode.none:
        return 'none';
      case SessionCompletionNotificationMode.backgroundOnly:
        return 'backgroundOnly';
      case SessionCompletionNotificationMode.always:
        return 'always';
    }
  }

  static SessionCompletionNotificationMode fromStorageValue(String? value) {
    switch (value) {
      case 'none':
        return SessionCompletionNotificationMode.none;
      case 'always':
        return SessionCompletionNotificationMode.always;
      default:
        return SessionCompletionNotificationMode.backgroundOnly;
    }
  }
}

final sessionCompletionNotificationModeProvider =
    NotifierProvider<
      SessionCompletionNotificationModeNotifier,
      SessionCompletionNotificationMode
    >(SessionCompletionNotificationModeNotifier.new);

class SessionCompletionNotificationModeNotifier
    extends Notifier<SessionCompletionNotificationMode> {
  late final HydratedValueController<SessionCompletionNotificationMode>
  _hydration = HydratedValueController<SessionCompletionNotificationMode>(
    readState: () => state,
    writeState: (value) => state = value,
    load: () => readSessionCompletionNotificationModeFromStorage(
      () => ref.read(sharedPreferencesProvider.future),
    ),
    persist: _persist,
    isMounted: () => ref.mounted,
  );

  @override
  SessionCompletionNotificationMode build() {
    _hydration.startRestore();
    return SessionCompletionNotificationMode.backgroundOnly;
  }

  Future<void> setMode(SessionCompletionNotificationMode mode) async {
    if (state == mode && !_hydration.isHydrating) return;
    await _hydration.setValue(mode, waitForHydration: true);
  }

  Future<void> _persist(SessionCompletionNotificationMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _kSessionCompletionNotificationModeKey,
      mode.storageValue,
    );
  }
}

Future<SessionCompletionNotificationMode>
readSessionCompletionNotificationModeFromStorage(
  Future<SharedPreferences> Function() preferencesLoader,
) async {
  final prefs = await preferencesLoader();
  final value = prefs.getString(_kSessionCompletionNotificationModeKey);
  return SessionCompletionNotificationModeX.fromStorageValue(value);
}
