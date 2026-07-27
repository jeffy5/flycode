import 'package:json_annotation/json_annotation.dart';
import 'message.dart' hide FileDiff;
import 'permission.dart';
import 'question.dart';
import 'session.dart';
import 'session_status.dart';

part 'global_event.g.dart';

@JsonSerializable()
class Todo {
  final String? id;
  final String content;
  final String status;
  final String priority;

  Todo({
    this.id,
    required this.content,
    required this.status,
    required this.priority,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);
}

@JsonSerializable()
class ProviderAuthErrorType {
  final String name;
  final String providerID;
  final String message;

  ProviderAuthErrorType({
    required this.name,
    required this.providerID,
    required this.message,
  });

  factory ProviderAuthErrorType.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ProviderAuthErrorTypeToJson(this);
}

@JsonSerializable()
class UnknownErrorType {
  final String name;
  final String message;

  UnknownErrorType({required this.name, required this.message});

  factory UnknownErrorType.fromJson(Map<String, dynamic> json) =>
      _$UnknownErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$UnknownErrorTypeToJson(this);
}

@JsonSerializable()
class MessageOutputLengthErrorType {
  final String name;
  final Map<String, dynamic> data;

  MessageOutputLengthErrorType({required this.name, required this.data});

  factory MessageOutputLengthErrorType.fromJson(Map<String, dynamic> json) =>
      _$MessageOutputLengthErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$MessageOutputLengthErrorTypeToJson(this);
}

@JsonSerializable()
class MessageAbortedErrorType {
  final String name;
  final String message;

  MessageAbortedErrorType({required this.name, required this.message});

  factory MessageAbortedErrorType.fromJson(Map<String, dynamic> json) =>
      _$MessageAbortedErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$MessageAbortedErrorTypeToJson(this);
}

@JsonSerializable()
class StructuredOutputErrorType {
  final String name;
  final String message;
  final int retries;

  StructuredOutputErrorType({
    required this.name,
    required this.message,
    required this.retries,
  });

  factory StructuredOutputErrorType.fromJson(Map<String, dynamic> json) =>
      _$StructuredOutputErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$StructuredOutputErrorTypeToJson(this);
}

@JsonSerializable()
class ContextOverflowErrorType {
  final String name;
  final String message;
  final String? responseBody;

  ContextOverflowErrorType({
    required this.name,
    required this.message,
    this.responseBody,
  });

  factory ContextOverflowErrorType.fromJson(Map<String, dynamic> json) =>
      _$ContextOverflowErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ContextOverflowErrorTypeToJson(this);
}

@JsonSerializable()
class ApiErrorType {
  final String name;
  final String message;
  final int? statusCode;
  final bool isRetryable;
  final Map<String, String>? responseHeaders;
  final String? responseBody;
  final Map<String, String>? metadata;

  ApiErrorType({
    required this.name,
    required this.message,
    this.statusCode,
    required this.isRetryable,
    this.responseHeaders,
    this.responseBody,
    this.metadata,
  });

  factory ApiErrorType.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorTypeFromJson(json);
  Map<String, dynamic> toJson() => _$ApiErrorTypeToJson(this);
}

Object? parseErrorType(Map<String, dynamic> json) {
  final name = json['name'] as String;
  final data = json['data'] as Map<String, dynamic>? ?? {};
  switch (name) {
    case 'ProviderAuthError':
      return ProviderAuthErrorType(
        name: name,
        providerID: data['providerID'] as String? ?? '',
        message: data['message'] as String? ?? '',
      );
    case 'UnknownError':
      return UnknownErrorType(
        name: name,
        message: data['message'] as String? ?? '',
      );
    case 'MessageOutputLengthError':
      return MessageOutputLengthErrorType(name: name, data: data);
    case 'MessageAbortedError':
      return MessageAbortedErrorType(
        name: name,
        message: data['message'] as String? ?? '',
      );
    case 'StructuredOutputError':
      return StructuredOutputErrorType(
        name: name,
        message: data['message'] as String? ?? '',
        retries: (data['retries'] as num?)?.toInt() ?? 0,
      );
    case 'ContextOverflowError':
      return ContextOverflowErrorType(
        name: name,
        message: data['message'] as String? ?? '',
        responseBody: data['responseBody'] as String?,
      );
    case 'APIError':
      return ApiErrorType(
        name: name,
        message: data['message'] as String? ?? '',
        statusCode: (data['statusCode'] as num?)?.toInt(),
        isRetryable: data['isRetryable'] as bool? ?? false,
        responseHeaders: data['responseHeaders'] == null
            ? null
            : (data['responseHeaders'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v as String),
              ),
        responseBody: data['responseBody'] as String?,
        metadata: data['metadata'] == null
            ? null
            : (data['metadata'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v as String),
              ),
      );
    default:
      return null;
  }
}

@JsonSerializable()
class EventMessageUpdated {
  final String type;
  final Object info;

