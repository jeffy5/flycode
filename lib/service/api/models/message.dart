import 'package:json_annotation/json_annotation.dart';
import 'parts.dart';

String _stringOrEmpty(Object? value) => value?.toString() ?? '';

int _intOrZero(Object? value) => (value as num?)?.toInt() ?? 0;

@JsonSerializable(createFactory: false, createToJson: false)
class MessageTime {
  final int created;
  final int? completed;

  MessageTime({required this.created, this.completed});

  factory MessageTime.fromJson(Map<String, dynamic> json) => MessageTime(
    created: (json['created'] as num).toInt(),
    completed: (json['completed'] as num?)?.toInt(),
  );
  Map<String, dynamic> toJson() => {
    'created': created,
    if (completed != null) 'completed': completed,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageModel {
  final String providerID;
  final String modelID;

  MessageModel({required this.providerID, required this.modelID});

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    providerID: json['providerID'] as String,
    modelID: json['modelID'] as String,
  );
  Map<String, dynamic> toJson() => {
    'providerID': providerID,
    'modelID': modelID,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessagePath {
  final String cwd;
  final String root;

  MessagePath({required this.cwd, required this.root});

  factory MessagePath.fromJson(Map<String, dynamic> json) =>
      MessagePath(cwd: json['cwd'] as String, root: json['root'] as String);
  Map<String, dynamic> toJson() => {'cwd': cwd, 'root': root};
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageCacheTokens {
  final int? read;
  final int? write;

  MessageCacheTokens({this.read, this.write});

  factory MessageCacheTokens.fromJson(Map<String, dynamic> json) =>
      MessageCacheTokens(
        read: (json['read'] as num?)?.toInt(),
        write: (json['write'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
    if (read != null) 'read': read,
    if (write != null) 'write': write,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageTokens {
  final int? input;
  final int? output;
  final int? total;
  final int? reasoning;
  final MessageCacheTokens? cache;

  MessageTokens({
    this.input,
    this.output,
    this.total,
    this.reasoning,
    this.cache,
  });

  factory MessageTokens.fromJson(Map<String, dynamic> json) => MessageTokens(
    input: (json['input'] as num?)?.toInt(),
    output: (json['output'] as num?)?.toInt(),
    total: (json['total'] as num?)?.toInt(),
    reasoning: (json['reasoning'] as num?)?.toInt(),
    cache: json['cache'] == null
        ? null
        : MessageCacheTokens.fromJson(json['cache'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    if (input != null) 'input': input,
    if (output != null) 'output': output,
    if (total != null) 'total': total,
    if (reasoning != null) 'reasoning': reasoning,
    if (cache != null) 'cache': cache?.toJson(),
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
class UserMessageSummary {
  final String? title;
  final String? body;
  final List<FileDiff> diffs;

  UserMessageSummary({this.title, this.body, required this.diffs});

  factory UserMessageSummary.fromJson(Map<String, dynamic> json) =>
      UserMessageSummary(
        title: json['title'] as String?,
        body: json['body'] as String?,
        diffs: (json['diffs'] as List<dynamic>? ?? const [])
            .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (body != null) 'body': body,
    'diffs': diffs.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ProviderAuthError {
  final String name;
  final String providerID;
  final String message;

  ProviderAuthError({
    required this.name,
    required this.providerID,
    required this.message,
  });

  factory ProviderAuthError.fromJson(Map<String, dynamic> json) =>
      ProviderAuthError(
        name: json['name'] as String,
        providerID: json['data']['providerID'] as String,
        message: json['data']['message'] as String,
      );
  Map<String, dynamic> toJson() => {
    'name': name,
    'data': {'providerID': providerID, 'message': message},
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class UnknownError {
  final String name;
  final String message;

  UnknownError({required this.name, required this.message});

  factory UnknownError.fromJson(Map<String, dynamic> json) => UnknownError(
    name: json['name'] as String,
    message: json['data']['message'] as String,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'data': {'message': message},
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageOutputLengthError {
  final String name;
  final Map<String, dynamic> data;

  MessageOutputLengthError({required this.name, required this.data});

  factory MessageOutputLengthError.fromJson(Map<String, dynamic> json) =>
      MessageOutputLengthError(
        name: json['name'] as String,
        data: json['data'] as Map<String, dynamic>,
      );
  Map<String, dynamic> toJson() => {'name': name, 'data': data};
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageAbortedError {
  final String name;
  final String message;

  MessageAbortedError({required this.name, required this.message});

  factory MessageAbortedError.fromJson(Map<String, dynamic> json) =>
      MessageAbortedError(
        name: json['name'] as String,
        message: json['data']['message'] as String,
      );
  Map<String, dynamic> toJson() => {
    'name': name,
    'data': {'message': message},
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ApiError {
  final String name;
  final String message;
  final int? statusCode;
  final bool isRetryable;
  final Map<String, String>? responseHeaders;
  final String? responseBody;

  ApiError({
    required this.name,
    required this.message,
    this.statusCode,
    required this.isRetryable,
    this.responseHeaders,
    this.responseBody,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ApiError(
      name: json['name'] as String,
      message: data['message'] as String,
      statusCode: (data['statusCode'] as num?)?.toInt(),
      isRetryable: data['isRetryable'] as bool,
      responseHeaders: data['responseHeaders'] == null
          ? null
          : (data['responseHeaders'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as String),
            ),
      responseBody: data['responseBody'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'data': {
      'message': message,
      if (statusCode != null) 'statusCode': statusCode,
      'isRetryable': isRetryable,
      if (responseHeaders != null) 'responseHeaders': responseHeaders,
      if (responseBody != null) 'responseBody': responseBody,
    },
  };
}

Object parseMessageError(Map<String, dynamic> json) {
  final name = json['name'] as String;
  switch (name) {
    case 'ProviderAuthError':
      return ProviderAuthError.fromJson(json);
    case 'UnknownError':
      return UnknownError.fromJson(json);
    case 'MessageOutputLengthError':
      return MessageOutputLengthError.fromJson(json);
    case 'MessageAbortedError':
      return MessageAbortedError.fromJson(json);
    case 'APIError':
      return ApiError.fromJson(json);
    default:
      throw Exception('Unknown error type: $name');
  }
}

Map<String, dynamic> messageErrorToJson(Object error) {
  if (error is ProviderAuthError) return error.toJson();
  if (error is UnknownError) return error.toJson();
  if (error is MessageOutputLengthError) return error.toJson();
  if (error is MessageAbortedError) return error.toJson();
  if (error is ApiError) return error.toJson();
  throw Exception('Unknown error type');
}

@JsonSerializable(createFactory: false, createToJson: false)
class UserMessage {
  final String id;
  final String sessionID;
  final String role;
  final MessageTime time;
  final UserMessageSummary? summary;
  final String agent;
  final MessageModel model;
  final String? system;
  final Map<String, bool>? tools;

  UserMessage({
    required this.id,
    required this.sessionID,
    required this.role,
    required this.time,
    this.summary,
    required this.agent,
    required this.model,
    this.system,
    this.tools,
  });

  factory UserMessage.fromJson(Map<String, dynamic> json) => UserMessage(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    role: json['role'] as String,
    time: MessageTime.fromJson(json['time'] as Map<String, dynamic>),
    summary: json['summary'] == null
        ? null
        : UserMessageSummary.fromJson(json['summary'] as Map<String, dynamic>),
    agent: json['agent'] as String,
    model: MessageModel.fromJson(json['model'] as Map<String, dynamic>),
    system: json['system'] as String?,
    tools: json['tools'] == null
        ? null
        : (json['tools'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as bool),
          ),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'role': role,
    'time': time.toJson(),
    if (summary != null) 'summary': summary?.toJson(),
    'agent': agent,
    'model': model.toJson(),
    if (system != null) 'system': system,
    if (tools != null) 'tools': tools,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class AssistantMessage {
  final String id;
  final String sessionID;
  final String role;
  final MessageTime time;
  final Object? error;
  final String parentID;
  final String modelID;
  final String providerID;
  final String mode;
  final MessagePath path;
  final bool? summary;
  final double? cost;
  final MessageTokens tokens;
  final String? finish;

  AssistantMessage({
    required this.id,
    required this.sessionID,
    required this.role,
    required this.time,
    this.error,
    required this.parentID,
    required this.modelID,
    required this.providerID,
    required this.mode,
    required this.path,
    this.summary,
    this.cost,
    required this.tokens,
    this.finish,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        id: json['id'] as String,
        sessionID: json['sessionID'] as String,
        role: json['role'] as String,
        time: MessageTime.fromJson(json['time'] as Map<String, dynamic>),
        error: json['error'] == null
            ? null
            : parseMessageError(json['error'] as Map<String, dynamic>),
        parentID: json['parentID'] as String,
        modelID: json['modelID'] as String,
        providerID: json['providerID'] as String,
        mode: json['mode'] as String,
        path: MessagePath.fromJson(json['path'] as Map<String, dynamic>),
        summary: json['summary'] as bool?,
        cost: (json['cost'] as num?)?.toDouble(),
        tokens: MessageTokens.fromJson(json['tokens'] as Map<String, dynamic>),
        finish: json['finish'] as String?,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'role': role,
    'time': time.toJson(),
    if (error != null) 'error': messageErrorToJson(error as Object),
    'parentID': parentID,
    'modelID': modelID,
    'providerID': providerID,
    'mode': mode,
    'path': path.toJson(),
    if (summary != null) 'summary': summary,
    if (cost != null) 'cost': cost,
    'tokens': tokens.toJson(),
    if (finish != null) 'finish': finish,
  };
}

Object parseMsg(Map<String, dynamic> json) {
  final role = json['role'] as String;
  if (role == 'user') {
    return UserMessage.fromJson(json);
  } else if (role == 'assistant') {
    return AssistantMessage.fromJson(json);
  }
  throw Exception('Unknown Message role: $role');
}

@JsonSerializable(createFactory: false, createToJson: false)
class MessageWithParts {
  final Object info;
  final List<Object> parts;

  MessageWithParts({required this.info, required this.parts});

  factory MessageWithParts.fromJson(Map<String, dynamic> json) {
    final infoJson = json['info'] as Map<String, dynamic>;
    final partsJson = json['parts'] as List<dynamic>;

    return MessageWithParts(
      info: parseMsg(infoJson),
      parts: partsJson
          .map((e) => parsePart(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'info': info is UserMessage
        ? (info as UserMessage).toJson()
        : (info as AssistantMessage).toJson(),
    'parts': parts.map((e) => partToJson(e)).toList(),
  };
}

Object parsePart(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'text':
      return TextPart.fromJson(json);
    case 'tool':
      return ToolPart.fromJson(json);
    case 'reasoning':
      return ReasoningPart.fromJson(json);
    case 'file':
      return FilePart.fromJson(json);
    case 'step-start':
      return StepStartPart.fromJson(json);
    case 'step-finish':
      return StepFinishPart.fromJson(json);
    case 'snapshot':
      return SnapshotPart.fromJson(json);
    case 'patch':
      return PatchPart.fromJson(json);
    case 'agent':
      return AgentPart.fromJson(json);
    case 'retry':
      return RetryPart.fromJson(json);
    case 'compaction':
      return CompactionPart.fromJson(json);
    case 'subtask':
      return SubtaskPart.fromJson(json);
    default:
      throw Exception('Unknown Part type: $type');
  }
}

Map<String, dynamic> partToJson(Object part) {
  if (part is TextPart) return part.toJson();
  if (part is ToolPart) return part.toJson();
  if (part is ReasoningPart) return part.toJson();
  if (part is FilePart) return part.toJson();
  if (part is StepStartPart) return part.toJson();
  if (part is StepFinishPart) return part.toJson();
  if (part is SnapshotPart) return part.toJson();
  if (part is PatchPart) return part.toJson();
  if (part is AgentPart) return part.toJson();
  if (part is RetryPart) return part.toJson();
  if (part is CompactionPart) return part.toJson();
  if (part is SubtaskPart) return part.toJson();
  throw Exception('Unknown Part type');
}
