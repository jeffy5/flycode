import 'package:flycode/service/api/models/parts.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/message_markdown_theme.dart';
import 'package:flycode/widgets/message/message_part.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const markdown = '''
# Heading 1

This is a paragraph with **bold text**, *italic text*, and [OpenAI](https://openai.com).

> This is a blockquote.

You can use `inline code` within text.

---

```dart
// This is a code block
void main() {
  print('Hello, World!');
}
```

| Feature | Support |
| --- | --- |
| Bold | Yes |
| Tables | Yes |

- [ ] Pending task
- [x] Completed task
''';

  Widget buildHarness({required Brightness brightness, required Widget child}) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    );
  }

  MessagePart buildMessagePart() {
    return MessagePart(
      part: TextPart(
        id: 'part-1',
        sessionID: 'session-1',
        messageID: 'message-1',
        type: 'text',
        text: markdown,
      ),
      isUser: false,
    );
  }

  TextStyle? findSpanStyle(WidgetTester tester, String targetText) {
    for (final widget in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      final textSpan = widget.textSpan;
      if (textSpan == null) {
        continue;
      }
      final style = _findSpanStyle(textSpan, targetText);
      if (style != null) {
        return style;
      }
    }
    return null;
  }

  TapGestureRecognizer? findLinkRecognizer(
    WidgetTester tester,
    String targetText,
  ) {
    for (final widget in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      final textSpan = widget.textSpan;
      if (textSpan == null) {
        continue;
      }
      final recognizer = _findLinkRecognizer(textSpan, targetText);
      if (recognizer != null) {
        return recognizer;
      }
    }
    return null;
  }

  tearDown(() {
    debugMessageMarkdownLinkLauncher = _noopLauncher;
  });

  testWidgets('renders markdown semantics with themed styles', (tester) async {
    debugMessageMarkdownLinkLauncher = _noopLauncher;

    await tester.pumpWidget(
      buildHarness(brightness: Brightness.light, child: buildMessagePart()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heading 1'), findsOneWidget);
    expect(find.byKey(messageMarkdownCodeBlockKey), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.text('Pending task'), findsOneWidget);
    expect(find.text('Completed task'), findsOneWidget);

    final headingStyle = findSpanStyle(tester, 'Heading 1');
    expect(headingStyle?.fontFamily, 'PlusJakartaSans');
    expect(headingStyle?.fontSize, 22);
    expect(headingStyle?.fontWeight, FontWeight.w700);

    final inlineCodeStyle = findSpanStyle(tester, 'inline code');
    expect(inlineCodeStyle?.fontFamily, 'monospace');
    expect(inlineCodeStyle?.fontSize, 14);
    expect(inlineCodeStyle?.fontWeight, FontWeight.w500);
    expect(inlineCodeStyle?.backgroundColor, isNull);

    final styleSheet = buildMessageMarkdownStyleSheet(
      tester.element(find.byType(MessagePart)),
    );
    final blockquoteDecoration =
        styleSheet.blockquoteDecoration! as BoxDecoration;
    final blockquoteBorder = blockquoteDecoration.border! as Border;
    expect(findSpanStyle(tester, 'This is a blockquote.'), isNotNull);
    expect(blockquoteBorder.left.width, 3);

    final completedTaskStyle = findSpanStyle(tester, 'Completed task');
    expect(completedTaskStyle?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('renders fenced code blocks as selectable text', (tester) async {
    debugMessageMarkdownLinkLauncher = _noopLauncher;

    await tester.pumpWidget(
      buildHarness(brightness: Brightness.light, child: buildMessagePart()),
    );
    await tester.pumpAndSettle();

    final selectableCodeBlock = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .where((widget) {
          final textSpan = widget.textSpan;
          return textSpan != null &&
              textSpan.toPlainText().contains('// This is a code block') &&
              textSpan.toPlainText().contains("print('Hello, World!');");
        });

    expect(selectableCodeBlock, isNotEmpty);
  });

  testWidgets('tapping markdown link uses link launcher', (tester) async {
    Uri? openedUri;
    debugMessageMarkdownLinkLauncher = (uri) async {
      openedUri = uri;
    };

    await tester.pumpWidget(
      buildHarness(brightness: Brightness.light, child: buildMessagePart()),
    );
    await tester.pumpAndSettle();

    final recognizer = findLinkRecognizer(tester, 'OpenAI');
    expect(recognizer, isNotNull);

    recognizer!.onTap!();
    await tester.pump();

    expect(openedUri, Uri.parse('https://openai.com'));
  });

  testWidgets('applies distinct markdown surfaces in dark theme', (
    tester,
  ) async {
    debugMessageMarkdownLinkLauncher = _noopLauncher;

    await tester.pumpWidget(
      buildHarness(brightness: Brightness.dark, child: buildMessagePart()),
    );
    await tester.pumpAndSettle();

    final codeBlock = tester.widget<Container>(
      find.byKey(messageMarkdownCodeBlockKey),
    );
    final codeDecoration = codeBlock.decoration! as BoxDecoration;
    expect(codeDecoration.color, const Color(0xFF131124));

    final styleSheet = buildMessageMarkdownStyleSheet(
      tester.element(find.byType(MessagePart)),
    );
    final blockquoteDecoration =
        styleSheet.blockquoteDecoration! as BoxDecoration;
    expect(blockquoteDecoration.color, isNotNull);
    expect(blockquoteDecoration.color, isNot(const Color(0xFFEDE9FE)));

    final darkStyleSheet = buildMessageMarkdownStyleSheet(
      tester.element(find.byType(MessagePart)),
    );
    final table = tester.widget<Table>(find.byType(Table));
    final border = table.border!;
    expect(border.top.color, darkStyleSheet.tableBorder!.top.color);
  });
}

TextStyle? _findSpanStyle(InlineSpan span, String targetText) {
  if (span is TextSpan) {
    if (span.text == targetText) {
      return span.style;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      final style = _findSpanStyle(child, targetText);
      if (style != null) {
        return style;
      }
    }
  }
  return null;
}

TapGestureRecognizer? _findLinkRecognizer(InlineSpan span, String targetText) {
  if (span is TextSpan) {
    if (span.text == targetText && span.recognizer is TapGestureRecognizer) {
      return span.recognizer! as TapGestureRecognizer;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      final recognizer = _findLinkRecognizer(child, targetText);
      if (recognizer != null) {
        return recognizer;
      }
    }
  }
  return null;
}

Future<void> _noopLauncher(Uri uri) async {}
