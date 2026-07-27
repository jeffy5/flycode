import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  final String? model;
  final String? smallModel;
  final String? theme;
  final String? username;
  final String? share;
  final bool? autoshare;
  final Map<String, dynamic>? agent;
  final Map<String, dynamic>? provider;
  final Map<String, dynamic>? mcp;
  final List<String>? instructions;

  Config({
    this.model,
    this.smallModel,
    this.theme,
    this.username,
    this.share,
    this.autoshare,
    this.agent,
    this.provider,
    this.mcp,
    this.instructions,
  });

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
