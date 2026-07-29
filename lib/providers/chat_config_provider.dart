import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/api/models/agent.dart' as agent_model;
import '../service/api/models/message.dart';
import 'chat_view_state_provider.dart';
import 'shared_preferences_provider.dart';
import 'session_provider.dart';

part 'chat_config_provider.g.dart';

const _kDefaultAgent = 'build';
const _kFallbackProviderID = 'opencode';
const _kFallbackModelID = 'minimax-m2.5-free';
const _kLastUsedConfigCacheKey = 'chat_config_last_used_model';
const _kModelVariantCacheKey = 'chat_config_model_variants';
const _unsetVariant = Object();

class ChatConfig {
  final String agent;
  final MessageModel model;
  final String? variant;

  const ChatConfig({required this.agent, required this.model, this.variant});

  ChatConfig copyWith({
    String? agent,
    MessageModel? model,
    Object? variant = _unsetVariant,
  }) {
    return ChatConfig(
      agent: agent ?? this.agent,
      model: model ?? this.model,
      variant: identical(variant, _unsetVariant)
          ? this.variant
          : variant as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'agent': agent,
    'model': model.toJson(),
    'variant': variant,
  };

  @override
  String toString() =>
      'ChatConfig(agent: $agent, providerID: ${model.providerID},'
      ' modelID: ${model.modelID}, variant: $variant)';
}

@Riverpod()
class ChatConfigNotifier extends _$ChatConfigNotifier {
  final Map<String, String?> _variantByModel = <String, String?>{};
  late final Future<SharedPreferences> _preferences;
  late final Future<void> _variantSelectionsReady;
  int _restoreGeneration = 0;
  Future<void> _configWrite = Future<void>.value();
  Future<void> _variantWrite = Future<void>.value();

  @override
  ChatConfig build() {
    final initialState = ref.read(chatViewStateProvider);
    _preferences = ref.read(sharedPreferencesProvider.future);
    _variantSelectionsReady = _restoreVariantSelections();

    ref.listen<ChatViewState>(chatViewStateProvider, (previous, next) {
      if (next.sessionId == previous?.sessionId &&
          next.isPending == previous?.isPending) {
        return;
      }
      unawaited(_restoreForChatState(next));
    });

    unawaited(_restoreForChatState(initialState));

    return ChatConfig(
      agent: _kDefaultAgent,
      model: MessageModel(
        providerID: _kFallbackProviderID,
        modelID: _kFallbackModelID,
      ),
    );
  }

  Future<void> _restoreForChatState(ChatViewState chatState) async {
    final generation = ++_restoreGeneration;
    await _variantSelectionsReady;
    if (!_isCurrentRestore(generation, chatState)) return;

    final sessionID = chatState.sessionId;
    if (!chatState.isPending && sessionID != null) {
      await _restoreFromSession(sessionID, generation);
      return;
    }

    await _restoreFromCache(generation, chatState);
  }

  Future<void> _restoreFromSession(String sessionID, int generation) async {
    ChatConfig? config;
    try {
      final messages = await ref.read(
        sessionMessagesProvider(sessionID).future,
      );
      if (messages.isNotEmpty) {
        config = _configFromMessage(messages.last.info);
      }
    } catch (_) {
      // Fall back to the last app-wide configuration below.
    }

    final expected = (sessionId: sessionID, isPending: false);
    if (!_isCurrentRestore(generation, expected)) return;

    if (config == null) {
      await _restoreFromCache(generation, expected);
      return;
    }

    _rememberVariant(config.model, config.variant);
    _setState(config, persistConfig: true, persistVariants: true);
  }

  Future<void> _restoreFromCache(int generation, ChatViewState expected) async {
    final cached = await _readCachedConfig();
    if (cached == null || !_isCurrentRestore(generation, expected)) return;
    _setState(cached);
  }

  bool _isCurrentRestore(int generation, ChatViewState expected) {
    if (!ref.mounted || generation != _restoreGeneration) return false;
    final current = ref.read(chatViewStateProvider);
    return current.sessionId == expected.sessionId &&
        current.isPending == expected.isPending;
  }

