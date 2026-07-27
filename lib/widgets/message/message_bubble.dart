import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/provider_list_provider.dart';
import '../../service/api/models/provider.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart'
    hide
        ProviderAuthError,
        UnknownError,
        MessageOutputLengthError,
        MessageAbortedError,
        ApiError;
import '../../theme/app_tokens.dart';
import 'message_part.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;
  final bool isLatestMessage;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageBubble({
    super.key,
    required this.messageWithParts,
    required this.prevIsUser,
    this.isLatestMessage = false,
    this.onNavigateToSubSession,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _copied = false;

  String get _messageId {
    final info = widget.messageWithParts.info;
    if (info is UserMessage) {
      return info.id;
    }
    if (info is AssistantMessage) {
      return info.id;
    }
    return info.hashCode.toString();
  }

  Key _partKey(Object part, int index) {
    final id = switch (part) {
      TextPart p => p.id,
      FilePart p => p.id,
      ToolPart p => p.id,
      ReasoningPart p => p.id,
      StepStartPart p => p.id,
      StepFinishPart p => p.id,
      SnapshotPart p => p.id,
      PatchPart p => p.id,
      AgentPart p => p.id,
      RetryPart p => p.id,
      CompactionPart p => p.id,
      SubtaskPart p => p.id,
      _ => index.toString(),
    };
    return ValueKey('$_messageId/$id');
  }

  String _extractText() {
    final buffer = StringBuffer();
    for (final part in widget.messageWithParts.parts) {
      if (part is TextPart && part.synthetic != true && part.text.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(part.text);
      }
    }
    return buffer.toString();
  }

  bool get _hasTextContent {
    for (final part in widget.messageWithParts.parts) {
      if (part is TextPart && part.synthetic != true && part.text.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _copyMessage() async {
    final text = _extractText();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final providerList = ref.watch(providerListProvider).asData?.value;
    final isUser = widget.messageWithParts.info is UserMessage;
    final userMessage = isUser
        ? widget.messageWithParts.info as UserMessage
        : null;
    final assistantMessage = !isUser
        ? widget.messageWithParts.info as AssistantMessage
        : null;

    final error = assistantMessage?.error;
    if (error != null) {
      return _buildErrorWidget(context, error);
    }

    if (isUser) {
      return _buildUserBubble(context, userMessage!, providerList);
    }

    return _buildAssistantContent(context, assistantMessage!, providerList);
  }

  String _resolveModelLabel(
    ProviderListResponse? providerList,
    String providerId,
    String modelId,
  ) {
    if (providerList == null) {
      return modelId;
    }
    for (final provider in providerList.all) {
      if (provider.id != providerId) {
        continue;
      }
      final model = provider.models[modelId];
      if (model != null && model.name.isNotEmpty) {
        return model.name;
      }
    }
    return modelId;
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildErrorWidget(BuildContext context, Object error) {
    final errorMessage = _getErrorMessage(error);
    final errorName = _getErrorName(error);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.errorSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tokens.errorSoftForeground.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.errorSoftForeground,
                    ),
                  ),
                ),
              ],
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.errorSoftForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is ProviderAuthError) return error.message;
    if (error is UnknownError) return error.message;
    if (error is MessageOutputLengthError) {
      return error.data['message'] as String? ?? '';
    }
    if (error is MessageAbortedError) return error.message;
    if (error is ApiError) return error.message;
    return '';
  }

  String _getErrorName(Object error) {
    if (error is ProviderAuthError) return 'Authentication Failed';
    if (error is UnknownError) return 'Error';
    if (error is MessageOutputLengthError) return 'Output Limit Exceeded';
    if (error is MessageAbortedError) return 'Message Aborted';
    if (error is ApiError) return 'API Error';
    return 'Unknown Error';
  }

  // ─── User bubble ──────────────────────────────────────────────────────────

  Widget _buildUserBubble(
    BuildContext context,
    UserMessage userMessage,
    ProviderListResponse? providerList,
  ) {
    final tokens = context.tokens;
    final modelLabel = _resolveModelLabel(
      providerList,
      userMessage.model.providerID,
      userMessage.model.modelID,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.info,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildUserPartWidgets(),
                ),
              ),
              const SizedBox(height: 6),
              _UserFooter(
                message: userMessage,
                agentLabel: _formatAgentLabel(userMessage.agent),
                modelLabel: modelLabel,
                copied: _copied,
                onCopy: _copyMessage,
                showCopy: _hasTextContent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildUserPartWidgets() {
    final widgets = <Widget>[];
    final parts = widget.messageWithParts.parts;
    var index = 0;

    while (index < parts.length) {
      final part = parts[index];
      if (_isImageFilePart(part)) {
        final galleryParts = <FilePart>[];
        final startIndex = index;
        while (index < parts.length && _isImageFilePart(parts[index])) {
          galleryParts.add(parts[index] as FilePart);
          index += 1;
        }
        widgets.add(
          MessageImageGallery(
            key: ValueKey('$_messageId/image-gallery-$startIndex'),
            images: galleryParts,
          ),
        );
        continue;
      }

      widgets.add(
        MessagePart(
          key: _partKey(part, index),
          part: part,
          isUser: true,
          onNavigateToSubSession: widget.onNavigateToSubSession,
        ),
      );
      index += 1;
    }

    return widgets;
  }

  bool _isImageFilePart(Object part) =>
      part is FilePart && part.mime.startsWith('image/');

  // ─── Assistant content (no bubble) ────────────────────────────────────────

  Widget _buildAssistantContent(
    BuildContext context,
    AssistantMessage assistantMessage,
    ProviderListResponse? providerList,
  ) {
    final modelLabel = _resolveModelLabel(
      providerList,
      assistantMessage.providerID,
      assistantMessage.modelID,
    );
    final isStreaming = assistantMessage.time.completed == null;
    final parts = widget.messageWithParts.parts;
    final lastAnimatedTextPartIndex = parts.lastIndexWhere(
      (p) => p is TextPart && p.text.isNotEmpty,
    );
    final lastTextPartIndex = parts.lastIndexWhere(
      (p) => p is TextPart && p.synthetic != true && p.text.isNotEmpty,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            MessagePart(
              key: _partKey(parts[i], i),
              part: parts[i],
              isUser: false,
              isStreaming: isStreaming,
              animateText:
                  widget.isLatestMessage &&
                  isStreaming &&
                  i == lastAnimatedTextPartIndex,
              onNavigateToSubSession: widget.onNavigateToSubSession,
            ),
            if (i == lastTextPartIndex) ...[
              const SizedBox(height: 6),
              _AssistantFooter(
                message: assistantMessage,
                modelLabel: modelLabel,
                copied: _copied,
                onCopy: _copyMessage,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Assistant footer & Copy Button ──────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  final bool copied;
  final VoidCallback onCopy;

  const _CopyButton({required this.copied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onCopy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: copied
            ? Row(
                key: ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: tokens.successForeground),
                  SizedBox(width: 4),
                  Text(
                    context.l10n.messageCopied,
                    style: TextStyle(
                      color: tokens.successForeground,
                      fontSize: 12,
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
                    color: tokens.mutedForeground,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AssistantFooter extends StatelessWidget {
  final AssistantMessage message;
  final String modelLabel;
  final bool copied;
  final VoidCallback onCopy;

  const _AssistantFooter({
    required this.message,
    required this.modelLabel,
    required this.copied,
    required this.onCopy,
  });

  String? _formatCompletedTime(int? completed) {
    if (completed == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(completed);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final completedTimeLabel = _formatCompletedTime(message.time.completed);
    final tokens = context.tokens;

    return DefaultTextStyle(
      style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
      child: Row(
        children: [
          _CopyButton(copied: copied, onCopy: onCopy),
          const SizedBox(width: 12),
          Flexible(
            fit: FlexFit.loose,
            child: Text(modelLabel, overflow: TextOverflow.ellipsis),
          ),
          if (completedTimeLabel != null) ...[
            const Text(' · '),
            Text(completedTimeLabel),
          ],
        ],
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  final UserMessage message;
  final String agentLabel;
  final String modelLabel;
  final bool copied;
  final VoidCallback onCopy;
  final bool showCopy;

  const _UserFooter({
    required this.message,
    required this.agentLabel,
    required this.modelLabel,
    required this.copied,
    required this.onCopy,
    required this.showCopy,
  });

  String _displayModelAndAgent() {
    if (agentLabel.isEmpty) return modelLabel;
    if (modelLabel.isEmpty) return agentLabel;
    return '$agentLabel · $modelLabel';
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(message.time.created);
    final maxModelWidth = MediaQuery.of(context).size.width * 0.35;
    final tokens = context.tokens;
    final modelAndAgentLabel = _displayModelAndAgent();

    return DefaultTextStyle(
      style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxModelWidth),
              child: Text(
                modelAndAgentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Text(timeLabel),
            if (showCopy) ...[
              const SizedBox(width: 12),
              _CopyButton(copied: copied, onCopy: onCopy),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatAgentLabel(String agent) {
  if (agent.isEmpty) return '';
  return '${agent[0].toUpperCase()}${agent.substring(1)}';
}
