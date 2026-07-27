import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/permission_provider.dart';
import '../../service/api/models/permission.dart';
import '../../theme/app_tokens.dart';

class SessionPermissionDock extends ConsumerWidget {
  const SessionPermissionDock({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    ref.watch(pendingPermissionsProvider);
    final notifier = ref.read(pendingPermissionsProvider.notifier);
    final responding = notifier.isResponding(request.id);

    Future<void> decide(PermissionReplyAction action) async {
      try {
        await notifier.respond(request, reply: action);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.permissionDockReplyFailed(e.toString()))),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusM),
        border: Border.all(color: tokens.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.permissionDockTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${request.permission} · ${request.patterns.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: tokens.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 47,
                child: OutlinedButton(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.reject),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    foregroundColor: colorScheme.error,
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(color: tokens.errorSoftForeground),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.permissionDockDeny),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 55,
                child: FilledButton(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.always),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.permissionDockAllowAlways),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 47,
                child: OutlinedButton(
                  onPressed: responding
                      ? null
                      : () => decide(PermissionReplyAction.once),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    foregroundColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.permissionDockAllowOnce),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
