import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class QuestionOption {
  final String label;
  final String description;

  QuestionOption({required this.label, required this.description});

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}

@JsonSerializable()
class QuestionInfo {
  final String question;
  final String header;
  final List<QuestionOption> options;
  final bool? multiple;
  final bool? custom;

  QuestionInfo({
    required this.question,
    required this.header,
    required this.options,
    this.multiple,
    this.custom,
  });

  factory QuestionInfo.fromJson(Map<String, dynamic> json) =>
      _$QuestionInfoFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionInfoToJson(this);
}

@JsonSerializable()
class QuestionTool {
  final String messageID;
  final String callID;

  QuestionTool({required this.messageID, required this.callID});

  factory QuestionTool.fromJson(Map<String, dynamic> json) =>
      _$QuestionToolFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToolToJson(this);
}

@JsonSerializable()
class QuestionRequest {
  final String id;
  final String sessionID;
  final List<QuestionInfo> questions;
  final QuestionTool? tool;

  QuestionRequest({
    required this.id,
    required this.sessionID,
    required this.questions,
    this.tool,
  });

  factory QuestionRequest.fromJson(Map<String, dynamic> json) =>
      _$QuestionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionRequestToJson(this);
}
