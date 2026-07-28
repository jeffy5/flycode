import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../service/api/models/command.dart';
import 'chat_suggestion_popup.dart';

class CommandPanelController extends SuggestionPanelController {
  @override
  bool visible = false;
  bool isDragging = false;
  double dragOffset = 0;
  String query = '';
  List<Command> filteredCommands = const [];

  int _showCount = 0;

  @override
  int get showCount => _showCount;

  @override
  int get itemCount => filteredCommands.length;

  @override
  String get signature => '$query:${filteredCommands.length}';

  void show(List<Command> commands, {String query = ''}) {
    filteredCommands = List<Command>.unmodifiable(commands);
    this.query = query;
    dragOffset = 0;
    isDragging = false;
    if (!visible) {
      visible = true;
      _showCount += 1;
    }
    notifyListeners();
  }

  void update(List<Command> commands, {String? query}) {
    filteredCommands = List<Command>.unmodifiable(commands);
    if (query != null) {
      this.query = query;
    }
    notifyListeners();
  }

  void hide() {
    if (!visible &&
        filteredCommands.isEmpty &&
        dragOffset == 0 &&
        !isDragging &&
        query.isEmpty) {
      return;
    }
    visible = false;
    filteredCommands = const [];
    query = '';
    dragOffset = 0;
    isDragging = false;
    notifyListeners();
  }

  void beginDrag() {
    if (isDragging) return;
    isDragging = true;
    notifyListeners();
  }

  void updateDrag(double delta) {
    final nextOffset = (dragOffset + delta).clamp(0.0, double.infinity);
    if (nextOffset == dragOffset && isDragging) return;
    dragOffset = nextOffset;
    isDragging = true;
    notifyListeners();
  }

  bool endDrag({double dismissThreshold = 16}) {
    final shouldDismiss = dragOffset > dismissThreshold;
    isDragging = false;
    notifyListeners();
    return shouldDismiss;
  }

  void resetDrag() {
    if (dragOffset == 0 && !isDragging) return;
    dragOffset = 0;
    isDragging = false;
    notifyListeners();
  }
}

class ChatCommandPopup extends StatelessWidget {
  const ChatCommandPopup({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final CommandPanelController controller;
  final ValueChanged<Command> onSelect;

  @override
  Widget build(BuildContext context) {
    return ChatSuggestionPopup(
      controller: controller,
      listKey: const Key('chat_command_popup.list'),
      surfaceKey: const Key('chat_command_popup.surface'),
      dragHandleKey: const Key('chat_command_popup.drag_handle'),
      itemBuilder: (context, index) {
        final command = controller.filteredCommands[index];
        return CommandSuggestionTile(
          command: command,
          emphasized: index == 0,
          onTap: () => onSelect(command),
        );
      },
    );
  }
}

class CommandSuggestionTile extends StatefulWidget {
  const CommandSuggestionTile({
    super.key,
    required this.command,
    required this.emphasized,
    required this.onTap,
  });

  final Command command;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  State<CommandSuggestionTile> createState() => _CommandSuggestionTileState();
}

class _CommandSuggestionTileState extends State<CommandSuggestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final description = widget.command.description;
    final hasDescription = description != null && description.isNotEmpty;
    final tileRadius = BorderRadius.circular(20);
    final baseColor = widget.emphasized ? tokens.card : Colors.transparent;
    final hoverColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
      ),
      theme.colorScheme.surface,
    );
    final tileColor = _isHovered ? hoverColor : baseColor;

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '/${widget.command.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
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
          ),
        ),
      ),
    );
  }
}

Widget buildCommandSuggestionListForTest({
  required List<Command> commands,
  required ValueChanged<Command> onSelect,
}) {
  final controller = CommandPanelController()..show(commands);
  return SizedBox(
    height: 420,
    child: ChatCommandPopup(controller: controller, onSelect: onSelect),
  );
}
