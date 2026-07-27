import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_view_state_provider.dart';
import 'session_status_provider.dart';
import 'session_unread_provider.dart';
import 'session_completion_notification_provider.dart';
import '../service/api/global_api.dart';
import '../service/api/models/global_event.dart';
import 'global_event/connection.dart';
import 'global_event/dispatcher.dart';
import 'global_event/notification_policy.dart' as global_event;

export 'global_event/connection.dart' show globalEventConnectionProvider;

part 'global_event_provider.g.dart';

bool shouldSendSessionCompletionNotification({
  required SessionCompletionNotificationMode mode,
  required AppLifecycleState lifecycleState,
}) {
  return global_event.shouldSendSessionCompletionNotification(
    mode: mode,
    lifecycleState: lifecycleState,
  );
}

@riverpod
class GlobalEventListener extends _$GlobalEventListener {
  @override
  Stream<GlobalEvent> build() async* {
    final api = await ref.watch(globalApiProvider.future);
    final connectionNotifier = ref.read(globalEventConnectionProvider.notifier);
    final dispatcher = ref.read(globalEventDispatcherProvider);
    var latestConnectionState = connectionNotifier.state;
    var isActive = true;
    _bootstrapGlobalEventSideEffects();
    ref.onDispose(() {
      isActive = false;
    });

    // 用 listenSelf 监听自身 stream state 来处理副作用，避免直接 stream.listen() 导致双重订阅
    listenSelf((_, next) {
      next.whenData(dispatcher.dispatch);
    });

    yield* api.subscribeToGlobalEvents(
      onConnectionStateChanged: (nextState) {
        final previousState = latestConnectionState;
        latestConnectionState = nextState;

        Future<void>(() async {
          if (!isActive) return;

          connectionNotifier.setState(nextState);
          final recovered =
              nextState.phase == GlobalEventConnectionPhase.connected &&
              previousState.phase == GlobalEventConnectionPhase.reconnecting;
          if (recovered && ref.mounted) {
            await ref.read(sessionStatusProvider.notifier).refreshFromServer();
          }
        });
      },
    );
  }

  void _bootstrapGlobalEventSideEffects() {
    ref.read(sessionUnreadProvider);

    ref.listen<ChatViewState>(chatViewStateProvider, (previous, next) {
      final nextSessionID = next.sessionId;
      if (nextSessionID == null || nextSessionID == previous?.sessionId) {
        return;
      }
      unawaited(
        ref.read(sessionUnreadProvider.notifier).markViewed(nextSessionID),
      );
    });

    unawaited(ref.read(sessionStatusProvider.notifier).refreshFromServer());
  }
}
