import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/agent_provider.dart';
import 'package:flycode/providers/chat_config_provider.dart';
import 'package:flycode/providers/model_variant_provider.dart';
import 'package:flycode/providers/provider_list_provider.dart';
import 'package:flycode/service/api/models/agent.dart';
import 'package:flycode/service/api/models/message.dart';
import 'package:flycode/service/api/models/provider.dart';

const _kVariantCacheKey = 'chat_config_model_variants';

ProviderListResponse _fakeProviderList = ProviderListResponse(
  all: <ProviderModel>[],
  defaultProvider: <String, String>{},
  connected: <String>[],
);
List<Agent> _fakeAgents = <Agent>[];

class _FakeProviderListNotifier extends ProviderList {
  @override
  Future<ProviderListResponse> build() async => _fakeProviderList;
}

ProviderContainer _makeContainer(ChatConfig config) {
  return ProviderContainer(
    overrides: [
      chatConfigProvider.overrideWithValue(config),
      providerListProvider.overrideWith(_FakeProviderListNotifier.new),
      agentsProvider.overrideWith((ref) async => _fakeAgents),
    ],
  );
}

ProviderListResponse _providerListWithVariants(Map<String, dynamic> variants) {
  final model = ModelInfo(
    id: 'm1',
    providerID: 'p1',
    api: ModelApi(id: 'api'),
    name: 'Model 1',
    capabilities: ModelCapabilities(),
    cost: ModelCost(input: 0, output: 0, cache: CacheCost()),
    limit: ModelLimit(context: 1, output: 1),
    status: 'stable',
    options: const <String, dynamic>{},
    headers: const <String, String>{},
    releaseDate: '2026-01-01',
    variants: variants.cast<String, Map<String, dynamic>>(),
  );
  return ProviderListResponse(
    all: <ProviderModel>[
      ProviderModel(
        id: 'p1',
        name: 'Provider 1',
        source: 'remote',
        env: const <String>[],
        options: const <String, dynamic>{},
        models: <String, ModelInfo>{'m1': model},
      ),
    ],
    defaultProvider: const <String, String>{},
    connected: const <String>['p1'],
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    _fakeProviderList = _providerListWithVariants(<String, dynamic>{
      'thinking': <String, dynamic>{},
      'fast': <String, dynamic>{},
    });
    _fakeAgents = <Agent>[
      const Agent(
        name: 'build',
        mode: 'primary',
        model: AgentModel(providerID: 'p1', modelID: 'm1', variant: 'thinking'),
      ),
    ];
  });

  test('resolveVariant applies selected > configured > default priority', () {
    expect(
      resolveVariant(
        variants: const <String>['thinking', 'fast'],
        selected: 'fast',
        configured: 'thinking',
      ),
      'fast',
    );
    expect(
      resolveVariant(
        variants: const <String>['thinking', 'fast'],
        selected: 'invalid',
        configured: 'thinking',
      ),
      'thinking',
    );
    expect(
      resolveVariant(
        variants: const <String>['thinking', 'fast'],
        selected: 'invalid',
        configured: 'invalid',
      ),
      isNull,
    );
  });

  test('cycleVariant includes default step', () {
    const variants = <String>['thinking', 'fast'];
    expect(cycleVariant(variants, null), 'thinking');
    expect(cycleVariant(variants, 'thinking'), 'fast');
    expect(cycleVariant(variants, 'fast'), isNull);
  });

  test('restores model-level variant from shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _kVariantCacheKey: jsonEncode(<String, String>{'p1/m1': 'fast'}),
    });

    final container = _makeContainer(
      ChatConfig(
        agent: 'build',
        model: MessageModel(providerID: 'p1', modelID: 'm1'),
      ),
    );
    addTearDown(container.dispose);

    final sub = container.listen<ModelVariantState>(
      modelVariantProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _flushAsyncWork();

    final state = container.read(modelVariantProvider);
    expect(state.selected, 'fast');
    expect(state.configured, 'thinking');
    expect(state.current, 'fast');
  });

  test('writes selected variant to per-model cache', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final container = _makeContainer(
      ChatConfig(
        agent: 'build',
        model: MessageModel(providerID: 'p1', modelID: 'm1'),
      ),
    );
    addTearDown(container.dispose);

    final sub = container.listen<ModelVariantState>(
      modelVariantProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await _flushAsyncWork();

    container
        .read(modelVariantProvider.notifier)
        .setSelectedForCurrentModel('thinking');
    await _flushAsyncWork();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVariantCacheKey);
    final map = jsonDecode(raw ?? '{}') as Map<String, dynamic>;

    expect(map['p1/m1'], 'thinking');
    expect(container.read(modelVariantProvider).current, 'thinking');
  });
}
