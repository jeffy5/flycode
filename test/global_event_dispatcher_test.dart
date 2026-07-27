import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/global_event/dispatcher.dart';
import 'package:flycode/providers/global_event/handlers.dart';
import 'package:flycode/providers/global_event/router.dart';
import 'package:flycode/service/api/models/global_event.dart';
import 'package:flycode/service/api/models/permission.dart';
import 'package:flycode/service/api/models/question.dart';
import 'package:flycode/service/api/models/session.dart';
import 'package:flycode/service/api/models/session_status.dart';

class _RecordingHandler implements GlobalEventHandler {
  final List<Object> payloads = <Object>[];

  @override
  void handle(Object payload) {
    payloads.add(payload);
  }
}

QuestionRequest _questionRequest() {
  return QuestionRequest(
    id: 'question-1',
    sessionID: 'session-1',
    questions: <QuestionInfo>[
      QuestionInfo(
        question: 'Continue?',
        header: 'Confirm',
        options: <QuestionOption>[
          QuestionOption(label: 'Yes', description: 'Continue the task'),
        ],
      ),
    ],
  );
}

PermissionRequest _permissionRequest() {
  return PermissionRequest(
    id: 'permission-1',
    sessionID: 'session-1',
    permission: 'bash',
    patterns: const <String>['npm test'],
    always: const <String>[],
  );
}

Session _session(String id) {
  return Session(
    id: id,
    slug: '$id-slug',
    projectID: 'project-1',
    directory: '/tmp/project',
    version: '1',
    time: SessionTime(created: 1, updated: 2),
  );
}

ProviderContainer _createContainer({
  required _RecordingHandler sessionHandler,
  required _RecordingHandler messageHandler,
  required _RecordingHandler questionHandler,
  required _RecordingHandler permissionHandler,
  required _RecordingHandler todoHandler,
  required _RecordingHandler unreadHandler,
  required _RecordingHandler notificationHandler,
  required _RecordingHandler statusHandler,
}) {
  return ProviderContainer(
    overrides: [
      globalEventSessionHandlerProvider.overrideWithValue(sessionHandler),
      globalEventMessageHandlerProvider.overrideWithValue(messageHandler),
      globalEventQuestionHandlerProvider.overrideWithValue(questionHandler),
      globalEventPermissionHandlerProvider.overrideWithValue(permissionHandler),
      globalEventTodoHandlerProvider.overrideWithValue(todoHandler),
      globalEventUnreadHandlerProvider.overrideWithValue(unreadHandler),
      globalEventNotificationHandlerProvider.overrideWithValue(
        notificationHandler,
      ),
      globalEventStatusHandlerProvider.overrideWithValue(statusHandler),
    ],
  );
}

