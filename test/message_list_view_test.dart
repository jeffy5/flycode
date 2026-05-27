// ignore_for_file: type=lint

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/message.dart' as message;
import 'package:flycode/service/api/models/parts.dart';
import 'package:flycode/service/api/models/provider.dart';
import 'package:flycode/service/api/provider_api.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProviderApi extends ProviderApi {
  _FakeProviderApi()
    : super(
        ApiClient(baseUrl: 'http://localhost'),
        preferencesLoader: SharedPreferences.getInstance,
      );

  @override
  Future<ProviderListResponse> list({
    String? directory,
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(minutes: 10),
  }) async => ProviderListResponse(
    all: const [],
    defaultProvider: const {},
    connected: const [],
  );
}

Widget _buildHarness(List<message.MessageWithParts> messages) {
  return ProviderScope(
    overrides: [
      providerApiProvider.overrideWith((ref) async => _FakeProviderApi()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            height: 340,
            child: MessageListView(messages: messages),
          ),
        ),
      ),
    ),
  );
}

message.MessageWithParts _message(int index, {int repeat = 4}) {
  final messageId = 'message-$index';
  return message.MessageWithParts(
    info: message.UserMessage(
      id: messageId,
      sessionID: 'session-1',
      role: 'user',
      time: message.MessageTime(created: index + 1),
      agent: 'codex',
      model: message.MessageModel(providerID: 'openai', modelID: 'gpt-5.4'),
    ),
    parts: [
      TextPart(
        id: 'part-$index',
        sessionID: 'session-1',
        messageID: messageId,
        type: 'text',
        text:
            'Message $index\n${List.filled(repeat, 'Line $index content for scrolling.').join('\n')}',
      ),
    ],
  );
}

List<message.MessageWithParts> _messages(int count, {int repeat = 4}) =>
    List.generate(count, (index) => _message(index, repeat: repeat));

message.MessageWithParts _assistantToolMessage(int index) {
  final messageId = 'assistant-message-$index';
  return message.MessageWithParts(
    info: message.AssistantMessage(
      id: messageId,
      sessionID: 'session-1',
      role: 'assistant',
      time: message.MessageTime(created: index + 1, completed: index + 2),
      parentID: 'parent-$index',
      modelID: 'gpt-5.4',
      providerID: 'openai',
      mode: 'chat',
      path: message.MessagePath(cwd: '/workspace', root: '/workspace'),
      tokens: message.MessageTokens(),
    ),
    parts: [
      ToolPart(
        id: 'tool-part-$index',
        sessionID: 'session-1',
        messageID: messageId,
        type: 'tool',
        callID: 'tool-call-$index',
        tool: 'write',
        metadata: null,
        state: ToolStateCompleted(
          status: 'completed',
          input: {'filePath': '/workspace/lib/file_$index.dart'},
          output: 'done',
          title: '',
          metadata: const {},
          time: ToolStateCompletedTime(start: 0, end: 1),
        ),
      ),
      TextPart(
        id: 'assistant-text-$index',
        sessionID: 'session-1',
        messageID: messageId,
        type: 'text',
        text: 'Assistant message $index',
      ),
    ],
  );
}

IgnorePointer _scrollButtonGuard(WidgetTester tester) {
  return tester.widget<IgnorePointer>(
    find.byKey(const Key('message_list.scroll_to_bottom_guard')),
  );
}

ScrollableState _messageScrollable(WidgetTester tester) {
  return tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .firstWhere(
        (state) =>
            state.position.axis == Axis.vertical &&
            state.position.viewportDimension > 300,
      );
}

double _scrollOffset(WidgetTester tester) {
  final scrollable = _messageScrollable(tester);
  return scrollable.position.pixels;
}

bool _isPinnedToBottom(WidgetTester tester) {
  final scrollable = _messageScrollable(tester);
  return scrollable.position.pixels <=
      scrollable.position.minScrollExtent + 0.5;
}

