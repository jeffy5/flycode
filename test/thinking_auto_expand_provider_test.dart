import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/thinking_auto_expand_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'thinkingAutoExpandProvider defaults to false on fresh install',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(thinkingAutoExpandProvider), isFalse);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(thinkingAutoExpandProvider), isFalse);
    },
  );

  test('setAutoExpand updates state and persists to storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(thinkingAutoExpandProvider.notifier)
        .setAutoExpand(true);
    expect(container.read(thinkingAutoExpandProvider), isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('thinking_auto_expand_v1'), isTrue);

    await container
        .read(thinkingAutoExpandProvider.notifier)
        .setAutoExpand(false);
    expect(container.read(thinkingAutoExpandProvider), isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'thinking_auto_expand_v1',
      ),
      isFalse,
    );
  });

  test(
    'thinkingAutoExpandProvider restores persisted value asynchronously',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'thinking_auto_expand_v1': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(thinkingAutoExpandProvider), isFalse);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(thinkingAutoExpandProvider), isTrue);
    },
  );
}
