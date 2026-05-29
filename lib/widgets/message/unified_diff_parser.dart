enum UnifiedDiffLineType { context, addition, deletion, meta }

class UnifiedDiffLine {
  const UnifiedDiffLine({required this.type, required this.text});

  final UnifiedDiffLineType type;
  final String text;
}

class UnifiedDiffParseResult {
  const UnifiedDiffParseResult({
    required this.lines,
    required this.isNewFile,
    required this.isDeletedFile,
  });

  final List<UnifiedDiffLine> lines;
  final bool isNewFile;
  final bool isDeletedFile;
}

UnifiedDiffParseResult? parseUnifiedDiff(String patch) {
  if (patch.trim().isEmpty) return null;

  final normalized = patch.replaceAll('\r\n', '\n');
  final rawLines = normalized.split('\n');
  final lines = <UnifiedDiffLine>[];
  var isNewFile = false;
  var isDeletedFile = false;
  var hasHunk = false;

  for (int index = 0; index < rawLines.length; index++) {
    final rawLine = rawLines[index];
    if (rawLine.startsWith('--- ')) {
      if (rawLine == '--- /dev/null') isNewFile = true;
      continue;
    }
    if (rawLine.startsWith('+++ ')) {
      if (rawLine == '+++ /dev/null') isDeletedFile = true;
      continue;
    }
    if (rawLine.startsWith('@@ ')) {
      hasHunk = true;
      lines.add(UnifiedDiffLine(type: UnifiedDiffLineType.meta, text: rawLine));
      continue;
    }
    if (!hasHunk) {
      continue;
    }
    if (rawLine.startsWith(r'\ No newline at end of file')) {
      continue;
    }
    if (rawLine.startsWith('+')) {
      lines.add(
        UnifiedDiffLine(
          type: UnifiedDiffLineType.addition,
          text: rawLine.substring(1),
        ),
      );
      continue;
    }
    if (rawLine.startsWith('-')) {
      lines.add(
        UnifiedDiffLine(
          type: UnifiedDiffLineType.deletion,
          text: rawLine.substring(1),
        ),
      );
      continue;
    }
    if (rawLine.startsWith(' ')) {
      lines.add(
        UnifiedDiffLine(
          type: UnifiedDiffLineType.context,
          text: rawLine.substring(1),
        ),
      );
      continue;
    }
    if (rawLine.isEmpty && index < rawLines.length - 1) {
      lines.add(
        const UnifiedDiffLine(type: UnifiedDiffLineType.context, text: ''),
      );
    }
  }

  if (!hasHunk) return null;

  return UnifiedDiffParseResult(
    lines: lines,
    isNewFile: isNewFile,
    isDeletedFile: isDeletedFile,
  );
}
