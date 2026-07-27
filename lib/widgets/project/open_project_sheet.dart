import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../models/chat_route_args.dart';
import '../../providers/current_directory_provider.dart';
import '../../service/api/api_client.dart';
import '../../service/api/file_api.dart';
import '../../service/api/models/file_node.dart';
import '../../service/api/project_api.dart';
import '../../theme/app_tokens.dart';

// ---------------------------------------------------------------------------
// 公开入口：显示打开项目底部 Sheet
// ---------------------------------------------------------------------------

Future<void> showOpenProjectSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OpenProjectSheet(),
  );
}

// ---------------------------------------------------------------------------
// 内部 Sheet 实现
// ---------------------------------------------------------------------------

class _OpenProjectSheet extends ConsumerStatefulWidget {
  const _OpenProjectSheet();

  @override
  ConsumerState<_OpenProjectSheet> createState() => _OpenProjectSheetState();
}

class _OpenProjectSheetState extends ConsumerState<_OpenProjectSheet> {
  static const double _resultAreaHeight = 320;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 搜索结果：每一条都是一个绝对路径
  List<String> _results = [];
  bool _loading = false;
  String? _error;

  // 选中后正在确认（调用 /project/current）
  bool _confirming = false;

  Timer? _debounce;

  // 路径导航模式的目录缓存：directory -> List<FileNode>
  final Map<String, List<FileNode>> _dirCache = {};
  String? _homeDir;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 输入处理
  // ---------------------------------------------------------------------------

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final isPathMode = _isPathInput(input);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await ref.read(apiClientProvider.future);
      final fileApi = FileApi(client);

      List<String> results;
      if (isPathMode) {
        results = await _navigatePath(fileApi, input);
      } else {
        // 关键词搜索模式：不传 directory，服务端用 process.cwd()
        final relPaths = await fileApi.findDirectory(input);
        results = relPaths;
      }

      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : e.toString().contains('resolve_home_failed')
            ? context.l10n.openProjectErrorResolveHome
            : e.toString();
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 判断是否为路径输入模式
  // ---------------------------------------------------------------------------

  bool _isPathInput(String input) {
    return input.startsWith('/') ||
        input.startsWith('~') ||
        input.contains('/');
  }

  // ---------------------------------------------------------------------------
  // 路径导航模式：逐段遍历，返回最终匹配的绝对路径列表
  // ---------------------------------------------------------------------------

  Future<List<String>> _navigatePath(FileApi fileApi, String input) async {
    final normalizedInput = _normalizePath(input);
    final String rootDir;
    final List<String> remainingSegments;

    if (normalizedInput == '~' || normalizedInput.startsWith('~/')) {
      final homeDir = await _resolveHomeDirectory(fileApi);
      rootDir = homeDir;
      if (normalizedInput == '~') {
        remainingSegments = [];
      } else {
        final tail = normalizedInput.substring(2);
        remainingSegments = _splitPath(
          tail,
        ).where((s) => s.isNotEmpty).toList();
      }
    } else if (normalizedInput.startsWith('/')) {
      rootDir = '/';
      remainingSegments = _splitPath(
        normalizedInput,
      ).where((s) => s.isNotEmpty).toList();
    } else {
      // 含 / 但不以 / 或 ~ 开头（如 "src/comp"）
      rootDir = '.';
      remainingSegments = _splitPath(
        normalizedInput,
      ).where((s) => s.isNotEmpty).toList();
    }

    // 逐层深入
    String currentDir = rootDir;
    final allSegments = remainingSegments;

    // 如果输入以 / 或 ~ 结尾（用户刚输入了分隔符），
    // 则列出当前目录内容
    final endsWithSlash =
        normalizedInput.endsWith('/') ||
        normalizedInput == '~' ||
        normalizedInput == '/';

    if (endsWithSlash) {
      // 逐段导航直到最后一段
      for (final seg in allSegments) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        final dirs = children.where((n) => n.isDirectory).toList();
        final match = _fuzzyFirst(dirs, seg);
        if (match == null) return [];
        currentDir = match.absolute;
      }
      // 列出当前目录内容
      final children = await _cachedListDirectory(fileApi, currentDir);
      return children
          .where((n) => n.isDirectory)
          .map((n) => n.absolute)
          .toList();
    } else {
      // 最后一段是筛选词，前面的段用于导航
      if (allSegments.isEmpty) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        return children
            .where((n) => n.isDirectory)
            .map((n) => n.absolute)
            .toList();
      }

