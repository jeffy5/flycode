import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/chat_file_popup.dart';
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

  test('parses trailing-slash directory without an empty name', () {
    final suggestion = FileSuggestion.fromPath('lib/widgets/');

    expect(suggestion.name, 'widgets');
    expect(suggestion.parentPath, 'lib');
    expect(suggestion.isDirectory, isTrue);
    expect(fileNameFromPath('lib/widgets/'), 'widgets');
  });

  testWidgets('renders file and directory with title and parent path', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: buildFileSuggestionListForTest(
          paths: const ['lib/widgets/', 'lib/app.dart'],
          onSelect: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('widgets'), findsOneWidget);
    expect(find.text('app.dart'), findsOneWidget);
    expect(find.text('lib'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('directory-icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('file-icon')), findsOneWidget);

    final title = tester.widget<Text>(find.text('widgets'));
    expect(title.style?.fontFamily, 'PlusJakartaSans');
    expect(title.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('selects original path on tap', (tester) async {
    String? selected;
    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.dark,
        child: buildFileSuggestionListForTest(
          paths: const ['lib/widgets/'],
          onSelect: (path) => selected = path,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('widgets'));

    expect(selected, 'lib/widgets/');
  });

  testWidgets('controller moves keyboard highlight between rows', (
    tester,
  ) async {
    final controller = FilePanelController()
      ..show(const ['lib/', 'test/'], query: '');

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.light,
        child: SizedBox(
          height: 420,
          child: ChatFilePopup(controller: controller, onSelect: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FileSuggestionTile>(find.byType(FileSuggestionTile).first)
          .emphasized,
      isTrue,
    );

    controller.moveHighlight(1);
    await tester.pump();

    expect(controller.highlightedPath, 'test/');
    expect(
      tester
          .widget<FileSuggestionTile>(find.byType(FileSuggestionTile).last)
          .emphasized,
      isTrue,
    );
  });

  testWidgets('long file list starts near four rows and remains scrollable', (
    tester,
  ) async {
    final paths = List<String>.generate(8, (index) => 'lib/file$index.dart');

    await tester.pumpWidget(
      buildHarness(
        brightness: Brightness.dark,
        child: buildFileSuggestionListForTest(paths: paths, onSelect: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byKey(const Key('chat_file_popup.list'));
    expect(tester.getSize(listFinder).height, inInclusiveRange(220.0, 280.0));
    expect(find.text('file7.dart'), findsNothing);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: listFinder, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    expect(find.text('file7.dart'), findsOneWidget);
  });
}
