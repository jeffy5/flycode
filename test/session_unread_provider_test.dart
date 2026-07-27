import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/shared_preferences_provider.dart';
import 'package:flycode/providers/session_unread_provider.dart';

class _FakeCurrentDirectory extends CurrentDirectory {
  @override
  String? build() => '/tmp/worktree';
}

Future<void> _drainMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('idle/error update unread and markViewed clears it', () async {
    final container = ProviderContainer(
      overrides: [
        currentDirectoryProvider.overrideWith(() => _FakeCurrentDirectory()),
        sharedPreferencesProvider.overrideWith(
          (ref) => SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sessionUnreadProvider.notifier);
    await notifier.addTurnComplete('sess-1');
    await notifier.addError('sess-1');
    await notifier.addTurnComplete('sess-2');

    final state = container.read(sessionUnreadProvider);
    expect(state.unseenCount('sess-1'), 2);
    expect(state.unseenCount('sess-2'), 1);
    expect(state.hasError('sess-1'), isTrue);

    await notifier.markViewed('sess-1');
    final afterViewed = container.read(sessionUnreadProvider);
    expect(afterViewed.unseenCount('sess-1'), 0);
    expect(afterViewed.hasError('sess-1'), isFalse);
    expect(afterViewed.unseenCount('sess-2'), 1);
  });

  test(
    'state is persisted by directory and restored on next container',
    () async {
      final first = ProviderContainer(
        overrides: [
          currentDirectoryProvider.overrideWith(() => _FakeCurrentDirectory()),
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(first.dispose);

      await first
          .read(sessionUnreadProvider.notifier)
          .addTurnComplete('sess-a');
      await first.read(sessionUnreadProvider.notifier).addError('sess-b');

      final second = ProviderContainer(
        overrides: [
          currentDirectoryProvider.overrideWith(() => _FakeCurrentDirectory()),
          sharedPreferencesProvider.overrideWith(
            (ref) => SharedPreferences.getInstance(),
          ),
        ],
      );
      addTearDown(second.dispose);

      second.read(sessionUnreadProvider);
      await _drainMicrotasks();

      final restored = second.read(sessionUnreadProvider);
      expect(restored.unseenCount('sess-a'), 1);
      expect(restored.unseenCount('sess-b'), 1);
      expect(restored.hasError('sess-b'), isTrue);
    },
  );

  test('different directory uses isolated cache key', () {
    final keyA = sessionUnreadCacheKeyForDirectory('/tmp/worktree-a');
    final keyB = sessionUnreadCacheKeyForDirectory('/tmp/worktree-b');
    expect(keyA, isNot(keyB));
  });

  test(
    'late restore replays newer unread updates instead of overwriting them',
    () async {
      final directory = '/tmp/worktree';
      SharedPreferences.setMockInitialValues(<String, Object>{
        sessionUnreadCacheKeyForDirectory(directory): jsonEncode(
          <String, Object>{
            'unseen': <String, int>{'sess-a': 1},
            'errors': <String>[],
          },
        ),
      });

      final restoreGate = Completer<SharedPreferences>();

      final container = ProviderContainer(
        overrides: [
          currentDirectoryProvider.overrideWith(() => _FakeCurrentDirectory()),
          sharedPreferencesProvider.overrideWith((ref) => restoreGate.future),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(sessionUnreadProvider).unseenCount('sess-a'), 0);

      await container
          .read(sessionUnreadProvider.notifier)
          .addTurnComplete('sess-b');

      final interim = container.read(sessionUnreadProvider);
      expect(interim.unseenCount('sess-a'), 0);
      expect(interim.unseenCount('sess-b'), 1);

      restoreGate.complete(await SharedPreferences.getInstance());
      await _drainMicrotasks();

      final restored = container.read(sessionUnreadProvider);
      expect(restored.unseenCount('sess-a'), 1);
      expect(restored.unseenCount('sess-b'), 1);

      final prefs = await SharedPreferences.getInstance();
      final persisted =
          jsonDecode(
                prefs.getString(sessionUnreadCacheKeyForDirectory(directory))!,
              )
              as Map<String, dynamic>;
      expect(persisted['unseen'], <String, dynamic>{'sess-a': 1, 'sess-b': 1});
    },
  );

  test(
    'late restore does not reintroduce sessions that were viewed while hydrating',
    () async {
      final directory = '/tmp/worktree';
      SharedPreferences.setMockInitialValues(<String, Object>{
        sessionUnreadCacheKeyForDirectory(directory): jsonEncode(
          <String, Object>{
            'unseen': <String, int>{'sess-a': 2},
            'errors': <String>['sess-a'],
          },
        ),
      });

      final restoreGate = Completer<SharedPreferences>();

      final container = ProviderContainer(
        overrides: [
          currentDirectoryProvider.overrideWith(() => _FakeCurrentDirectory()),
          sharedPreferencesProvider.overrideWith((ref) => restoreGate.future),
        ],
      );
      addTearDown(container.dispose);

      container.read(sessionUnreadProvider);
      await container.read(sessionUnreadProvider.notifier).markViewed('sess-a');

      restoreGate.complete(await SharedPreferences.getInstance());
      await _drainMicrotasks();

      final restored = container.read(sessionUnreadProvider);
      expect(restored.unseenCount('sess-a'), 0);
      expect(restored.hasError('sess-a'), isFalse);
    },
  );
}
