import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/providers/session_completion_notification_provider.dart';

void main() {
  test('none mode never sends notifications', () {
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.none,
        lifecycleState: AppLifecycleState.resumed,
      ),
      isFalse,
    );
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.none,
        lifecycleState: AppLifecycleState.paused,
      ),
      isFalse,
    );
  });

  test('background-only mode sends only when app is not foreground', () {
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.backgroundOnly,
        lifecycleState: AppLifecycleState.resumed,
      ),
      isFalse,
    );
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.backgroundOnly,
        lifecycleState: AppLifecycleState.paused,
      ),
      isTrue,
    );
  });

  test('always mode always sends notifications', () {
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.always,
        lifecycleState: AppLifecycleState.resumed,
      ),
      isTrue,
    );
    expect(
      shouldSendSessionCompletionNotification(
        mode: SessionCompletionNotificationMode.always,
        lifecycleState: AppLifecycleState.paused,
      ),
      isTrue,
    );
  });
}
