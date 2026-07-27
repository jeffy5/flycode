import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/file_provider.dart';
import '../service/api/models/file_content.dart';
import '../theme/app_tokens.dart';

// ──────────────────────────────────────────────
// 工具函数
// ──────────────────────────────────────────────

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
}

String _fileExtension(String path) {
  final name = _fileName(path);
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == name.length - 1) return '';
  return name.substring(dotIndex + 1).toLowerCase();
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ──────────────────────────────────────────────
// 页面入口
// ──────────────────────────────────────────────

class FileContentPage extends ConsumerWidget {
  const FileContentPage({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileName = _fileName(filePath);
    final contentAsync = ref.watch(fileContentProvider(filePath));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (filePath != fileName)
              Text(
                filePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.mutedForeground,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: tokens.border.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
        actions: [
          if (contentAsync.hasValue && !contentAsync.value!.isBinary)
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: tokens.mutedForeground,
              ),
              tooltip: context.l10n.fileContentCopyTooltip,
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: contentAsync.value!.content),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.fileContentCopied),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: contentAsync.when(
        loading: () => const _SkeletonLoader(),
        error: (error, _) => _ErrorView(error: error),
        data: (fc) => _ContentView(filePath: filePath, content: fc),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 骨架屏加载态
// ──────────────────────────────────────────────

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final tokens = context.tokens;
        final shimmer = Color.lerp(tokens.accent, tokens.border, _anim.value)!;
        return Column(
          children: List.generate(18, (i) {
            // 随机行宽模拟真实代码行
            final widthFactor = switch (i % 7) {
              0 => 0.85,
              1 => 0.55,
              2 => 0.70,
              3 => 0.40,
              4 => 0.92,
              5 => 0.63,
              _ => 0.78,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tokens.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widthFactor,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────
// 错误视图
// ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final pagePadding = context.tokens.pageHorizontalPadding;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pagePadding, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: tokens.errorSoftForeground,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.fileContentLoadFailed,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 内容视图（根据类型分发）
// ──────────────────────────────────────────────

class _ContentView extends StatelessWidget {
  const _ContentView({required this.filePath, required this.content});

  final String filePath;
  final FileContent content;

  @override
  Widget build(BuildContext context) {
    if (content.isBinary) {
      return _BinaryUnsupportedView(mimeType: content.mimeType);
    }

    final lines = _splitLines(content.content);
    final ext = _fileExtension(filePath);
    final sizeBytes = content.content.length; // UTF-16 近似，足够展示用

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FileInfoBar(lineCount: lines.length, ext: ext, sizeBytes: sizeBytes),
        Expanded(child: _TextContentView(lines: lines)),
      ],
    );
  }

  /// 按换行拆分，去掉末尾多余空行
  static List<String> _splitLines(String text) {
    final lines = text.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      return lines.sublist(0, lines.length - 1);
    }
    return lines;
  }
}

// ──────────────────────────────────────────────
// 文件信息栏
// ──────────────────────────────────────────────

class _FileInfoBar extends StatelessWidget {
  const _FileInfoBar({
    required this.lineCount,
    required this.ext,
    required this.sizeBytes,
  });

  final int lineCount;
  final String ext;
  final int sizeBytes;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.accent,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          // 语言标签
          if (ext.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.border.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ext,
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.accentForeground,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          // 行数
          Icon(
            Icons.format_list_numbered_rounded,
            size: 13,
            color: tokens.mutedForeground,
          ),
          const SizedBox(width: 3),
          Text(
            context.l10n.fileContentLines(lineCount),
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
          const SizedBox(width: 10),
          // 大小
          Icon(
            Icons.data_usage_rounded,
            size: 13,
            color: tokens.mutedForeground,
          ),
          const SizedBox(width: 3),
          Text(
            _formatBytes(sizeBytes),
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 二进制文件不支持提示
// ──────────────────────────────────────────────

class _BinaryUnsupportedView extends StatelessWidget {
  const _BinaryUnsupportedView({this.mimeType});
  final String? mimeType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tokens.accent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 36,
              color: tokens.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.fileContentPreviewUnsupported,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mimeType != null
                ? context.l10n.fileContentBinaryWithMime(mimeType!)
                : context.l10n.fileContentBinary,
            style: TextStyle(color: tokens.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 文本内容视图
//
// 架构说明：
//   - 竖向滚动：ListView.builder（虚拟化，支持大文件）
//   - 横向滚动：外层 SingleChildScrollView(horizontal) + 共享 ScrollController
//     内层每行宽度 = max(屏幕宽, 最长行估算宽度)，保证行宽一致
//   - 两个 ScrollController 分别控制横向和竖向，互不干扰
// ──────────────────────────────────────────────

class _TextContentView extends StatefulWidget {
  const _TextContentView({required this.lines});
  final List<String> lines;

  @override
  State<_TextContentView> createState() => _TextContentViewState();
}

class _TextContentViewState extends State<_TextContentView> {
  final ScrollController _verticalCtrl = ScrollController();
  final ScrollController _horizontalCtrl = ScrollController();

  static const double _charWidth = 7.2; // monospace 12px 近似字符宽
  static const double _codePadding = 12.0 * 2; // 左右 padding

  @override
  void dispose() {
    _verticalCtrl.dispose();
    _horizontalCtrl.dispose();
    super.dispose();
  }

  /// 估算所有行中最长行的像素宽度
  double _maxLineWidth(double gutterWidth) {
    int maxChars = 0;
    for (final line in widget.lines) {
      if (line.length > maxChars) maxChars = line.length;
    }
    return gutterWidth + 1 + _codePadding + maxChars * _charWidth;
  }

  double _gutterWidthFor(int lineCount) {
    if (lineCount < 100) return 36.0;
    if (lineCount < 1000) return 44.0;
    return 52.0;
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = widget.lines.length;
    final gutterWidth = _gutterWidthFor(lineCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final estimatedMaxWidth = _maxLineWidth(gutterWidth);
        final contentWidth = math.max(screenWidth, estimatedMaxWidth);

        return Scrollbar(
          controller: _horizontalCtrl,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalCtrl,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              child: Scrollbar(
                controller: _verticalCtrl,
                child: ListView.builder(
                  controller: _verticalCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: lineCount,
                  // 每行固定高度，大幅提升 ListView 渲染性能
                  itemExtent: 22.0,
                  itemBuilder: (context, index) => _CodeLineRow(
                    lineNumber: index + 1,
                    text: widget.lines[index],
                    gutterWidth: gutterWidth,
                    isEven: index.isEven,
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

// ──────────────────────────────────────────────
// 单行代码行（行号 + 内容）
// ──────────────────────────────────────────────

class _CodeLineRow extends StatelessWidget {
  const _CodeLineRow({
    required this.lineNumber,
    required this.text,
    required this.gutterWidth,
    required this.isEven,
  });

  final int lineNumber;
  final String text;
  final double gutterWidth;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 行号列
        Container(
          width: gutterWidth,
          color: tokens.accent,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            '$lineNumber',
            style: TextStyle(
              fontSize: 12,
              color: tokens.mutedForeground,
              fontFamily: 'monospace',
              height: 1.0,
            ),
          ),
        ),
        // 分隔线
        Container(width: 1, color: tokens.border),
        // 代码内容
        Expanded(
          child: Container(
            color: isEven
                ? colorScheme.surface
                : tokens.accent.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontFamily: 'monospace',
                height: 1.0,
              ),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }
}
