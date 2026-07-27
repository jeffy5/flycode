// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Todo _$TodoFromJson(Map<String, dynamic> json) => Todo(
  id: json['id'] as String?,
  content: json['content'] as String,
  status: json['status'] as String,
  priority: json['priority'] as String,
);

Map<String, dynamic> _$TodoToJson(Todo instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'status': instance.status,
  'priority': instance.priority,
};

ProviderAuthErrorType _$ProviderAuthErrorTypeFromJson(
  Map<String, dynamic> json,
) => ProviderAuthErrorType(
  name: json['name'] as String,
  providerID: json['providerID'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$ProviderAuthErrorTypeToJson(
  ProviderAuthErrorType instance,
) => <String, dynamic>{
  'name': instance.name,
  'providerID': instance.providerID,
  'message': instance.message,
};

UnknownErrorType _$UnknownErrorTypeFromJson(Map<String, dynamic> json) =>
    UnknownErrorType(
      name: json['name'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$UnknownErrorTypeToJson(UnknownErrorType instance) =>
    <String, dynamic>{'name': instance.name, 'message': instance.message};

MessageOutputLengthErrorType _$MessageOutputLengthErrorTypeFromJson(
  Map<String, dynamic> json,
) => MessageOutputLengthErrorType(
  name: json['name'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$MessageOutputLengthErrorTypeToJson(
  MessageOutputLengthErrorType instance,
) => <String, dynamic>{'name': instance.name, 'data': instance.data};

MessageAbortedErrorType _$MessageAbortedErrorTypeFromJson(
  Map<String, dynamic> json,
) => MessageAbortedErrorType(
  name: json['name'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$MessageAbortedErrorTypeToJson(
  MessageAbortedErrorType instance,
) => <String, dynamic>{'name': instance.name, 'message': instance.message};

StructuredOutputErrorType _$StructuredOutputErrorTypeFromJson(
  Map<String, dynamic> json,
) => StructuredOutputErrorType(
  name: json['name'] as String,
  message: json['message'] as String,
  retries: (json['retries'] as num).toInt(),
);

Map<String, dynamic> _$StructuredOutputErrorTypeToJson(
  StructuredOutputErrorType instance,
) => <String, dynamic>{
  'name': instance.name,
  'message': instance.message,
  'retries': instance.retries,
};

ContextOverflowErrorType _$ContextOverflowErrorTypeFromJson(
  Map<String, dynamic> json,
) => ContextOverflowErrorType(
  name: json['name'] as String,
  message: json['message'] as String,
  responseBody: json['responseBody'] as String?,
);

Map<String, dynamic> _$ContextOverflowErrorTypeToJson(
  ContextOverflowErrorType instance,
) => <String, dynamic>{
  'name': instance.name,
  'message': instance.message,
  'responseBody': instance.responseBody,
};

ApiErrorType _$ApiErrorTypeFromJson(Map<String, dynamic> json) => ApiErrorType(
  name: json['name'] as String,
  message: json['message'] as String,
  statusCode: (json['statusCode'] as num?)?.toInt(),
  isRetryable: json['isRetryable'] as bool,
  responseHeaders: (json['responseHeaders'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  responseBody: json['responseBody'] as String?,
  metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$ApiErrorTypeToJson(ApiErrorType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'message': instance.message,
      'statusCode': instance.statusCode,
      'isRetryable': instance.isRetryable,
      'responseHeaders': instance.responseHeaders,
      'responseBody': instance.responseBody,
      'metadata': instance.metadata,
    };

EventMessageUpdated _$EventMessageUpdatedFromJson(Map<String, dynamic> json) =>
    EventMessageUpdated(
      type: json['type'] as String,
      info: json['info'] as Object,
    );

Map<String, dynamic> _$EventMessageUpdatedToJson(
  EventMessageUpdated instance,
) => <String, dynamic>{'type': instance.type, 'info': instance.info};

EventMessageRemoved _$EventMessageRemovedFromJson(Map<String, dynamic> json) =>
    EventMessageRemoved(
      type: json['type'] as String,
      sessionID: json['sessionID'] as String,
      messageID: json['messageID'] as String,
    );

Map<String, dynamic> _$EventMessageRemovedToJson(
  EventMessageRemoved instance,
) => <String, dynamic>{
  'type': instance.type,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
};

EventMessagePartUpdated _$EventMessagePartUpdatedFromJson(
  Map<String, dynamic> json,
) => EventMessagePartUpdated(
  type: json['type'] as String,
  part: json['part'] as Object,
);

Map<String, dynamic> _$EventMessagePartUpdatedToJson(
  EventMessagePartUpdated instance,
) => <String, dynamic>{'type': instance.type, 'part': instance.part};

EventMessagePartRemoved _$EventMessagePartRemovedFromJson(
  Map<String, dynamic> json,
) => EventMessagePartRemoved(
  type: json['type'] as String,
  sessionID: json['sessionID'] as String,
  messageID: json['messageID'] as String,
  partID: json['partID'] as String,
);

Map<String, dynamic> _$EventMessagePartRemovedToJson(
  EventMessagePartRemoved instance,
) => <String, dynamic>{
  'type': instance.type,
  'sessionID': instance.sessionID,
  'messageID': instance.messageID,
  'partID': instance.partID,
};

EventTodoUpdated _$EventTodoUpdatedFromJson(Map<String, dynamic> json) =>
    EventTodoUpdated(
      type: json['type'] as String,
      sessionID: json['sessionID'] as String,
      todos: (json['todos'] as List<dynamic>)
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventTodoUpdatedToJson(EventTodoUpdated instance) =>
    <String, dynamic>{
      'type': instance.type,
      'sessionID': instance.sessionID,
      'todos': instance.todos,
    };

EventSessionCreated _$EventSessionCreatedFromJson(Map<String, dynamic> json) =>
    EventSessionCreated(
      type: json['type'] as String,
      info: Session.fromJson(json['info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventSessionCreatedToJson(
  EventSessionCreated instance,
) => <String, dynamic>{'type': instance.type, 'info': instance.info};

EventSessionUpdated _$EventSessionUpdatedFromJson(Map<String, dynamic> json) =>
    EventSessionUpdated(
      type: json['type'] as String,
      info: Session.fromJson(json['info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventSessionUpdatedToJson(
  EventSessionUpdated instance,
) => <String, dynamic>{'type': instance.type, 'info': instance.info};

EventSessionDeleted _$EventSessionDeletedFromJson(Map<String, dynamic> json) =>
    EventSessionDeleted(
      type: json['type'] as String,
      info: Session.fromJson(json['info'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventSessionDeletedToJson(
  EventSessionDeleted instance,
) => <String, dynamic>{'type': instance.type, 'info': instance.info};

EventSessionDiff _$EventSessionDiffFromJson(Map<String, dynamic> json) =>
    EventSessionDiff(
      type: json['type'] as String,
      sessionID: json['sessionID'] as String,
      diff: (json['diff'] as List<dynamic>)
          .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EventSessionDiffToJson(EventSessionDiff instance) =>
    <String, dynamic>{
      'type': instance.type,
      'sessionID': instance.sessionID,
      'diff': instance.diff,
    };

EventSessionError _$EventSessionErrorFromJson(Map<String, dynamic> json) =>
    EventSessionError(
      type: json['type'] as String,
      sessionID: json['sessionID'] as String?,
      error: json['error'],
    );

Map<String, dynamic> _$EventSessionErrorToJson(EventSessionError instance) =>
    <String, dynamic>{
      'type': instance.type,
      'sessionID': instance.sessionID,
      'error': instance.error,
    };

GlobalEvent _$GlobalEventFromJson(Map<String, dynamic> json) => GlobalEvent(
  directory: json['directory'] as String,
  payload: json['payload'] as Object,
);

Map<String, dynamic> _$GlobalEventToJson(GlobalEvent instance) =>
    <String, dynamic>{
      'directory': instance.directory,
      'payload': instance.payload,
    };
