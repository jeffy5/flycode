import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../service/api/models/global_event.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart';
import '../../service/api/models/session.dart';
import '../../service/api/session_api.dart';
import '../../service/notification/local_notification_service.dart';
import '../app_lifecycle_provider.dart';
import '../chat_view_state_provider.dart';
import '../current_directory_provider.dart';
import '../permission_provider.dart';
import '../question_provider.dart';
import '../session_completion_notification_provider.dart';
import '../session_provider.dart';
import '../session_status_provider.dart';
import '../session_unread_provider.dart';
import '../todo_provider.dart';
import 'notification_policy.dart';

part 'handlers.g.dart';

abstract interface class GlobalEventHandler {
  void handle(Object payload);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventSessionHandler(Ref ref) {
  return _SessionGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventMessageHandler(Ref ref) {
  return _MessageGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventQuestionHandler(Ref ref) {
  return _QuestionGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventPermissionHandler(Ref ref) {
  return _PermissionGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventTodoHandler(Ref ref) {
  return _TodoGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventStatusHandler(Ref ref) {
  return _StatusGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventUnreadHandler(Ref ref) {
  return _UnreadGlobalEventHandler(ref);
}

@Riverpod(keepAlive: true)
GlobalEventHandler globalEventNotificationHandler(Ref ref) {
  return _NotificationGlobalEventHandler(ref);
}

class _SessionGlobalEventHandler implements GlobalEventHandler {
  const _SessionGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is! EventSessionCreated &&
        payload is! EventSessionUpdated &&
        payload is! EventSessionDeleted) {
      return;
    }

    ref.invalidate(sessionsProvider);
    ref.invalidate(allSessionsProvider);

    if (payload is EventSessionDeleted) {
      unawaited(
        ref.read(sessionUnreadProvider.notifier).clearSession(payload.info.id),
      );
    }
  }
}

class _MessageGlobalEventHandler implements GlobalEventHandler {
  const _MessageGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is EventMessageUpdated) {
      _handleMessageUpdated(payload);
      return;
    }

    if (payload is EventMessageRemoved) {
      ref
          .read(sessionMessagesProvider(payload.sessionID).notifier)
          .removeMessage(payload.sessionID, payload.messageID);
      _dispatchToSubSession(
        payload.sessionID,
        (notifier) =>
            notifier.removeMessage(payload.sessionID, payload.messageID),
      );
      return;
    }

    if (payload is EventMessagePartUpdated) {
      final newPart = payload.part;
      final sessionID = partSessionId(newPart);
      final messageID = partMessageId(newPart);
      if (sessionID == null || messageID == null) return;

      ref
          .read(sessionMessagesProvider(sessionID).notifier)
          .updatePart(sessionID, messageID, newPart);
      _dispatchToSubSession(
        sessionID,
        (notifier) => notifier.updatePart(sessionID, messageID, newPart),
      );
      return;
    }

    if (payload is EventMessagePartRemoved) {
      ref
          .read(sessionMessagesProvider(payload.sessionID).notifier)
          .removePart(payload.sessionID, payload.messageID, payload.partID);
      _dispatchToSubSession(
        payload.sessionID,
        (notifier) => notifier.removePart(
          payload.sessionID,
          payload.messageID,
          payload.partID,
        ),
      );
      return;
    }

    if (payload is EventMessagePartDelta) {
      if (payload.field != 'text' || payload.delta.isEmpty) return;

      ref
          .read(sessionMessagesProvider(payload.sessionID).notifier)
          .appendPartDelta(
            payload.sessionID,
            payload.messageID,
            payload.partID,
            payload.field,
            payload.delta,
          );
      _dispatchToSubSession(
        payload.sessionID,
        (notifier) => notifier.appendPartDelta(
          payload.sessionID,
          payload.messageID,
          payload.partID,
          payload.field,
          payload.delta,
        ),
      );
    }
  }

  void _handleMessageUpdated(EventMessageUpdated event) {
    final info = event.info;
    final sessionID = switch (info) {
      UserMessage message => message.sessionID,
      AssistantMessage message => message.sessionID,
      _ => null,
    };
    if (sessionID == null) return;

    final message = MessageWithParts(info: info, parts: const []);
    ref
        .read(sessionMessagesProvider(sessionID).notifier)
        .updateMessage(sessionID, message);
    _dispatchToSubSession(
      sessionID,
      (notifier) => notifier.updateMessage(sessionID, message),
    );
  }

  void _dispatchToSubSession(
    String sessionID,
    void Function(SubSessionMessagesNotifier notifier) action,
  ) {
    try {
      final notifier = ref.read(subSessionMessagesProvider(sessionID).notifier);
      action(notifier);
    } catch (_) {
      // Ignore when the sub-session provider was never created.
    }
  }
}

class _QuestionGlobalEventHandler implements GlobalEventHandler {
  const _QuestionGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is EventQuestionAsked) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .addQuestion(payload.properties);
      return;
    }

    if (payload is EventQuestionReplied) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .removeQuestion(payload.requestID);
      return;
    }