      final navigationSegments = allSegments.sublist(0, allSegments.length - 1);
      final filterSegment = allSegments.last;

      for (final seg in navigationSegments) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        final dirs = children.where((n) => n.isDirectory).toList();
        final match = _fuzzyFirst(dirs, seg);
        if (match == null) return [];
        currentDir = match.absolute;
      }

      // 在当前目录用最后一段做模糊过滤
      final children = await _cachedListDirectory(fileApi, currentDir);
      final dirs = children.where((n) => n.isDirectory).toList();
      final filtered = _fuzzyFilter(dirs, filterSegment);
      return filtered.map((n) => n.absolute).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  List<String> _splitPath(String path) {
    return path.split('/');
  }

  String _normalizePath(String path) {
    return path.replaceAll('\\', '/');
  }

  Future<String> _resolveHomeDirectory(FileApi fileApi) async {
    final cached = _homeDir;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final fromPathApi = await fileApi.resolveHomeDirectory();
    if (fromPathApi != null && fromPathApi.isNotEmpty) {
      _homeDir = fromPathApi;
      return fromPathApi;
    }

    final currentDirectory = ref.read(currentDirectoryProvider);
    final fromProject = _inferHomeFromPath(currentDirectory);
    if (fromProject != null) {
      _homeDir = fromProject;
      return fromProject;
    }

    final cwdNodes = await _cachedListDirectory(fileApi, '.');
    final cwd = _inferDirectoryFromNodes(cwdNodes);
    final fromCwd = _inferHomeFromPath(cwd);
    if (fromCwd != null) {
      _homeDir = fromCwd;
      return fromCwd;
    }

    throw Exception('resolve_home_failed');
  }

  String? _inferDirectoryFromNodes(List<FileNode> nodes) {
    for (final node in nodes) {
      final absolute = _normalizePath(node.absolute);
      final relative = _normalizePath(node.path);
      if (absolute.isEmpty || relative.isEmpty) continue;
      final suffix = '/$relative';
      if (!absolute.endsWith(suffix)) continue;
      final base = absolute.substring(0, absolute.length - suffix.length);
      if (base.isNotEmpty) return base;
    }
    return null;
  }

  String? _inferHomeFromPath(String? path) {
    if (path == null || path.isEmpty) return null;

    final normalized = _normalizePath(path);
    final parts = normalized.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 2) return null;

    if (parts.first == 'Users') {
      return '/Users/${parts[1]}';
    }

    if (parts.first == 'home') {
      return '/home/${parts[1]}';
    }

    if (parts.length >= 3 && parts[0].endsWith(':') && parts[1] == 'Users') {
      return '${parts[0]}/Users/${parts[2]}';
    }

    return null;
  }

  String _displayPath(String absolutePath) {
    final input = _normalizePath(_controller.text.trim());
    if (!(input == '~' || input.startsWith('~/'))) {
      return absolutePath;
    }

    final home = _homeDir;
    if (home == null || home.isEmpty) {
      return absolutePath;
    }

    final normalizedAbsolute = _normalizePath(absolutePath);
    final normalizedHome = _normalizePath(home);
    if (normalizedAbsolute == normalizedHome) {
      return '~';
    }
    final prefix = '$normalizedHome/';
    if (normalizedAbsolute.startsWith(prefix)) {
      return '~/${normalizedAbsolute.substring(prefix.length)}';
    }
    return absolutePath;
  }

  Future<List<FileNode>> _cachedListDirectory(
    FileApi fileApi,
    String directory,
  ) async {
    if (_dirCache.containsKey(directory)) {
      return _dirCache[directory]!;
    }
    final nodes = await fileApi.listDirectory(directory);
    _dirCache[directory] = nodes;
    return nodes;
  }

  /// 简单模糊匹配：返回 name 包含 [query]（不区分大小写）的第一个结果
  FileNode? _fuzzyFirst(List<FileNode> nodes, String query) {
    if (query.isEmpty) return nodes.isNotEmpty ? nodes.first : null;
    final lower = query.toLowerCase();
    // 优先精确匹配，其次 startsWith，其次 contains
    FileNode? exact = nodes
        .where((n) => n.name.toLowerCase() == lower)
        .firstOrNull;
    if (exact != null) return exact;
    FileNode? starts = nodes
        .where((n) => n.name.toLowerCase().startsWith(lower))
        .firstOrNull;
    if (starts != null) return starts;
    return nodes.where((n) => n.name.toLowerCase().contains(lower)).firstOrNull;
  }

  /// 返回 name 包含 [query]（不区分大小写）的所有节点
  List<FileNode> _fuzzyFilter(List<FileNode> nodes, String query) {
    if (query.isEmpty) return nodes;
    final lower = query.toLowerCase();
    return nodes.where((n) => n.name.toLowerCase().contains(lower)).toList();
  }

  // ---------------------------------------------------------------------------
  // 确认选择目录
  // ---------------------------------------------------------------------------

  Future<void> _selectDirectory(String absolutePath) async {
    if (_confirming) return;
    setState(() => _confirming = true);

    try {
      final project = ref
          .read(projectsProvider.notifier)
          .addProjectByDirectory(absolutePath);

      if (!mounted) return;

      ref.read(currentDirectoryProvider.notifier).set(project.worktree);

      if (!mounted) return;

      // 先关闭 Sheet，再在下一帧处理后续导航，避免 Navigator 锁冲突。
      Navigator.of(context).pop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push(
          '/chat',
          extra: ChatRouteArgs(directory: project.worktree),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      final l10n = context.l10n;
      final tokens = context.tokens;
      final msg = l10n.openProjectErrorOpenFailed(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: tokens.errorSoftForeground,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusM),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 标题
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pagePadding),
              child: Row(
                children: [
                  Text(
                    context.l10n.openProjectTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_confirming)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 搜索输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_confirming,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: context.l10n.openProjectInputHint,
                  hintStyle: TextStyle(
                    color: tokens.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: tokens.mutedForeground,
                    size: 20,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: tokens.mutedForeground,
                            size: 18,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _error = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: tokens.accent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // 进度条
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              )
            else
              const SizedBox(height: 2),

            const SizedBox(height: 4),

            // 结果区域
            _buildResultArea(colorScheme),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea(ColorScheme colorScheme) {
    return SizedBox(
      height: _resultAreaHeight,
      child: _buildResultContent(colorScheme),
    );
  }

  Widget _buildResultContent(ColorScheme colorScheme) {
    final pagePadding = context.tokens.pageHorizontalPadding;

    // 错误状态
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pagePadding),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.tokens.errorSoftForeground,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: context.tokens.errorSoftForeground,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 空状态（未输入或无结果）
    if (_results.isEmpty && !_loading) {
      if (_controller.text.trim().isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 40,
                color: context.tokens.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.openProjectPlaceholderSearch,
                style: TextStyle(
                  color: context.tokens.mutedForeground,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.openProjectPlaceholderPathSupport,
                style: TextStyle(
                  color: context.tokens.mutedForeground.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Text(
            context.l10n.openProjectNoMatch,
            style: TextStyle(
              color: context.tokens.mutedForeground,
              fontSize: 13,
            ),
          ),
        );
      }
    }

    // 结果列表
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final path = _results[index];
        final displayPath = _displayPath(path);
        final parts = path.replaceAll('\\', '/').split('/');
        final name = parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _confirming ? null : () => _selectDirectory(path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      size: 20,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.tokens.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: context.tokens.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
