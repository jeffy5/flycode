import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/app_lifecycle_provider.dart';
import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/providers/session_completion_notification_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/global_api.dart';
import 'package:flycode/service/api/models/global_event.dart';
import 'package:flycode/service/api/models/session.dart';
import 'package:flycode/service/api/session_api.dart';
import 'package:flycode/service/notification/local_notification_service.dart';

class _FakeGlobalApi extends GlobalApi {
  _FakeGlobalApi(this._controller)
    : super(ApiClient(baseUrl: 'http://localhost'));

  final StreamController<GlobalEvent> _controller;

  @override
  Stream<GlobalEvent> subscribeToGlobalEvents({
    void Function(GlobalEventConnectionState state)? onConnectionStateChanged,
  }) => _controller.stream;
}

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi({required this.sessionsById, this.throwOnGetSession = false})
    : super(ApiClient(baseUrl: 'http://localhost'));

  final Map<String, Session> sessionsById;
  final bool throwOnGetSession;
  final List<String> requestedSessionIds = <String>[];

  @override
  Future<Session> getSession(String id, {String? directory}) async {
    requestedSessionIds.add(id);
    if (throwOnGetSession) {
      throw Exception('getSession failed');
    }

    final session = sessionsById[id];
    if (session == null) {
      throw Exception('Session not found: $id');
    }
    return session;
  }

  @override
  Future<Map<String, dynamic>> getSessionStatus({String? directory}) async {
    return <String, dynamic>{};
  }
}

class _FakeLocalNotificationService extends LocalNotificationService {
  _FakeLocalNotificationService() : super(FlutterLocalNotificationsPlugin());

  final List<String?> shownSessionTitles = <String?>[];

  @override
  Future<void> showSessionCompleted({String? sessionTitle}) async {
    shownSessionTitles.add(sessionTitle);
  }
}

Session _session({required String id, String? parentID, String? title}) {
  return Session(
    id: id,
    slug: '$id-slug',
    projectID: 'project-1',
    directory: '/tmp/project',
    parentID: parentID,
    title: title,
    version: '1',
    time: SessionTime(created: 1, updated: 2),
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderContainer _createContainer({
  required _FakeGlobalApi globalApi,
  required _FakeSessionApi sessionApi,
  required _FakeLocalNotificationService notificationService,
}) {
  final container = ProviderContainer(
    overrides: [
      globalApiProvider.overrideWith((ref) async => globalApi),
      sessionApiProvider.overrideWith((ref) async => sessionApi),
      localNotificationServiceProvider.overrideWith((ref) {
        return notificationService;
      }),
    ],
  );

  container
      .read(sessionCompletionNotificationModeProvider.notifier)
      .setMode(SessionCompletionNotificationMode.always);
  container
      .read(appLifecycleStateProvider.notifier)
      .setState(AppLifecycleState.resumed);
  container.read(currentDirectoryProvider.notifier).set('/tmp/project');

  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'root session idle sends notification using session fetched from api',
    () async {
      final controller = StreamController<GlobalEvent>();
      final globalApi = _FakeGlobalApi(controller);
      final sessionApi = _FakeSessionApi(
        sessionsById: <String, Session>{
          'root-1': _session(id: 'root-1', title: 'Root session'),
        },
      );
      final notificationService = _FakeLocalNotificationService();
      final container = _createContainer(
        globalApi: globalApi,
        sessionApi: sessionApi,
        notificationService: notificationService,
      );

      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      final sub = container.listen<AsyncValue<GlobalEvent>>(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _flushAsyncWork();

      controller.add(
        GlobalEvent(
          directory: '/tmp/project',
          payload: EventSessionIdle(type: 'session.idle', sessionID: 'root-1'),
        ),
      );
      await _flushAsyncWork();

      expect(sessionApi.requestedSessionIds, ['root-1']);
      expect(notificationService.shownSessionTitles, ['Root session']);
    },
  );

  test('sub-session idle does not send notification', () async {
    final controller = StreamController<GlobalEvent>();
    final globalApi = _FakeGlobalApi(controller);
    final sessionApi = _FakeSessionApi(
      sessionsById: <String, Session>{
        'sub-1': _session(
          id: 'sub-1',
          parentID: 'root-1',
          title: 'Sub session',
        ),
      },
    );
    final notificationService = _FakeLocalNotificationService();
    final container = _createContainer(
      globalApi: globalApi,
      sessionApi: sessionApi,
      notificationService: notificationService,
    );

    addTearDown(() async {
      await controller.close();
      container.dispose();
    });

    final sub = container.listen<AsyncValue<GlobalEvent>>(
      globalEventListenerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _flushAsyncWork();

    controller.add(
      GlobalEvent(
        directory: '/tmp/project',
        payload: EventSessionIdle(type: 'session.idle', sessionID: 'sub-1'),
      ),
    );
    await _flushAsyncWork();

    expect(sessionApi.requestedSessionIds, ['sub-1']);
    expect(notificationService.shownSessionTitles, isEmpty);
  });

  test('root session without title still sends notification', () async {
    final controller = StreamController<GlobalEvent>();
    final globalApi = _FakeGlobalApi(controller);
    final sessionApi = _FakeSessionApi(
      sessionsById: <String, Session>{
        'root-2': _session(id: 'root-2', title: '   '),
      },
    );
    final notificationService = _FakeLocalNotificationService();
    final container = _createContainer(
      globalApi: globalApi,
      sessionApi: sessionApi,
      notificationService: notificationService,
    );

    addTearDown(() async {
      await controller.close();
      container.dispose();
    });

    final sub = container.listen<AsyncValue<GlobalEvent>>(
      globalEventListenerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _flushAsyncWork();

    controller.add(
      GlobalEvent(
        directory: '/tmp/project',
        payload: EventSessionIdle(type: 'session.idle', sessionID: 'root-2'),
      ),
    );
    await _flushAsyncWork();

    expect(sessionApi.requestedSessionIds, ['root-2']);
    expect(notificationService.shownSessionTitles, [null]);
  });

  test(
    'getSession failure skips notification without breaking listener',
    () async {
      final controller = StreamController<GlobalEvent>();
      final globalApi = _FakeGlobalApi(controller);
      final sessionApi = _FakeSessionApi(
        sessionsById: const <String, Session>{},
        throwOnGetSession: true,
      );
      final notificationService = _FakeLocalNotificationService();
      final container = _createContainer(
        globalApi: globalApi,
        sessionApi: sessionApi,
        notificationService: notificationService,
      );

      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      final sub = container.listen<AsyncValue<GlobalEvent>>(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _flushAsyncWork();

      controller.add(
        GlobalEvent(
          directory: '/tmp/project',
          payload: EventSessionIdle(type: 'session.idle', sessionID: 'root-3'),
        ),
      );
      await _flushAsyncWork();

      expect(sessionApi.requestedSessionIds, ['root-3']);
      expect(notificationService.shownSessionTitles, isEmpty);
      expect(container.read(globalEventListenerProvider).hasError, isFalse);
    },
  );
}
