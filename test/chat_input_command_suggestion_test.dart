import 'package:flycode/service/api/models/command.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/chat_command_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({required Brightness brightness, required Widget child}) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(
        body: SizedBox.expand(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    );
  }

  const initCommand = Command(
    name: 'init',
    description: 'create or update AGENTS.md',
    template: 'template',
    hints: <String>[],
  );

  const reviewCommand = Command(
    name: 'review',
    description: 'review changes in commit, branch, or PR',
    template: 'template',
    hints: <String>[],
  );

  List<Command> manyCommands() => List<Command>.generate(
    8,
    (index) => Command(
      name: 'cmd$index',
      description: 'description $index',
      template: 'template',
      hints: const <String>[],
    ),
  );

  testWidgets('renders command title and description in vertical hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: const [initCommand, reviewCommand],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('/init'), findsOneWidget);
    expect(find.text('create or update AGENTS.md'), findsOneWidget);

    final title = tester.widget<Text>(find.text('/init'));
    final description = tester.widget<Text>(
      find.text('create or update AGENTS.md'),
    );

    expect(title.style?.fontFamily, 'PlusJakartaSans');
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(description.style?.fontFamily, 'Inter');
    expect(description.style?.fontSize, 11);

    final titleTop = tester.getTopLeft(find.text('/init')).dy;
    final descriptionTop = tester
        .getTopLeft(find.text('create or update AGENTS.md'))
        .dy;
    expect(descriptionTop, greaterThan(titleTop));
  });

  testWidgets('keeps layout stable when description is missing', (
    tester,
  ) async {
    const noDescriptionCommand = Command(
      name: 'plain',
      template: 'template',
      hints: <String>[],
    );

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: const [noDescriptionCommand],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('/plain'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.text('create or update AGENTS.md'), findsNothing);
  });

  testWidgets('selects command on tap', (tester) async {
    Command? selected;

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.dark,
        child: buildCommandSuggestionListForTest(
          commands: const [initCommand, reviewCommand],
          onSelect: (command) => selected = command,
        ),
      ),
    );

    await tester.pumpAndSettle();
    tester
        .widget<CommandSuggestionTile>(find.byType(CommandSuggestionTile).last)
        .onTap();
    await tester.pump();

    expect(selected?.name, 'review');
  });

  testWidgets('initial popup height stays near four rows', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: manyCommands(),
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final popupHeight = tester
        .getSize(find.byKey(const Key('chat_command_popup.list')))
        .height;
    expect(popupHeight, inInclusiveRange(220.0, 280.0));
  });

  testWidgets('single result uses compact height without extra blank area', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildCommandSuggestionListForTest(
          commands: const [reviewCommand],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    final popupHeight = tester
        .getSize(find.byKey(const Key('chat_command_popup.surface')))
        .height;
    expect(popupHeight, lessThan(120.0));
  });

  testWidgets('long command list remains scrollable', (tester) async {
    final controller = CommandPanelController()..show(manyCommands());

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.dark,
        child: SizedBox(
          height: 420,
          child: ChatCommandPopup(controller: controller, onSelect: (_) {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('/cmd7'), findsNothing);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('chat_command_popup.list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    expect(find.text('/cmd7'), findsOneWidget);
  });

  testWidgets('narrowing to one result resets popup viewport', (tester) async {
    final controller = CommandPanelController()..show(manyCommands());

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: SizedBox(
          height: 420,
          child: ChatCommandPopup(controller: controller, onSelect: (_) {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('chat_command_popup.list')),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    controller.update(const [
      Command(
        name: 'git-commit',
        description: 'Execute git commit with conventional commit message',
        template: 'template',
        hints: <String>[],
      ),
    ], query: 'g');
    await tester.pumpAndSettle();

    expect(find.text('/git-commit'), findsOneWidget);
    final itemRect = tester.getRect(find.text('/git-commit'));
    final listRect = tester.getRect(
      find.byKey(const Key('chat_command_popup.list')),
    );
    expect(itemRect.top, greaterThanOrEqualTo(listRect.top));
    expect(itemRect.bottom, lessThanOrEqualTo(listRect.bottom));
  });

  testWidgets('underlying message list is frozen while popup is visible', (
    tester,
  ) async {
    final controller = CommandPanelController()..show(manyCommands());
    final scrollController = ScrollController();

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: SizedBox(
          height: 480,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: controller.visible,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 50,
                    itemBuilder: (context, index) =>
                        SizedBox(height: 40, child: Text('message $index')),
                  ),
                ),
              ),
              Positioned.fill(
                child: ChatCommandPopup(
                  controller: controller,
                  onSelect: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.text('message 1'),
      const Offset(0, -200),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0);
  });
}
