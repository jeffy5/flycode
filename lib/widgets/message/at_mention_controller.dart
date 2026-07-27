import 'package:flutter/material.dart';

/// Represents a single @-file pill embedded in the text.
///
/// [path] is the relative file path (e.g. "src/foo.ts").
/// [start] and [end] are the character offsets of the full pill text
/// (including the leading `@`) within the [TextEditingController.text].
class FilePill {
  final String path;
  int start;
  int end;

  FilePill({required this.path, required this.start, required this.end});

  /// The display text for this pill, e.g. "@src/foo.ts".
  String get displayText => '@$path';

  @override
  String toString() => 'FilePill($path, $start..$end)';
}

/// A [TextEditingController] that tracks inline @-file pills and renders
/// them with a distinct blue style.
///
/// Pills are atomic units: when the cursor moves just past the end of a pill
/// and the user presses Backspace, the entire pill should be deleted.
/// Call [tryDeletePillBeforeCursor] in the key-event handler to do this.
class AtMentionController extends TextEditingController {
  /// The list of currently-tracked pills, sorted by [FilePill.start].
  final List<FilePill> pills = [];

  // ─── Pill management ─────────────────────────────────────────────

  /// Insert a pill by replacing the text range [atStart..cursorEnd] with
  /// the pill display text (e.g. "@src/foo.ts"), then appending a space.
  ///
  /// [atStart] is the index of the `@` character in the current text.
  /// [cursorEnd] is the current cursor position (end of the `@query` text).
  void insertPill(String relativePath, int atStart, int cursorEnd) {
    final currentText = text;
    final pillText = '@$relativePath';
    final newText =
        '${currentText.substring(0, atStart)}$pillText ${currentText.substring(cursorEnd)}';

    // Register the pill before updating value so syncPills doesn't strip it.
    final pill = FilePill(
      path: relativePath,
      start: atStart,
      end: atStart + pillText.length,
    );
    pills.add(pill);
    _sortPills();

    // New cursor position: just after the appended space.
    final newCursor = atStart + pillText.length + 1;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Call this after every text change to remove pills whose text no longer
  /// matches what is in the controller (e.g. user edited inside a pill).
  void syncPills() {
    final currentText = text;
    pills.removeWhere((pill) {
      if (pill.end > currentText.length) return true;
      final slice = currentText.substring(pill.start, pill.end);
      return slice != pill.displayText;
    });
  }

  /// If the cursor is immediately after a pill's end character, remove the
  /// entire pill text from the controller and return true.
  /// Returns false if no pill was found at that position.
  bool tryDeletePillBeforeCursor() {
    final sel = selection;
    if (!sel.isCollapsed) return false;
    final pos = sel.baseOffset;

    for (final pill in pills) {
      if (pill.end == pos) {
        // Delete the pill text from the controller.
        final newText =
            text.substring(0, pill.start) + text.substring(pill.end);
        pills.remove(pill);
        // Shift subsequent pills.
        final removed = pill.end - pill.start;
        for (final p in pills) {
          if (p.start >= pill.end) {
            p.start -= removed;
            p.end -= removed;
          }
        }
        value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: pill.start),
        );
        return true;
      }
    }
    return false;
  }

  /// Returns the pill that contains [offset], or null.
  FilePill? pillAt(int offset) {
    for (final pill in pills) {
      if (offset >= pill.start && offset < pill.end) return pill;
    }
    return null;
  }

  void _sortPills() {
    pills.sort((a, b) => a.start.compareTo(b.start));
  }

  // ─── Rendering ───────────────────────────────────────────────────

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final currentText = text;
    if (currentText.isEmpty || pills.isEmpty) {
      return TextSpan(text: currentText, style: style);
    }

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final pill in pills) {
      // Text before this pill.
      if (pill.start > cursor) {
        spans.add(
          TextSpan(
            text: currentText.substring(cursor, pill.start),
            style: style,
          ),
        );
      }
      // The pill itself.
      if (pill.end <= currentText.length) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        spans.add(
          TextSpan(
            text: currentText.substring(pill.start, pill.end),
            style: (style ?? const TextStyle()).copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        cursor = pill.end;
      }
    }

    // Remaining text after all pills.
    if (cursor < currentText.length) {
      spans.add(TextSpan(text: currentText.substring(cursor), style: style));
    }

    return TextSpan(children: spans, style: style);
  }

  @override
  void dispose() {
    pills.clear();
    super.dispose();
  }
}
