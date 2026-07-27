import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/session_provider.dart';
import '../route_navigation.dart';
import '../service/api/models/session.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/diff_view.dart';

// ──────────────────────────────────────────────
// 页面入口
// ──────────────────────────────────────────────

class SessionDiffPage extends ConsumerWidget {
  const SessionDiffPage({super.key, required this.sessionID});

  final String sessionID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final diffsAsync = ref.watch(sessionDiffProvider(sessionID));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.sessionDiffTitle,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
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
      ),
      body: diffsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.tokens.pageHorizontalPadding,
              vertical: 24,
            ),
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
                  l10n.sessionDiffLoadFailed,
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
        ),
        data: (diffs) {
          if (diffs.isEmpty) {
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
                      Icons.check_circle_outline_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.sessionDiffEmptyTitle,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sessionDiffEmptySubtitle,
                    style: TextStyle(
                      color: tokens.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          // 汇总统计
          final totalAdditions = diffs.fold(0, (s, d) => s + d.additions);
          final totalDeletions = diffs.fold(0, (s, d) => s + d.deletions);

          return Column(
            children: [
              _SummaryBar(
                fileCount: diffs.length,
                additions: totalAdditions,
                deletions: totalDeletions,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  itemCount: diffs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: tokens.border.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, index) =>
                      _FileDiffTile(diff: diffs[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 顶部汇总栏
// ──────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.fileCount,
    required this.additions,
    required this.deletions,
  });

  final int fileCount;
  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.accent,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 14,
            color: tokens.mutedForeground,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.sessionDiffFilesCount(fileCount),
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
          const SizedBox(width: 12),
          Text(
            '+$additions',
            style: TextStyle(
              fontSize: 12,
              color: tokens.successForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '-$deletions',
            style: TextStyle(
              fontSize: 12,
              color: tokens.errorSoftForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 单文件 diff 展开块
// ──────────────────────────────────────────────

class _FileDiffTile extends StatelessWidget {
  const _FileDiffTile({required this.diff});

  final FileDiff diff;

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final fileName = _fileName(diff.file);
    final isNewFile = diff.before.isEmpty && diff.after.isNotEmpty;
    final isDeletedFile = diff.before.isNotEmpty && diff.after.isEmpty;

    return Theme(
      // 移除 ExpansionTile 默认顶部分隔线
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _iconBgColor(context, isNewFile, isDeletedFile),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _fileIcon(isNewFile, isDeletedFile),
            size: 16,
            color: _iconColor(context, isNewFile, isDeletedFile),
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: diff.file != fileName
            ? Text(
                diff.file,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diff.additions > 0)
              Text(
                '+${diff.additions}',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.successForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (diff.additions > 0 && diff.deletions > 0)
              const SizedBox(width: 4),
            if (diff.deletions > 0)
              Text(
                '-${diff.deletions}',
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.errorSoftForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 6),
            // 查看文件内容按钮
            GestureDetector(
              onTap: () => context.pushFileContentByPath(diff.file),
              child: Tooltip(
                message: context.l10n.sessionDiffViewFileContent,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.visibility_outlined,
                    size: 15,
                    color: tokens.mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: tokens.mutedForeground,
            ),
          ],
        ),
        expandedAlignment: Alignment.topLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 4,
            ),
            child: DiffView(
              before: diff.before,
              after: diff.after,
              fileName: diff.file,
            ),
          ),
        ],
      ),
    );
  }

  Color _iconBgColor(BuildContext context, bool isNew, bool isDeleted) {
    final tokens = context.tokens;
    if (isNew) return tokens.success.withValues(alpha: 0.7);
    if (isDeleted) return tokens.errorSoft.withValues(alpha: 0.7);
    return tokens.accent;
  }

  IconData _fileIcon(bool isNew, bool isDeleted) {
    if (isNew) return Icons.add_circle_outline_rounded;
    if (isDeleted) return Icons.remove_circle_outline_rounded;
    return Icons.insert_drive_file_outlined;
  }

  Color _iconColor(BuildContext context, bool isNew, bool isDeleted) {
    final tokens = context.tokens;
    if (isNew) return tokens.successForeground;
    if (isDeleted) return tokens.errorSoftForeground;
    return tokens.mutedForeground;
  }
}
