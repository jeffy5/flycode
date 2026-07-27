import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

String _stringOrEmpty(Object? value) => value?.toString() ?? '';

int _intOrZero(Object? value) => (value as num?)?.toInt() ?? 0;

@JsonSerializable(createFactory: false, createToJson: false)
class SessionTime {
  final int created;
  final int updated;
  final int? compacting;
  final int? archived;

  SessionTime({
    required this.created,
    required this.updated,
    this.compacting,
    this.archived,
  });

  factory SessionTime.fromJson(Map<String, dynamic> json) => SessionTime(
    created: (json['created'] as num).toInt(),
    updated: (json['updated'] as num).toInt(),
    compacting: (json['compacting'] as num?)?.toInt(),
    archived: (json['archived'] as num?)?.toInt(),
  );
  Map<String, dynamic> toJson() => {
    'created': created,
    'updated': updated,
    if (compacting != null) 'compacting': compacting,
    if (archived != null) 'archived': archived,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class FileDiff {
  final String file;
  final String before;
  final String after;
  final int additions;
  final int deletions;
  final String? status;

  FileDiff({
    required this.file,
    required this.before,
    required this.after,
    required this.additions,
    required this.deletions,
    this.status,
  });

  factory FileDiff.fromJson(Map<String, dynamic> json) => FileDiff(
    file: _stringOrEmpty(
      json['file'] ?? json['relativePath'] ?? json['filePath'],
    ),
    before: _stringOrEmpty(json['before']),
    after: _stringOrEmpty(json['after']),
    additions: _intOrZero(json['additions']),
    deletions: _intOrZero(json['deletions']),
    status: json['status'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'file': file,
    'before': before,
    'after': after,
    'additions': additions,
    'deletions': deletions,
    if (status != null) 'status': status,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class SessionSummary {
  final int additions;
  final int deletions;
  final int files;
  final List<FileDiff>? diffs;

  SessionSummary({
    required this.additions,
    required this.deletions,
    required this.files,
    this.diffs,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
    additions: (json['additions'] as num).toInt(),
    deletions: (json['deletions'] as num).toInt(),
    files: (json['files'] as num).toInt(),
    diffs: (json['diffs'] as List<dynamic>?)
        ?.map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'additions': additions,
    'deletions': deletions,
    'files': files,
    if (diffs != null) 'diffs': diffs?.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class SessionShare {
  final String url;

  SessionShare({required this.url});

  factory SessionShare.fromJson(Map<String, dynamic> json) =>
      SessionShare(url: json['url'] as String);
  Map<String, dynamic> toJson() => {'url': url};
}

@JsonSerializable(createFactory: false, createToJson: false)
class SessionRevert {
  final String messageID;
  final String? partID;
  final String? snapshot;
  final String? diff;

  SessionRevert({
    required this.messageID,
    this.partID,
    this.snapshot,
    this.diff,
  });

  factory SessionRevert.fromJson(Map<String, dynamic> json) => SessionRevert(
    messageID: json['messageID'] as String,
    partID: json['partID'] as String?,
    snapshot: json['snapshot'] as String?,
    diff: json['diff'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'messageID': messageID,
    if (partID != null) 'partID': partID,
    if (snapshot != null) 'snapshot': snapshot,
    if (diff != null) 'diff': diff,
  };
}

enum PermissionAction { allow, deny }

@JsonSerializable(createFactory: false, createToJson: false)
class PermissionRule {
  final String permission;
  final String pattern;
  final PermissionAction action;

  PermissionRule({
    required this.permission,
    required this.pattern,
    required this.action,
  });

  factory PermissionRule.fromJson(Map<String, dynamic> json) => PermissionRule(
    permission: json['permission'] as String,
    pattern: json['pattern'] as String,
    action: PermissionAction.values.firstWhere(
      (e) => e.name == json['action'],
      orElse: () => PermissionAction.deny,
    ),
  );
  Map<String, dynamic> toJson() => {
    'permission': permission,
    'pattern': pattern,
    'action': action.name,
  };
}

typedef PermissionRuleset = List<PermissionRule>;

class CreateSessionRequest {
  final String? parentID;
  final String? title;
  final PermissionRuleset? permission;

  CreateSessionRequest({this.parentID, this.title, this.permission});

  Map<String, dynamic> toJson() => {
    if (parentID != null) 'parentID': parentID,
    if (title != null) 'title': title,
    if (permission != null)
      'permission': permission!.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable(createToJson: false)
class Session {
  final String id;
  final String slug;
  final String projectID;
  final String directory;
  final String? parentID;
  final SessionSummary? summary;
  final SessionShare? share;
  final String? title;
  final String version;
  final SessionTime time;
  final PermissionRuleset? permission;
  final SessionRevert? revert;

  Session({
    required this.id,
    required this.slug,
    required this.projectID,
    required this.directory,
    this.parentID,
    this.summary,
    this.share,
    this.title,
    required this.version,
    required this.time,
    this.permission,
    this.revert,
  });

  int? get updatedAt => time.updated;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'projectID': projectID,
    'directory': directory,
    if (parentID != null) 'parentID': parentID,
    if (summary != null) 'summary': summary?.toJson(),
    if (share != null) 'share': share?.toJson(),
    if (title != null) 'title': title,
    'version': version,
    'time': time.toJson(),
    if (permission != null)
      'permission': permission?.map((e) => e.toJson()).toList(),
    if (revert != null) 'revert': revert?.toJson(),
  };
}
