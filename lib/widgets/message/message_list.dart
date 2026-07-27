import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/session_provider.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart';
import '../../theme/app_tokens.dart';
import 'message_error_state.dart';
import 'message_bubble.dart';

enum _PendingScrollAction { none, jumpToBottom, animateToBottom }

class MessageList extends ConsumerWidget {
  final String sessionID;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageList({
    super.key,
    required this.sessionID,
    this.onNavigateToSubSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider(sessionID));
    final l10n = context.l10n;

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        if (kDebugMode) {
          debugPrint('MessageList Error: $error\n$stack');
        }
        return MessageErrorState(message: l10n.messageListLoadFailed);
      },
      data: (messages) {
        final notifier = ref.read(sessionMessagesProvider(sessionID).notifier);
        return _MessageListBody(
          messages: messages,
          getContentNotifier: notifier.contentNotifier,
          hasMore: notifier.hasMore,
          onLoadMore: () => notifier.loadMore(),
          onNavigateToSubSession: onNavigateToSubSession,
        );
      },
    );
  }
}

/// 纯消息列表渲染（可复用于子 Session 页面）
class MessageListView extends StatefulWidget {
  final List<MessageWithParts> messages;
  final ValueNotifier<MessageWithParts> Function(String)? getContentNotifier;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;
  final void Function(String sessionId)? onNavigateToSubSession;
  final double bottomDetachedThreshold;
  final Duration scrollToBottomAnimationDuration;

  const MessageListView({
    super.key,
    required this.messages,
    this.getContentNotifier,
    this.hasMore = false,
    this.onLoadMore,
    this.onNavigateToSubSession,
    this.bottomDetachedThreshold = 72,
    this.scrollToBottomAnimationDuration = const Duration(milliseconds: 220),
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListBody extends StatelessWidget {
  final List<MessageWithParts> messages;
  final ValueNotifier<MessageWithParts> Function(String)? getContentNotifier;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;
  final void Function(String sessionId)? onNavigateToSubSession;

  const _MessageListBody({
    required this.messages,
    this.getContentNotifier,
    this.hasMore = false,
    this.onLoadMore,
    this.onNavigateToSubSession,
  });

  @override
  Widget build(BuildContext context) => MessageListView(
    messages: messages,
    getContentNotifier: getContentNotifier,
    hasMore: hasMore,
    onLoadMore: onLoadMore,
    onNavigateToSubSession: onNavigateToSubSession,
  );
}

class _MessageListViewState extends State<MessageListView> {
  static const listViewKey = Key('message_list.list_view');
  static const scrollToBottomButtonKey = Key('message_list.scroll_to_bottom');
  static const scrollToBottomIgnorePointerKey = Key(
    'message_list.scroll_to_bottom_guard',
  );

  final ScrollController _scrollController = ScrollController();

  bool _autoFollowBottom = true;
  bool _isDetachedFromBottom = false;
  bool _showScrollToBottomButton = false;
  List<MessageWithParts>? _frozenMessages;
  _PendingScrollAction _pendingScrollAction = _PendingScrollAction.none;
  bool _scrollActionScheduled = false;
  bool _isLoadingMore = false;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.messages.length;
    _requestScrollAction(_PendingScrollAction.jumpToBottom);
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_scrollController.hasClients) return;

    final oldLen = oldWidget.messages.length;
    final newLen = widget.messages.length;

    // 结构未变（无增删消息），只是流式内容更新，无需计算签名
    if (oldLen == newLen && oldLen == _lastMessageCount) return;

    _lastMessageCount = newLen;

    // 加载更多或后台刷新：更新冻结列表，不影响滚动位置
    if (oldLen != newLen && _isDetachedFromBottom) {
      _frozenMessages = null; // 解除冻结，build 会用 widget.messages
    }

    if (_isDetachedFromBottom &&
        _messageListSignature(oldWidget.messages) !=
            _messageListSignature(widget.messages)) {
      return;
    }

    if (_autoFollowBottom &&
        !_isDetachedFromBottom &&
        _didBottomAffectingContentChange(oldWidget.messages, widget.messages)) {
      _requestScrollAction(_PendingScrollAction.jumpToBottom);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_scrollController.hasClients) return false;

    if (notification is ScrollUpdateNotification ||
        notification is UserScrollNotification) {
      if (_autoFollowBottom && _distanceFromBottom() > 0.5) {
        _detachFromBottom();
        return false;
      }
    } else if (notification is ScrollEndNotification) {
      if (!_autoFollowBottom &&
          _distanceFromBottom() <= widget.bottomDetachedThreshold) {
        _reattachToBottom();
        return false;
      }

      // 滑到顶部自动加载更早消息
      if (widget.hasMore && widget.onLoadMore != null && !_isLoadingMore) {
        final pos = _scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 80) {
          _isLoadingMore = true;
          widget.onLoadMore!().then((_) {
            _isLoadingMore = false;
          });
        }
      }
    }

    _syncDetachedState();
    return false;
  }

