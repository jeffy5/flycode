import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

import '../../theme/app_tokens.dart';
import 'code_highlight_theme.dart';

// ──────────────────────────────────────────────
// Diff 渲染器（从 session_diff_page.dart 提取）
// ──────────────────────────────────────────────

/// 单行展示数据
class DiffLine {
  const DiffLine({required this.op, required this.text});

  /// DIFF_DELETE=-1, DIFF_EQUAL=0, DIFF_INSERT=1
  final int op;
  final String text;
}

/// 折叠占位符
class CollapsedHint {
  const CollapsedHint(this.count);
  final int count;
}

class DiffView extends StatelessWidget {
  const DiffView({
    super.key,
    required this.before,
    required this.after,
    this.fileName,
    this.maxLines = 1000,
    this.maxHeight,
  });

  final String before;
  final String after;
  final String? fileName;
  final int maxLines;

  /// 当传入时，DiffView 内部自行限高并提供双向滚动；
  /// 为 null 时不限高，由父级决定布局（session_diff_page 等场景）。
  final double? maxHeight;

  static const int _contextLines = 3;

  /// 从文件名推断语言，排除纯文本类型
  String? get _language {
    if (fileName == null || fileName!.isEmpty) return null;

    final ext = fileName!.toLowerCase().split('.').lastOrNull;
    if (ext == null || ext.isEmpty) return null;

    // 排除纯文本类型
    const textExtensions = {'txt', 'md', 'markdown', 'log', 'csv', 'tsv'};
    if (textExtensions.contains(ext)) return null;

    return ext;
  }

  /// 检查是否超过最大行数限制
  bool get _isTooLarge {
    final beforeLines = before.isEmpty ? 0 : before.split('\n').length;
    final afterLines = after.isEmpty ? 0 : after.split('\n').length;
    return (beforeLines + afterLines) > maxLines;
  }

  List<DiffLine> _computeDiffLines() {
    if (before.isEmpty && after.isEmpty) return [];

    final dmp = DiffMatchPatch();

    final lineArray = <String>[''];
    final lineHash = <String, int>{};

    String linesToChars(String text) {
      final lines = text.split('\n');
      final sb = StringBuffer();
      for (final line in lines) {
        if (lineHash.containsKey(line)) {
          sb.writeCharCode(lineHash[line]!);
        } else {
          lineArray.add(line);
          final code = lineArray.length - 1;
          lineHash[line] = code;
          sb.writeCharCode(code);
        }
      }
      return sb.toString();
    }

    final chars1 = linesToChars(before);
    final chars2 = linesToChars(after);

    final diffs = dmp.diff(chars1, chars2, false);
    dmp.diffCleanupSemantic(diffs);

    final result = <DiffLine>[];
    for (final d in diffs) {
      for (final charCode in d.text.codeUnits) {
        final line = charCode < lineArray.length ? lineArray[charCode] : '';
        result.add(DiffLine(op: d.operation, text: line));
      }
    }
    return result;
  }

