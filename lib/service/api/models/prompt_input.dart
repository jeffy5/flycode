import 'package:json_annotation/json_annotation.dart';
import 'message.dart';
import 'parts.dart';

part 'prompt_input.g.dart';

@JsonSerializable(includeIfNull: false)
class TextPartInput {
  final String? id;
  final String type;
  final String text;
  final bool? synthetic;
  final bool? ignored;
  final PartTime? time;
  final Map<String, dynamic>? metadata;

  TextPartInput({
    this.id,
    this.type = 'text',
    required this.text,
    this.synthetic,
    this.ignored,
    this.time,
    this.metadata,
  });

  factory TextPartInput.fromJson(Map<String, dynamic> json) =>
      _$TextPartInputFromJson(json);
  Map<String, dynamic> toJson() => _$TextPartInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class FilePartInput {
  final String? id;
  final String type;
  final String mime;
  final String? filename;
  final String url;
  final Object? source;

  FilePartInput({
    this.id,
    this.type = 'file',
    required this.mime,
    this.filename,
    required this.url,
    this.source,
  });

  factory FilePartInput.fromJson(Map<String, dynamic> json) =>
      _$FilePartInputFromJson(json);
  Map<String, dynamic> toJson() => _$FilePartInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class AgentPartInput {
  final String? id;
  final String type;
  final String name;
  final AgentPartSource? source;

  AgentPartInput({
    this.id,
    this.type = 'agent',
    required this.name,
    this.source,
  });

  factory AgentPartInput.fromJson(Map<String, dynamic> json) =>
      _$AgentPartInputFromJson(json);
  Map<String, dynamic> toJson() => _$AgentPartInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class SubtaskPartInput {
  final String? id;
  final String type;
  final String prompt;
  final String description;
  final String agent;

  SubtaskPartInput({
    this.id,
    this.type = 'subtask',
    required this.prompt,
    required this.description,
    required this.agent,
  });

  factory SubtaskPartInput.fromJson(Map<String, dynamic> json) =>
      _$SubtaskPartInputFromJson(json);
  Map<String, dynamic> toJson() => _$SubtaskPartInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class PromptAsyncInput {
  final String? messageID;
  final MessageModel? model;
  final String? agent;
  final bool? noReply;
  final Map<String, bool>? tools;
  final String? format;
  final String? system;
  final String? variant;
  final List<Object> parts;

  PromptAsyncInput({
    this.messageID,
    this.model,
    this.agent,
    this.noReply,
    this.tools,
    this.format,
    this.system,
    this.variant,
    required this.parts,
  });

  factory PromptAsyncInput.fromJson(Map<String, dynamic> json) =>
      _$PromptAsyncInputFromJson(json);
  Map<String, dynamic> toJson() {
    final json = _$PromptAsyncInputToJson(this);
    json.removeWhere((k, v) => v == null);
    json['parts'] = parts.map((e) {
      if (e is TextPartInput) {
        return e.toJson()..removeWhere((k, v) => v == null);
      }
      if (e is FilePartInput) {
        return e.toJson()..removeWhere((k, v) => v == null);
      }
      if (e is AgentPartInput) {
        return e.toJson()..removeWhere((k, v) => v == null);
      }
      if (e is SubtaskPartInput) {
        return e.toJson()..removeWhere((k, v) => v == null);
      }
      if (e is Map<String, dynamic>) return e;
      throw Exception('Unknown part input type: ${e.runtimeType}');
    }).toList();
    return json;
  }
}
