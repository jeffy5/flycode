import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:highlight/highlight.dart' show Node, highlight;
import 'package:markdown/markdown.dart' as md;

import 'code_highlight_theme.dart';
import 'message_markdown_theme.dart';

/// A custom [MarkdownElementBuilder] that renders fenced code blocks with
/// a language header bar and a copy-to-clipboard button.
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'pre') return null;

    // Fenced code blocks are <pre><code class="language-xxx">...</code></pre>
    final codeElement = element.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'code')
        .firstOrNull;

    final rawLanguage = codeElement?.attributes['class'] ?? '';
    // markdown encodes language as "language-dart", "language-python", etc.
    final language = rawLanguage.startsWith('language-')
        ? rawLanguage.substring('language-'.length)
        : rawLanguage;

    final code = (codeElement?.textContent ?? element.textContent).trimRight();

    return _CodeBlockWidget(language: language, code: code);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String language;
  final String code;

  const _CodeBlockWidget({required this.language, required this.code});

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(12));
    const headerRadius = BorderRadius.vertical(top: Radius.circular(12));
    const bodyRadius = BorderRadius.vertical(bottom: Radius.circular(12));
    final hasLanguage = widget.language.isNotEmpty;
    final theme = Theme.of(context);
    final codeTheme = buildMessageCodeBlockTheme(context);
    final highlightTheme = buildHighlightTheme(context);

    // Normalize language name for flutter_highlight
    // Some common mappings
    final normalizedLanguage = _normalizeLanguage(widget.language);

    return Container(
      key: messageMarkdownCodeBlockKey,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: codeTheme.backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: codeTheme.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: codeTheme.headerColor,
              borderRadius: headerRadius,
              border: Border(bottom: BorderSide(color: codeTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  hasLanguage ? widget.language : 'code',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: codeTheme.languageColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: codeTheme.successColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copied',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: codeTheme.successColor,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: codeTheme.iconColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: codeTheme.iconColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: codeTheme.backgroundColor,
              borderRadius: bodyRadius,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildCodeContent(
                normalizedLanguage: normalizedLanguage,
                highlightTheme: highlightTheme,
                codeColor: codeTheme.codeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent({
    required String normalizedLanguage,
    required Map<String, TextStyle> highlightTheme,
    required Color codeColor,
  }) {
    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.5,
    );

    if (widget.language.isEmpty || normalizedLanguage.isEmpty) {
      return SelectableText(
        widget.code,
        style: textStyle.copyWith(color: codeColor),
      );
    }

    try {
      final nodes = highlight
          .parse(widget.code, language: normalizedLanguage)
          .nodes;
      final spans = _convertHighlightedNodes(
        nodes ?? const <Node>[],
        highlightTheme,
      );
      return SelectableText.rich(
        TextSpan(
          style: textStyle.copyWith(
            color: highlightTheme['root']?.color ?? codeColor,
          ),
          children: spans,
        ),
      );
    } on ArgumentError {
      return SelectableText(
        widget.code,
        style: textStyle.copyWith(color: codeColor),
      );
    }
  }

  List<TextSpan> _convertHighlightedNodes(
    List<Node> nodes,
    Map<String, TextStyle> theme,
  ) {
    final spans = <TextSpan>[];
    var currentSpans = spans;
    final stack = <List<TextSpan>>[];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(
          node.className == null
              ? TextSpan(text: node.value)
              : TextSpan(text: node.value, style: theme[node.className!]),
        );
        return;
      }

      final children = node.children;
      if (children == null || children.isEmpty) {
        return;
      }

      final nestedSpans = <TextSpan>[];
      currentSpans.add(
        TextSpan(children: nestedSpans, style: theme[node.className ?? '']),
      );
      stack.add(currentSpans);
      currentSpans = nestedSpans;

      for (final child in children) {
        traverse(child);
      }

      currentSpans = stack.removeLast();
    }

    for (final node in nodes) {
      traverse(node);
    }

    return spans;
  }

  /// Normalizes language name to match flutter_highlight language identifiers.
  String _normalizeLanguage(String language) {
    final lower = language.toLowerCase().trim();

    // Common language mappings
    const languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'shell': 'bash',
      'zsh': 'bash',
      'yml': 'yaml',
      'md': 'markdown',
      'cs': 'csharp',
      'cpp': 'cpp',
      'c++': 'cpp',
      'objc': 'objectivec',
      'objective-c': 'objectivec',
      'kt': 'kotlin',
      'rs': 'rust',
      'go': 'go',
      'dart': 'dart',
      'java': 'java',
      'swift': 'swift',
      'php': 'php',
      'sql': 'sql',
      'html': 'xml',
      'xml': 'xml',
      'css': 'css',
      'scss': 'scss',
      'sass': 'scss',
      'json': 'json',
      'dockerfile': 'dockerfile',
      'makefile': 'makefile',
      'vim': 'vim',
      'lua': 'lua',
      'r': 'r',
      'matlab': 'matlab',
      'scala': 'scala',
      'groovy': 'groovy',
      'perl': 'perl',
      'clojure': 'clojure',
      'haskell': 'haskell',
      'erlang': 'erlang',
      'elixir': 'elixir',
      'ocaml': 'ocaml',
      'f#': 'fsharp',
      'fsharp': 'fsharp',
      'powershell': 'powershell',
      'ps1': 'powershell',
      'batch': 'dos',
      'cmd': 'dos',
      'vb': 'vbnet',
      'vb.net': 'vbnet',
    };

    return languageMap[lower] ?? lower;
  }
}