  ChatConfig? _configFromMessage(Object info) {
    if (info case final UserMessage user) {
      return _validConfig(
        agent: user.agent,
        model: user.model,
        variant: user.variant,
      );
    }

    if (info case final AssistantMessage assistant) {
      return _validConfig(
        agent: assistant.agent ?? assistant.mode,
        model: MessageModel(
          providerID: assistant.providerID,
          modelID: assistant.modelID,
        ),
        variant: assistant.variant,
      );
    }

    return null;
  }

  ChatConfig? _validConfig({
    required String agent,
    required MessageModel model,
    String? variant,
  }) {
    if (agent.trim().isEmpty ||
        model.providerID.trim().isEmpty ||
        model.modelID.trim().isEmpty) {
      return null;
    }
    return ChatConfig(agent: agent, model: model, variant: variant);
  }

  void setAgent(
    String agent, {
    agent_model.AgentModel? linkedModel,
    String? linkedVariant,
  }) {
    _restoreGeneration++;
    if (linkedModel == null) {
      _setState(state.copyWith(agent: agent), persistConfig: true);
      return;
    }

    final model = MessageModel(
      providerID: linkedModel.providerID,
      modelID: linkedModel.modelID,
    );
    final modelKey = _modelKey(model);
    final variant = _variantByModel.containsKey(modelKey)
        ? _variantByModel[modelKey]
        : linkedVariant ?? linkedModel.variant;
    _rememberVariant(model, variant);
    _setState(
      ChatConfig(agent: agent, model: model, variant: variant),
      persistConfig: true,
      persistVariants: true,
    );
  }

  void setModel(MessageModel model) {
    _restoreGeneration++;
    final modelKey = _modelKey(model);
    final variant = _variantByModel.containsKey(modelKey)
        ? _variantByModel[modelKey]
        : null;
    _setState(
      ChatConfig(agent: state.agent, model: model, variant: variant),
      persistConfig: true,
    );
  }

  void setVariant(String? variant) {
    _restoreGeneration++;
    _rememberVariant(state.model, variant);
    _setState(
      state.copyWith(variant: variant),
      persistConfig: true,
      persistVariants: true,
    );
  }

  Future<ChatConfig?> _readCachedConfig() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_kLastUsedConfigCacheKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      if (json['model'] case final Map<String, dynamic> modelJson) {
        return _validConfig(
          agent: json['agent'] as String? ?? _kDefaultAgent,
          model: MessageModel.fromJson(modelJson),
          variant: json['variant'] as String?,
        );
      }

      final model = MessageModel.fromJson(json);
      final migrated = _validConfig(
        agent: _kDefaultAgent,
        model: model,
        variant: _variantByModel[_modelKey(model)],
      );
      if (migrated != null) {
        await prefs.setString(
          _kLastUsedConfigCacheKey,
          jsonEncode(migrated.toJson()),
        );
      }
      return migrated;
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreVariantSelections() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_kModelVariantCacheKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return;
      _variantByModel
        ..clear()
        ..addEntries(
          json.entries
              .where((entry) {
                return entry.key.isNotEmpty &&
                    (entry.value == null || entry.value is String);
              })
              .map((entry) => MapEntry(entry.key, entry.value as String?)),
        );
    } catch (_) {
      // Ignore invalid legacy cache payloads.
    }
  }

  void _rememberVariant(MessageModel model, String? variant) {
    _variantByModel[_modelKey(model)] = variant;
  }

  String _modelKey(MessageModel model) {
    return '${model.providerID}/${model.modelID}';
  }

  void _persistConfig(ChatConfig config) {
    _configWrite = _configWrite.then((_) async {
      final prefs = await _preferences;
      await prefs.setString(
        _kLastUsedConfigCacheKey,
        jsonEncode(config.toJson()),
      );
    });
  }

  void _persistVariantSelections() {
    final snapshot = Map<String, String?>.from(_variantByModel);
    _variantWrite = _variantWrite.then((_) async {
      final prefs = await _preferences;
      await prefs.setString(_kModelVariantCacheKey, jsonEncode(snapshot));
    });
  }

  void _setState(
    ChatConfig next, {
    bool persistConfig = false,
    bool persistVariants = false,
  }) {
    if (!ref.mounted) return;
    final changed =
        next.agent != state.agent ||
        next.model.providerID != state.model.providerID ||
        next.model.modelID != state.model.modelID ||
        next.variant != state.variant;
    if (changed) state = next;

    if (persistConfig) _persistConfig(next);
    if (persistVariants) _persistVariantSelections();
  }
}
