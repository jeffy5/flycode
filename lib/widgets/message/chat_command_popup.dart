import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../service/api/models/command.dart';

class CommandPanelController extends ChangeNotifier {
  bool visible = false;
  bool isDragging = false;
  double dragOffset = 0;
  String query = '';
  List<Command> filteredCommands = const [];

  int _showCount = 0;

  int get showCount => _showCount;

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

class ChatCommandPopup extends StatefulWidget {
  const ChatCommandPopup({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final CommandPanelController controller;
  final ValueChanged<Command> onSelect;

  @override
  State<ChatCommandPopup> createState() => _ChatCommandPopupState();
}

class _ChatCommandPopupState extends State<ChatCommandPopup>
    with SingleTickerProviderStateMixin {
  static const _horizontalPadding = 12.0;
  static const _listPadding = EdgeInsets.fromLTRB(6, 0, 6, 6);
  static const _tileHeight = 58.0;
  static const _tileSpacing = 2.0;
  static const _dragHandleHeight = 18.0;
  static const _defaultVisibleRows = 4;

  late final AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late DraggableScrollableController _sheetController;
  bool _present = false;
  String _sheetSignature = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _sheetController = DraggableScrollableController();
    _slideAnimation = const AlwaysStoppedAnimation<double>(1);
    widget.controller.addListener(_handleControllerChanged);
    _sheetSignature = _commandSignature();
  }

  @override
  void didUpdateWidget(covariant ChatCommandPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final visible =
        widget.controller.visible &&
        widget.controller.filteredCommands.isNotEmpty;
    final nextSignature = _commandSignature();

    if (nextSignature != _sheetSignature) {
      final previousController = _sheetController;
      _sheetController = DraggableScrollableController();
      _sheetSignature = nextSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousController.dispose();
      });
    }

    if (visible) {
      if (!_present) {
        _playEnterAnimation(firstTime: widget.controller.showCount <= 1);
      } else {
        setState(() {});
      }
      return;
    }

    if (_present) {
      _playExitAnimation();
    } else {
      setState(() {});
    }
  }

  String _commandSignature() =>
      '${widget.controller.query}:${widget.controller.filteredCommands.length}';

  void _playEnterAnimation({required bool firstTime}) {
    setState(() {
      _present = true;
    });
    _animationController.stop();
    _animationController.duration = Duration(
      milliseconds: firstTime ? 320 : 150,
    );
    _slideAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: firstTime ? Curves.easeOutBack : Curves.easeOutCubic,
      ),
    );
    _animationController.value = 0;
    _animationController.forward();
  }

  void _playExitAnimation() {
    _animationController.stop();
    _animationController.duration = const Duration(milliseconds: 150);
    final begin = _currentVisualOffset(0);
    _slideAnimation = Tween<double>(begin: begin, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.value = 0;
    _animationController.forward().whenComplete(() {
      if (!mounted || widget.controller.visible) return;
      setState(() {
        _present = false;
      });
    });
  }

  double _initialChildSize(double availableHeight, int itemCount) {
    if (availableHeight <= 0) return 1;
    final visibleCount = itemCount.clamp(1, _defaultVisibleRows);
    final exactContentHeight = _contentHeightForItems(itemCount);
    final defaultHeight = _contentHeightForItems(visibleCount);
    final targetHeight = itemCount <= _defaultVisibleRows
        ? exactContentHeight
        : defaultHeight;
    return (targetHeight / availableHeight).clamp(0.0, 1.0);
  }

  double _contentHeightForItems(int itemCount) {
    final safeCount = itemCount.clamp(1, 1 << 20);
    return _dragHandleHeight +
        _listPadding.vertical +
        (_tileHeight * safeCount) +
        (_tileSpacing * (safeCount - 1));
  }

  double _currentVisualOffset(double maxHeight) {
    if (maxHeight <= 0) return 0;
    return _slideAnimation.value * maxHeight;
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    double minChildSize,
  ) {
    return false;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _sheetController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_present &&
        (!widget.controller.visible ||
            widget.controller.filteredCommands.isEmpty)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        if (availableHeight <= 0) {
          return const SizedBox.shrink();
        }

        final commands = widget.controller.filteredCommands;
        final initialChildSize = _initialChildSize(
          availableHeight,
          commands.length,
        );
        final maxChildSize = 1.0;
        final effectiveExtent = _sheetController.isAttached
            ? _sheetController.size
            : initialChildSize;
        final popupHeight = availableHeight * effectiveExtent;

        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _animationController,
              widget.controller,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _currentVisualOffset(popupHeight)),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              child: SizedBox(
                height: availableHeight,
                child: DraggableScrollableSheet(
                  key: ValueKey<String>(_sheetSignature),
                  controller: _sheetController,
                  expand: false,
                  initialChildSize: initialChildSize,
                  minChildSize: initialChildSize,
                  maxChildSize: maxChildSize,
                  builder: (context, scrollController) {
                    return _CommandPopupSurface(
                      commands: commands,
                      scrollController: scrollController,
                      onSelect: widget.onSelect,
                      onPanelDragEnd: () {},
                      onPanelDragUpdate: (delta) {
                        if (!_sheetController.isAttached) {
                          return;
                        }
                        if (delta < 0 && _sheetController.size < maxChildSize) {
                          final nextSize =
                              (_sheetController.size +
                                      (-delta / availableHeight))
                                  .clamp(initialChildSize, maxChildSize);
                          _sheetController.jumpTo(nextSize);
                        }
                      },
                      scrollNotificationPredicate: (notification) =>
                          _handleScrollNotification(
                            notification,
                            initialChildSize,
                          ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommandPopupSurface extends StatelessWidget {
  const _CommandPopupSurface({
    required this.commands,
    required this.scrollController,
    required this.onSelect,
    required this.onPanelDragUpdate,
    required this.onPanelDragEnd,
    required this.scrollNotificationPredicate,
  });

  final List<Command> commands;
  final ScrollController scrollController;
  final ValueChanged<Command> onSelect;
  final ValueChanged<double> onPanelDragUpdate;
  final VoidCallback onPanelDragEnd;
  final bool Function(ScrollNotification notification)
  scrollNotificationPredicate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final sheetRadius = BorderRadius.circular(tokens.radiusL);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tokens.card.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.22 : 0.18,
          ),
          theme.colorScheme.surface,
        ),
        borderRadius: sheetRadius,
        border: Border.all(color: tokens.border.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            offset: const Offset(0, 14),
            blurRadius: 34,
          ),
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: sheetRadius,
        child: Material(
          color: Colors.transparent,
          child: Column(
            key: const Key('chat_command_popup.surface'),
            children: [
              GestureDetector(
                key: const Key('chat_command_popup.drag_handle'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) =>
                    onPanelDragUpdate(details.delta.dy),
                child: SizedBox(
                  height: 18,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.border.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: scrollNotificationPredicate,
                  child: ListView.builder(
                    key: const Key('chat_command_popup.list'),
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                    itemCount: commands.length,
                    itemBuilder: (ctx, i) {
                      final command = commands[i];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == commands.length - 1 ? 0 : 2,
                        ),
                        child: SizedBox(
                          height: 58,
                          child: CommandSuggestionTile(
                            command: command,
                            emphasized: i == 0,
                            onTap: () => onSelect(command),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
