import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/session_completion_notification_provider.dart';
import 'package:flycode/providers/shared_preferences_provider.dart';

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('defaults to background-only mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionCompletionNotificationModeProvider);
    await _flushAsyncWork();

    expect(
      container.read(sessionCompletionNotificationModeProvider),
      SessionCompletionNotificationMode.backgroundOnly,
    );
  });

  test('restores persisted mode from shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'session_completion_notification_mode_v1': 'always',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionCompletionNotificationModeProvider);
    await _flushAsyncWork();

    expect(
      container.read(sessionCompletionNotificationModeProvider),
      SessionCompletionNotificationMode.always,
    );
  });

  test('setMode persists selected value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(sessionCompletionNotificationModeProvider.notifier)
        .setMode(SessionCompletionNotificationMode.none);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('session_completion_notification_mode_v1'), 'none');
  });

  test(
    'late restore does not override a newer notification selection',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'session_completion_notification_mode_v1': 'always',
      });

      final restoreGate = Completer<SharedPreferences>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => restoreGate.future),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(sessionCompletionNotificationModeProvider),
        SessionCompletionNotificationMode.backgroundOnly,
      );

      final future = container
          .read(sessionCompletionNotificationModeProvider.notifier)
          .setMode(SessionCompletionNotificationMode.none);

      restoreGate.complete(await SharedPreferences.getInstance());
      await future;
      await _flushAsyncWork();

      expect(
        container.read(sessionCompletionNotificationModeProvider),
        SessionCompletionNotificationMode.none,
      );
    },
  );

  test('setMode waits for restore before returning', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'session_completion_notification_mode_v1': 'always',
    });

    final restoreGate = Completer<SharedPreferences>();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => restoreGate.future),
      ],
    );
    addTearDown(container.dispose);

    container.read(sessionCompletionNotificationModeProvider);
    final future = container
        .read(sessionCompletionNotificationModeProvider.notifier)
        .setMode(SessionCompletionNotificationMode.none);

    var completed = false;
    future.then((_) {
      completed = true;
    });

    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    restoreGate.complete(await SharedPreferences.getInstance());
    await future;

    expect(completed, isTrue);
  });
}
