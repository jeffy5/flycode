import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/api/models/agent.dart';
import '../service/api/models/message.dart';
import '../service/api/models/provider.dart';
import 'agent_provider.dart';
import 'chat_config_provider.dart';
import 'provider_list_provider.dart';
import 'shared_preferences_provider.dart';

part 'model_variant_provider.g.dart';

const _kModelVariantCacheKey = 'chat_config_model_variants';

String buildModelKey(MessageModel model) {
  return '${model.providerID}/${model.modelID}';
}

String? resolveVariant({
  required List<String> variants,
  String? selected,
  String? configured,
}) {
  if (selected != null && variants.contains(selected)) {
    return selected;
  }
  if (configured != null && variants.contains(configured)) {
    return configured;
  }
  return null;
}

String? cycleVariant(List<String> variants, String? current) {
  if (variants.isEmpty) return null;
  if (current == null || current.isEmpty) {
    return variants.first;
  }
  final currentIndex = variants.indexOf(current);
  if (currentIndex == -1) {
    return variants.first;
  }
  if (currentIndex == variants.length - 1) {
    return null;
  }
  return variants[currentIndex + 1];
}

class ModelVariantState {
  final String modelKey;
  final List<String> available;
  final Map<String, String> selectedByModel;
  final String? selected;
  final String? configured;
  final String? current;

  const ModelVariantState({
    required this.modelKey,
    required this.available,
    required this.selectedByModel,
    required this.selected,
    required this.configured,
    required this.current,
  });
}

@riverpod
class ModelVariant extends _$ModelVariant {
  final Map<String, String> _selectedByModel = <String, String>{};
  bool _restored = false;

  @override
  ModelVariantState build() {
    final chatConfig = ref.watch(chatConfigProvider);
    final providerList = ref.watch(providerListProvider).asData?.value;
    final agents = ref.watch(agentsProvider).asData?.value ?? const <Agent>[];

    if (!_restored) {
      _restored = true;
      unawaited(_restoreSelections());
    }

    final nextState = _stateFromContext(
      chatConfig: chatConfig,
      providerList: providerList,
      agents: agents,
    );

    final selected = nextState.selected;
    if (selected != null && !nextState.available.contains(selected)) {
      _selectedByModel.remove(nextState.modelKey);
      unawaited(_persistSelections());
      return ModelVariantState(
        modelKey: nextState.modelKey,
        available: nextState.available,
        selectedByModel: Map<String, String>.from(_selectedByModel),
        selected: null,
        configured: nextState.configured,
        current: resolveVariant(
          variants: nextState.available,
          selected: null,
          configured: nextState.configured,
        ),
      );
    }

    return nextState;
  }

  void setSelectedForCurrentModel(String? variant) {
    final modelKey = state.modelKey;
    if (variant == null || variant.trim().isEmpty) {
      _selectedByModel.remove(modelKey);
    } else {
      if (!state.available.contains(variant)) return;
      _selectedByModel[modelKey] = variant;
    }

    _recomputeState();
    unawaited(_persistSelections());
  }

  void cycleForCurrentModel() {
    final next = cycleVariant(state.available, state.current);
    setSelectedForCurrentModel(next);
  }

  Future<void> _restoreSelections() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_kModelVariantCacheKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return;
      _selectedByModel
        ..clear()
        ..addEntries(
          json.entries
              .where((entry) {
                return entry.key.isNotEmpty &&
                    entry.value is String &&
                    (entry.value as String).isNotEmpty;
              })
              .map((entry) {
                return MapEntry(entry.key, entry.value as String);
              }),
        );
      if (!ref.mounted) return;
      _recomputeState();
    } catch (_) {
      // Ignore invalid cached payload.
    }
  }

  Future<void> _persistSelections() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kModelVariantCacheKey, jsonEncode(_selectedByModel));
  }

  void _recomputeState() {
    if (!ref.mounted) return;
    final chatConfig = ref.read(chatConfigProvider);
    final providerList = ref.read(providerListProvider).asData?.value;
    final agents = ref.read(agentsProvider).asData?.value ?? const <Agent>[];
    state = _stateFromContext(
      chatConfig: chatConfig,
      providerList: providerList,
      agents: agents,
    );
  }

  ModelVariantState _stateFromContext({
    required ChatConfig chatConfig,
    required ProviderListResponse? providerList,
    required List<Agent> agents,
  }) {
    final modelKey = buildModelKey(chatConfig.model);
    final available = _availableVariants(providerList, chatConfig.model);
    final selected = _selectedByModel[modelKey];
    final configured = _configuredVariant(agents, chatConfig.agent);
    final current = resolveVariant(
      variants: available,
      selected: selected,
      configured: configured,
    );

    return ModelVariantState(
      modelKey: modelKey,
      available: available,
      selectedByModel: Map<String, String>.from(_selectedByModel),
      selected: selected,
      configured: configured,
      current: current,
    );
  }

  List<String> _availableVariants(
    ProviderListResponse? providerList,
    MessageModel model,
  ) {
    if (providerList == null) return const <String>[];
    for (final provider in providerList.all) {
      if (provider.id != model.providerID) continue;
      final modelInfo = provider.models[model.modelID];
      if (modelInfo == null) return const <String>[];
      final variants = modelInfo.variants;
      if (variants == null || variants.isEmpty) return const <String>[];
      return variants.keys.toList();
    }
    return const <String>[];
  }

  String? _configuredVariant(List<Agent> agents, String agentName) {
    for (final agent in agents) {
      if (agent.name == agentName) {
        return agent.model?.variant;
      }
    }
    return null;
  }
}