    if (payload is EventQuestionRejected) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .removeQuestion(payload.requestID);
    }
  }
}

class _PermissionGlobalEventHandler implements GlobalEventHandler {
  const _PermissionGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is EventPermissionAsked) {
      ref
          .read(pendingPermissionsProvider.notifier)
          .addPermission(payload.request);
      return;
    }

    if (payload is EventPermissionReplied) {
      ref
          .read(pendingPermissionsProvider.notifier)
          .removePermission(payload.requestID);
    }
  }
}

class _TodoGlobalEventHandler implements GlobalEventHandler {
  const _TodoGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is! EventTodoUpdated) return;
    ref
        .read(sessionTodosProvider(payload.sessionID).notifier)
        .updateTodos(payload.todos);
  }
}

class _StatusGlobalEventHandler implements GlobalEventHandler {
  const _StatusGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is! EventSessionStatus) return;
    ref
        .read(sessionStatusProvider.notifier)
        .updateStatus(payload.sessionID, payload.status);
  }
}

class _UnreadGlobalEventHandler implements GlobalEventHandler {
  const _UnreadGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is EventSessionIdle) {
      _markSessionUnread(payload.sessionID, isError: false);
      return;
    }

    if (payload is EventSessionError) {
      final sessionID = payload.sessionID;
      if (sessionID == null || sessionID.isEmpty) return;
      _markSessionUnread(sessionID, isError: true);
    }
  }

  void _markSessionUnread(String sessionID, {required bool isError}) {
    if (sessionID.isEmpty) return;
    final activeSessionID = ref.read(chatViewStateProvider).sessionId;
    if (activeSessionID == sessionID) {
      unawaited(ref.read(sessionUnreadProvider.notifier).markViewed(sessionID));
      return;
    }

    if (isError) {
      unawaited(ref.read(sessionUnreadProvider.notifier).addError(sessionID));
      return;
    }

    unawaited(
      ref.read(sessionUnreadProvider.notifier).addTurnComplete(sessionID),
    );
  }
}

class _NotificationGlobalEventHandler implements GlobalEventHandler {
  const _NotificationGlobalEventHandler(this.ref);

  final Ref ref;

  @override
  void handle(Object payload) {
    if (payload is! EventSessionIdle) return;
    unawaited(_notifySessionCompleted(payload.sessionID));
  }

  Future<void> _notifySessionCompleted(String sessionID) async {
    if (sessionID.isEmpty) return;

    final mode = ref.read(sessionCompletionNotificationModeProvider);
    final lifecycleState = ref.read(appLifecycleStateProvider);
    final shouldSend = shouldSendSessionCompletionNotification(
      mode: mode,
      lifecycleState: lifecycleState,
    );
    if (!shouldSend) return;

    final session = await _sessionForNotification(sessionID);
    if (session == null || _isSubSession(session)) return;

    try {
      await ref
          .read(localNotificationServiceProvider)
          .showSessionCompleted(
            sessionTitle: _normalizedSessionTitle(session.title),
          );
    } catch (_) {
      // Ignore local notification failures to avoid affecting SSE handling.
    }
  }

  Future<Session?> _sessionForNotification(String sessionID) async {
    try {
      final api = await ref.read(sessionApiProvider.future);
      if (!ref.mounted) return null;
      final directory = ref.read(currentDirectoryProvider);
      if (!ref.mounted) return null;
      return await api.getSession(sessionID, directory: directory);
    } catch (_) {
      return null;
    }
  }

  bool _isSubSession(Session session) {
    final parentID = session.parentID;
    return parentID != null && parentID.isNotEmpty;
  }

  String? _normalizedSessionTitle(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
