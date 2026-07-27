/// Tool metadata: display names, subtitle extraction, and args extraction.
library;

class ToolMeta {
  final String displayName;
  final String? Function(Map<String, dynamic> input) getSubtitle;
  final List<String> Function(Map<String, dynamic> input) getArgs;
  final bool hasExpandableContent;

  const ToolMeta({
    required this.displayName,
    required this.getSubtitle,
    required this.getArgs,
    this.hasExpandableContent = false,
  });
}

/// Returns the filename portion of a path (last segment).
String getFilename(String? path) {
  if (path == null || path.isEmpty) return '';
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/');
  return parts.last;
}

/// Returns a path relative to the working directory prefix.
/// Strips leading absolute path prefixes if present.
String relativizePath(String? path) {
  if (path == null || path.isEmpty) return '';
  // Strip common absolute prefixes so paths display cleanly
  final normalized = path.replaceAll('\\', '/');
  // Remove leading slash to make relative
  if (normalized.startsWith('/')) {
    // Keep just the meaningful portion after any project root
    // e.g. /Users/x/project/foo/bar -> foo/bar
    // We return the full path but trimmed of leading slash for display
    return normalized;
  }
  return normalized;
}

/// Formats a nullable arg value as "key=value" label, or null if absent.
String? _argLabel(String key, dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  return '$key=$str';
}

final _toolMetaMap = <String, ToolMeta>{
  'read': ToolMeta(
    displayName: 'Read',
    getSubtitle: (input) => getFilename(input['filePath']?.toString()),
    getArgs: (input) {
      final args = <String>[];
      final label = _argLabel('offset', input['offset']);
      if (label != null) args.add(label);
      final limit = _argLabel('limit', input['limit']);
      if (limit != null) args.add(limit);
      return args;
    },
    hasExpandableContent: false,
  ),
  'glob': ToolMeta(
    displayName: 'Glob',
    getSubtitle: (input) => relativizePath(input['path']?.toString()),
    getArgs: (input) {
      final args = <String>[];
      final pattern = _argLabel('pattern', input['pattern']);
      if (pattern != null) args.add(pattern);
      return args;
    },
    hasExpandableContent: false,
  ),
  'grep': ToolMeta(
    displayName: 'Grep',
    getSubtitle: (input) => relativizePath(input['path']?.toString()),
    getArgs: (input) {
      final args = <String>[];
      final pattern = _argLabel('pattern', input['pattern']);
      if (pattern != null) args.add(pattern);
      final include = _argLabel('include', input['include']);
      if (include != null) args.add(include);
      return args;
    },
    hasExpandableContent: false,
  ),
  'list': ToolMeta(
    displayName: 'List',
    getSubtitle: (input) => relativizePath(input['path']?.toString()),
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
  'bash': ToolMeta(
    displayName: 'Shell',
    getSubtitle: (input) => input['description']?.toString(),
    getArgs: (input) => [],
    hasExpandableContent: true,
  ),
  'edit': ToolMeta(
    displayName: 'Edit',
    getSubtitle: (input) => getFilename(input['filePath']?.toString()),
    getArgs: (input) => [],
    hasExpandableContent: true,
  ),
  'write': ToolMeta(
    displayName: 'Write',
    getSubtitle: (input) => getFilename(input['filePath']?.toString()),
    getArgs: (input) => [],
    hasExpandableContent: true,
  ),
  'apply_patch': ToolMeta(
    displayName: 'Patch',
    getSubtitle: (input) {
      final files = input['files'];
      if (files is List) {
        return '${files.length} files';
      }
      return null;
    },
    getArgs: (input) => [],
    hasExpandableContent: true,
  ),
  'task': ToolMeta(
    displayName: 'Task',
    getSubtitle: (input) => input['description']?.toString(),
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
  'webfetch': ToolMeta(
    displayName: 'Web Fetch',
    getSubtitle: (input) => input['url']?.toString(),
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
  'question': ToolMeta(
    displayName: 'Question',
    getSubtitle: (input) => null,
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
  'skill': ToolMeta(
    displayName: 'Skill',
    getSubtitle: (input) => null,
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
  'todowrite': ToolMeta(
    displayName: 'Todo',
    getSubtitle: (input) => null,
    getArgs: (input) => [],
    hasExpandableContent: false,
  ),
};

ToolMeta toolMetaOf(String tool) {
  return _toolMetaMap[tool] ??
      ToolMeta(
        displayName: tool,
        getSubtitle: (input) => null,
        getArgs: (input) => [],
        hasExpandableContent: true,
      );
}