bool _isDetachedFromBottom(WidgetTester tester) {
  final scrollable = _messageScrollable(tester);
  return scrollable.position.pixels > scrollable.position.minScrollExtent + 72;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('starts pinned to bottom without scroll button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness(_messages(12)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Message 11'), findsOneWidget);
    expect(_scrollButtonGuard(tester).ignoring, isTrue);
  });

  testWidgets('shows scroll to bottom button after user scrolls upward', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness(_messages(12)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 240));
    await tester.pumpAndSettle();

    expect(_scrollButtonGuard(tester).ignoring, isFalse);
  });

  testWidgets(
    'keeps viewport stable when a new message arrives while detached',
    (WidgetTester tester) async {
      var messages = _messages(14);
      await tester.pumpWidget(_buildHarness(messages));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 260));
      await tester.pumpAndSettle();

      final beforeOffset = _scrollOffset(tester);

      messages = [...messages, _message(14)];
      await tester.pumpWidget(_buildHarness(messages));
      await tester.pump();
      await tester.pump();

      expect(_scrollOffset(tester), closeTo(beforeOffset, 1.0));
      expect(_scrollButtonGuard(tester).ignoring, isFalse);
      expect(_isPinnedToBottom(tester), isFalse);
    },
  );

  testWidgets(
    'keeps viewport stable when the latest message text grows while detached',
    (WidgetTester tester) async {
      var messages = _messages(14, repeat: 3);
      await tester.pumpWidget(_buildHarness(messages));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 260));
      await tester.pumpAndSettle();

      messages = [
        ...messages.take(messages.length - 1),
        _message(13, repeat: 12),
      ];
      await tester.pumpWidget(_buildHarness(messages));
      await tester.pump();
      await tester.pump();

      expect(_scrollButtonGuard(tester).ignoring, isFalse);
      expect(_isPinnedToBottom(tester), isFalse);
      expect(_scrollOffset(tester), greaterThan(0));
    },
  );

  testWidgets('stays pinned to bottom when new messages arrive at bottom', (
    WidgetTester tester,
  ) async {
    var messages = _messages(10);
    await tester.pumpWidget(_buildHarness(messages));
    await tester.pumpAndSettle();

    messages = [...messages, _message(10)];
    await tester.pumpWidget(_buildHarness(messages));
    await tester.pumpAndSettle();

    expect(find.textContaining('Message 10'), findsOneWidget);
    expect(_scrollButtonGuard(tester).ignoring, isTrue);
    expect(_isPinnedToBottom(tester), isTrue);
  });

  testWidgets('scroll button animates back to bottom and hides itself', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildHarness(_messages(14)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 260));
    await tester.pumpAndSettle();
    expect(_scrollButtonGuard(tester).ignoring, isFalse);

    await tester.tap(find.byKey(const Key('message_list.scroll_to_bottom')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pumpAndSettle();

    expect(_scrollButtonGuard(tester).ignoring, isTrue);
    expect(find.textContaining('Message 13'), findsOneWidget);
    expect(_isPinnedToBottom(tester), isTrue);
  });

  testWidgets(
    'reattaches to bottom when user returns near the latest message',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildHarness(_messages(14)));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 260));
      await tester.pumpAndSettle();

      expect(_scrollButtonGuard(tester).ignoring, isFalse);
      expect(_isDetachedFromBottom(tester), isTrue);

      final scrollable = _messageScrollable(tester);
      scrollable.position.jumpTo(scrollable.position.minScrollExtent + 16);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(_scrollButtonGuard(tester).ignoring, isTrue);
      expect(_isPinnedToBottom(tester), isTrue);
    },
  );

  testWidgets('tool expansion state survives offscreen scroll rebuilds', (
    WidgetTester tester,
  ) async {
    final messages = [..._messages(24), _assistantToolMessage(99)];

    await tester.pumpWidget(_buildHarness(messages));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1400));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
