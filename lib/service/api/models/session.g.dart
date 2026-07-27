// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  id: json['id'] as String,
  slug: json['slug'] as String,
  projectID: json['projectID'] as String,
  directory: json['directory'] as String,
  parentID: json['parentID'] as String?,
  summary: json['summary'] == null
      ? null
      : SessionSummary.fromJson(json['summary'] as Map<String, dynamic>),
  share: json['share'] == null
      ? null
      : SessionShare.fromJson(json['share'] as Map<String, dynamic>),
  title: json['title'] as String?,
  version: json['version'] as String,
  time: SessionTime.fromJson(json['time'] as Map<String, dynamic>),
  permission: (json['permission'] as List<dynamic>?)
      ?.map((e) => PermissionRule.fromJson(e as Map<String, dynamic>))
      .toList(),
  revert: json['revert'] == null
      ? null
      : SessionRevert.fromJson(json['revert'] as Map<String, dynamic>),
);
