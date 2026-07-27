import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/providers/session_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/global_api.dart';
import 'package:flycode/service/api/models/global_event.dart';
import 'package:flycode/service/api/models/message.dart' as msg;
import 'package:flycode/service/api/models/parts.dart'
    show PartTime, ReasoningPart, TextPart;
import 'package:flycode/service/api/session_api.dart';

const _kSessionId = 'sub-1';
const _kMessageId = 'msg-1';
const _kDirectory = '/tmp/project';

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi(this._messagesBySession)
    : super(ApiClient(baseUrl: 'http://localhost'));

  final Map<String, List<msg.MessageWithParts>> _messagesBySession;

  @override
  Future<List<msg.MessageWithParts>> getSessionMessages(
    String id, {
    String? directory,
    int? limit,
  }) async => _messagesBySession[id] ?? const <msg.MessageWithParts>[];
}

class _FakeGlobalApi extends GlobalApi {
  _FakeGlobalApi(this._controller)
    : super(ApiClient(baseUrl: 'http://localhost'));

  final StreamController<GlobalEvent> _controller;

  @override
  Stream<GlobalEvent> subscribeToGlobalEvents({
    void Function(GlobalEventConnectionState state)? onConnectionStateChanged,
  }) => _controller.stream;
}

msg.MessageWithParts _messageWithText({
  required String sessionID,
  required String messageID,
  required String text,
  String providerID = 'openai',
  String modelID = 'gpt-5.4',
}) {
  return msg.MessageWithParts(
    info: msg.AssistantMessage(
      id: messageID,
      sessionID: sessionID,
      role: 'assistant',
      time: msg.MessageTime(created: 1),
      parentID: 'parent-1',
      modelID: modelID,
      providerID: providerID,
      mode: 'chat',
      path: msg.MessagePath(cwd: '/tmp/project', root: '/tmp/project'),
      tokens: msg.MessageTokens(),
    ),
    parts: <Object>[
      TextPart(
        id: 'part-$messageID',
        sessionID: sessionID,
        messageID: messageID,
        type: 'text',
        text: text,
      ),
    ],
  );
}

msg.MessageWithParts _messageInfoOnly({
  required String sessionID,
  required String messageID,
  String providerID = 'openai',
  String modelID = 'gpt-5.4-updated',
}) {
  return msg.MessageWithParts(
    info: msg.AssistantMessage(
      id: messageID,
      sessionID: sessionID,
      role: 'assistant',
      time: msg.MessageTime(created: 2),
      parentID: 'parent-1',
      modelID: modelID,
      providerID: providerID,
      mode: 'chat',
      path: msg.MessagePath(cwd: '/tmp/project', root: '/tmp/project'),
      tokens: msg.MessageTokens(output: 42),
    ),
    parts: const <Object>[],
  );
}

