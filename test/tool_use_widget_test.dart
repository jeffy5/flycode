import 'package:flycode/service/api/models/parts.dart';
import 'package:flycode/widgets/message/tool_use_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness(Widget child, {double width = 260}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  ToolPart completedToolPart({
    required String tool,
    required Map<String, dynamic> input,
    Map<String, dynamic>? metadata,
  }) {
    return ToolPart(
      id: 'p1',
      sessionID: 's1',
      messageID: 'm1',
      type: 'tool',
      callID: 'c1',
      tool: tool,
      metadata: metadata,
      state: ToolStateCompleted(
        status: 'completed',
        input: input,
        output: '',
        title: '',
        metadata: const {},
        time: ToolStateCompletedTime(start: 0, end: 1),
      ),
    );
  }

  testWidgets('renders long single arg without overflow in narrow width', (
    tester,
  ) async {
    final longPattern = 'pattern=${'very_long_tag_value_' * 12}';
    final part = completedToolPart(
      tool: 'grep',
      input: {
        'pattern': longPattern.substring('pattern='.length),
        'path': '/Users/jeffrey/project/flycode',
      },
    );

    await tester.pumpWidget(buildHarness(ToolUseWidget(toolPart: part)));
    await tester.pumpAndSettle();

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders multiple args and keeps collapse action visible', (
    tester,
  ) async {
    final grepPart = completedToolPart(
      tool: 'grep',
      input: {
        'pattern': 'shared_preferences|prefs|preferences|cache|model',
        'include': '*.dart',
        'path': '/Users/jeffrey/project/flycode',
      },
    );
    final writePart = completedToolPart(
      tool: 'write',
      input: {'filePath': '/Users/jeffrey/project/flycode/lib/app.dart'},
    );

    await tester.pumpWidget(
      buildHarness(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToolUseWidget(toolPart: grepPart),
            ToolUseWidget(toolPart: writePart),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long subtitle uses full width then single-line ellipsis', (
    tester,
  ) async {
    final longPath =
        '/Users/jeffrey/project/flycode/lib/really/long/path/that/keeps/'
        'going/and/going/tool_use_widget_overflow_regression_case.dart';
    final part = completedToolPart(
      tool: 'glob',
      input: {'pattern': 'lib/providers/*.dart', 'path': longPath},
    );

    await tester.pumpWidget(buildHarness(ToolUseWidget(toolPart: part)));
    await tester.pumpAndSettle();

    final subtitleFinder = find.byWidgetPredicate((widget) {
      return widget is Text &&
          widget.data == longPath &&
          widget.maxLines == 1 &&
          widget.overflow == TextOverflow.ellipsis;
    });

    expect(subtitleFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping blank header space toggles expandable content', (
    tester,
  ) async {
    final part = completedToolPart(
      tool: 'write',
      input: {'filePath': '/Users/jeffrey/project/flycode/lib/app.dart'},
    );

    await tester.pumpWidget(
      buildHarness(ToolUseWidget(toolPart: part), width: 320),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    final toolRect = tester.getRect(find.byType(ToolUseWidget));
    await tester.tapAt(Offset(toolRect.right - 48, toolRect.top + 12));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
