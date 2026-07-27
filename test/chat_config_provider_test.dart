import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/chat_config_provider.dart';
import 'package:flycode/providers/chat_view_state_provider.dart';
import 'package:flycode/providers/session_provider.dart';
import 'package:flycode/service/api/models/message.dart';

const _kCacheKey = 'chat_config_last_used_model';
const _kFallbackProvider = 'opencode';
const _kFallbackModel = 'minimax-m2.5-free';

List<MessageWithParts> _fakeSessionMessages = <MessageWithParts>[];

class _FakeSessionMessagesNotifier extends SessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build(String sessionID) async =>
      _fakeSessionMessages;
}

MessageWithParts _userMessage({
  required String agent,
  required String providerID,
  required String modelID,
}) {
  return MessageWithParts(
    info: UserMessage(
      id: 'msg-1',
      sessionID: 'sess-1',
      role: 'user',
      time: MessageTime(created: 1),
      agent: agent,
      model: MessageModel(providerID: providerID, modelID: modelID),
    ),
    parts: const <Object>[],
  );
}

MessageWithParts _assistantMessage({
  required String providerID,
  required String modelID,
}) {
  return MessageWithParts(
    info: AssistantMessage(
      id: 'asst-1',
      sessionID: 'sess-1',
      role: 'assistant',
      time: MessageTime(created: 2),
      parentID: 'msg-1',
      modelID: modelID,
      providerID: providerID,
      mode: 'chat',
      path: MessagePath(cwd: '/tmp/project', root: '/tmp/project'),
      tokens: MessageTokens(),
    ),
    parts: const <Object>[],
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

ProviderSubscription<ChatConfig> _listenChatConfig(
  ProviderContainer container,
) {
  return container.listen<ChatConfig>(
    chatConfigProvider,
    (previous, next) {},
    fireImmediately: true,
  );
}

ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      sessionMessagesProvider(
        'sess-1',
      ).overrideWith(_FakeSessionMessagesNotifier.new),
    ],
  );
}

ProviderContainer _makeContainerWithSelectedSession(String sessionID) {
  return ProviderContainer(
    overrides: [
      sessionMessagesProvider(
        sessionID,
      ).overrideWith(_FakeSessionMessagesNotifier.new),
      chatViewStateProvider.overrideWithValue((
        sessionId: sessionID,
        isPending: false,
      )),
    ],
  );
}

void main() {
  setUp(() {
    _fakeSessionMessages = <MessageWithParts>[];
  });

  test('no session + valid cache falls back to cached model', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'providerID': 'cached-provider',
        'modelID': 'cached-model',
      }),
    });

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.model.providerID, 'cached-provider');
    expect(config.model.modelID, 'cached-model');
  });

  test('no session + no cache uses hard-coded fallback model', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.model.providerID, _kFallbackProvider);
    expect(config.model.modelID, _kFallbackModel);
  });

  test('invalid cache payload safely falls back to hard-coded model', () async {
    SharedPreferences.setMockInitialValues({_kCacheKey: 'not-json'});

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.model.providerID, _kFallbackProvider);
    expect(config.model.modelID, _kFallbackModel);
  });

  test('existing session model has priority over cache model', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'providerID': 'cached-provider',
        'modelID': 'cached-model',
      }),
    });
    _fakeSessionMessages = <MessageWithParts>[
      _userMessage(
        agent: 'session-agent',
        providerID: 'session-provider',
        modelID: 'session-model',
      ),
    ];

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    container.read(chatViewStateProvider.notifier).selectSessionId('sess-1');
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'session-agent');
    expect(config.model.providerID, 'session-provider');
    expect(config.model.modelID, 'session-model');
  });

  test(
    'initial selected session syncs model on first provider build',
    () async {
      SharedPreferences.setMockInitialValues({
        _kCacheKey: jsonEncode({
          'providerID': 'cached-provider',
          'modelID': 'cached-model',
        }),
      });
      _fakeSessionMessages = <MessageWithParts>[
        _userMessage(
          agent: 'session-agent',
          providerID: 'session-provider',
          modelID: 'session-model',
        ),
      ];

      final container = _makeContainerWithSelectedSession('sess-1');
      addTearDown(container.dispose);

      final sub = _listenChatConfig(container);
      addTearDown(sub.close);
      await _flushAsyncWork();

      final config = container.read(chatConfigProvider);
      expect(config.agent, 'session-agent');
      expect(config.model.providerID, 'session-provider');
      expect(config.model.modelID, 'session-model');
    },
  );

  test('session falls back to last assistant message model', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'providerID': 'cached-provider',
        'modelID': 'cached-model',
      }),
    });
    _fakeSessionMessages = <MessageWithParts>[
      _assistantMessage(
        providerID: 'assistant-provider',
        modelID: 'assistant-model',
      ),
    ];

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    container.read(chatViewStateProvider.notifier).selectSessionId('sess-1');
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.model.providerID, 'assistant-provider');
    expect(config.model.modelID, 'assistant-model');
  });

  test('switch back to new session restores model from cache', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'providerID': 'cached-provider',
        'modelID': 'cached-model',
      }),
    });
    _fakeSessionMessages = <MessageWithParts>[
      _userMessage(
        agent: 'session-agent',
        providerID: 'session-provider',
        modelID: 'session-model',
      ),
    ];

    final container = _makeContainer();
    addTearDown(container.dispose);

    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    container.read(chatViewStateProvider.notifier).selectSessionId('sess-1');
    await _flushAsyncWork();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCacheKey,
      jsonEncode({'providerID': 'cached-provider', 'modelID': 'cached-model'}),
    );

    container.read(chatViewStateProvider.notifier).startNew();
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.model.providerID, 'cached-provider');
    expect(config.model.modelID, 'cached-model');
  });

  test(
    'manual model selection is restored after provider recreation',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final container1 = _makeContainer();
      container1
          .read(chatConfigProvider.notifier)
          .setModel(
            MessageModel(
              providerID: 'manual-provider',
              modelID: 'manual-model',
            ),
          );
      await _flushAsyncWork();
      container1.dispose();

      final container2 = _makeContainer();
      addTearDown(container2.dispose);
      final sub = _listenChatConfig(container2);
      addTearDown(sub.close);
      await _flushAsyncWork();

      final config = container2.read(chatConfigProvider);
      expect(config.model.providerID, 'manual-provider');
      expect(config.model.modelID, 'manual-model');
    },
  );
}
