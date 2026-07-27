// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionOption _$QuestionOptionFromJson(Map<String, dynamic> json) =>
    QuestionOption(
      label: json['label'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$QuestionOptionToJson(QuestionOption instance) =>
    <String, dynamic>{
      'label': instance.label,
      'description': instance.description,
    };

QuestionInfo _$QuestionInfoFromJson(Map<String, dynamic> json) => QuestionInfo(
  question: json['question'] as String,
  header: json['header'] as String,
  options: (json['options'] as List<dynamic>)
      .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  multiple: json['multiple'] as bool?,
  custom: json['custom'] as bool?,
);

Map<String, dynamic> _$QuestionInfoToJson(QuestionInfo instance) =>
    <String, dynamic>{
      'question': instance.question,
      'header': instance.header,
      'options': instance.options,
      'multiple': instance.multiple,
      'custom': instance.custom,
    };

QuestionTool _$QuestionToolFromJson(Map<String, dynamic> json) => QuestionTool(
  messageID: json['messageID'] as String,
  callID: json['callID'] as String,
);

Map<String, dynamic> _$QuestionToolToJson(QuestionTool instance) =>
    <String, dynamic>{
      'messageID': instance.messageID,
      'callID': instance.callID,
    };

QuestionRequest _$QuestionRequestFromJson(Map<String, dynamic> json) =>
    QuestionRequest(
      id: json['id'] as String,
      sessionID: json['sessionID'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      tool: json['tool'] == null
          ? null
          : QuestionTool.fromJson(json['tool'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$QuestionRequestToJson(QuestionRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionID': instance.sessionID,
      'questions': instance.questions,
      'tool': instance.tool,
    };
