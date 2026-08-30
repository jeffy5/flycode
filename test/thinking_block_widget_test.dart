import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/service/api/models/parts.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/message_part.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ReasoningPart _reasoningPart({
  String id = 'reasoning-1',
  required String text,
  int? start = 1000,
  int? end,
}) {
  return ReasoningPart(
    id: id,
    sessionID: 'session-1',
    messageID: 'message-1',
    type: 'reasoning',
    text: text,
    time: PartTime(start: start, end: end),
  );
}

Widget _buildHarness(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('completed reasoning shows duration label and stays collapsed', (
    tester,
  ) async {
    final part = _reasoningPart(text: 'chain of thought', end: 11000);

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(part: part, isStreaming: false, isExpanded: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thought for 10s'), findsOneWidget);
    expect(find.text('chain of thought'), findsNothing);
  });

  testWidgets('streaming reasoning shows in-progress label', (tester) async {
    final part = _reasoningPart(text: 'partial thoughts');

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(part: part, isStreaming: true, isExpanded: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.text('partial thoughts'), findsNothing);
  });

  testWidgets('expanded reasoning renders text body', (tester) async {
    final part = _reasoningPart(text: 'rendered reasoning', end: 11000);

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(part: part, isStreaming: false, isExpanded: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thought for 10s'), findsOneWidget);
    expect(find.text('rendered reasoning'), findsOneWidget);
  });

  testWidgets('completed reasoning body renders full text immediately', (
    tester,
  ) async {
    final part = _reasoningPart(text: 'already finished reasoning', end: 11000);

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(
          part: part,
          isStreaming: true,
          isExpanded: true,
          animate: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('already finished reasoning'), findsOneWidget);
  });

  testWidgets('mid-stream expansion shows existing backlog immediately', (
    tester,
  ) async {
    final part = _reasoningPart(text: 'accumulated while collapsed');

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(
          part: part,
          isStreaming: true,
          isExpanded: true,
          animate: true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('accumulated while collapsed'), findsOneWidget);
  });

  testWidgets('tapping header reports expanded via callback', (tester) async {
    final part = _reasoningPart(text: 'tap target', end: 11000);
    bool? reportedExpanded;

    await tester.pumpWidget(
      _buildHarness(
        ThinkingBlockWidget(
          part: part,
          isStreaming: false,
          isExpanded: false,
          onExpandedChanged: (isExpanded) {
            reportedExpanded = isExpanded;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('tap target'), findsNothing);

    await tester.tap(find.byKey(kThinkingBlockHeaderKey));
    await tester.pumpAndSettle();

    expect(reportedExpanded, isTrue);
  });
}
