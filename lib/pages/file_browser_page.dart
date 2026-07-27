import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_provider.dart';
import '../route_navigation.dart';
import '../theme/app_tokens.dart';

class FileBrowserPage extends ConsumerStatefulWidget {
  final String directory;

  const FileBrowserPage({super.key, required this.directory});

  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage> {
  late String _currentDir;
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentDir = widget.directory;
    _pathController.text = _currentDir;
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _navigateTo(String dir) {
    setState(() {
      _currentDir = dir;
      _pathController.text = dir;
    });
  }

  void _navigateUp() {
    final normalized = _currentDir.replaceAll('\\', '/');
    if (normalized.isEmpty || normalized == '/') return;
    final parent = normalized.substring(0, normalized.lastIndexOf('/'));
    if (parent.isEmpty) return;
    _navigateTo(parent);
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(fileDirectoryListingProvider(_currentDir));
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('文件浏览器'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: tokens.border.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  tooltip: '上一级',
                  onPressed: _navigateUp,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateUp,
                    child: Text(
                      _currentDir,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: tokens.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '加载失败: $error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.mutedForeground),
                  ),
                ),
              ),
              data: (nodes) {
                if (nodes.isEmpty) {
                  return Center(
                    child: Text(
                      '空目录',
                      style: TextStyle(color: tokens.mutedForeground),
                    ),
                  );
                }

                final dirs = nodes.where((n) => n.isDirectory).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                final files = nodes.where((n) => !n.isDirectory).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: dirs.length + files.length,
                  itemBuilder: (context, index) {
                    if (index < dirs.length) {
                      final dir = dirs[index];
                      return _FileTile(
                        icon: Icons.folder_rounded,
                        iconColor: Colors.amber,
                        name: dir.name,
                        absolutePath: dir.absolute,
                        onTap: () => _navigateTo(dir.absolute),
                      );
                    }
                    final file = files[index - dirs.length];
                    return _FileTile(
                      icon: Icons.insert_drive_file_outlined,
                      iconColor: tokens.mutedForeground,
                      name: file.name,
                      absolutePath: file.absolute,
                      onTap: () => context.pushFileContentByPath(file.absolute),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String absolutePath;
  final VoidCallback onTap;

  const _FileTile({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.absolutePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: onTap,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: absolutePath));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已复制: $absolutePath'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      hoverColor: tokens.accent,
    );
  }
}
