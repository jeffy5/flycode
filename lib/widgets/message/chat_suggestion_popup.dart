import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

abstract class SuggestionPanelController extends ChangeNotifier {
  bool get visible;
  int get showCount;
  int get itemCount;
  String get signature;
}

class ChatSuggestionPopup extends StatefulWidget {
  const ChatSuggestionPopup({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.listKey,
    required this.surfaceKey,
    required this.dragHandleKey,
  });

  final SuggestionPanelController controller;
  final IndexedWidgetBuilder itemBuilder;
  final Key listKey;
  final Key surfaceKey;
  final Key dragHandleKey;

  @override
  State<ChatSuggestionPopup> createState() => _ChatSuggestionPopupState();
}

class _ChatSuggestionPopupState extends State<ChatSuggestionPopup>
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
    _sheetSignature = widget.controller.signature;
    if (widget.controller.visible && widget.controller.itemCount > 0) {
      _present = true;
      _slideAnimation = const AlwaysStoppedAnimation<double>(0);
    }
  }

  @override
  void didUpdateWidget(covariant ChatSuggestionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _sheetSignature = widget.controller.signature;
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final visible =
        widget.controller.visible && widget.controller.itemCount > 0;
    final nextSignature = widget.controller.signature;

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

  void _playEnterAnimation({required bool firstTime}) {
    setState(() => _present = true);
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
      setState(() => _present = false);
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
        (!widget.controller.visible || widget.controller.itemCount == 0)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        if (availableHeight <= 0) return const SizedBox.shrink();

        final itemCount = widget.controller.itemCount;
        final initialChildSize = _initialChildSize(availableHeight, itemCount);
        const maxChildSize = 1.0;
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
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _currentVisualOffset(popupHeight)),
              child: child,
            ),
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
                  builder: (context, scrollController) =>
                      _SuggestionPopupSurface(
                        itemCount: itemCount,
                        itemBuilder: widget.itemBuilder,
                        scrollController: scrollController,
                        listKey: widget.listKey,
                        surfaceKey: widget.surfaceKey,
                        dragHandleKey: widget.dragHandleKey,
                        onPanelDragUpdate: (delta) {
                          if (!_sheetController.isAttached || delta >= 0) {
                            return;
                          }
                          final nextSize =
                              (_sheetController.size +
                                      (-delta / availableHeight))
                                  .clamp(initialChildSize, maxChildSize);
                          _sheetController.jumpTo(nextSize);
                        },
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuggestionPopupSurface extends StatelessWidget {
  const _SuggestionPopupSurface({
    required this.itemCount,
    required this.itemBuilder,
    required this.scrollController,
    required this.listKey,
    required this.surfaceKey,
    required this.dragHandleKey,
    required this.onPanelDragUpdate,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController scrollController;
  final Key listKey;
  final Key surfaceKey;
  final Key dragHandleKey;
  final ValueChanged<double> onPanelDragUpdate;

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
            key: surfaceKey,
            children: [
              GestureDetector(
                key: dragHandleKey,
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
                child: ListView.builder(
                  key: listKey,
                  controller: scrollController,
                  padding: _ChatSuggestionPopupState._listPadding,
                  itemCount: itemCount,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == itemCount - 1 ? 0 : 2,
                    ),
                    child: SizedBox(
                      height: _ChatSuggestionPopupState._tileHeight,
                      child: itemBuilder(context, index),
                    ),
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