  void _syncDetachedState() {
    if (!_autoFollowBottom) {
      if (_isDetachedFromBottom && _showScrollToBottomButton) {
        return;
      }

      setState(() {
        _isDetachedFromBottom = true;
        _showScrollToBottomButton = true;
      });
      return;
    }

    final shouldDetach = _distanceFromBottom() > widget.bottomDetachedThreshold;
    if (shouldDetach == _isDetachedFromBottom &&
        shouldDetach == _showScrollToBottomButton) {
      return;
    }

    setState(() {
      _isDetachedFromBottom = shouldDetach;
      _showScrollToBottomButton = shouldDetach;
      if (shouldDetach) {
        _frozenMessages = List<MessageWithParts>.unmodifiable(widget.messages);
        return;
      }

      _frozenMessages = null;
    });

    if (!shouldDetach) {
      _requestScrollAction(_PendingScrollAction.jumpToBottom);
    }
  }

  void _detachFromBottom() {
    if (!_autoFollowBottom) {
      return;
    }

    setState(() {
      _autoFollowBottom = false;
      _isDetachedFromBottom = true;
      _showScrollToBottomButton = true;
      _frozenMessages = List<MessageWithParts>.unmodifiable(widget.messages);
    });
  }

  void _reattachToBottom() {
    setState(() {
      _autoFollowBottom = true;
      _isDetachedFromBottom = false;
      _showScrollToBottomButton = false;
      _frozenMessages = null;
    });
    _requestScrollAction(_PendingScrollAction.jumpToBottom);
  }

  double _distanceFromBottom() {
    final position = _scrollController.position;
    return (position.pixels - position.minScrollExtent).clamp(
      0.0,
      double.infinity,
    );
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
  }

  Future<void> _animateToBottom() async {
    setState(() {
      _autoFollowBottom = true;
      _frozenMessages = null;
      _isDetachedFromBottom = false;
      _showScrollToBottomButton = false;
    });
    _requestScrollAction(_PendingScrollAction.animateToBottom);
  }

