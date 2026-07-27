import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/providers/hydrated_state.dart';

void main() {
  test('value controller keeps pending write over late restore', () async {
    var state = 'default';
    final restoreGate = Completer<String>();
    final persisted = <String>[];

    final controller = HydratedValueController<String>(
      readState: () => state,
      writeState: (value) => state = value,
      load: () => restoreGate.future,
      persist: (value) async {
        persisted.add(value);
      },
      isMounted: () => true,
    );

    controller.startRestore();
    await controller.setValue('next');
    expect(state, 'next');

    restoreGate.complete('restored');
    await controller.whenHydrated;

    expect(state, 'next');
    expect(persisted, <String>['next']);
  });

  test('value controller ignores stale restore generations', () async {
    var state = 'default';
    final firstGate = Completer<String>();
    final secondGate = Completer<String>();
    var loadCount = 0;

    final controller = HydratedValueController<String>(
      readState: () => state,
      writeState: (value) => state = value,
      load: () {
        loadCount += 1;
        return loadCount == 1 ? firstGate.future : secondGate.future;
      },
      persist: (_) async {},
      isMounted: () => true,
    );

    controller.startRestore();
    controller.startRestore();

    firstGate.complete('stale');
    await Future<void>.delayed(Duration.zero);
    expect(state, 'default');

    secondGate.complete('fresh');
    await controller.whenHydrated;
    expect(state, 'fresh');
  });

  test('mutation controller replays queued mutations after restore', () async {
    var state = 0;
    final restoreGate = Completer<int>();
    final persisted = <int>[];

    final controller = HydratedMutationController<int, int>(
      readState: () => state,
      writeState: (value) => state = value,
      load: () => restoreGate.future,
      persist: (value) async {
        persisted.add(value);
      },
      applyMutation: (current, mutation) => current + mutation,
      isMounted: () => true,
    );

    controller.startRestore();
    await controller.apply(2);
    await controller.apply(3);
    expect(state, 5);

    restoreGate.complete(10);
    await controller.whenHydrated;

    expect(state, 15);
    expect(persisted, <int>[15]);
  });
}
