import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../models/chat_route_args.dart';
import '../service/api/models/project.dart';
import '../service/api/api_client.dart';
import '../providers/current_directory_provider.dart';
import '../providers/project_pin_provider.dart';
import '../providers/server_config_provider.dart';
import '../service/api/project_api.dart';
import '../theme/app_tokens.dart';
import '../widgets/project/open_project_sheet.dart';

String _projectDisplayName(Project project) {
  if (project.name != null && project.name!.isNotEmpty) return project.name!;
  final worktree = project.worktree;
  final parts = worktree.replaceAll('\\', '/').split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => worktree);
}

String _normalizeSearchText(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final isLetterOrDigit = RegExp(r'[a-z0-9\u4e00-\u9fff]').hasMatch(char);
    if (isLetterOrDigit) {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

Iterable<String> _searchTokens(Project project) sync* {
  final values = <String>[_projectDisplayName(project), project.worktree];

  for (final value in values) {
    for (final segment in value.split(RegExp(r'[\\/\s._-]+'))) {
      final normalizedSegment = _normalizeSearchText(segment);
      if (normalizedSegment.isNotEmpty) {
        yield normalizedSegment;
      }
    }
  }
}

bool _isSubsequenceMatch(String query, String target) {
  if (query.isEmpty) return true;
  if (target.isEmpty) return false;

  var queryIndex = 0;
  for (var i = 0; i < target.length && queryIndex < query.length; i++) {
    if (target[i] == query[queryIndex]) {
      queryIndex++;
    }
  }

  return queryIndex == query.length;
}

bool _matchesProjectQuery(Project project, String query) {
  final normalizedQuery = _normalizeSearchText(query.trim());
  if (normalizedQuery.isEmpty) return true;

  final displayName = _projectDisplayName(project);
  final normalizedDisplayName = _normalizeSearchText(displayName);
  final candidates = <String>{displayName, project.worktree};

  for (final candidate in candidates) {
    final normalizedCandidate = _normalizeSearchText(candidate);
    if (normalizedCandidate.contains(normalizedQuery)) {
      return true;
    }
  }

  if (_isSubsequenceMatch(normalizedQuery, normalizedDisplayName)) {
    return true;
  }

  for (final token in _searchTokens(project)) {
    if (_isSubsequenceMatch(normalizedQuery, token)) {
      return true;
    }
  }

  return false;
}

List<Project> _filterProjects(List<Project> projects, String query) {
  if (query.trim().isEmpty) return projects;
  return projects
      .where((project) => _matchesProjectQuery(project, query))
      .toList();
}

String _formatUpdatedTime(BuildContext context, int timestampMs) {
  final l10n = context.l10n;
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return l10n.projectListUpdatedJustNow;
  if (diff.inMinutes < 60) {
    return l10n.projectListUpdatedMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) return l10n.projectListUpdatedHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.projectListUpdatedDaysAgo(diff.inDays);

  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  if (dt.year == now.year) return '$m-$d';
  return '$y-$m-$d';
}

List<Project> _sortProjects(
  List<Project> projects,
  Map<String, int> pinnedProjects,
) {
  final sorted = List<Project>.from(projects);

  sorted.sort((a, b) {
    final aPinnedAt = pinnedProjects[a.worktree];
    final bPinnedAt = pinnedProjects[b.worktree];

    final aPinned = aPinnedAt != null;
    final bPinned = bPinnedAt != null;

    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }

    if (aPinned && bPinned) {
      final pinCompare = bPinnedAt.compareTo(aPinnedAt);
      if (pinCompare != 0) return pinCompare;
    }

    return b.time.updated.compareTo(a.time.updated);
  });

  return sorted;
}

String _connectionErrorText(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is ApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return l10n.projectListErrorAuthFailed;
    }
    if (error.statusCode >= 500) {
      return l10n.projectListErrorServerUnavailable(error.statusCode);
    }
    return l10n.projectListErrorRequestFailed(error.statusCode, error.message);
  }
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return l10n.projectListErrorCannotConnect;
  }
  return l10n.projectListErrorLoadFailed;
}

Future<void> _showProjectActionMenu(
  BuildContext context,
  WidgetRef ref,
  Project project,
  bool isPinned,
) async {
  final colorScheme = Theme.of(context).colorScheme;
  final tokens = context.tokens;

  HapticFeedback.lightImpact();

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: colorScheme.onSurface,
              ),
              title: Text(
                isPinned
                    ? context.l10n.projectListActionUnpin
                    : context.l10n.projectListActionPin,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.of(context).pop('toggle_pin'),
            ),
            SizedBox(height: tokens.radiusXs / 2),
          ],
        ),
      );
    },
  );

  if (action != 'toggle_pin') return;

  await ref.read(projectPinsProvider.notifier).togglePin(project);
}