  List<Object> _buildDisplayItems(List<DiffLine> lines) {
    if (lines.isEmpty) return [];

    final result = <Object>[];
    int i = 0;

    while (i < lines.length) {
      if (lines[i].op == DIFF_EQUAL) {
        final start = i;
        while (i < lines.length && lines[i].op == DIFF_EQUAL) {
          i++;
        }
        final equalCount = i - start;
        final keepBefore = result.isNotEmpty ? _contextLines : 0;
        final keepAfter = i < lines.length ? _contextLines : 0;
        final collapseCount = equalCount - keepBefore - keepAfter;

        if (collapseCount > 0) {
          for (int j = start; j < start + keepBefore; j++) {
            result.add(lines[j]);
          }
          result.add(CollapsedHint(collapseCount));
          for (int j = i - keepAfter; j < i; j++) {
            result.add(lines[j]);
          }
        } else {
          for (int j = start; j < i; j++) {
            result.add(lines[j]);
          }
        }
      } else {
        result.add(lines[i]);
        i++;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    // 检查是否超过最大行数
    if (_isTooLarge) {
      return _buildTooLargeWidget(context, tokens, theme);
    }

    final lines = _computeDiffLines();

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
        ),
        child: Text(
          '(empty)',
          style: TextStyle(
            fontSize: 12,
            color: tokens.mutedForeground,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final items = _buildDisplayItems(lines);
    final highlightTheme = buildHighlightTheme(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 0.0;

          // SizedBox(width: parentWidth, height: 0) 作为 Column 第一项撑宽，
          // 使 IntrinsicWidth 至少等于父级宽度。
          // IntrinsicWidth 让 Column 得到有限宽约束，crossAxisAlignment.stretch 才能正常铺满。
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: parentWidth, height: 0),
              ...items.map((item) {
                if (item is CollapsedHint) {
                  return CollapsedHintRow(count: item.count);
                }
                return DiffLineRow(
                  line: item as DiffLine,
                  language: _language,
                  highlightTheme: highlightTheme,
                );
              }),
            ],
          );

          final hScroll = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(child: column),
          );

          if (maxHeight != null) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight!),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: hScroll,
              ),
            );
          }
          return hScroll;
        },
      ),
    );
  }

  Widget _buildTooLargeWidget(
    BuildContext context,
    AppThemeTokens tokens,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: tokens.warningForeground,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            '变更内容过大（超过 $maxLines 行）',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '暂不支持查看完整 diff',
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 折叠提示行
// ──────────────────────────────────────────────

class CollapsedHintRow extends StatelessWidget {
  const CollapsedHintRow({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      color: tokens.card,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        '... $count lines unchanged',
        style: TextStyle(
          fontSize: 11,
          color: tokens.mutedForeground,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 单行渲染（支持语法高亮）
// ──────────────────────────────────────────────

class DiffLineRow extends StatelessWidget {
  const DiffLineRow({
    super.key,
    required this.line,
    this.language,
    required this.highlightTheme,
  });

  final DiffLine line;
  final String? language;
  final Map<String, TextStyle> highlightTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final Color bg;
    final Color textColor;
    final String prefix;

    switch (line.op) {
      case DIFF_INSERT:
        bg = tokens.success;
        textColor = tokens.successForeground;
        prefix = '+';
      case DIFF_DELETE:
        bg = tokens.errorSoft;
        textColor = tokens.errorSoftForeground;
        prefix = '-';
      default:
        bg = theme.colorScheme.surface;
        textColor = theme.colorScheme.onSurface;
        prefix = ' ';
    }

    // 构建行内容：使用语法高亮或纯文本
    final Widget content;
    if (language != null && line.text.isNotEmpty) {
      // 使用底层 highlight API 解析，手动构建 RichText
      // 这样可以避免 HighlightView 的 Container 背景色问题
      final result = highlight.parse(line.text, language: language);
      final spans = _convertNodes(result.nodes ?? [], highlightTheme);

      content = RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.5,
            color: textColor,
          ),
          children: spans.isEmpty ? [TextSpan(text: line.text)] : spans,
        ),
      );
    } else {
      content = Text(
        line.text,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      );
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            child: Text(
              prefix,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          content,
        ],
      ),
    );
  }

  /// 将 highlight 解析的节点转换为 TextSpan 列表
  List<TextSpan> _convertNodes(List<Node> nodes, Map<String, TextStyle> theme) {
    final spans = <TextSpan>[];

    void traverse(Node node, List<TextSpan> currentSpans) {
      if (node.value != null) {
        // 叶子节点：有文本内容
        final style = node.className != null ? theme[node.className!] : null;
        currentSpans.add(TextSpan(text: node.value, style: style));
      } else if (node.children != null) {
        // 内部节点：有子节点
        final children = <TextSpan>[];
        final style = node.className != null ? theme[node.className!] : null;
        currentSpans.add(TextSpan(children: children, style: style));

        for (var i = 0; i < node.children!.length; i++) {
          traverse(node.children![i], children);
        }
      }
    }

    for (final node in nodes) {
      traverse(node, spans);
    }

    return spans;
  }
}
