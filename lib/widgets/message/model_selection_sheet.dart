import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../service/api/models/provider.dart';
import '../../service/api/models/message.dart';
import '../../providers/model_config_provider.dart';
import '../../providers/chat_config_provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../theme/app_tokens.dart';

class ModelSelectionSheet extends ConsumerStatefulWidget {
  const ModelSelectionSheet({super.key});

  @override
  ConsumerState<ModelSelectionSheet> createState() =>
      _ModelSelectionSheetState();
}

class _ModelSelectionSheetState extends ConsumerState<ModelSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilterKey = _filterAll;

  static const String _filterAll = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final providerListAsync = ref.watch(providerListProvider);
    final configsAsync = ref.watch(modelConfigProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusM + 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pagePadding, 6, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.modelSelectionTitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 12),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l10n.modelSelectionSearchHint,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: tokens.mutedForeground,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: tokens.mutedForeground,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: Icon(
                            Icons.cancel,
                            size: 18,
                            color: tokens.mutedForeground,
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  filled: true,
                  fillColor: tokens.accent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusL),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusL),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusL),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            providerListAsync.when(
              data: (providerList) {
                final connectedProviders = providerList.all
                    .where((p) => providerList.connected.contains(p.id))
                    .toList();
                return _buildFilterChips(context, connectedProviders);
              },
              loading: () => const SizedBox(height: 42),
              error: (_, _) => const SizedBox(height: 42),
            ),
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),
            Expanded(
              child: providerListAsync.when(
                data: (providerList) {
                  return configsAsync.when(
                    data: (configs) => _buildList(
                      context,
                      providerList,
                      configs,
                      _searchQuery,
                      _selectedProviderId,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => _buildErrorState(
                      context,
                      l10n.modelSelectionConfigLoadFailed(e.toString()),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildErrorState(
                  context,
                  l10n.modelSelectionListLoadFailed(e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _selectedProviderId {
    if (_selectedFilterKey == _filterAll) {
      return null;
    }
    return _selectedFilterKey;
  }

  Widget _buildErrorState(BuildContext context, String message) {
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

  Widget _buildFilterChips(
    BuildContext context,
    List<ProviderModel> providers,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;

    Widget chip({required String key, required String label}) {
      final selected = _selectedFilterKey == key;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterKey = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : tokens.accent,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(pagePadding, 0, pagePadding, 10),
      child: Row(
        children: [
          chip(key: _filterAll, label: context.l10n.commonAll),
          for (final provider in providers) ...[
            const SizedBox(width: 8),
            chip(key: provider.id, label: provider.name),
          ],
        ],
      ),
    );
  }

  Map<ProviderModel, List<MapEntry<String, ModelInfo>>> _buildProviderGroups(
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final selectedProviderId = _selectedProviderId;

    final connectedProviders = providerList.all
        .where((p) => providerList.connected.contains(p.id))
        .where((p) => selectedProviderId == null || p.id == selectedProviderId)
        .toList();

    final grouped = <ProviderModel, List<MapEntry<String, ModelInfo>>>{};

    for (final provider in connectedProviders) {
      final providerConfigs = configs[provider.id] ?? {};

      var availableModels = provider.models.entries.where((entry) {
        final modelId = entry.key;
        final model = entry.value;

        if (providerConfigs.containsKey(modelId)) {
          return providerConfigs[modelId]!;
        }
        return _isRecentlyReleased(model.releaseDate);
      }).toList();

      if (normalizedQuery.isNotEmpty) {
        availableModels = availableModels.where((entry) {
          final model = entry.value;
          return model.name.toLowerCase().contains(normalizedQuery) ||
              model.id.toLowerCase().contains(normalizedQuery);
        }).toList();
      }

      if (availableModels.isNotEmpty) {
        grouped[provider] = availableModels;
      }
    }

    return grouped;
  }

  Widget _buildList(
    BuildContext context,
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
    String searchQuery,
    String? selectedProviderId,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final providerGroups = _buildProviderGroups(
      providerList,
      configs,
      searchQuery,
    );

    if (providerList.connected.isEmpty) {
      return Center(
        child: Text(
          context.l10n.modelSelectionNoConnectedProviders,
          style: TextStyle(color: tokens.mutedForeground),
        ),
      );
    }

    final List<Widget> listItems = [];

    for (final entry in providerGroups.entries) {
      final provider = entry.key;
      final availableModels = entry.value;

      listItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Text(
                provider.name,
                style: TextStyle(
                  color: tokens.mutedForeground,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
                child: Text(
                  '${availableModels.length}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final modelEntry in availableModels) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: _ModelTile(
              providerId: provider.id,
              modelInfo: modelEntry.value,
            ),
          ),
        );
      }
    }

    if (listItems.isEmpty) {
      final noMatchByQuery = searchQuery.trim().isNotEmpty;
      final noMatchByProvider =
          selectedProviderId != null && searchQuery.trim().isEmpty;
      String message = context.l10n.modelSelectionNoModels;
      if (noMatchByQuery) {
        message = context.l10n.modelSelectionNoMatchedModels;
      } else if (noMatchByProvider) {
        message = context.l10n.modelSelectionNoModelsUnderProvider;
      }

      return Center(
        child: Text(
          message,
          style: TextStyle(color: tokens.mutedForeground, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
    );
  }

  bool _isRecentlyReleased(String releaseDate) {
    if (releaseDate.isEmpty) {
      return true;
    }
    try {
      final release = DateTime.parse(releaseDate);
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      return release.isAfter(sixMonthsAgo);
    } catch (e) {
      return true;
    }
  }
}

class _ModelTile extends ConsumerWidget {
  final String providerId;
  final ModelInfo modelInfo;

  const _ModelTile({required this.providerId, required this.modelInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(chatConfigProvider);
    final isSelected =
        currentConfig.model.providerID == providerId &&
        currentConfig.model.modelID == modelInfo.id;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isFavorite = _isFavoriteModel(modelInfo);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ref
              .read(chatConfigProvider.notifier)
              .setModel(
                MessageModel(providerID: providerId, modelID: modelInfo.id),
              );
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: tokens.accent,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      modelInfo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isFavorite && !isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: theme.colorScheme.primary,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            context.l10n.modelSelectionFavorited,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                modelInfo.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFavoriteModel(ModelInfo model) {
    final dynamic raw = model.options['favorite'] ?? model.options['favourite'];
    return raw == true;
  }
}
