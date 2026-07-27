import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:shimmer/shimmer.dart';
import '../../service/api/models/parts.dart';
import '../../theme/app_tokens.dart';
import '../../utils/external_link_launcher.dart';
import 'code_highlight_theme.dart';
import 'diff_view.dart';
import 'message_markdown_theme.dart';
import 'tool_meta.dart';

const double _kToolPanelMaxHeight = 220;

class ToolUseWidget extends StatefulWidget {
  final ToolPart toolPart;
  final void Function(String sessionId)? onNavigateToSubSession;

  const ToolUseWidget({
    super.key,
    required this.toolPart,
    this.onNavigateToSubSession,
  });

  @override
  State<ToolUseWidget> createState() => _ToolUseWidgetState();
}

class _ToolUseWidgetState extends State<ToolUseWidget> {
  bool _isExpanded = true;

  ToolPart get _part => widget.toolPart;

  bool get _isPending => _part.state is ToolStatePending;
  bool get _isRunning => _part.state is ToolStateRunning;
  bool get _isCompleted => _part.state is ToolStateCompleted;
  bool get _isError => _part.state is ToolStateError;
  bool get _isActive => _isPending || _isRunning;

  Map<String, dynamic> get _input {
    final state = _part.state;
    if (state is ToolStatePending) return state.input;
    if (state is ToolStateRunning) return state.input;
    if (state is ToolStateCompleted) return state.input;
    if (state is ToolStateError) return state.input;
    return {};
  }

  String? get _errorText {
    final state = _part.state;
    if (state is ToolStateError) {
      var err = state.error;
      if (err.startsWith('Error: ')) err = err.substring(7);
      return err;
    }
    return null;
  }

  String? get _output {
    final state = _part.state;
    if (state is ToolStateRunning) {
      return state.metadata?['output']?.toString();
    }
    if (state is ToolStateCompleted) {
      final metaOut = state.metadata['output']?.toString();
      return (metaOut != null && metaOut.isNotEmpty) ? metaOut : state.output;
    }
    return null;
  }

  String? get _subSessionId {
    // Check top-level ToolPart.metadata first
    final topLevel = _part.metadata?['sessionId'] as String?;
    if (topLevel != null) return topLevel;
    // Fall back to state-level metadata (server may put sessionId there)
    final state = _part.state;
    if (state is ToolStateCompleted) {
      return state.metadata['sessionId'] as String?;
    }
    if (state is ToolStateRunning) {
      return state.metadata?['sessionId'] as String?;
    }
    return null;
  }

  bool get _canNavigate =>
      _part.tool == 'task' &&
      _subSessionId != null &&
      widget.onNavigateToSubSession != null;

  _ApplyPatchSummary? get _applyPatchSummary {
    if (_part.tool != 'apply_patch') return null;
    final state = _part.state;
    Map<String, dynamic>? metadata;
    if (state is ToolStateCompleted) {
      metadata = state.metadata;
    } else if (state is ToolStateRunning) {
      metadata = state.metadata;
    } else if (state is ToolStateError) {
      metadata = state.metadata;
    }

    final rawFiles = metadata?['files'];
    if (rawFiles is! List || rawFiles.isEmpty) return null;

    final first = rawFiles.first;
    if (first is! Map) return null;
    final firstFile = first.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final relativePath = _toNonEmptyString(firstFile['relativePath']);
    final filePath = _toNonEmptyString(firstFile['filePath']);
    final path = relativePath ?? filePath;
    if (path == null) return null;

    final normalizedPath = path.replaceAll('\\', '/');
    final slashIndex = normalizedPath.lastIndexOf('/');
    final fileName = slashIndex >= 0
        ? normalizedPath.substring(slashIndex + 1)
        : normalizedPath;
    var directory = slashIndex > 0
        ? normalizedPath.substring(0, slashIndex)
        : '';
    if (directory.isNotEmpty && !directory.startsWith('/')) {
      directory = '/$directory';
    }

    return _ApplyPatchSummary(
      fileName: fileName,
      directory: directory,
      additions: _toInt(firstFile['additions']),
      deletions: _toInt(firstFile['deletions']),
      extraFilesCount: rawFiles.length > 1 ? rawFiles.length - 1 : 0,
    );
  }

