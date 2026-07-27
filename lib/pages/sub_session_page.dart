import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n.dart';
import '../providers/session_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/message_error_state.dart';
import '../widgets/message/message_list.dart';

/// 子 Session 只读消息列表页
///
/// 通过 [sessionID] 加载并展示子 Session 的消息，支持 SSE 实时更新。
/// 不支持发送消息，通过系统返回手势/按钮回到父 Session。
class SubSessionPage extends ConsumerWidget {
  final String sessionID;

  const SubSessionPage({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(subSessionMessagesProvider(sessionID));
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sub Session',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          if (kDebugMode) {
            debugPrint('SubSessionPage Error: $error\n$stack');
          }
          return MessageErrorState(message: l10n.messageListLoadFailed);
        },
        data: (messages) => MessageListView(messages: messages),
      ),
    );
  }
}
