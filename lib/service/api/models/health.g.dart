// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) => Health(
  healthy: json['healthy'] as bool,
  version: json['version'] as String,
);

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'healthy': instance.healthy,
  'version': instance.version,
};