  EventMessageUpdated({required this.type, required this.info});

  factory EventMessageUpdated.fromJson(Map<String, dynamic> json) =>
      _$EventMessageUpdatedFromJson(json);
  Map<String, dynamic> toJson() => _$EventMessageUpdatedToJson(this);
}

@JsonSerializable()
class EventMessageRemoved {
  final String type;
  final String sessionID;
  final String messageID;

  EventMessageRemoved({
    required this.type,
    required this.sessionID,
    required this.messageID,
  });

  factory EventMessageRemoved.fromJson(Map<String, dynamic> json) =>
      _$EventMessageRemovedFromJson(json);
  Map<String, dynamic> toJson() => _$EventMessageRemovedToJson(this);
}

@JsonSerializable()
class EventMessagePartUpdated {
  final String type;
  final Object part;

  EventMessagePartUpdated({required this.type, required this.part});

  factory EventMessagePartUpdated.fromJson(Map<String, dynamic> json) =>
      _$EventMessagePartUpdatedFromJson(json);
  Map<String, dynamic> toJson() => _$EventMessagePartUpdatedToJson(this);
}

class EventMessagePartDelta {
  final String type;
  final String sessionID;
  final String messageID;
  final String partID;
  final String field;
  final String delta;

  EventMessagePartDelta({
    required this.type,
    required this.sessionID,
    required this.messageID,
    required this.partID,
    required this.field,
    required this.delta,
  });
}

@JsonSerializable()
class EventMessagePartRemoved {
  final String type;
  final String sessionID;
  final String messageID;
  final String partID;

  EventMessagePartRemoved({
    required this.type,
    required this.sessionID,
    required this.messageID,
    required this.partID,
  });

  factory EventMessagePartRemoved.fromJson(Map<String, dynamic> json) =>
      _$EventMessagePartRemovedFromJson(json);
  Map<String, dynamic> toJson() => _$EventMessagePartRemovedToJson(this);
}

@JsonSerializable()
class EventTodoUpdated {
  final String type;
  final String sessionID;
  final List<Todo> todos;

  EventTodoUpdated({
    required this.type,
    required this.sessionID,
    required this.todos,
  });

  factory EventTodoUpdated.fromJson(Map<String, dynamic> json) =>
      _$EventTodoUpdatedFromJson(json);
  Map<String, dynamic> toJson() => _$EventTodoUpdatedToJson(this);
}

@JsonSerializable()
class EventSessionCreated {
  final String type;
  final Session info;

  EventSessionCreated({required this.type, required this.info});

  factory EventSessionCreated.fromJson(Map<String, dynamic> json) =>
      _$EventSessionCreatedFromJson(json);
  Map<String, dynamic> toJson() => _$EventSessionCreatedToJson(this);
}

@JsonSerializable()
class EventSessionUpdated {
  final String type;
  final Session info;

  EventSessionUpdated({required this.type, required this.info});