  /// Returns all files from apply_patch metadata as a list of maps.
  List<Map<String, dynamic>> get _applyPatchFiles {
    if (_part.tool != 'apply_patch') return [];
    final state = _part.state;
    Map<String, dynamic>? metadata;
    if (state is ToolStateCompleted) {
      metadata = state.metadata;
    } else if (state is ToolStateRunning) {
      metadata = state.metadata;
    } else if (state is ToolStateError) {
      metadata = state.metadata;
    }
    final rawFiles = metadata?['files'];
    if (rawFiles is! List) return [];
    return rawFiles
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  String? _toNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Determines if this tool should render at all
  // (question only shows when completed or dismissed-error)
  bool get _shouldRender {
    if (_part.tool == 'question') {
      if (_isCompleted) return true;
      if (_isError) {
        final err = _errorText ?? '';
        return err.toLowerCase().contains('dismissed');
      }
      return false;
    }
    return true;
  }

  bool get _hasExpandableContent {
    if (_isActive || _isError) return false;
    final meta = toolMetaOf(_part.tool);
    if (!meta.hasExpandableContent) return false;
    if (_part.tool == 'bash') return true;
    if (_part.tool == 'edit') return true;
    if (_part.tool == 'write') return true;
    if (_part.tool == 'apply_patch') return _applyPatchFiles.isNotEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender) return const SizedBox.shrink();

    // question dismissed
    if (_part.tool == 'question' && _isError) {
      return _buildQuestionDismissed(context);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (!_isActive && _isError) _buildErrorBody(context),
          if (_isExpanded && !_isError) _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildQuestionDismissed(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Question dismissed',
        style: TextStyle(
          fontSize: 12,
          color: tokens.mutedForeground,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    if (_part.tool == 'apply_patch' && !_isActive && !_isError) {
      final summary = _applyPatchSummary;
      if (summary != null) {
        return _buildApplyPatchHeader(context, summary);
      }
    }

    final meta = toolMetaOf(_part.tool);
    final input = _input;

    // Resolve display name (task uses subagent_type, skill uses name)
    String displayName = meta.displayName;
    if (_part.tool == 'task') {
      displayName = input['subagent_type']?.toString() ?? 'Task';
    } else if (_part.tool == 'skill') {
      displayName = input['name']?.toString() ?? 'Skill';
    }

    final subtitle = meta.getSubtitle(input);
    final args = _isActive ? <String>[] : meta.getArgs(input);
    final rightAction = _canNavigate
        ? Icon(
            Icons.open_in_new,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          )
        : _hasExpandableContent && !_isActive
        ? Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: tokens.mutedForeground,
          )
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canNavigate
          ? () => widget.onNavigateToSubSession!(_subSessionId!)
          : _hasExpandableContent
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display name — shimmer when active
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _isActive
                          ? Shimmer.fromColors(
                              baseColor: tokens.mutedForeground.withValues(
                                alpha: 0.45,
                              ),
                              highlightColor: tokens.card,
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isError
                                    ? tokens.errorSoftForeground
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                      SizedBox(width: 8),
                      if (!_isActive &&
                          !_isError &&
                          subtitle != null &&
                          subtitle.isNotEmpty)
                        Expanded(
                          child: _part.tool == 'webfetch'
                              ? GestureDetector(
                                  onTap: () => _launchUrl(subtitle),
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              : Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.mutedForeground,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  // Args chips (only when not active)
                  if (args.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top:
                            (!_isActive &&
                                !_isError &&
                                subtitle != null &&
                                subtitle.isNotEmpty)
                            ? 6
                            : 4,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : 280.0;
                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: args
                                .map(
                                  (arg) =>
                                      _ArgChip(label: arg, maxWidth: maxWidth),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (rightAction != null) ...[const SizedBox(width: 8), rightAction],
          ],
        ),
      ),
    );
  }

  Widget _buildApplyPatchHeader(
    BuildContext context,
    _ApplyPatchSummary summary,
  ) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text(
            'Patch',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: summary.fileName,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (summary.directory.isNotEmpty)
                    TextSpan(
                      text: ' ${summary.directory}',
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  if (summary.extraFilesCount > 0)
                    TextSpan(
                      text: '  +${summary.extraFilesCount} files',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.mutedForeground,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${summary.additions}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.successForeground,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '-${summary.deletions}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context) {
    final tokens = context.tokens;
    final err = _errorText ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.errorSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tokens.errorSoftForeground.withValues(alpha: 0.28),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _kToolPanelMaxHeight),
        child: SingleChildScrollView(
          child: Text(
            err,
            style: TextStyle(
              fontSize: 12,
              color: tokens.errorSoftForeground,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_part.tool == 'bash')
          _BashOutputPanel(
            command: _input['command']?.toString() ?? '',
            output: _output,
            running: _isRunning,
          )
        else if (_part.tool == 'edit')
          _EditDiffPanel(
            oldString: _input['oldString']?.toString() ?? '',
            newString: _input['newString']?.toString() ?? '',
          )
        else if (_part.tool == 'write')
          _FilePathPanel(filePath: _input['filePath']?.toString() ?? '')
        else if (_part.tool == 'apply_patch')
          _PatchDiffPanel(files: _applyPatchFiles)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchExternalUri(uri);
  }
}

class _ApplyPatchSummary {
  final String fileName;
  final String directory;
  final int additions;
  final int deletions;
  final int extraFilesCount;

  const _ApplyPatchSummary({
    required this.fileName,
    required this.directory,
    required this.additions,
    required this.deletions,
    required this.extraFilesCount,
  });
}

// ─── Arg chip ────────────────────────────────────────────────────────────────

class _ArgChip extends StatelessWidget {
  final String label;
  final double maxWidth;

  const _ArgChip({required this.label, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: 11,
            color: tokens.accentForeground,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// ─── Bash output panel ────────────────────────────────────────────────────────

class _BashOutputPanel extends StatelessWidget {
  final String command;
  final String? output;
  final bool running;

  const _BashOutputPanel({
    required this.command,
    required this.output,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final codeTheme = buildMessageCodeBlockTheme(context);
    final highlightTheme = buildHighlightTheme(context);
    final displayOutput = (output?.isNotEmpty == true)
        ? output!
        : (running ? 'running...' : 'no output');

    // 构建命令行内容
    final Widget commandWidget;
    if (command.isNotEmpty) {
      // 使用底层 highlight API 进行语法高亮
      final result = highlight.parse(command, language: 'bash');
      final spans = _convertNodes(result.nodes ?? [], highlightTheme);

      commandWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$ ',
            style: TextStyle(
              color: codeTheme.codeColor,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: codeTheme.codeColor,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'monospace',
              ),
              children: spans.isEmpty ? [TextSpan(text: command)] : spans,
            ),
          ),
        ],
      );
    } else {
      commandWidget = const SizedBox.shrink();
    }

    // 构建内容
    final Widget content;
    if (command.isNotEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commandWidget,
          const SizedBox(height: 8),
          SelectableText(
            displayOutput.trimRight(),
            style: TextStyle(
              color: codeTheme.codeColor,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      );
    } else {
      content = SelectableText(
        displayOutput,
        style: TextStyle(
          color: codeTheme.codeColor,
          fontSize: 13,
          height: 1.5,
          fontFamily: 'monospace',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: codeTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: codeTheme.borderColor),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _kToolPanelMaxHeight),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: content,
            ),
          ),
        ),
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

// ─── Edit diff panel ─────────────────────────────────────────────────────────

class _EditDiffPanel extends StatelessWidget {
  final String oldString;
  final String newString;

  const _EditDiffPanel({required this.oldString, required this.newString});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: DiffView(
        before: oldString,
        after: newString,
        maxHeight: _kToolPanelMaxHeight,
      ),
    );
  }
}

// ─── Patch diff panel (apply_patch) ──────────────────────────────────────────

class _PatchDiffPanel extends StatelessWidget {
  final List<Map<String, dynamic>> files;

  const _PatchDiffPanel({required this.files});

  String _fileName(String? path) {
    if (path == null || path.isEmpty) return '';
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => normalized);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (files.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: files.map((file) {
          final before = file['before']?.toString() ?? '';
          final after = file['after']?.toString() ?? '';
          final relativePath = file['relativePath']?.toString();
          final filePath = file['filePath']?.toString();
          final path = (relativePath?.isNotEmpty == true)
              ? relativePath!
              : filePath ?? '';
          final fileName = _fileName(path);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fileName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.mutedForeground,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              DiffView(
                before: before,
                after: after,
                fileName: fileName,
                maxHeight: _kToolPanelMaxHeight,
              ),
              if (file != files.last) const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── File path panel (write) ──────────────────────────────────────────────────

class _FilePathPanel extends StatelessWidget {
  final String filePath;

  const _FilePathPanel({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _kToolPanelMaxHeight),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                filePath,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.mutedForeground,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