void main() {
  test('routeGlobalEventPayload maps payloads to expected targets', () {
    expect(
      routeGlobalEventPayload(
        EventSessionDeleted(
          type: 'session.deleted',
          info: _session('session-1'),
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.session],
    );
    expect(
      routeGlobalEventPayload(
        EventMessageRemoved(
          type: 'message.removed',
          sessionID: 'session-1',
          messageID: 'message-1',
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.message],
    );
    expect(
      routeGlobalEventPayload(
        EventQuestionAsked(
          type: 'question.asked',
          properties: _questionRequest(),
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.question],
    );
    expect(
      routeGlobalEventPayload(
        EventPermissionAsked(
          type: 'permission.asked',
          request: _permissionRequest(),
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.permission],
    );
    expect(
      routeGlobalEventPayload(
        EventTodoUpdated(
          type: 'todo.updated',
          sessionID: 'session-1',
          todos: const <Todo>[],
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.todo],
    );
    expect(
      routeGlobalEventPayload(
        EventSessionStatus(
          type: 'session.status',
          sessionID: 'session-1',
          status: const SessionStatusBusy(),
        ),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.status],
    );
    expect(
      routeGlobalEventPayload(
        EventSessionIdle(type: 'session.idle', sessionID: 'session-1'),
      ),
      <GlobalEventRouteTarget>[
        GlobalEventRouteTarget.unread,
        GlobalEventRouteTarget.notification,
      ],
    );
    expect(
      routeGlobalEventPayload(
        EventSessionError(type: 'session.error', sessionID: 'session-1'),
      ),
      <GlobalEventRouteTarget>[GlobalEventRouteTarget.unread],
    );
    expect(
      routeGlobalEventPayload(const EventUnknown('future.event')),
      isEmpty,
    );
  });

  test('scopeForGlobalEventPayload maps known payloads to expected scopes', () {
    expect(
      scopeForGlobalEventPayload(
        EventSessionUpdated(
          type: 'session.updated',
          info: _session('session-1'),
        ),
      ),
      GlobalEventScope.project,
    );
    expect(
      scopeForGlobalEventPayload(
        EventQuestionRejected(
          type: 'question.rejected',
          sessionID: 'session-1',
          requestID: 'question-1',
        ),
      ),
      GlobalEventScope.project,
    );
    expect(
      scopeForGlobalEventPayload(const EventUnknown('future.event')),
      GlobalEventScope.global,
    );
  });

  test('dispatcher filters by directory before invoking handlers', () {
    final sessionHandler = _RecordingHandler();
    final messageHandler = _RecordingHandler();
    final questionHandler = _RecordingHandler();
    final permissionHandler = _RecordingHandler();
    final todoHandler = _RecordingHandler();
    final unreadHandler = _RecordingHandler();
    final notificationHandler = _RecordingHandler();
    final statusHandler = _RecordingHandler();
    final container = _createContainer(
      sessionHandler: sessionHandler,
      messageHandler: messageHandler,
      questionHandler: questionHandler,
      permissionHandler: permissionHandler,
      todoHandler: todoHandler,
      unreadHandler: unreadHandler,
      notificationHandler: notificationHandler,
      statusHandler: statusHandler,
    );
    addTearDown(container.dispose);

    container.read(currentDirectoryProvider.notifier).set('/tmp/project');

    container
        .read(globalEventDispatcherProvider)
        .dispatch(
          GlobalEvent(
            directory: '/other/project',
            payload: EventSessionStatus(
              type: 'session.status',
              sessionID: 'session-1',
              status: const SessionStatusBusy(),
            ),
          ),
        );

    expect(statusHandler.payloads, isEmpty);
  });

  test(
    'dispatcher drops project-scoped events when current directory is null',
    () {
      final sessionHandler = _RecordingHandler();
      final messageHandler = _RecordingHandler();
      final questionHandler = _RecordingHandler();
      final permissionHandler = _RecordingHandler();
      final todoHandler = _RecordingHandler();
      final unreadHandler = _RecordingHandler();
      final notificationHandler = _RecordingHandler();
      final statusHandler = _RecordingHandler();
      final container = _createContainer(
        sessionHandler: sessionHandler,
        messageHandler: messageHandler,
        questionHandler: questionHandler,
        permissionHandler: permissionHandler,
        todoHandler: todoHandler,
        unreadHandler: unreadHandler,
        notificationHandler: notificationHandler,
        statusHandler: statusHandler,
      );
      addTearDown(container.dispose);

      container
          .read(globalEventDispatcherProvider)
          .dispatch(
            GlobalEvent(
              directory: '/tmp/project',
              payload: EventSessionIdle(
                type: 'session.idle',
                sessionID: 'session-1',
              ),
            ),
          );

      expect(unreadHandler.payloads, isEmpty);
      expect(notificationHandler.payloads, isEmpty);
      expect(sessionHandler.payloads, isEmpty);
      expect(messageHandler.payloads, isEmpty);
      expect(questionHandler.payloads, isEmpty);
      expect(permissionHandler.payloads, isEmpty);
      expect(todoHandler.payloads, isEmpty);
      expect(statusHandler.payloads, isEmpty);
    },
  );

  test(
    'dispatcher allows global-scoped events without a current directory',
    () {
      final sessionHandler = _RecordingHandler();
      final messageHandler = _RecordingHandler();
      final questionHandler = _RecordingHandler();
      final permissionHandler = _RecordingHandler();
      final todoHandler = _RecordingHandler();
      final unreadHandler = _RecordingHandler();
      final notificationHandler = _RecordingHandler();
      final statusHandler = _RecordingHandler();
      final container = _createContainer(
        sessionHandler: sessionHandler,
        messageHandler: messageHandler,
        questionHandler: questionHandler,
        permissionHandler: permissionHandler,
        todoHandler: todoHandler,
        unreadHandler: unreadHandler,
        notificationHandler: notificationHandler,
        statusHandler: statusHandler,
      );
      addTearDown(container.dispose);

      container
          .read(globalEventDispatcherProvider)
          .dispatch(
            GlobalEvent(
              directory: '',
              payload: const EventUnknown('future.event'),
            ),
          );

      expect(sessionHandler.payloads, isEmpty);
      expect(messageHandler.payloads, isEmpty);
      expect(questionHandler.payloads, isEmpty);
      expect(permissionHandler.payloads, isEmpty);
      expect(todoHandler.payloads, isEmpty);
      expect(unreadHandler.payloads, isEmpty);
      expect(notificationHandler.payloads, isEmpty);
      expect(statusHandler.payloads, isEmpty);
    },
  );

  test('dispatcher fans out multi-target payloads to both handlers', () {
    final sessionHandler = _RecordingHandler();
    final messageHandler = _RecordingHandler();
    final questionHandler = _RecordingHandler();
    final permissionHandler = _RecordingHandler();
    final todoHandler = _RecordingHandler();
    final unreadHandler = _RecordingHandler();
    final notificationHandler = _RecordingHandler();
    final statusHandler = _RecordingHandler();
    final container = _createContainer(
      sessionHandler: sessionHandler,
      messageHandler: messageHandler,
      questionHandler: questionHandler,
      permissionHandler: permissionHandler,
      todoHandler: todoHandler,
      unreadHandler: unreadHandler,
      notificationHandler: notificationHandler,
      statusHandler: statusHandler,
    );
    addTearDown(container.dispose);

    container.read(currentDirectoryProvider.notifier).set('/tmp/project');

    final payload = EventSessionIdle(
      type: 'session.idle',
      sessionID: 'session-1',
    );

    container
        .read(globalEventDispatcherProvider)
        .dispatch(GlobalEvent(directory: '/tmp/project', payload: payload));

    expect(unreadHandler.payloads, <Object>[payload]);
    expect(notificationHandler.payloads, <Object>[payload]);
    expect(sessionHandler.payloads, isEmpty);
    expect(messageHandler.payloads, isEmpty);
    expect(questionHandler.payloads, isEmpty);
    expect(permissionHandler.payloads, isEmpty);
    expect(todoHandler.payloads, isEmpty);
    expect(statusHandler.payloads, isEmpty);
  });
}