  factory EventSessionUpdated.fromJson(Map<String, dynamic> json) =>
      _$EventSessionUpdatedFromJson(json);
  Map<String, dynamic> toJson() => _$EventSessionUpdatedToJson(this);
}

@JsonSerializable()
class EventSessionDeleted {
  final String type;
  final Session info;

  EventSessionDeleted({required this.type, required this.info});

  factory EventSessionDeleted.fromJson(Map<String, dynamic> json) =>
      _$EventSessionDeletedFromJson(json);
  Map<String, dynamic> toJson() => _$EventSessionDeletedToJson(this);
}

@JsonSerializable()
class EventSessionDiff {
  final String type;
  final String sessionID;
  final List<FileDiff> diff;

  EventSessionDiff({
    required this.type,
    required this.sessionID,
    required this.diff,
  });

  factory EventSessionDiff.fromJson(Map<String, dynamic> json) =>
      _$EventSessionDiffFromJson(json);
  Map<String, dynamic> toJson() => _$EventSessionDiffToJson(this);
}

@JsonSerializable()
class EventSessionError {
  final String type;
  final String? sessionID;
  final Object? error;

  EventSessionError({required this.type, this.sessionID, this.error});

  factory EventSessionError.fromJson(Map<String, dynamic> json) =>
      _$EventSessionErrorFromJson(json);
  Map<String, dynamic> toJson() => _$EventSessionErrorToJson(this);
}

class EventQuestionAsked {
  final String type;
  final QuestionRequest properties;

  EventQuestionAsked({required this.type, required this.properties});
}

class EventQuestionReplied {
  final String type;
  final String sessionID;
  final String requestID;
  final List<List<String>> answers;

  EventQuestionReplied({
    required this.type,
    required this.sessionID,
    required this.requestID,
    required this.answers,
  });
}

class EventQuestionRejected {
  final String type;
  final String sessionID;
  final String requestID;

  EventQuestionRejected({
    required this.type,
    required this.sessionID,
    required this.requestID,
  });
}

class EventSessionStatus {
  final String type;
  final String sessionID;
  final SessionStatus status;

  EventSessionStatus({
    required this.type,
    required this.sessionID,
    required this.status,
  });
}

class EventSessionIdle {
  final String type;
  final String sessionID;

  EventSessionIdle({required this.type, required this.sessionID});
}

class EventPermissionAsked {
  final String type;
  final PermissionRequest request;

  EventPermissionAsked({required this.type, required this.request});
}

class EventPermissionReplied {
  final String type;
  final String sessionID;
  final String requestID;