ReasoningPart _reasoningPart({
  required String sessionID,
  required String messageID,
  required String partID,
  required String text,
}) {
  return ReasoningPart(
    id: partID,
    sessionID: sessionID,
    messageID: messageID,
    type: 'reasoning',
    text: text,
    time: PartTime(start: 1, end: 2),
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'session notifier keeps existing parts when update has info only',
    () async {
      final initial = _messageWithText(
        sessionID: _kSessionId,
        messageID: _kMessageId,
        text: 'original text',
      );
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container.read(sessionMessagesProvider(_kSessionId).future);

      container
          .read(sessionMessagesProvider(_kSessionId).notifier)
          .updateMessage(
            _kSessionId,
            _messageInfoOnly(sessionID: _kSessionId, messageID: _kMessageId),
          );

      final updated = container
          .read(sessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as TextPart).text, 'original text');
      expect((updated.info as msg.AssistantMessage).modelID, 'gpt-5.4-updated');
    },
  );

  test(
    'sub-session notifier keeps existing parts when update has info only',
    () async {
      final initial = _messageWithText(
        sessionID: _kSessionId,
        messageID: _kMessageId,
        text: 'sub-session text',
      );
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container.read(subSessionMessagesProvider(_kSessionId).future);

      container
          .read(subSessionMessagesProvider(_kSessionId).notifier)
          .updateMessage(
            _kSessionId,
            _messageInfoOnly(sessionID: _kSessionId, messageID: _kMessageId),
          );

      final updated = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as TextPart).text, 'sub-session text');
      expect((updated.info as msg.AssistantMessage).modelID, 'gpt-5.4-updated');
    },
  );

  test(
    'notifier still inserts new empty-shell message for first message.updated',
    () async {
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: const <msg.MessageWithParts>[],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container.read(subSessionMessagesProvider(_kSessionId).future);

      container
          .read(subSessionMessagesProvider(_kSessionId).notifier)
          .updateMessage(
            _kSessionId,
            _messageInfoOnly(sessionID: _kSessionId, messageID: _kMessageId),
          );

      final inserted = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(inserted.parts, isEmpty);
      expect((inserted.info as msg.AssistantMessage).id, _kMessageId);
    },
  );

  test(
    'global message.updated preserves sub-session parts even without main-session cache',
    () async {
      final initial = _messageWithText(
        sessionID: _kSessionId,
        messageID: _kMessageId,
        text: 'keep me',
      );
      final sessionApi = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final controller = StreamController<GlobalEvent>();
      final globalApi = _FakeGlobalApi(controller);
      final container = ProviderContainer(
        overrides: [
          sessionApiProvider.overrideWith((ref) async => sessionApi),
          globalApiProvider.overrideWith((ref) async => globalApi),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      await container.read(subSessionMessagesProvider(_kSessionId).future);
      final subSessionState = container
          .listen<AsyncValue<List<msg.MessageWithParts>>>(
            subSessionMessagesProvider(_kSessionId),
            (previous, next) {},
            fireImmediately: true,
          );
      addTearDown(subSessionState.close);
      final sub = container.listen<AsyncValue<GlobalEvent>>(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _flushAsyncWork();

      controller.add(
        GlobalEvent(
          directory: '',
          payload: EventMessageUpdated(
            type: 'message.updated',
            info: _messageInfoOnly(
              sessionID: _kSessionId,
              messageID: _kMessageId,
            ).info,
          ),
        ),
      );
      await _flushAsyncWork();

      final subSessionMessage = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect((subSessionMessage.parts.single as TextPart).text, 'keep me');
    },
  );

  test(
    'global message.part.updated updates main-session reasoning part',
    () async {
      final initial = msg.MessageWithParts(
        info: _messageWithText(
          sessionID: _kSessionId,
          messageID: _kMessageId,
          text: 'placeholder',
        ).info,
        parts: <Object>[
          _reasoningPart(
            sessionID: _kSessionId,
            messageID: _kMessageId,
            partID: 'part-reasoning',
            text: 'before',
          ),
        ],
      );
      final sessionApi = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final controller = StreamController<GlobalEvent>();
      final globalApi = _FakeGlobalApi(controller);
      final container = ProviderContainer(
        overrides: [
          sessionApiProvider.overrideWith((ref) async => sessionApi),
          globalApiProvider.overrideWith((ref) async => globalApi),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      await container.read(sessionMessagesProvider(_kSessionId).future);
      container.read(currentDirectoryProvider.notifier).set(_kDirectory);
      final sessionState = container
          .listen<AsyncValue<List<msg.MessageWithParts>>>(
            sessionMessagesProvider(_kSessionId),
            (previous, next) {},
            fireImmediately: true,
          );
      addTearDown(sessionState.close);
      final sub = container.listen<AsyncValue<GlobalEvent>>(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _flushAsyncWork();

      controller.add(
        GlobalEvent(
          directory: _kDirectory,
          payload: EventMessagePartUpdated(
            type: 'message.part.updated',
            part: _reasoningPart(
              sessionID: _kSessionId,
              messageID: _kMessageId,
              partID: 'part-reasoning',
              text: 'after',
            ),
          ),
        ),
      );
      await _flushAsyncWork();

      final updated = container
          .read(sessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as ReasoningPart).text, 'after');
    },
  );

  test(
    'global message.part.updated updates sub-session reasoning part without main-session cache',
    () async {
      final initial = msg.MessageWithParts(
        info: _messageWithText(
          sessionID: _kSessionId,
          messageID: _kMessageId,
          text: 'placeholder',
        ).info,
        parts: <Object>[
          _reasoningPart(
            sessionID: _kSessionId,
            messageID: _kMessageId,
            partID: 'part-reasoning',
            text: 'before',
          ),
        ],
      );
      final sessionApi = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final controller = StreamController<GlobalEvent>();
      final globalApi = _FakeGlobalApi(controller);
      final container = ProviderContainer(
        overrides: [
          sessionApiProvider.overrideWith((ref) async => sessionApi),
          globalApiProvider.overrideWith((ref) async => globalApi),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      await container.read(subSessionMessagesProvider(_kSessionId).future);
      container.read(currentDirectoryProvider.notifier).set(_kDirectory);
      final subSessionState = container
          .listen<AsyncValue<List<msg.MessageWithParts>>>(
            subSessionMessagesProvider(_kSessionId),
            (previous, next) {},
            fireImmediately: true,
          );
      addTearDown(subSessionState.close);
      final sub = container.listen<AsyncValue<GlobalEvent>>(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await _flushAsyncWork();

      controller.add(
        GlobalEvent(
          directory: _kDirectory,
          payload: EventMessagePartUpdated(
            type: 'message.part.updated',
            part: _reasoningPart(
              sessionID: _kSessionId,
              messageID: _kMessageId,
              partID: 'part-reasoning',
              text: 'after',
            ),
          ),
        ),
      );
      await _flushAsyncWork();

      final updated = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as ReasoningPart).text, 'after');
    },
  );

  test(
    'sub-session updatePart replaces existing reasoning part by id',
    () async {
      final initial = msg.MessageWithParts(
        info: _messageWithText(
          sessionID: _kSessionId,
          messageID: _kMessageId,
          text: 'placeholder',
        ).info,
        parts: <Object>[
          _reasoningPart(
            sessionID: _kSessionId,
            messageID: _kMessageId,
            partID: 'part-reasoning',
            text: 'before',
          ),
        ],
      );
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container.read(subSessionMessagesProvider(_kSessionId).future);

      container
          .read(subSessionMessagesProvider(_kSessionId).notifier)
          .updatePart(
            _kSessionId,
            _kMessageId,
            _reasoningPart(
              sessionID: _kSessionId,
              messageID: _kMessageId,
              partID: 'part-reasoning',
              text: 'after',
            ),
          );

      final updated = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as ReasoningPart).text, 'after');
    },
  );

  test(
    'sub-session build normalizes duplicate part ids from initial payload',
    () async {
      final initial = msg.MessageWithParts(
        info: _messageWithText(
          sessionID: _kSessionId,
          messageID: _kMessageId,
          text: 'placeholder',
        ).info,
        parts: <Object>[
          _reasoningPart(
            sessionID: _kSessionId,
            messageID: _kMessageId,
            partID: 'part-reasoning',
            text: 'before',
          ),
          _reasoningPart(
            sessionID: _kSessionId,
            messageID: _kMessageId,
            partID: 'part-reasoning',
            text: 'after',
          ),
        ],
      );
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      final message = (await container.read(
        subSessionMessagesProvider(_kSessionId).future,
      )).single;

      expect(message.parts, hasLength(1));
      expect((message.parts.single as ReasoningPart).text, 'after');
    },
  );

  test(
    'appendPartDelta updates existing text part instead of appending duplicate',
    () async {
      final initial = _messageWithText(
        sessionID: _kSessionId,
        messageID: _kMessageId,
        text: 'hello',
      );
      final api = _FakeSessionApi(<String, List<msg.MessageWithParts>>{
        _kSessionId: <msg.MessageWithParts>[initial],
      });
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container.read(subSessionMessagesProvider(_kSessionId).future);

      container
          .read(subSessionMessagesProvider(_kSessionId).notifier)
          .appendPartDelta(
            _kSessionId,
            _kMessageId,
            'part-$_kMessageId',
            'text',
            ' world',
          );

      final updated = container
          .read(subSessionMessagesProvider(_kSessionId))
          .requireValue
          .single;
      expect(updated.parts, hasLength(1));
      expect((updated.parts.single as TextPart).text, 'hello world');
    },
  );
}
