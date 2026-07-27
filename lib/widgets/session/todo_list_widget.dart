import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/todo_provider.dart';
import '../../service/api/models/global_event.dart' show Todo;
import '../../theme/app_tokens.dart';

/// 展示当前 session 的 AI Todo 任务列表。
///
/// 展示规则：
/// - 只有存在非 completed 的 todo 时才显示整个区域
/// - 展开态展示所有 todo，保持原始顺序
/// - 折叠态仅预览第一个 in_progress todo
/// - 支持折叠/展开
class TodoListWidget extends ConsumerStatefulWidget {
  const TodoListWidget({super.key, required this.sessionID});

  final String sessionID;

  @override
  ConsumerState<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends ConsumerState<TodoListWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(sessionTodosProvider(widget.sessionID));

    return todosAsync.when(
      data: (todos) => _buildContent(context, todos),
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, List<Todo> todos) {
    final tokens = context.tokens;

    // 只有存在非 completed 的 todo 时才显示
    final hasActive = todos.any((t) => t.status != 'completed');
    if (!hasActive) return const SizedBox.shrink();
    final currentTodo = todos
        .where((t) => t.status == 'in_progress')
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, todos),
          if (_expanded) ...[
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.45)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: todos.length,
              separatorBuilder: (_, idx) => Divider(
                height: 1,
                indent: 40,
                color: tokens.border.withValues(alpha: 0.25),
              ),
              itemBuilder: (context, index) => _buildTodoItem(todos[index]),
            ),
          ] else if (currentTodo != null) ...[
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.45)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildTodoItem(currentTodo),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Todo> todos) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final inProgressCount = todos
        .where((t) => t.status == 'in_progress')
        .length;
    final pendingCount = todos.where((t) => t.status == 'pending').length;
    final completedCount = todos.where((t) => t.status == 'completed').length;

    return InkWell(
      borderRadius: _expanded
          ? const BorderRadius.vertical(top: Radius.circular(16))
          : BorderRadius.circular(16),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 16,
              color: tokens.mutedForeground,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.todoPanelTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 8),
            if (inProgressCount > 0)
              _buildBadge(
                l10n.todoBadgeInProgress(inProgressCount),
                tokens.infoForeground,
              ),
            if (pendingCount > 0)
              _buildBadge(
                l10n.todoBadgePending(pendingCount),
                tokens.mutedForeground,
              ),
            if (completedCount > 0)
              _buildBadge(
                l10n.todoBadgeCompleted(completedCount),
                tokens.successForeground,
              ),
            const Spacer(),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: tokens.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    final tokens = context.tokens;
    final statusInfo = _statusInfo(todo.status);
    final isCompleted = todo.status == 'completed';
    final priorityInfo = _priorityInfo(todo.priority);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态图标
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(statusInfo.icon, size: 16, color: statusInfo.color),
          ),
          const SizedBox(width: 10),
          // 任务内容
          Expanded(
            child: Text(
              todo.content,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted
                    ? tokens.mutedForeground.withValues(alpha: 0.6)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.9),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: tokens.mutedForeground.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 优先级标签
          if (todo.priority != 'low')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: priorityInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: priorityInfo.color.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                priorityInfo.label,
                style: TextStyle(
                  fontSize: 10,
                  color: priorityInfo.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(String status) {
    final tokens = context.tokens;
    switch (status) {
      case 'in_progress':
        return _StatusInfo(
          icon: Icons.radio_button_checked,
          color: tokens.infoForeground,
        );
      case 'completed':
        return _StatusInfo(
          icon: Icons.check_circle,
          color: tokens.successForeground,
        );
      case 'cancelled':
        return _StatusInfo(
          icon: Icons.cancel,
          color: Theme.of(context).colorScheme.error,
        );
      default: // pending
        return _StatusInfo(
          icon: Icons.radio_button_unchecked,
          color: tokens.mutedForeground,
        );
    }
  }

  _PriorityInfo _priorityInfo(String priority) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    switch (priority) {
      case 'high':
        return _PriorityInfo(
          label: l10n.todoPriorityHigh,
          color: Theme.of(context).colorScheme.error,
        );
      case 'medium':
        return _PriorityInfo(
          label: l10n.todoPriorityMedium,
          color: tokens.warningForeground,
        );
      default: // low
        return _PriorityInfo(
          label: l10n.todoPriorityLow,
          color: tokens.mutedForeground,
        );
    }
  }
}

class _StatusInfo {
  const _StatusInfo({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

class _PriorityInfo {
  const _PriorityInfo({required this.label, required this.color});
  final String label;
  final Color color;
}
