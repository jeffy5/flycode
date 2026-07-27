import 'package:json_annotation/json_annotation.dart';

class Part {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;

  Part({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
  });
}

@JsonSerializable(createFactory: false, createToJson: false)
class PartTime {
  final int? start;
  final int? end;

  PartTime({this.start, this.end});

  factory PartTime.fromJson(Map<String, dynamic> json) => PartTime(
    start: (json['start'] as num?)?.toInt(),
    end: (json['end'] as num?)?.toInt(),
  );
  Map<String, dynamic> toJson() => {
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class TextPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String text;
  final bool? synthetic;
  final bool? ignored;
  final PartTime? time;
  final Map<String, dynamic>? metadata;

  TextPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.text,
    this.synthetic,
    this.ignored,
    this.time,
    this.metadata,
  });

  factory TextPart.fromJson(Map<String, dynamic> json) => TextPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    text: json['text'] as String,
    synthetic: json['synthetic'] as bool?,
    ignored: json['ignored'] as bool?,
    time: json['time'] == null
        ? null
        : PartTime.fromJson(json['time'] as Map<String, dynamic>),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'text': text,
    if (synthetic != null) 'synthetic': synthetic,
    if (ignored != null) 'ignored': ignored,
    if (time != null) 'time': time?.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ReasoningPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String text;
  final Map<String, dynamic>? metadata;
  final PartTime time;

  ReasoningPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.text,
    this.metadata,
    required this.time,
  });

  factory ReasoningPart.fromJson(Map<String, dynamic> json) => ReasoningPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    text: json['text'] as String,
    metadata: json['metadata'] as Map<String, dynamic>?,
    time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'text': text,
    if (metadata != null) 'metadata': metadata,
    'time': time.toJson(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class FilePartSourceText {
  final String value;
  final int? start;
  final int? end;

  FilePartSourceText({required this.value, this.start, this.end});

  factory FilePartSourceText.fromJson(Map<String, dynamic> json) =>
      FilePartSourceText(
        value: json['value'] as String,
        start: (json['start'] as num?)?.toInt(),
        end: (json['end'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
    'value': value,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class Range {
  final RangeStart start;
  final RangeEnd end;

  Range({required this.start, required this.end});

  factory Range.fromJson(Map<String, dynamic> json) => Range(
    start: RangeStart.fromJson(json['start'] as Map<String, dynamic>),
    end: RangeEnd.fromJson(json['end'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class RangeStart {
  final int line;
  final int character;

  RangeStart({required this.line, required this.character});

  factory RangeStart.fromJson(Map<String, dynamic> json) => RangeStart(
    line: (json['line'] as num).toInt(),
    character: (json['character'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {'line': line, 'character': character};
}

@JsonSerializable(createFactory: false, createToJson: false)
class RangeEnd {
  final int line;
  final int character;

  RangeEnd({required this.line, required this.character});

  factory RangeEnd.fromJson(Map<String, dynamic> json) => RangeEnd(
    line: (json['line'] as num).toInt(),
    character: (json['character'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {'line': line, 'character': character};
}

@JsonSerializable(createFactory: false, createToJson: false)
class FileSource {
  final FilePartSourceText text;
  final String type;
  final String path;

  FileSource({required this.text, required this.type, required this.path});

  factory FileSource.fromJson(Map<String, dynamic> json) => FileSource(
    text: FilePartSourceText.fromJson(json['text'] as Map<String, dynamic>),
    type: json['type'] as String,
    path: json['path'] as String,
  );
  Map<String, dynamic> toJson() => {
    'text': text.toJson(),
    'type': type,
    'path': path,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class SymbolSource {
  final FilePartSourceText text;
  final String type;
  final String path;
  final Range range;
  final String name;
  final int kind;

  SymbolSource({
    required this.text,
    required this.type,
    required this.path,
    required this.range,
    required this.name,
    required this.kind,
  });

  factory SymbolSource.fromJson(Map<String, dynamic> json) => SymbolSource(
    text: FilePartSourceText.fromJson(json['text'] as Map<String, dynamic>),
    type: json['type'] as String,
    path: json['path'] as String,
    range: Range.fromJson(json['range'] as Map<String, dynamic>),
    name: json['name'] as String,
    kind: (json['kind'] as num).toInt(),
  );
  Map<String, dynamic> toJson() => {
    'text': text.toJson(),
    'type': type,
    'path': path,
    'range': range.toJson(),
    'name': name,
    'kind': kind,
  };
}

Object parseFilePartSource(Map<String, dynamic> json) {
  final type = json['type'] as String;
  if (type == 'file') {
    return FileSource.fromJson(json);
  } else if (type == 'symbol') {
    return SymbolSource.fromJson(json);
  }
  throw Exception('Unknown FilePartSource type: $type');
}

Map<String, dynamic> filePartSourceToJson(Object source) {
  if (source is FileSource) return source.toJson();
  if (source is SymbolSource) return source.toJson();
  throw Exception('Unknown FilePartSource type');
}

@JsonSerializable(createFactory: false, createToJson: false)
class FilePart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String mime;
  final String? filename;
  final String url;
  final Object? source;

  FilePart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.mime,
    this.filename,
    required this.url,
    this.source,
  });

  factory FilePart.fromJson(Map<String, dynamic> json) => FilePart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    mime: json['mime'] as String,
    filename: json['filename'] as String?,
    url: json['url'] as String,
    source: json['source'] == null
        ? null
        : parseFilePartSource(json['source'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'mime': mime,
    if (filename != null) 'filename': filename,
    'url': url,
    if (source != null) 'source': filePartSourceToJson(source as Object),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolStatePending {
  final String status;
  final Map<String, dynamic> input;
  final String raw;

  ToolStatePending({
    required this.status,
    required this.input,
    required this.raw,
  });

  factory ToolStatePending.fromJson(Map<String, dynamic> json) =>
      ToolStatePending(
        status: json['status'] as String,
        input: json['input'] as Map<String, dynamic>,
        raw: json['raw'] as String,
      );
  Map<String, dynamic> toJson() => {
    'status': status,
    'input': input,
    'raw': raw,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolStateRunning {
  final String status;
  final Map<String, dynamic> input;
  final String? title;
  final Map<String, dynamic>? metadata;
  final PartTime time;

  ToolStateRunning({
    required this.status,
    required this.input,
    this.title,
    this.metadata,
    required this.time,
  });

  factory ToolStateRunning.fromJson(Map<String, dynamic> json) =>
      ToolStateRunning(
        status: json['status'] as String,
        input: json['input'] as Map<String, dynamic>,
        title: json['title'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
      );
  Map<String, dynamic> toJson() => {
    'status': status,
    'input': input,
    if (title != null) 'title': title,
    if (metadata != null) 'metadata': metadata,
    'time': time.toJson(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolStateCompleted {
  final String status;
  final Map<String, dynamic> input;
  final String output;
  final String title;
  final Map<String, dynamic> metadata;
  final ToolStateCompletedTime time;
  final List<FilePart>? attachments;

  ToolStateCompleted({
    required this.status,
    required this.input,
    required this.output,
    required this.title,
    required this.metadata,
    required this.time,
    this.attachments,
  });

  factory ToolStateCompleted.fromJson(Map<String, dynamic> json) =>
      ToolStateCompleted(
        status: json['status'] as String,
        input: json['input'] as Map<String, dynamic>,
        output: json['output'] as String,
        title: json['title'] as String,
        metadata: json['metadata'] as Map<String, dynamic>,
        time: ToolStateCompletedTime.fromJson(
          json['time'] as Map<String, dynamic>,
        ),
        attachments: json['attachments'] == null
            ? null
            : (json['attachments'] as List<dynamic>)
                  .map((e) => FilePart.fromJson(e as Map<String, dynamic>))
                  .toList(),
      );
  Map<String, dynamic> toJson() => {
    'status': status,
    'input': input,
    'output': output,
    'title': title,
    'metadata': metadata,
    'time': time.toJson(),
    if (attachments != null)
      'attachments': attachments?.map((e) => e.toJson()).toList(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolStateCompletedTime {
  final int start;
  final int end;
  final int? compacted;

  ToolStateCompletedTime({
    required this.start,
    required this.end,
    this.compacted,
  });

  factory ToolStateCompletedTime.fromJson(Map<String, dynamic> json) =>
      ToolStateCompletedTime(
        start: (json['start'] as num).toInt(),
        end: (json['end'] as num).toInt(),
        compacted: (json['compacted'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    if (compacted != null) 'compacted': compacted,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolStateError {
  final String status;
  final Map<String, dynamic> input;
  final String error;
  final Map<String, dynamic>? metadata;
  final PartTime time;

  ToolStateError({
    required this.status,
    required this.input,
    required this.error,
    this.metadata,
    required this.time,
  });

  factory ToolStateError.fromJson(Map<String, dynamic> json) => ToolStateError(
    status: json['status'] as String,
    input: json['input'] as Map<String, dynamic>,
    error: json['error'] as String,
    metadata: json['metadata'] as Map<String, dynamic>?,
    time: PartTime.fromJson(json['time'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'status': status,
    'input': input,
    'error': error,
    if (metadata != null) 'metadata': metadata,
    'time': time.toJson(),
  };
}

Object parseToolState(Map<String, dynamic> json) {
  final status = json['status'] as String;
  switch (status) {
    case 'pending':
      return ToolStatePending.fromJson(json);
    case 'running':
      return ToolStateRunning.fromJson(json);
    case 'completed':
      return ToolStateCompleted.fromJson(json);
    case 'error':
      return ToolStateError.fromJson(json);
    default:
      throw Exception('Unknown ToolState status: $status');
  }
}

Map<String, dynamic> toolStateToJson(Object state) {
  if (state is ToolStatePending) return state.toJson();
  if (state is ToolStateRunning) return state.toJson();
  if (state is ToolStateCompleted) return state.toJson();
  if (state is ToolStateError) return state.toJson();
  throw Exception('Unknown ToolState type');
}

@JsonSerializable(createFactory: false, createToJson: false)
class ToolPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String callID;
  final String tool;
  final Object state;
  final Map<String, dynamic>? metadata;

  ToolPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.callID,
    required this.tool,
    required this.state,
    this.metadata,
  });

  factory ToolPart.fromJson(Map<String, dynamic> json) => ToolPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    callID: json['callID'] as String,
    tool: json['tool'] as String,
    state: parseToolState(json['state'] as Map<String, dynamic>),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'callID': callID,
    'tool': tool,
    'state': toolStateToJson(state),
    if (metadata != null) 'metadata': metadata,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class StepStartPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String? snapshot;

  StepStartPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    this.snapshot,
  });

  factory StepStartPart.fromJson(Map<String, dynamic> json) => StepStartPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    snapshot: json['snapshot'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    if (snapshot != null) 'snapshot': snapshot,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class StepFinishPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String reason;
  final String? snapshot;
  final double? cost;
  final MessageTokens tokens;

  StepFinishPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.reason,
    this.snapshot,
    this.cost,
    required this.tokens,
  });

  factory StepFinishPart.fromJson(Map<String, dynamic> json) => StepFinishPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    reason: json['reason'] as String,
    snapshot: json['snapshot'] as String?,
    cost: (json['cost'] as num?)?.toDouble(),
    tokens: MessageTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'reason': reason,
    if (snapshot != null) 'snapshot': snapshot,
    if (cost != null) 'cost': cost,
    'tokens': tokens.toJson(),
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
class SnapshotPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String snapshot;

  SnapshotPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.snapshot,
  });

  factory SnapshotPart.fromJson(Map<String, dynamic> json) => SnapshotPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    snapshot: json['snapshot'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'snapshot': snapshot,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class PatchPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String hash;
  final List<String> files;

  PatchPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.hash,
    required this.files,
  });

  factory PatchPart.fromJson(Map<String, dynamic> json) => PatchPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    hash: json['hash'] as String,
    files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'hash': hash,
    'files': files,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class AgentPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String name;
  final AgentPartSource? source;

  AgentPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.name,
    this.source,
  });

  factory AgentPart.fromJson(Map<String, dynamic> json) => AgentPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    source: json['source'] == null
        ? null
        : AgentPartSource.fromJson(json['source'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'name': name,
    if (source != null) 'source': source?.toJson(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class AgentPartSource {
  final String value;
  final int start;
  final int end;

  AgentPartSource({
    required this.value,
    required this.start,
    required this.end,
  });

  factory AgentPartSource.fromJson(Map<String, dynamic> json) =>
      AgentPartSource(
        value: json['value'] as String,
        start: (json['start'] as num).toInt(),
        end: (json['end'] as num).toInt(),
      );
  Map<String, dynamic> toJson() => {'value': value, 'start': start, 'end': end};
}

@JsonSerializable(createFactory: false, createToJson: false)
class RetryPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final int attempt;
  final Object error;
  final RetryPartTime time;

  RetryPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.attempt,
    required this.error,
    required this.time,
  });

  factory RetryPart.fromJson(Map<String, dynamic> json) => RetryPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    attempt: (json['attempt'] as num).toInt(),
    error: parseMessageError(json['error'] as Map<String, dynamic>),
    time: RetryPartTime.fromJson(json['time'] as Map<String, dynamic>),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'attempt': attempt,
    'error': messageErrorToJson(error),
    'time': time.toJson(),
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class RetryPartTime {
  final int created;

  RetryPartTime({required this.created});

  factory RetryPartTime.fromJson(Map<String, dynamic> json) =>
      RetryPartTime(created: (json['created'] as num).toInt());
  Map<String, dynamic> toJson() => {'created': created};
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

@JsonSerializable(createFactory: false, createToJson: false)
class CompactionPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final bool auto;

  CompactionPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.auto,
  });

  factory CompactionPart.fromJson(Map<String, dynamic> json) => CompactionPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    auto: json['auto'] as bool,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'auto': auto,
  };
}

@JsonSerializable(createFactory: false, createToJson: false)
class SubtaskPart {
  final String id;
  final String sessionID;
  final String messageID;
  final String type;
  final String prompt;
  final String description;
  final String agent;

  SubtaskPart({
    required this.id,
    required this.sessionID,
    required this.messageID,
    required this.type,
    required this.prompt,
    required this.description,
    required this.agent,
  });

  factory SubtaskPart.fromJson(Map<String, dynamic> json) => SubtaskPart(
    id: json['id'] as String,
    sessionID: json['sessionID'] as String,
    messageID: json['messageID'] as String,
    type: json['type'] as String,
    prompt: json['prompt'] as String,
    description: json['description'] as String,
    agent: json['agent'] as String,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'messageID': messageID,
    'type': type,
    'prompt': prompt,
    'description': description,
    'agent': agent,
  };
}

String? partId(Object part) {
  return switch (part) {
    TextPart value => value.id,
    FilePart value => value.id,
    ToolPart value => value.id,
    ReasoningPart value => value.id,
    StepStartPart value => value.id,
    StepFinishPart value => value.id,
    SnapshotPart value => value.id,
    PatchPart value => value.id,
    AgentPart value => value.id,
    RetryPart value => value.id,
    CompactionPart value => value.id,
    SubtaskPart value => value.id,
    _ => null,
  };
}

String? partSessionId(Object part) {
  return switch (part) {
    TextPart value => value.sessionID,
    FilePart value => value.sessionID,
    ToolPart value => value.sessionID,
    ReasoningPart value => value.sessionID,
    StepStartPart value => value.sessionID,
    StepFinishPart value => value.sessionID,
    SnapshotPart value => value.sessionID,
    PatchPart value => value.sessionID,
    AgentPart value => value.sessionID,
    RetryPart value => value.sessionID,
    CompactionPart value => value.sessionID,
    SubtaskPart value => value.sessionID,
    _ => null,
  };
}

String? partMessageId(Object part) {
  return switch (part) {
    TextPart value => value.messageID,
    FilePart value => value.messageID,
    ToolPart value => value.messageID,
    ReasoningPart value => value.messageID,
    StepStartPart value => value.messageID,
    StepFinishPart value => value.messageID,
    SnapshotPart value => value.messageID,
    PatchPart value => value.messageID,
    AgentPart value => value.messageID,
    RetryPart value => value.messageID,
    CompactionPart value => value.messageID,
    SubtaskPart value => value.messageID,
    _ => null,
  };
}
