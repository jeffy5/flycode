import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/model_config_provider.dart';
import '../providers/provider_list_provider.dart';
import '../service/api/models/provider.dart';
import '../theme/app_tokens.dart';

class ModelConfigPage extends ConsumerStatefulWidget {
  const ModelConfigPage({super.key});

  @override
  ConsumerState<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends ConsumerState<ModelConfigPage> {
  static const String _filterAll = '__all__';

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _pendingProviderIds = <String>{};
  final Set<String> _pendingModelKeys = <String>{};

  String _searchQuery = '';
  String _selectedProviderFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final providerListAsync = ref.watch(providerListProvider);
    final isRefreshing = providerListAsync.isLoading;
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modelConfigTitle),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: tokens.accent,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              child: InkWell(
                borderRadius: BorderRadius.circular(tokens.radiusPill),
                onTap: isRefreshing
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref
                              .read(providerListProvider.notifier)
                              .refresh();
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.modelConfigRefreshed)),
                          );
                        } catch (error) {
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.modelConfigRefreshFailed(error.toString()),
                              ),
                            ),
                          );
                        }
                      },
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.refresh,
                    size: 20,
                    color: isRefreshing
                        ? tokens.mutedForeground
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: providerListAsync.when(
        data: (providerList) => _buildContent(context, providerList),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(message: l10n.modelConfigLoadFailed(error.toString())),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProviderListResponse providerList,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;
    final configsAsync = ref.watch(modelConfigProvider);
    final connectedProviders = providerList.all
        .where((p) => providerList.connected.contains(p.id))
        .toList();

    return Column(
      children: [
        Divider(height: 1, color: tokens.border.withValues(alpha: 0.45)),
        Padding(
          padding: EdgeInsets.fromLTRB(pagePadding, 12, pagePadding, 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.modelConfigSearchHint,
              filled: true,
              fillColor: tokens.accent,
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: tokens.mutedForeground,
              ),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : GestureDetector(
                      onTap: _searchController.clear,
                      child: Icon(
                        Icons.cancel,
                        size: 18,
                        color: tokens.mutedForeground,
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusPill),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusPill),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusPill),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ),
        _ProviderFilterChips(
          providers: connectedProviders,
          selectedFilter: _selectedProviderFilter,
          onSelected: (value) {
            setState(() {
              _selectedProviderFilter = value;
            });
          },
        ),
        Expanded(
          child: configsAsync.when(
            data: (configs) {
              final visibleProviders = _buildVisibleProviders(
                providers: connectedProviders,
                searchQuery: _searchQuery,
                selectedProviderFilter: _selectedProviderFilter,
              );

              if (visibleProviders.isEmpty) {
                return _ErrorState(
                  message: connectedProviders.isEmpty
                      ? context.l10n.modelConfigNoProvider
                      : context.l10n.modelConfigNoMatch,
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 20),
                itemCount: visibleProviders.length,
                itemBuilder: (context, index) {
                  final provider = visibleProviders[index];
                  final modelEntries = _resolveVisibleModels(
                    provider: provider,
                    searchQuery: _searchQuery,
                  );

                  final providerEnabled = provider.models.entries.every(
                    (entry) => _isModelEnabled(configs, provider.id, entry),
                  );
                  final providerPending = _pendingProviderIds.contains(
                    provider.id,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(tokens.radiusXs),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  provider.name,
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: providerPending ? 0.6 : 1,
                                child: IgnorePointer(
                                  ignoring: providerPending,
                                  child: _MiniSwitch(
                                    value: providerEnabled,
                                    onChanged: (value) => _toggleProvider(
                                      provider: provider,
                                      enabled: value,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final entry in modelEntries)
                          _ModelRow(
                            providerId: provider.id,
                            modelEntry: entry,
                            enabled: _isModelEnabled(
                              configs,
                              provider.id,
                              entry,
                            ),
                            pending: _pendingModelKeys.contains(
                              '${provider.id}/${entry.key}',
                            ),
                            onChanged: (value) => _toggleModel(
                              providerId: provider.id,
                              modelId: entry.key,
                              enabled: value,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: context.l10n.modelConfigLoadConfigFailed(
                error.toString(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<ProviderModel> _buildVisibleProviders({
    required List<ProviderModel> providers,
    required String searchQuery,
    required String selectedProviderFilter,
  }) {
    final selectedProviderId = selectedProviderFilter == _filterAll
        ? null
        : selectedProviderFilter;

    return providers.where((provider) {
      if (selectedProviderId != null && provider.id != selectedProviderId) {
        return false;
      }

      return _resolveVisibleModels(
        provider: provider,
        searchQuery: searchQuery,
      ).isNotEmpty;
    }).toList();
  }

  List<MapEntry<String, ModelInfo>> _resolveVisibleModels({
    required ProviderModel provider,
    required String searchQuery,
  }) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return provider.models.entries.toList();
    }

    final providerMatched =
        provider.name.toLowerCase().contains(query) ||
        provider.id.toLowerCase().contains(query);
    if (providerMatched) {
      return provider.models.entries.toList();
    }

    return provider.models.entries.where((entry) {
      final model = entry.value;
      return model.name.toLowerCase().contains(query) ||
          model.id.toLowerCase().contains(query);
    }).toList();
  }

  bool _isModelEnabled(
    Map<String, Map<String, bool>> configs,
    String providerId,
    MapEntry<String, ModelInfo> modelEntry,
  ) {
    final providerConfigs = configs[providerId];
    final configured = providerConfigs?[modelEntry.key];
    if (configured != null) {
      return configured;
    }
    return _isRecentlyReleased(modelEntry.value.releaseDate);
  }

  Future<void> _toggleProvider({
    required ProviderModel provider,
    required bool enabled,
  }) async {
    setState(() {
      _pendingProviderIds.add(provider.id);
    });

    try {
      await ref
          .read(modelConfigProvider.notifier)
          .updateProviderModelsConfig(
            provider.id,
            provider.models.keys,
            enabled,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.modelConfigBatchUpdateFailed(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingProviderIds.remove(provider.id);
        });
      }
    }
  }

  Future<void> _toggleModel({
    required String providerId,
    required String modelId,
    required bool enabled,
  }) async {
    final modelKey = '$providerId/$modelId';
    setState(() {
      _pendingModelKeys.add(modelKey);
    });

    try {
      await ref
          .read(modelConfigProvider.notifier)
          .updateModelConfig(providerId, modelId, enabled);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.modelConfigUpdateFailed(error.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingModelKeys.remove(modelKey);
        });
      }
    }
  }
}

class _ProviderFilterChips extends StatelessWidget {
  final List<ProviderModel> providers;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _ProviderFilterChips({
    required this.providers,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;

    Widget chip({required String value, required String label}) {
      final selected = selectedFilter == value;
      return GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : tokens.border.withValues(alpha: 0.9),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : tokens.accentForeground,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 6),
      child: Row(
        children: [
          chip(
            value: _ModelConfigPageState._filterAll,
            label: context.l10n.commonAll,
          ),
          for (final provider in providers) ...[
            const SizedBox(width: 8),
            chip(value: provider.id, label: provider.name),
          ],
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final String providerId;
  final MapEntry<String, ModelInfo> modelEntry;
  final bool enabled;
  final bool pending;
  final ValueChanged<bool> onChanged;

  const _ModelRow({
    required this.providerId,
    required this.modelEntry,
    required this.enabled,
    required this.pending,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelEntry.value.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$providerId-${modelEntry.key}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: pending ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: pending,
              child: _MiniSwitch(value: enabled, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? theme.colorScheme.primary : tokens.border,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.pageHorizontalPadding),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.mutedForeground),
        ),
      ),
    );
  }
}

bool _isRecentlyReleased(String releaseDate) {
  if (releaseDate.isEmpty) {
    return true;
  }
  try {
    final release = DateTime.parse(releaseDate);
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return release.isAfter(sixMonthsAgo);
  } catch (_) {
    return true;
  }
}
