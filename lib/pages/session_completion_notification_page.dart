import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/session_completion_notification_provider.dart';
import '../service/notification/local_notification_service.dart';

class SessionCompletionNotificationPage extends ConsumerWidget {
  const SessionCompletionNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(sessionCompletionNotificationModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionCompletionNotificationTitle)),
      body: RadioGroup<SessionCompletionNotificationMode>(
        groupValue: selected,
        onChanged: (value) async {
          if (value == null) return;
          await ref
              .read(sessionCompletionNotificationModeProvider.notifier)
              .setMode(value);
          if (value == SessionCompletionNotificationMode.none) return;
          await ref
              .read(localNotificationServiceProvider)
              .ensurePermissionPrompted();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              l10n.sessionCompletionNotificationDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final mode in SessionCompletionNotificationMode.values)
              RadioListTile<SessionCompletionNotificationMode>(
                value: mode,
                title: Text(mode.label(l10n)),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }
}