  EventPermissionReplied({
    required this.type,
    required this.sessionID,
    required this.requestID,
  });
}

/// Sentinel object returned for unknown/unhandled event types.
/// Using a sentinel instead of throwing prevents SSE connection crashes
/// when the backend introduces new event types.
class EventUnknown {
  final String type;
  const EventUnknown(this.type);
}

Object parseEvent(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'message.updated':
      final infoJson = json['properties']['info'] as Map<String, dynamic>;
      return EventMessageUpdated(type: type, info: parseMsg(infoJson));
    case 'message.removed':
      return EventMessageRemoved(
        type: type,
        sessionID: json['properties']['sessionID'] as String,
        messageID: json['properties']['messageID'] as String,
      );
    case 'message.part.updated':
      final partJson = json['properties']['part'] as Map<String, dynamic>;
      return EventMessagePartUpdated(type: type, part: parsePart(partJson));
    case 'message.part.delta':
      final props = json['properties'] as Map<String, dynamic>;
      return EventMessagePartDelta(
        type: type,
        sessionID: props['sessionID'] as String,
        messageID: props['messageID'] as String,
        partID: props['partID'] as String,
        field: props['field'] as String,
        delta: props['delta'] as String,
      );
    case 'message.part.removed':
      return EventMessagePartRemoved(
        type: type,
        sessionID: json['properties']['sessionID'] as String,
        messageID: json['properties']['messageID'] as String,
        partID: json['properties']['partID'] as String,
      );
    case 'todo.updated':
      final todosJson = json['properties']['todos'] as List<dynamic>;
      return EventTodoUpdated(
        type: type,
        sessionID: json['properties']['sessionID'] as String,
        todos: todosJson
            .map((e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    case 'session.created':
      final sessionJson = json['properties']['info'] as Map<String, dynamic>;
      return EventSessionCreated(
        type: type,
        info: Session.fromJson(sessionJson),
      );
    case 'session.updated':
      final sessionJson2 = json['properties']['info'] as Map<String, dynamic>;
      return EventSessionUpdated(
        type: type,
        info: Session.fromJson(sessionJson2),
      );
    case 'session.deleted':
      final sessionJson3 = json['properties']['info'] as Map<String, dynamic>;
      return EventSessionDeleted(
        type: type,
        info: Session.fromJson(sessionJson3),
      );
    case 'session.diff':
      final diffJson = json['properties']['diff'] as List<dynamic>;
      return EventSessionDiff(
        type: type,
        sessionID: json['properties']['sessionID'] as String,
        diff: diffJson
            .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    case 'session.error':
      final errorJson = json['properties']['error'] as Map<String, dynamic>?;
      return EventSessionError(
        type: type,
        sessionID: json['properties']['sessionID'] as String?,
        error: errorJson != null ? parseErrorType(errorJson) : null,
      );
    case 'question.asked':
      final propsJson = json['properties'] as Map<String, dynamic>;
      return EventQuestionAsked(
        type: type,
        properties: QuestionRequest.fromJson(propsJson),
      );
    case 'question.replied':
      final repliedProps = json['properties'] as Map<String, dynamic>;
      final rawAnswers = repliedProps['answers'] as List<dynamic>;
      return EventQuestionReplied(
        type: type,
        sessionID: repliedProps['sessionID'] as String,
        requestID: repliedProps['requestID'] as String,
        answers: rawAnswers
            .map(
              (row) => (row as List<dynamic>).map((v) => v as String).toList(),
            )
            .toList(),
      );
    case 'question.rejected':
      final rejectedProps = json['properties'] as Map<String, dynamic>;
      return EventQuestionRejected(
        type: type,
        sessionID: rejectedProps['sessionID'] as String,
        requestID: rejectedProps['requestID'] as String,
      );
    case 'session.status':
      final statusProps = json['properties'] as Map<String, dynamic>;
      return EventSessionStatus(
        type: type,
        sessionID: statusProps['sessionID'] as String,
        status: SessionStatus.fromJson(
          statusProps['status'] as Map<String, dynamic>,
        ),
      );
    case 'session.idle':
      final idleProps = json['properties'] as Map<String, dynamic>;
      return EventSessionIdle(
        type: type,
        sessionID: idleProps['sessionID'] as String,
      );
    case 'permission.asked':
      final props = json['properties'] as Map<String, dynamic>;
      return EventPermissionAsked(
        type: type,
        request: PermissionRequest.fromJson(props),
      );
    case 'permission.replied':
      final props = json['properties'] as Map<String, dynamic>;
      return EventPermissionReplied(
        type: type,
        sessionID: props['sessionID'] as String? ?? '',
        requestID:
            props['requestID'] as String? ?? props['id'] as String? ?? '',
      );
    default:
      // Return a sentinel instead of throwing so unknown future event types
      // do not crash the SSE connection.
      return EventUnknown(type);
  }
}

@JsonSerializable()
class GlobalEvent {
  final String directory;
  final Object payload;

  GlobalEvent({required this.directory, required this.payload});

  factory GlobalEvent.fromJson(Map<String, dynamic> json) =>
      _$GlobalEventFromJson(json);
  Map<String, dynamic> toJson() => _$GlobalEventToJson(this);
}

GlobalEvent parseGlobalEvent(Map<String, dynamic> json) {
  final payloadJson = json['payload'] as Map<String, dynamic>;
  return GlobalEvent(
    directory: json['directory'] as String? ?? '',
    payload: parseEvent(payloadJson),
  );
}
