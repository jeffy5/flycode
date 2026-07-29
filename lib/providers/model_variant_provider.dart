import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/api/models/agent.dart';
import '../service/api/models/message.dart';
import '../service/api/models/provider.dart';
import 'agent_provider.dart';
import 'chat_config_provider.dart';
import 'provider_list_provider.dart';

part 'model_variant_provider.g.dart';

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
  final String? selected;
  final String? configured;
  final String? current;

  const ModelVariantState({
    required this.modelKey,
    required this.available,
    required this.selected,
    required this.configured,
    required this.current,
  });
}

@riverpod
class ModelVariant extends _$ModelVariant {
  @override
  ModelVariantState build() {
    final chatConfig = ref.watch(chatConfigProvider);
    final providerList = ref.watch(providerListProvider).asData?.value;
    final agents = ref.watch(agentsProvider).asData?.value ?? const <Agent>[];
    final available = _availableVariants(providerList, chatConfig.model);
    final configured = _configuredVariant(agents, chatConfig);

    return ModelVariantState(
      modelKey: buildModelKey(chatConfig.model),
      available: available,
      selected: chatConfig.variant,
      configured: configured,
      current: resolveVariant(
        variants: available,
        selected: chatConfig.variant,
        configured: configured,
      ),
    );
  }

  void setSelectedForCurrentModel(String? variant) {
    if (variant != null && !state.available.contains(variant)) return;
    ref.read(chatConfigProvider.notifier).setVariant(variant);
  }

  void cycleForCurrentModel() {
    final next = cycleVariant(state.available, state.current);
    setSelectedForCurrentModel(next);
  }

  List<String> _availableVariants(
    ProviderListResponse? providerList,
    MessageModel model,
  ) {
    if (providerList == null) return const <String>[];
    for (final provider in providerList.all) {
      if (provider.id != model.providerID) continue;
      final variants = provider.models[model.modelID]?.variants;
      if (variants == null || variants.isEmpty) return const <String>[];
      return variants.keys.toList();
    }
    return const <String>[];
  }

  String? _configuredVariant(List<Agent> agents, ChatConfig chatConfig) {
    for (final agent in agents) {
      if (agent.name != chatConfig.agent) continue;
      final model = agent.model;
      if (model == null ||
          model.providerID != chatConfig.model.providerID ||
          model.modelID != chatConfig.model.modelID) {
        return null;
      }
      return agent.variant ?? model.variant;
    }
    return null;
  }
}
