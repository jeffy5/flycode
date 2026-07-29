import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/chat_config_provider.dart';
import 'package:flycode/providers/chat_view_state_provider.dart';
import 'package:flycode/providers/session_provider.dart';
import 'package:flycode/service/api/models/message.dart';

const _kCacheKey = 'chat_config_last_used_model';
const _kVariantCacheKey = 'chat_config_model_variants';
const _kFallbackProvider = 'opencode';
const _kFallbackModel = 'minimax-m2.5-free';

List<MessageWithParts> _fakeSessionMessages = <MessageWithParts>[];
final Map<String, List<MessageWithParts>> _fakeMessagesBySession = {};
final Map<String, Completer<List<MessageWithParts>>> _messageCompleters = {};
bool _throwSessionMessages = false;

class _FakeSessionMessagesNotifier extends SessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build(String sessionID) async {
    if (_throwSessionMessages) throw Exception('message load failed');
    final completer = _messageCompleters[sessionID];
    if (completer != null) return completer.future;
    return _fakeMessagesBySession[sessionID] ?? _fakeSessionMessages;
  }
}

MessageWithParts _userMessage({
  required String agent,
  required String providerID,
  required String modelID,
  String? variant,
}) {
  return MessageWithParts(
    info: UserMessage(
      id: 'msg-1',
      sessionID: 'sess-1',
      role: 'user',
      time: MessageTime(created: 1),
      agent: agent,
      model: MessageModel(providerID: providerID, modelID: modelID),
      variant: variant,
    ),
    parts: const <Object>[],
  );
}

MessageWithParts _assistantMessage({
  required String providerID,
  required String modelID,
  String? agent,
  String? variant,
  String mode = 'chat',
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
      agent: agent,
      variant: variant,
      mode: mode,
      path: MessagePath(cwd: '/tmp/project', root: '/tmp/project'),
      tokens: MessageTokens(),
    ),
    parts: const <Object>[],
  );
}

Future<void> _flushAsyncWork() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
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

ProviderContainer _makeContainerForSessions(List<String> sessionIDs) {
  return ProviderContainer(
    overrides: [
      for (final sessionID in sessionIDs)
        sessionMessagesProvider(
          sessionID,
        ).overrideWith(_FakeSessionMessagesNotifier.new),
    ],
  );
}