  void _requestScrollAction(_PendingScrollAction action) {
    if (action == _PendingScrollAction.none) return;

    _pendingScrollAction = switch ((_pendingScrollAction, action)) {
      (_PendingScrollAction.animateToBottom, _) =>
        _PendingScrollAction.animateToBottom,
      (_, _PendingScrollAction.animateToBottom) =>
        _PendingScrollAction.animateToBottom,
      _ => _PendingScrollAction.jumpToBottom,
    };

    if (_scrollActionScheduled) {
      return;
    }
    _scrollActionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scrollActionScheduled = false;
      if (!mounted || _pendingScrollAction == _PendingScrollAction.none) {
        return;
      }
      if (!_scrollController.hasClients) {
        _requestScrollAction(_pendingScrollAction);
        return;
      }

      final actionToRun = _pendingScrollAction;
      _pendingScrollAction = _PendingScrollAction.none;

      switch (actionToRun) {
        case _PendingScrollAction.none:
          return;
        case _PendingScrollAction.jumpToBottom:
          _jumpToBottom();
          _syncDetachedState();
          break;
        case _PendingScrollAction.animateToBottom:
          await _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: widget.scrollToBottomAnimationDuration,
            curve: Curves.easeOutCubic,
          );
          if (mounted) {
            _syncDetachedState();
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sourceMessages = (!_autoFollowBottom && _isDetachedFromBottom)
        ? (_frozenMessages ?? widget.messages)
        : widget.messages;
    final visibleMessages = sourceMessages
        .where((message) => !_isSyntheticOnlyUserMessage(message))
        .toList();

    if (visibleMessages.isEmpty) {
      return Center(
        child: Builder(
          builder: (context) {
            final tokens = context.tokens;
            return Text(
              'No messages yet',
              style: TextStyle(color: tokens.mutedForeground),
            );
          },
        ),
      );
    }

    final tokens = context.tokens;
    final itemCount = visibleMessages.length;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: ListView.builder(
            key: listViewKey,
            controller: _scrollController,
            reverse: true,
            cacheExtent: 500,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final messageWithParts =
                  visibleMessages[visibleMessages.length - 1 - index];
              final prevIndex = visibleMessages.length - 2 - index;
              final prevMessage = prevIndex >= 0
                  ? visibleMessages[prevIndex]
                  : null;
              final prevIsUser = prevMessage?.info is UserMessage;

              final msgId = _messageId(messageWithParts);
              final getNotifier = widget.getContentNotifier;

              if (getNotifier != null) {
                final contentNotifier = getNotifier(msgId);
                return ValueListenableBuilder<MessageWithParts>(
                  valueListenable: contentNotifier,
                  builder: (context, liveMessage, child) => MessageBubble(
                    key: ValueKey(msgId),
                    messageWithParts: liveMessage,
                    prevIsUser: prevIsUser,
                    isLatestMessage: index == 0,
                    onNavigateToSubSession: widget.onNavigateToSubSession,
                  ),
                );
              }

              return MessageBubble(
                key: ValueKey(msgId),
                messageWithParts: messageWithParts,
                prevIsUser: prevIsUser,
                isLatestMessage: index == 0,
                onNavigateToSubSession: widget.onNavigateToSubSession,
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: IgnorePointer(
            key: scrollToBottomIgnorePointerKey,
            ignoring: !_showScrollToBottomButton,
            child: AnimatedOpacity(
              opacity: _showScrollToBottomButton ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.accentForeground,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: IconButton(
                  key: scrollToBottomButtonKey,
                  tooltip: 'Scroll to bottom',
                  onPressed: _animateToBottom,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: tokens.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _messageId(MessageWithParts message) {
  final info = message.info;
  if (info is UserMessage) {
    return info.id;
  }
  if (info is AssistantMessage) {
    return info.id;
  }
  return info.hashCode.toString();
}

bool _isSyntheticOnlyUserMessage(MessageWithParts message) {
  if (message.info is! UserMessage) return false;
  if (message.parts.isEmpty) return false;

  for (final part in message.parts) {
    if (part is TextPart) {
      if (part.synthetic != true) return false;
      continue;
    }
    return false;
  }
  return true;
}

bool _didBottomAffectingContentChange(
  List<MessageWithParts> previous,
  List<MessageWithParts> next,
) {
  // 只找最后一个可见消息，避免全量过滤
  MessageWithParts? lastPrev;
  MessageWithParts? lastNext;
  int prevCount = 0;
  int nextCount = 0;

  for (final m in previous.reversed) {
    if (!_isSyntheticOnlyUserMessage(m)) {
      if (lastPrev == null) lastPrev = m;
      prevCount++;
    }
  }
  for (final m in next.reversed) {
    if (!_isSyntheticOnlyUserMessage(m)) {
      if (lastNext == null) lastNext = m;
      nextCount++;
    }
  }

  if (prevCount != nextCount) return true;
  if (lastPrev == null || lastNext == null) return false;

  return _bottomAnchorSignature(lastPrev) != _bottomAnchorSignature(lastNext);
}

String _messageListSignature(List<MessageWithParts> messages) {
  // 只需要第一个和最后一个可见消息的签名（用于判断是否冻结视图）
  MessageWithParts? firstVis;
  MessageWithParts? lastVis;
  int count = 0;
  for (final m in messages) {
    if (_isSyntheticOnlyUserMessage(m)) continue;
    count++;
    lastVis = m;
    if (firstVis == null) firstVis = m;
  }
  if (firstVis == null) return 'empty';

  return '$count:${_messageId(firstVis)}:${_bottomAnchorSignature(lastVis!)}';
}

String _bottomAnchorSignature(MessageWithParts message) {
  final buffer = StringBuffer(_messageId(message));
  for (final part in message.parts) {
    if (part is TextPart) {
      buffer
        ..write('|text:')
        ..write(part.id)
        ..write(':')
        ..write(part.text.length);
      continue;
    }
    if (part is ToolPart) {
      buffer
        ..write('|tool:')
        ..write(part.id)
        ..write(':')
        ..write(part.state);
      continue;
    }
    buffer
      ..write('|')
      ..write(part.runtimeType);
  }
  return buffer.toString();
}
