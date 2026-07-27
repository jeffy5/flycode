import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Command {
  final String name;
  final String? description;
  final String? agent;
  final String? model;
  final bool? mcp;
  final String template;
  final bool? subtask;
  final List<String> hints;

  const Command({
    required this.name,
    this.description,
    this.agent,
    this.model,
    this.mcp,
    required this.template,
    this.subtask,
    required this.hints,
  });

  factory Command.fromJson(Map<String, dynamic> json) => Command(
    name: json['name'] as String,
    description: json['description'] as String?,
    agent: json['agent'] as String?,
    model: json['model'] as String?,
    mcp: json['mcp'] as bool?,
    template: json['template'] as String,
    subtask: json['subtask'] as bool?,
    hints: (json['hints'] as List<dynamic>).map((e) => e as String).toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (agent != null) 'agent': agent,
    if (model != null) 'model': model,
    if (mcp != null) 'mcp': mcp,
    'template': template,
    if (subtask != null) 'subtask': subtask,
    'hints': hints,
  };
}
