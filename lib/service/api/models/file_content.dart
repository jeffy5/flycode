class FileContentHunk {
  final int? oldStart;
  final int? oldLines;
  final int? newStart;
  final int? newLines;
  final List<String> lines;

  FileContentHunk({
    this.oldStart,
    this.oldLines,
    this.newStart,
    this.newLines,
    required this.lines,
  });

  factory FileContentHunk.fromJson(Map<String, dynamic> json) =>
      FileContentHunk(
        oldStart: (json['oldStart'] as num?)?.toInt(),
        oldLines: (json['oldLines'] as num?)?.toInt(),
        newStart: (json['newStart'] as num?)?.toInt(),
        newLines: (json['newLines'] as num?)?.toInt(),
        lines: (json['lines'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    if (oldStart != null) 'oldStart': oldStart,
    if (oldLines != null) 'oldLines': oldLines,
    if (newStart != null) 'newStart': newStart,
    if (newLines != null) 'newLines': newLines,
    'lines': lines,
  };
}

class FileContentPatch {
  final String oldFileName;
  final String newFileName;
  final String? oldHeader;
  final String? newHeader;
  final String? index;
  final List<FileContentHunk> hunks;

  FileContentPatch({
    required this.oldFileName,
    required this.newFileName,
    this.oldHeader,
    this.newHeader,
    this.index,
    required this.hunks,
  });

  factory FileContentPatch.fromJson(Map<String, dynamic> json) =>
      FileContentPatch(
        oldFileName: json['oldFileName'] as String,
        newFileName: json['newFileName'] as String,
        oldHeader: json['oldHeader'] as String?,
        newHeader: json['newHeader'] as String?,
        index: json['index'] as String?,
        hunks: (json['hunks'] as List<dynamic>)
            .map((e) => FileContentHunk.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'oldFileName': oldFileName,
    'newFileName': newFileName,
    if (oldHeader != null) 'oldHeader': oldHeader,
    if (newHeader != null) 'newHeader': newHeader,
    if (index != null) 'index': index,
    'hunks': hunks.map((e) => e.toJson()).toList(),
  };
}

class FileContent {
  final String type;
  final String content;
  final String? encoding;
  final String? mimeType;
  final String? diff;
  final FileContentPatch? patch;

  FileContent({
    required this.type,
    required this.content,
    this.encoding,
    this.mimeType,
    this.diff,
    this.patch,
  });

  bool get isBinary => encoding == 'base64';

  factory FileContent.fromJson(Map<String, dynamic> json) => FileContent(
    type: json['type'] as String,
    content: json['content'] as String,
    encoding: json['encoding'] as String?,
    mimeType: json['mimeType'] as String?,
    diff: json['diff'] as String?,
    patch: json['patch'] == null
        ? null
        : FileContentPatch.fromJson(json['patch'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'content': content,
    if (encoding != null) 'encoding': encoding,
    if (mimeType != null) 'mimeType': mimeType,
    if (diff != null) 'diff': diff,
    if (patch != null) 'patch': patch!.toJson(),
  };
}
