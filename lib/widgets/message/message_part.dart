import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../../l10n/l10n.dart';
import '../../service/api/models/parts.dart';
import '../../theme/app_tokens.dart';
import 'code_block_widget.dart';
import 'image_preview_dialog.dart';
import 'message_markdown_theme.dart';
import 'tool_use_widget.dart';

class MessagePart extends StatelessWidget {
  final Object part;
  final bool isUser;
  final bool isStreaming;
  final bool animateText;
  final bool animateThinking;
  final void Function(String sessionId)? onNavigateToSubSession;
  final bool? toolIsExpanded;
  final ValueChanged<bool>? onToolExpandedChanged;
  final bool? thinkingIsExpanded;
  final ValueChanged<bool>? onThinkingExpandedChanged;
  final List<String>? imagePreviewUrls;
  final int imagePreviewInitialIndex;

  const MessagePart({
    super.key,
    required this.part,
    required this.isUser,
    this.isStreaming = false,
    this.animateText = false,
    this.animateThinking = false,
    this.onNavigateToSubSession,
    this.toolIsExpanded,
    this.onToolExpandedChanged,
    this.thinkingIsExpanded,
    this.onThinkingExpandedChanged,
    this.imagePreviewUrls,
    this.imagePreviewInitialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (part is CompactionPart) {
      return const _CompactionDivider();
    }
    if (part is ReasoningPart) {
      final reasoningPart = part as ReasoningPart;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ThinkingBlockWidget(
          key: ValueKey('thinking-${reasoningPart.id}'),
          part: reasoningPart,
          isStreaming: isStreaming,
          isExpanded: thinkingIsExpanded ?? false,
          animate: animateThinking,
          onExpandedChanged: onThinkingExpandedChanged,
        ),
      );
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
        isExpanded: toolIsExpanded ?? true,
        onExpandedChanged: onToolExpandedChanged,
      );
    } else if (part is FilePart) {
      final filePart = part as FilePart;
      if (filePart.mime.startsWith('image/')) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ImagePartWidget(
            url: filePart.url,
            previewUrls: imagePreviewUrls,
            initialIndex: imagePreviewInitialIndex,
          ),
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
  final bool showInitialTextImmediately;
  final MarkdownStyleSheet? styleSheet;

  const _TypewriterMarkdownText({
    super.key,
    required this.text,
    required this.animate,
    this.showInitialTextImmediately = false,
    this.styleSheet,
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
    _visibleCount = !widget.animate || widget.showInitialTextImmediately
        ? _chars.length
        : 0;
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
    final styleSheet =
        widget.styleSheet ?? buildMessageMarkdownStyleSheet(context);

    return RepaintBoundary(
      child: MarkdownBody(
        data: text,
        selectable: true,
        builders: {
          'pre': CodeBlockBuilder(),
          'ul': _MarkdownListBuilder(ordered: false, styleSheet: styleSheet),
          'ol': _MarkdownListBuilder(ordered: true, styleSheet: styleSheet),
        },
        onTapLink: (text, href, title) => openMessageMarkdownLink(href),
        styleSheet: styleSheet,
      ),
    );
  }
}

class _MarkdownListBuilder extends MarkdownElementBuilder {
  final bool ordered;
  final MarkdownStyleSheet? styleSheet;

  _MarkdownListBuilder({required this.ordered, this.styleSheet});

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
    final styleSheet =
        this.styleSheet ?? buildMessageMarkdownStyleSheet(context);
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
              styleSheet: styleSheet,
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
              styleSheet: styleSheet,
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
  final MarkdownStyleSheet styleSheet;

  const _MarkdownTaskListItem({
    required this.checked,
    required this.contentMarkdown,
    required this.nestedLists,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final styleSheet = this.styleSheet.copyWith(
      blockSpacing: 0,
      pPadding: EdgeInsets.zero,
    );
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
                      'ul': _MarkdownListBuilder(
                        ordered: false,
                        styleSheet: styleSheet,
                      ),
                      'ol': _MarkdownListBuilder(
                        ordered: true,
                        styleSheet: styleSheet,
                      ),
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
                _NestedMarkdownList(element: nested, styleSheet: styleSheet),
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
  final MarkdownStyleSheet styleSheet;

  const _MarkdownListItem({
    required this.marker,
    required this.bulletStyle,
    required this.contentMarkdown,
    required this.nestedLists,
    required this.textColor,
    required this.markerColor,
    required this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    final styleSheet = this.styleSheet.copyWith(
      blockSpacing: 0,
      pPadding: EdgeInsets.zero,
    );

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
                    'ul': _MarkdownListBuilder(
                      ordered: false,
                      styleSheet: styleSheet,
                    ),
                    'ol': _MarkdownListBuilder(
                      ordered: true,
                      styleSheet: styleSheet,
                    ),
                  },
                  onTapLink: (text, href, title) =>
                      openMessageMarkdownLink(href),
                  styleSheet: styleSheet,
                ),
              for (final nested in nestedLists) ...[
                const SizedBox(height: 4),
                _NestedMarkdownList(element: nested, styleSheet: styleSheet),
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
  final MarkdownStyleSheet? styleSheet;

  const _NestedMarkdownList({required this.element, this.styleSheet});

  @override
  Widget build(BuildContext context) {
    final builder = _MarkdownListBuilder(
      ordered: element.tag == 'ol',
      styleSheet: styleSheet,
    );
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
  final List<String>? previewUrls;
  final int initialIndex;

  const _ImagePartWidget({
    required this.url,
    this.size = 200,
    this.previewUrls,
    this.initialIndex = 0,
  });

  @override
  State<_ImagePartWidget> createState() => _ImagePartWidgetState();
}

class _ImagePartWidgetState extends State<_ImagePartWidget> {
  late ImageProvider<Object> _imageProvider;

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

  ImageProvider<Object> _buildImageProvider(String url) {
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

  void _showFullscreen(BuildContext context) {
    final previewUrls = widget.previewUrls ?? [widget.url];
    final images = <ImageProvider<Object>>[
      for (var index = 0; index < previewUrls.length; index++)
        if (index == widget.initialIndex && previewUrls[index] == widget.url)
          _imageProvider
        else
          _buildImageProvider(previewUrls[index]),
    ];
    showImagePreviewDialog(
      context: context,
      images: images,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: () => _showFullscreen(context),
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
    final previewUrls = images
        .map((image) => image.url)
        .toList(growable: false);

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
                  previewUrls: previewUrls,
                  initialIndex: index,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

const Key kThinkingBlockHeaderKey = Key('thinking_block.header');
const Key kThinkingBlockBodyKey = Key('thinking_block.body');

class ThinkingBlockWidget extends StatelessWidget {
  final ReasoningPart part;
  final bool isStreaming;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool animate;

  const ThinkingBlockWidget({
    super.key,
    required this.part,
    required this.isStreaming,
    required this.isExpanded,
    this.onExpandedChanged,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.accent,
        borderRadius: BorderRadius.circular(tokens.radiusXs),
        border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThinkingHeader(
            part: part,
            isStreaming: isStreaming,
            isExpanded: isExpanded,
            onToggle: onExpandedChanged == null
                ? null
                : () => onExpandedChanged!(!isExpanded),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) =>
                SizeTransition(sizeFactor: animation, child: child),
            child: isExpanded && part.text.isNotEmpty
                ? Padding(
                    key: kThinkingBlockBodyKey,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: _TypewriterMarkdownText(
                      key: ValueKey('thinking-body-${part.id}'),
                      text: part.text,
                      animate: animate && part.time.end == null,
                      showInitialTextImmediately: true,
                      styleSheet: _buildThinkingMarkdownStyleSheet(context),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ThinkingHeader extends StatelessWidget {
  final ReasoningPart part;
  final bool isStreaming;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const _ThinkingHeader({
    required this.part,
    required this.isStreaming,
    required this.isExpanded,
    this.onToggle,
  });

  String _label(BuildContext context) {
    final time = part.time;
    final start = time.start;
    final end = time.end;
    if (part.text.isEmpty && (isStreaming || end == null)) {
      return context.l10n.thinkingInProgress;
    }
    if (start == null || end == null) {
      return context.l10n.thinkingInProgress;
    }
    final seconds = ((end - start) / 1000).ceil().clamp(1, 86400);
    return context.l10n.thoughtForDuration(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inProgress = isStreaming && part.time.end == null;

    return InkWell(
      key: kThinkingBlockHeaderKey,
      onTap: onToggle,
      borderRadius: BorderRadius.circular(tokens.radiusXs),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 14,
              color: tokens.mutedForeground,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _label(context),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.mutedForeground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (inProgress) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: tokens.mutedForeground,
                ),
              ),
            ],
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: tokens.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

MarkdownStyleSheet _buildThinkingMarkdownStyleSheet(BuildContext context) {
  final tokens = context.tokens;
  final base = buildMessageMarkdownStyleSheet(context);
  final body = base.p?.copyWith(
    fontSize: 13,
    height: 1.55,
    color: tokens.mutedForeground,
  );

  return base.copyWith(
    p: body,
    strong: body?.copyWith(fontWeight: FontWeight.w600),
    em: body?.copyWith(fontStyle: FontStyle.italic),
    a: body?.copyWith(fontWeight: FontWeight.w500),
    listBullet: body?.copyWith(fontSize: 13),
    blockSpacing: 8,
  );
}
