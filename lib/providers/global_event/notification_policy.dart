import 'package:flutter/widgets.dart';

import '../app_lifecycle_provider.dart';
import '../session_completion_notification_provider.dart';

bool shouldSendSessionCompletionNotification({
  required SessionCompletionNotificationMode mode,
  required AppLifecycleState lifecycleState,
}) {
  switch (mode) {
    case SessionCompletionNotificationMode.none:
      return false;
    case SessionCompletionNotificationMode.backgroundOnly:
      return !isAppInForeground(lifecycleState);
    case SessionCompletionNotificationMode.always:
      return true;
  }
}
