import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../../service/api/models/parts.dart';
import '../../theme/app_tokens.dart';
import 'code_block_widget.dart';
import 'message_markdown_theme.dart';
import 'tool_use_widget.dart';

class MessagePart extends StatelessWidget {
  final Object part;
  final bool isUser;
  final bool isStreaming;
  final bool animateText;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessagePart({
    super.key,
    required this.part,
    required this.isUser,
    this.isStreaming = false,
    this.animateText = false,
    this.onNavigateToSubSession,
  });

  @override
  Widget build(BuildContext context) {
    if (part is CompactionPart) {
      return const _CompactionDivider();
    }
    if (part is TextPart) {
      final textPart = part as TextPart;
      if (textPart.synthetic == true && !isStreaming) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _TypewriterMarkdownText(
          key: ValueKey(textPart.id),
          text: textPart.text,
          animate: !isUser && animateText,
        ),
      );
    } else if (part is ToolPart) {
      return ToolUseWidget(
        toolPart: part as ToolPart,
        onNavigateToSubSession: onNavigateToSubSession,
      );
    } else if (part is FilePart) {
      final filePart = part as FilePart;
      if (filePart.mime.startsWith('image/')) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ImagePartWidget(url: filePart.url),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

const double kMessageImageThumbnailSize = 64;
const Key kMessageImageGalleryKey = ValueKey('message-image-gallery');

class _TypewriterMarkdownText extends StatefulWidget {
  final String text;
  final bool animate;

  const _TypewriterMarkdownText({
    super.key,
    required this.text,
    required this.animate,
  });

  @override
  State<_TypewriterMarkdownText> createState() =>
      _TypewriterMarkdownTextState();
}

class _TypewriterMarkdownTextState extends State<_TypewriterMarkdownText> {
  static const Duration _tick = Duration(milliseconds: 24);
  static const Duration _streamingLag = Duration(milliseconds: 320);

  Timer? _timer;
  List<String> _chars = const [];
  int _visibleCount = 0;
  DateTime? _lastLengthUpdateAt;
  double _incomingCharsPerSecond = 24;
  ValueListenable<bool>? _isScrollingListenable;
  bool _isUserScrolling = false;
  bool _pendingScrollStateSync = false;

  @override
  void initState() {
    super.initState();
    _chars = widget.text.characters.toList();
    _visibleCount = widget.animate ? 0 : _chars.length;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _TypewriterMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldLength = _chars.length;
    _chars = widget.text.characters.toList();
    final newLength = _chars.length;

    if (newLength > oldLength) {
      final now = DateTime.now();
      final last = _lastLengthUpdateAt;
      if (last != null) {
        final elapsedMs = now.difference(last).inMilliseconds;
        if (elapsedMs > 0) {
          final incoming =
              (newLength - oldLength) * 1000 / elapsedMs.clamp(1, 60000);
          final clamped = incoming.clamp(6, 240).toDouble();
          _incomingCharsPerSecond =
              (_incomingCharsPerSecond * 0.6) + (clamped * 0.4);
        }
      }
      _lastLengthUpdateAt = now;
    }

    if (!widget.animate) {
      _timer?.cancel();
      _timer = null;
      if (_visibleCount != newLength) {
        setState(() {
          _visibleCount = newLength;
        });
      }
      return;
    }

    if (oldLength == 0 && newLength > 0 && _visibleCount == 0) {
      setState(() {
        _visibleCount = 1;
      });
    }

    if (newLength < oldLength && _visibleCount > newLength) {
      setState(() {
        _visibleCount = newLength;
      });
    }

    _syncAnimation();
  }

  @override
  void dispose() {
    _detachScrollListener();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachScrollListener();
  }

  void _syncAnimation() {
    if (!widget.animate || _isUserScrolling || _visibleCount >= _chars.length) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _timer ??= Timer.periodic(_tick, (_) {
      if (!mounted) return;

      final targetVisible = _targetVisibleCount();
      final remaining = targetVisible - _visibleCount;
      if (remaining <= 0) {
        if (_visibleCount < _chars.length) {
          return;
        }
        _timer?.cancel();
        _timer = null;
        return;
      }

      final isReceivingRecently = _isReceivingDeltaRecently();
      final basedOnIncoming =
          (_incomingCharsPerSecond * _tick.inMilliseconds) /
          Duration.millisecondsPerSecond;
      var step = basedOnIncoming.ceil().clamp(1, isReceivingRecently ? 10 : 4);
      if (remaining > step * 4) {
        final catchUp = (remaining / 4).ceil().clamp(
          1,
          isReceivingRecently ? 14 : 6,
        );
        if (catchUp > step) {
          step = catchUp;
        }
      }

      setState(() {
        _visibleCount = (_visibleCount + step).clamp(0, _chars.length);
      });

      if (_visibleCount >= _chars.length) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  bool _isReceivingDeltaRecently() {
    final last = _lastLengthUpdateAt;
    if (last == null) return false;
    return DateTime.now().difference(last) <= _streamingLag;
  }

  void _attachScrollListener() {
    final scrollable = Scrollable.maybeOf(context);
    final listenable = scrollable?.position.isScrollingNotifier;
    if (identical(_isScrollingListenable, listenable)) {
      return;
    }

    _detachScrollListener();
    _isScrollingListenable = listenable;
    _isUserScrolling = listenable?.value ?? false;
    _isScrollingListenable?.addListener(_handleScrollStateChanged);
  }

  void _detachScrollListener() {
    _isScrollingListenable?.removeListener(_handleScrollStateChanged);
    _isScrollingListenable = null;
  }

  void _handleScrollStateChanged() {
    final scrolling = _isScrollingListenable?.value ?? false;
    if (scrolling == _isUserScrolling) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (_pendingScrollStateSync) {
      return;
    }

    _pendingScrollStateSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingScrollStateSync = false;
      if (!mounted) {
        return;
      }

      final latestScrolling = _isScrollingListenable?.value ?? false;
      if (latestScrolling == _isUserScrolling) {
        return;
      }

      setState(() {
        _isUserScrolling = latestScrolling;
      });
      _syncAnimation();
    });
  }

  int _targetVisibleCount() {
    if (!widget.animate) {
      return _chars.length;
    }
    final last = _lastLengthUpdateAt;
    if (last == null) {
      return _chars.length;
    }
    final elapsed = DateTime.now().difference(last);
    if (elapsed > _streamingLag) {
      return _chars.length;
    }

    final lagChars =
        (_incomingCharsPerSecond *
                _streamingLag.inMilliseconds /
                Duration.millisecondsPerSecond)
            .ceil()
            .clamp(2, 28);
    final target = _chars.length - lagChars;
    return target.clamp(1, _chars.length);
  }

  @override
  Widget build(BuildContext context) {
    final text = _chars.take(_visibleCount).join();

    return RepaintBoundary(
      child: MarkdownBody(
        data: text,
        selectable: true,
        builders: {
          'pre': CodeBlockBuilder(),
          'ul': _MarkdownListBuilder(ordered: false),
          'ol': _MarkdownListBuilder(ordered: true),
        },
        onTapLink: (text, href, title) => openMessageMarkdownLink(href),
        styleSheet: buildMessageMarkdownStyleSheet(context),
      ),
    );
  }
}

class _MarkdownListBuilder extends MarkdownElementBuilder {
  final bool ordered;

  _MarkdownListBuilder({required this.ordered});

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final items = element.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'li')
        .toList();
    if (items == null || items.isEmpty) {
      return null;
    }

    final start = ordered
        ? int.tryParse(element.attributes['start'] ?? '') ?? 1
        : 1;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final styleSheet = buildMessageMarkdownStyleSheet(context);
    final bulletStyle =
        styleSheet.listBullet ??
        theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (_taskListCheckedState(items[i]) case final checked?)
            _MarkdownTaskListItem(
              checked: checked,
              contentMarkdown: _serializeListItemContent(items[i]),
              nestedLists:
                  items[i].children
                      ?.whereType<md.Element>()
                      .where((child) => child.tag == 'ul' || child.tag == 'ol')
                      .toList() ??
                  const <md.Element>[],
            )
          else
            _MarkdownListItem(
              marker: ordered ? '${start + i}.' : '•',
              bulletStyle: bulletStyle,
              contentMarkdown: _serializeListItemContent(items[i]),
              nestedLists:
                  items[i].children
                      ?.whereType<md.Element>()
                      .where((child) => child.tag == 'ul' || child.tag == 'ol')
                      .toList() ??
                  const <md.Element>[],
              textColor: preferredStyle?.color ?? theme.colorScheme.onSurface,
              markerColor: tokens.mutedForeground,
            ),
          if (i != items.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _MarkdownTaskListItem extends StatelessWidget {
  final bool checked;
  final String contentMarkdown;
  final List<md.Element> nestedLists;

  const _MarkdownTaskListItem({
    required this.checked,
    required this.contentMarkdown,
    required this.nestedLists,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final styleSheet = buildMessageMarkdownStyleSheet(
      context,
    ).copyWith(blockSpacing: 0, pPadding: EdgeInsets.zero);
    final checkboxBackground = checked
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final checkboxBorder = checked
        ? theme.colorScheme.primary
        : tokens.border.withValues(alpha: 0.9);
    final checkboxIconColor = checked
        ? theme.colorScheme.onPrimary
        : Colors.transparent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checkboxBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: checkboxBorder, width: 1.5),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 13,
              color: checkboxIconColor,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contentMarkdown.trim().isNotEmpty)
                DefaultTextStyle.merge(
                  style: TextStyle(
                    color: checked
                        ? tokens.mutedForeground
                        : theme.colorScheme.onSurface,
                    decoration: checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: checked
                        ? tokens.mutedForeground.withValues(alpha: 0.9)
                        : null,
                  ),
                  child: MarkdownBody(
                    data: contentMarkdown,
                    selectable: true,
                    builders: {
                      'pre': CodeBlockBuilder(),
                      'ul': _MarkdownListBuilder(ordered: false),
                      'ol': _MarkdownListBuilder(ordered: true),
                    },
                    onTapLink: (text, href, title) =>
                        openMessageMarkdownLink(href),
                    styleSheet: styleSheet.copyWith(
                      p: styleSheet.p?.copyWith(
                        color: checked
                            ? tokens.mutedForeground
                            : theme.colorScheme.onSurface,
                        decoration: checked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: checked
                            ? tokens.mutedForeground.withValues(alpha: 0.9)
                            : null,
                      ),
                    ),
                  ),
                ),
              for (final nested in nestedLists) ...[
                const SizedBox(height: 4),
                _NestedMarkdownList(element: nested),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MarkdownListItem extends StatelessWidget {
  final String marker;
  final TextStyle? bulletStyle;
  final String contentMarkdown;
  final List<md.Element> nestedLists;
  final Color textColor;
  final Color markerColor;

  const _MarkdownListItem({
    required this.marker,
    required this.bulletStyle,
    required this.contentMarkdown,
    required this.nestedLists,
    required this.textColor,
    required this.markerColor,
  });

  @override
  Widget build(BuildContext context) {
    final styleSheet = buildMessageMarkdownStyleSheet(
      context,
    ).copyWith(blockSpacing: 0, pPadding: EdgeInsets.zero);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: Text(
              marker,
              textAlign: TextAlign.right,
              style: bulletStyle?.copyWith(color: markerColor),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contentMarkdown.trim().isNotEmpty)
                MarkdownBody(
                  data: contentMarkdown,
                  selectable: true,
                  builders: {
                    'pre': CodeBlockBuilder(),
                    'ul': _MarkdownListBuilder(ordered: false),
                    'ol': _MarkdownListBuilder(ordered: true),
                  },
                  onTapLink: (text, href, title) =>
                      openMessageMarkdownLink(href),
                  styleSheet: styleSheet,
                ),
              for (final nested in nestedLists) ...[
                const SizedBox(height: 4),
                _NestedMarkdownList(element: nested),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NestedMarkdownList extends StatelessWidget {
  final md.Element element;

  const _NestedMarkdownList({required this.element});

  @override
  Widget build(BuildContext context) {
    final builder = _MarkdownListBuilder(ordered: element.tag == 'ol');
    return builder.visitElementAfterWithContext(context, element, null, null) ??
        const SizedBox.shrink();
  }
}

String _serializeListItemContent(md.Element item) {
  final nodes = <md.Node>[];
  for (final child in item.children ?? const <md.Node>[]) {
    if (child is md.Element &&
        (child.tag == 'ul' ||
            child.tag == 'ol' ||
            child.attributes['type'] == 'checkbox')) {
      continue;
    }
    nodes.add(child);
  }
  return nodes.map(_serializeMarkdownNode).join().trim();
}

bool? _taskListCheckedState(md.Element item) {
  final firstElement = item.children?.whereType<md.Element>().firstOrNull;
  if (firstElement == null || firstElement.attributes['type'] != 'checkbox') {
    return null;
  }
  return firstElement.attributes.containsKey('checked');
}

String _serializeMarkdownNode(md.Node node) {
  if (node is md.Text) {
    return node.text;
  }
  if (node is! md.Element) {
    return node.textContent;
  }

  final content = (node.children ?? const <md.Node>[])
      .map(_serializeMarkdownNode)
      .join();

  return switch (node.tag) {
    'p' => content,
    'strong' => '**$content**',
    'em' => '*$content*',
    'del' => '~~$content~~',
    'code' => '`$content`',
    'a' =>
      '[${content.isEmpty ? node.textContent : content}](${node.attributes['href'] ?? ''})',
    'br' => '  \n',
    _ => content,
  };
}

class _CompactionDivider extends StatelessWidget {
  const _CompactionDivider();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: tokens.border.withValues(alpha: 0.8),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Context compacted',
              style: TextStyle(
                fontSize: 11,
                color: tokens.mutedForeground,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: tokens.border.withValues(alpha: 0.8),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePartWidget extends StatefulWidget {
  final String url;
  final double size;

  const _ImagePartWidget({required this.url, this.size = 200});

  @override
  State<_ImagePartWidget> createState() => _ImagePartWidgetState();
}

class _ImagePartWidgetState extends State<_ImagePartWidget> {
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = _buildImageProvider(widget.url);
  }

  @override
  void didUpdateWidget(covariant _ImagePartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageProvider = _buildImageProvider(widget.url);
    }
  }

  ImageProvider _buildImageProvider(String url) {
    if (!url.startsWith('data:')) {
      return NetworkImage(url);
    }
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1 || commaIndex == url.length - 1) {
      return NetworkImage(url);
    }
    final base64Data = url.substring(commaIndex + 1);
    return MemoryImage(base64Decode(base64Data));
  }

  void _showFullscreen(BuildContext context, ImageProvider imageProvider) {
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.scrim,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image(image: imageProvider, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: () => _showFullscreen(context, _imageProvider),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image(
          image: _imageProvider,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Container(
            width: widget.size,
            height: widget.size,
            color: tokens.accent,
            child: Icon(Icons.broken_image, color: tokens.mutedForeground),
          ),
        ),
      ),
    );
  }
}

class MessageImageGallery extends StatelessWidget {
  final List<FilePart> images;

  const MessageImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SingleChildScrollView(
        key: kMessageImageGalleryKey,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < images.length; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              RepaintBoundary(
                key: ValueKey(images[index].id),
                child: _ImagePartWidget(
                  url: images[index].url,
                  size: kMessageImageThumbnailSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
