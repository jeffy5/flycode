import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/session_provider.dart';
import '../service/api/session_api.dart';
import '../providers/provider_list_provider.dart';
import '../service/api/models/message.dart'
    hide MessageTokens, MessageCacheTokens;
import '../service/api/models/provider.dart';
import '../service/api/models/session.dart';
import '../theme/app_tokens.dart';

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------

/// Flattened token snapshot – avoids name clash between message.dart and
/// parts.dart both defining MessageTokens.
class _TokenSnapshot {
  final int input;
  final int output;
  final int total;
  final int? reasoning;
  final int? cacheRead;
  final int? cacheWrite;

  const _TokenSnapshot({
    required this.input,
    required this.output,
    required this.total,
    this.reasoning,
    this.cacheRead,
    this.cacheWrite,
  });
}

class _ContextMetrics {
  final _TokenSnapshot? snapshot;

  /// Total cost in USD (sum of AssistantMessage.cost + StepFinishPart.cost).
  final double totalCostUsd;
  final int totalTokens;
  final int? contextLimit;
  final String modelID;
  final String providerID;
  final int userMessageCount;
  final int assistantMessageCount;

  const _ContextMetrics({
    required this.snapshot,
    required this.totalCostUsd,
    required this.totalTokens,
    required this.contextLimit,
    required this.modelID,
    required this.providerID,
    required this.userMessageCount,
    required this.assistantMessageCount,
  });

  double get usagePercent => contextLimit != null && contextLimit! > 0
      ? (totalTokens / contextLimit!).clamp(0.0, 1.0)
      : 0.0;

  String get costString {
    if (totalCostUsd == 0) return 'US\$0.00';
    if (totalCostUsd < 0.01) return 'US\$<0.01';
    return 'US\$${totalCostUsd.toStringAsFixed(2)}';
  }
}

_ContextMetrics _computeMetrics(
  List<MessageWithParts> messages,
  ModelInfo? modelInfo,
) {
  _TokenSnapshot? snapshot;
  double totalCostUsd = 0;
  int userCount = 0;
  int assistantCount = 0;
  String modelID = '';
  String providerID = '';

  for (final msg in messages) {
    if (msg.info is UserMessage) {
      userCount++;
    } else if (msg.info is AssistantMessage) {
      final a = msg.info as AssistantMessage;
      assistantCount++;
      if (a.cost != null) {
        totalCostUsd += a.cost!;
      }
      if ((a.tokens.total ?? 0) > 0) {
        snapshot = _TokenSnapshot(
          input: a.tokens.input ?? 0,
          output: a.tokens.output ?? 0,
          total: a.tokens.total ?? 0,
          reasoning: a.tokens.reasoning,
          cacheRead: a.tokens.cache?.read,
          cacheWrite: a.tokens.cache?.write,
        );
        modelID = a.modelID;
        providerID = a.providerID;
      }
    }
  }

  return _ContextMetrics(
    snapshot: snapshot,
    totalCostUsd: totalCostUsd,
    totalTokens: snapshot?.total ?? 0,
    contextLimit: modelInfo?.limit.context,
    modelID: modelID,
    providerID: providerID,
    userMessageCount: userCount,
    assistantMessageCount: assistantCount,
  );
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class SessionContextPage extends ConsumerWidget {
  const SessionContextPage({super.key, required this.sessionID});

  final String sessionID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider(sessionID));
    final sessionsAsync = ref.watch(sessionsProvider);
    final providerListAsync = ref.watch(providerListProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          l10n.sessionContextTitle,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.border)),
            ),
          ),
        ),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.sessionContextLoadFailed(e.toString()))),
        data: (messages) {
          final sessions = sessionsAsync.asData?.value ?? const <Session>[];
          Session? session;
          for (final item in sessions) {
            if (item.id == sessionID) {
              session = item;
              break;
            }
          }

          ModelInfo? modelInfo;
          String? lastModelID;
          String? lastProviderID;
          for (final msg in messages.reversed) {
            if (msg.info is AssistantMessage) {
              final a = msg.info as AssistantMessage;
              lastModelID = a.modelID;
              lastProviderID = a.providerID;
              break;
            }
          }
          if (lastModelID != null &&
              lastProviderID != null &&
              providerListAsync.hasValue) {
            final pList = providerListAsync.value!;
            try {
              final provider = pList.all.firstWhere(
                (p) => p.id == lastProviderID,
              );
              modelInfo = provider.models[lastModelID];
            } catch (_) {}
          }

          final metrics = _computeMetrics(messages, modelInfo);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionMessagesProvider(sessionID));
              await ref.read(providerListProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _UsageSection(metrics: metrics),
                const SizedBox(height: 16),
                _SessionInfoCard(metrics: metrics, session: session),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Usage ring section
// ---------------------------------------------------------------------------

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.metrics});
  final _ContextMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final percent = metrics.usagePercent;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final usageColor = _usageColor(context, percent);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _RingPainter(progress: percent, color: usageColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: usageColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.sessionContextUsed,
                      style: TextStyle(
                        fontSize: 13,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: context.l10n.sessionContextTotalTokens,
                  value: _formatNum(metrics.totalTokens),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StatCell(
                  label: context.l10n.sessionContextLimit,
                  value: metrics.contextLimit != null
                      ? _formatNum(metrics.contextLimit!)
                      : '—',
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _StatCell(
                  label: context.l10n.sessionContextTotalCost,
                  value: metrics.costString,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _usageColor(BuildContext context, double p) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    if (p >= 0.9) return theme.colorScheme.error;
    if (p >= 0.75) return tokens.warningForeground;
    return theme.colorScheme.primary;
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trackColor = progress > 0.9
        ? Colors.transparent
        : color.withValues(alpha: 0.18);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 10;
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// Session info card
// ---------------------------------------------------------------------------

class _SessionInfoCard extends StatelessWidget {
  const _SessionInfoCard({required this.metrics, required this.session});
  final _ContextMetrics metrics;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.sessionContextInfoTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: context.l10n.sessionContextProvider,
            value: metrics.providerID.isEmpty ? '—' : metrics.providerID,
          ),
          const Divider(height: 20),
          _InfoRow(
            label: context.l10n.sessionContextModel,
            value: metrics.modelID.isEmpty ? '—' : metrics.modelID,
          ),
          const Divider(height: 20),
          _InfoRow(
            label: context.l10n.sessionContextUserMessages,
            value: '${metrics.userMessageCount}',
          ),
          const Divider(height: 20),
          _InfoRow(
            label: context.l10n.sessionContextAssistantMessages,
            value: '${metrics.assistantMessageCount}',
          ),
          const Divider(height: 20),
          _InfoRow(
            label: context.l10n.sessionContextCreatedAt,
            value: session != null ? _formatTime(session!.time.created) : '—',
          ),
          const Divider(height: 20),
          _InfoRow(
            label: context.l10n.sessionContextLastActive,
            value: session != null ? _formatTime(session!.time.updated) : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: tokens.mutedForeground),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: context.tokens.border);
  }
}

String _formatNum(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  return '$n';
}

String _formatTime(int timestampMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final y = dt.year;
  final mo = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mi = dt.minute.toString().padLeft(2, '0');
  return '$y/$mo/$d $h:$mi';
}
