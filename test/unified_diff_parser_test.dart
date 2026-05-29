import 'package:flutter_test/flutter_test.dart';
import 'package:flycode/widgets/message/unified_diff_parser.dart';

void main() {
  test('parses standard unified diff hunks', () {
    const patch = '''diff --git a/lib/a.dart b/lib/a.dart
index 1111111..2222222 100644
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -1,2 +1,2 @@
-old line
+new line
 context
''';

    final result = parseUnifiedDiff(patch);

    expect(result, isNotNull);
    expect(result!.lines.length, 4);
    expect(result.lines[0].type, UnifiedDiffLineType.meta);
    expect(result.lines[1].type, UnifiedDiffLineType.deletion);
    expect(result.lines[1].text, 'old line');
    expect(result.lines[2].type, UnifiedDiffLineType.addition);
    expect(result.lines[2].text, 'new line');
    expect(result.lines[3].type, UnifiedDiffLineType.context);
    expect(result.lines[3].text, 'context');
  });

  test('detects new and deleted files from dev null headers', () {
    const newFilePatch = '''--- /dev/null
+++ b/lib/new.dart
@@ -0,0 +1 @@
+hello
''';
    const deletedFilePatch = '''--- a/lib/old.dart
+++ /dev/null
@@ -1 +0,0 @@
-bye
''';

    final added = parseUnifiedDiff(newFilePatch);
    final deleted = parseUnifiedDiff(deletedFilePatch);

    expect(added, isNotNull);
    expect(added!.isNewFile, isTrue);
    expect(added.isDeletedFile, isFalse);

    expect(deleted, isNotNull);
    expect(deleted!.isDeletedFile, isTrue);
    expect(deleted.isNewFile, isFalse);
  });

  test('returns null when patch has no hunks', () {
    expect(parseUnifiedDiff('diff --git a/a b/a'), isNull);
  });
}