void main() {
  setUp(() {
    _fakeSessionMessages = <MessageWithParts>[];
    _fakeMessagesBySession.clear();
    _messageCompleters.clear();
    _throwSessionMessages = false;
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
    expect(config.agent, 'build');
    expect(config.variant, isNull);
  });

  test('no session restores the complete cached configuration', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'agent': 'cached-agent',
        'model': {'providerID': 'cached-provider', 'modelID': 'cached-model'},
        'variant': 'high',
      }),
    });

    final container = _makeContainer();
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'cached-agent');
    expect(config.model.providerID, 'cached-provider');
    expect(config.model.modelID, 'cached-model');
    expect(config.variant, 'high');
  });

  test('legacy model cache migrates its remembered variant', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'providerID': 'cached-provider',
        'modelID': 'cached-model',
      }),
      _kVariantCacheKey: jsonEncode({'cached-provider/cached-model': 'high'}),
    });

    final container = _makeContainer();
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'build');
    expect(config.variant, 'high');
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
        agent: 'assistant-agent',
        variant: 'high',
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
    expect(config.agent, 'assistant-agent');
    expect(config.variant, 'high');
  });

  test('last assistant message replaces the complete user config', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _fakeSessionMessages = <MessageWithParts>[
      _userMessage(
        agent: 'user-agent',
        providerID: 'user-provider',
        modelID: 'user-model',
        variant: 'low',
      ),
      _assistantMessage(
        agent: 'assistant-agent',
        providerID: 'assistant-provider',
        modelID: 'assistant-model',
        variant: 'high',
      ),
    ];

    final container = _makeContainerWithSelectedSession('sess-1');
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'assistant-agent');
    expect(config.model.providerID, 'assistant-provider');
    expect(config.model.modelID, 'assistant-model');
    expect(config.variant, 'high');
  });

  test('missing session variant is restored as Default', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'agent': 'cached-agent',
        'model': {'providerID': 'cached-provider', 'modelID': 'cached-model'},
        'variant': 'high',
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
    expect(config.model.modelID, 'session-model');
    expect(config.variant, isNull);
  });

  test('empty session falls back to the complete cached config', () async {
    SharedPreferences.setMockInitialValues({
      _kCacheKey: jsonEncode({
        'agent': 'cached-agent',
        'model': {'providerID': 'cached-provider', 'modelID': 'cached-model'},
        'variant': 'high',
      }),
    });

    final container = _makeContainerWithSelectedSession('sess-1');
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'cached-agent');
    expect(config.model.modelID, 'cached-model');
    expect(config.variant, 'high');
  });

  test(
    'message load failure falls back to the complete cached config',
    () async {
      SharedPreferences.setMockInitialValues({
        _kCacheKey: jsonEncode({
          'agent': 'cached-agent',
          'model': {'providerID': 'cached-provider', 'modelID': 'cached-model'},
          'variant': 'high',
        }),
      });
      _throwSessionMessages = true;

      final container = _makeContainerWithSelectedSession('sess-1');
      addTearDown(container.dispose);
      final sub = _listenChatConfig(container);
      addTearDown(sub.close);
      await _flushAsyncWork();

      final config = container.read(chatConfigProvider);
      expect(config.agent, 'cached-agent');
      expect(config.model.modelID, 'cached-model');
      expect(config.variant, 'high');
    },
  );

  test('stale session restore cannot overwrite a newer selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final firstSession = Completer<List<MessageWithParts>>();
    _messageCompleters['sess-1'] = firstSession;
    _fakeMessagesBySession['sess-2'] = [
      _userMessage(
        agent: 'new-agent',
        providerID: 'new-provider',
        modelID: 'new-model',
        variant: 'high',
      ),
    ];

    final container = _makeContainerForSessions(['sess-1', 'sess-2']);
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    container.read(chatViewStateProvider.notifier).selectSessionId('sess-1');
    await _flushAsyncWork();
    container.read(chatViewStateProvider.notifier).selectSessionId('sess-2');
    await _flushAsyncWork();

    expect(container.read(chatConfigProvider).agent, 'new-agent');
    firstSession.complete([
      _userMessage(
        agent: 'old-agent',
        providerID: 'old-provider',
        modelID: 'old-model',
      ),
    ]);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'new-agent');
    expect(config.model.modelID, 'new-model');
    expect(config.variant, 'high');
  });

  test('manual config change cancels an in-flight session restore', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sessionMessages = Completer<List<MessageWithParts>>();
    _messageCompleters['sess-1'] = sessionMessages;

    final container = _makeContainerForSessions(['sess-1']);
    addTearDown(container.dispose);
    final sub = _listenChatConfig(container);
    addTearDown(sub.close);
    await _flushAsyncWork();

    container.read(chatViewStateProvider.notifier).selectSessionId('sess-1');
    await _flushAsyncWork();
    final notifier = container.read(chatConfigProvider.notifier);
    notifier.setModel(
      MessageModel(providerID: 'manual-provider', modelID: 'manual-model'),
    );
    notifier.setAgent('manual-agent');
    notifier.setVariant('high');

    sessionMessages.complete([
      _userMessage(
        agent: 'session-agent',
        providerID: 'session-provider',
        modelID: 'session-model',
      ),
    ]);
    await _flushAsyncWork();

    final config = container.read(chatConfigProvider);
    expect(config.agent, 'manual-agent');
    expect(config.model.modelID, 'manual-model');
    expect(config.variant, 'high');
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

  test('manual configuration is restored after provider recreation', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final container1 = _makeContainer();
    container1
        .read(chatConfigProvider.notifier)
        .setModel(
          MessageModel(providerID: 'manual-provider', modelID: 'manual-model'),
        );
    container1.read(chatConfigProvider.notifier).setAgent('manual-agent');
    container1.read(chatConfigProvider.notifier).setVariant('high');
    await _flushAsyncWork();
    container1.dispose();

    final container2 = _makeContainer();
    addTearDown(container2.dispose);
    final sub = _listenChatConfig(container2);
    addTearDown(sub.close);
    await _flushAsyncWork();

    final config = container2.read(chatConfigProvider);
    expect(config.agent, 'manual-agent');
    expect(config.model.providerID, 'manual-provider');
    expect(config.model.modelID, 'manual-model');
    expect(config.variant, 'high');

    final prefs = await SharedPreferences.getInstance();
    final cached = jsonDecode(prefs.getString(_kCacheKey)!) as Map;
    expect(cached['agent'], 'manual-agent');
    expect(cached['variant'], 'high');
  });
}
