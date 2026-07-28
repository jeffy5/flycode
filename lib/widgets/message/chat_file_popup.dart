import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'chat_suggestion_popup.dart';

class FileSuggestion {
  const FileSuggestion({
    required this.path,
    required this.name,
    required this.parentPath,
    required this.isDirectory,
  });

  factory FileSuggestion.fromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final isDirectory = normalized.endsWith('/');
    final parts = normalized
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    final name = parts.isEmpty ? normalized : parts.last;
    final parentPath = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join('/')
        : null;
    return FileSuggestion(
      path: path,
      name: name,
      parentPath: parentPath,
      isDirectory: isDirectory,
    );
  }

  final String path;
  final String name;
  final String? parentPath;
  final bool isDirectory;
}

String fileNameFromPath(String path) => FileSuggestion.fromPath(path).name;

class FilePanelController extends SuggestionPanelController {
  bool _visible = false;
  int _showCount = 0;
  String query = '';
  List<FileSuggestion> suggestions = const [];
  int highlightedIndex = 0;

  @override
  bool get visible => _visible;

  @override
  int get showCount => _showCount;

  @override
  int get itemCount => suggestions.length;

  @override
  String get signature =>
      '$query:${suggestions.map((item) => item.path).join('|')}';

  void show(List<String> paths, {required String query}) {
    suggestions = paths.map(FileSuggestion.fromPath).toList(growable: false);
    this.query = query;
    highlightedIndex = 0;
    if (suggestions.isEmpty) {
      _visible = false;
    } else if (!_visible) {
      _visible = true;
      _showCount += 1;
    }
    notifyListeners();
  }

  void hide() {
    if (!_visible && suggestions.isEmpty && query.isEmpty) return;
    _visible = false;
    suggestions = const [];
    query = '';
    highlightedIndex = 0;
    notifyListeners();
  }

  void moveHighlight(int delta) {
    if (suggestions.isEmpty) return;
    final next = (highlightedIndex + delta).clamp(0, suggestions.length - 1);
    if (next == highlightedIndex) return;
    highlightedIndex = next;
    notifyListeners();
  }

  String? get highlightedPath =>
      suggestions.isEmpty ? null : suggestions[highlightedIndex].path;
}

class ChatFilePopup extends StatelessWidget {
  const ChatFilePopup({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final FilePanelController controller;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ChatSuggestionPopup(
      controller: controller,
      listKey: const Key('chat_file_popup.list'),
      surfaceKey: const Key('chat_file_popup.surface'),
      dragHandleKey: const Key('chat_file_popup.drag_handle'),
      itemBuilder: (context, index) {
        final suggestion = controller.suggestions[index];
        return FileSuggestionTile(
          suggestion: suggestion,
          emphasized: index == controller.highlightedIndex,
          onTap: () => onSelect(suggestion.path),
        );
      },
    );
  }
}

class FileSuggestionTile extends StatefulWidget {
  const FileSuggestionTile({
    super.key,
    required this.suggestion,
    required this.emphasized,
    required this.onTap,
  });

  final FileSuggestion suggestion;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  State<FileSuggestionTile> createState() => _FileSuggestionTileState();
}

class _FileSuggestionTileState extends State<FileSuggestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final tileRadius = BorderRadius.circular(20);
    final baseColor = widget.emphasized ? tokens.card : Colors.transparent;
    final hoverColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
      ),
      theme.colorScheme.surface,
    );
    final tileColor = _isHovered ? hoverColor : baseColor;
    final suggestion = widget.suggestion;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(color: tileColor, borderRadius: tileRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: tileRadius,
            hoverColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.10),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(tokens.radiusXs),
                    ),
                    child: Icon(
                      suggestion.isDirectory
                          ? Icons.folder_rounded
                          : Icons.insert_drive_file_outlined,
                      key: ValueKey<String>(
                        suggestion.isDirectory ? 'directory-icon' : 'file-icon',
                      ),
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        if (suggestion.parentPath != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            suggestion.parentPath!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              color: tokens.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildFileSuggestionListForTest({
  required List<String> paths,
  required ValueChanged<String> onSelect,
}) {
  final controller = FilePanelController()..show(paths, query: '');
  return SizedBox(
    height: 420,
    child: ChatFilePopup(controller: controller, onSelect: onSelect),
  );
}
