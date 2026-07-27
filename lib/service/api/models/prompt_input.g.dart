// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPartInput _$TextPartInputFromJson(Map<String, dynamic> json) =>
    TextPartInput(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String,
      synthetic: json['synthetic'] as bool?,
      ignored: json['ignored'] as bool?,
      time: json['time'] == null
          ? null
          : PartTime.fromJson(json['time'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TextPartInputToJson(TextPartInput instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.type,
      'text': instance.text,
      'synthetic': ?instance.synthetic,
      'ignored': ?instance.ignored,
      'time': ?instance.time,
      'metadata': ?instance.metadata,
    };

FilePartInput _$FilePartInputFromJson(Map<String, dynamic> json) =>
    FilePartInput(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'file',
      mime: json['mime'] as String,
      filename: json['filename'] as String?,
      url: json['url'] as String,
      source: json['source'],
    );

Map<String, dynamic> _$FilePartInputToJson(FilePartInput instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.type,
      'mime': instance.mime,
      'filename': ?instance.filename,
      'url': instance.url,
      'source': ?instance.source,
    };

AgentPartInput _$AgentPartInputFromJson(Map<String, dynamic> json) =>
    AgentPartInput(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'agent',
      name: json['name'] as String,
      source: json['source'] == null
          ? null
          : AgentPartSource.fromJson(json['source'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AgentPartInputToJson(AgentPartInput instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.type,
      'name': instance.name,
      'source': ?instance.source,
    };

SubtaskPartInput _$SubtaskPartInputFromJson(Map<String, dynamic> json) =>
    SubtaskPartInput(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'subtask',
      prompt: json['prompt'] as String,
      description: json['description'] as String,
      agent: json['agent'] as String,
    );

Map<String, dynamic> _$SubtaskPartInputToJson(SubtaskPartInput instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'type': instance.type,
      'prompt': instance.prompt,
      'description': instance.description,
      'agent': instance.agent,
    };

PromptAsyncInput _$PromptAsyncInputFromJson(Map<String, dynamic> json) =>
    PromptAsyncInput(
      messageID: json['messageID'] as String?,
      model: json['model'] == null
          ? null
          : MessageModel.fromJson(json['model'] as Map<String, dynamic>),
      agent: json['agent'] as String?,
      noReply: json['noReply'] as bool?,
      tools: (json['tools'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ),
      format: json['format'] as String?,
      system: json['system'] as String?,
      variant: json['variant'] as String?,
      parts: (json['parts'] as List<dynamic>).map((e) => e as Object).toList(),
    );

Map<String, dynamic> _$PromptAsyncInputToJson(PromptAsyncInput instance) =>
    <String, dynamic>{
      'messageID': ?instance.messageID,
      'model': ?instance.model,
      'agent': ?instance.agent,
      'noReply': ?instance.noReply,
      'tools': ?instance.tools,
      'format': ?instance.format,
      'system': ?instance.system,
      'variant': ?instance.variant,
      'parts': instance.parts,
    };
