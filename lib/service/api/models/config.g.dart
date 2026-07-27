// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
  model: json['model'] as String?,
  smallModel: json['smallModel'] as String?,
  theme: json['theme'] as String?,
  username: json['username'] as String?,
  share: json['share'] as String?,
  autoshare: json['autoshare'] as bool?,
  agent: json['agent'] as Map<String, dynamic>?,
  provider: json['provider'] as Map<String, dynamic>?,
  mcp: json['mcp'] as Map<String, dynamic>?,
  instructions: (json['instructions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
  'model': instance.model,
  'smallModel': instance.smallModel,
  'theme': instance.theme,
  'username': instance.username,
  'share': instance.share,
  'autoshare': instance.autoshare,
  'agent': instance.agent,
  'provider': instance.provider,
  'mcp': instance.mcp,
  'instructions': instance.instructions,
};