void _openProjectChat(BuildContext context, WidgetRef ref, Project project) {
  ref.read(currentDirectoryProvider.notifier).set(project.worktree);
  context.push('/chat', extra: ChatRouteArgs(directory: project.worktree));
}

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final projectsAsync = ref.watch(projectsProvider);
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final pinnedProjectsAsync = ref.watch(projectPinsProvider);
    final contentBottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final pagePadding = tokens.pageHorizontalPadding;

    Future<void> refreshProjects() async {
      await Future.wait([
        ref.refresh(projectsProvider.future),
        ref.refresh(projectPinsProvider.future),
      ]);
    }

    void openServerConfigPage() {
      final config = asyncServerConfig.value;
      if (config != null) {
        context.push('/settings/server', extra: config);
      } else {
        context.push('/settings/server');
      }
    }

    Widget buildHeader() {
      return Padding(
        padding: EdgeInsets.fromLTRB(pagePadding, 8, pagePadding, 12),
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.projectListHeader,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showOpenProjectSheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.projectListNew,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: l10n.openProjectPlaceholderSearch,
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: tokens.mutedForeground,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: tokens.mutedForeground,
                ),
                suffixIcon: _searchQuery.trim().isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: tokens.mutedForeground,
                        ),
                      ),
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
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildPageLayout(Widget body) {
      return Column(
        children: [
          buildHeader(),
          Container(height: 1, color: tokens.border.withValues(alpha: 0.45)),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: projectsAsync.when(
          loading: () =>
              buildPageLayout(const Center(child: CircularProgressIndicator())),
          error: (error, stack) => buildPageLayout(
            RefreshIndicator(
              onRefresh: refreshProjects,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  0,
                  pagePadding,
                  contentBottomPadding,
                ),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 44,
                    color: tokens.mutedForeground.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.projectListLoadFailedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _connectionErrorText(context, error),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: openServerConfigPage,
                    icon: const Icon(Icons.settings_ethernet),
                    label: Text(l10n.projectListGoConfigureServer),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(projectsProvider);
                      ref.invalidate(projectPinsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.projectListRetryLoad),
                  ),
                ],
              ),
            ),
          ),
          data: (projects) {
            return pinnedProjectsAsync.when(
              loading: () => buildPageLayout(
                const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => buildPageLayout(
                Center(
                  child: Text(
                    '$error',
                    style: TextStyle(color: tokens.mutedForeground),
                  ),
                ),
              ),
              data: (pinnedProjects) {
                final sortedProjects = _sortProjects(projects, pinnedProjects);
                final visibleProjects = _filterProjects(
                  sortedProjects,
                  _searchQuery,
                );

                if (sortedProjects.isEmpty) {
                  return buildPageLayout(
                    RefreshIndicator(
                      onRefresh: refreshProjects,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: contentBottomPadding),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.16,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: tokens.card,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.folder_off_rounded,
                                    size: 36,
                                    color: tokens.mutedForeground.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.projectListEmpty,
                                  style: TextStyle(
                                    color: tokens.mutedForeground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.projectListPleaseAddProject,
                                  style: TextStyle(
                                    color: tokens.mutedForeground.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: openServerConfigPage,
                                  icon: const Icon(
                                    Icons.settings_ethernet_outlined,
                                  ),
                                  label: Text(
                                    l10n.projectListCheckServerConfig,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (visibleProjects.isEmpty) {
                  return buildPageLayout(
                    RefreshIndicator(
                      onRefresh: refreshProjects,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          pagePadding,
                          20,
                          pagePadding,
                          contentBottomPadding,
                        ),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.12,
                          ),
                          Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: tokens.mutedForeground.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.openProjectNoMatch,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.trim(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return buildPageLayout(
                  RefreshIndicator(
                    onRefresh: refreshProjects,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        20,
                        pagePadding,
                        contentBottomPadding,
                      ),
                      itemCount: visibleProjects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final project = visibleProjects[index];
                        final isPinned = pinnedProjects.containsKey(
                          project.worktree,
                        );
                        final displayName = _projectDisplayName(project);
                        final updatedText = _formatUpdatedTime(
                          context,
                          project.time.updated,
                        );
                        final iconColor = colorScheme.primary;
                        final iconText = displayName.trim().isEmpty
                            ? '?'
                            : displayName.trim().substring(0, 1).toUpperCase();

                        return Material(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(tokens.radiusM),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(tokens.radiusM),
                            onTap: () =>
                                _openProjectChat(context, ref, project),
                            onLongPress: () => _showProjectActionMenu(
                              context,
                              ref,
                              project,
                              isPinned,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      iconText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          project.worktree,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tokens.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isPinned) ...[
                                        Icon(
                                          Icons.push_pin,
                                          size: 14,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        updatedText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: tokens.mutedForeground
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
