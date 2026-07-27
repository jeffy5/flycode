/// Agent model returned by GET /agent
class AgentModel {
  final String providerID;
  final String modelID;
  final String? variant;

  const AgentModel({
    required this.providerID,
    required this.modelID,
    this.variant,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      providerID: json['providerID'] as String,
      modelID: json['modelID'] as String,
      variant: json['variant'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'providerID': providerID,
    'modelID': modelID,
    if (variant != null) 'variant': variant,
  };
}

class Agent {
  final String name;
  final String? description;

  /// "subagent" | "primary" | "all"
  final String mode;
  final bool hidden;
  final String? color;

  /// Optional default model bound to this agent.
  final AgentModel? model;

  const Agent({
    required this.name,
    this.description,
    required this.mode,
    this.hidden = false,
    this.color,
    this.model,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    AgentModel? model;
    if (json['model'] != null) {
      model = AgentModel.fromJson(json['model'] as Map<String, dynamic>);
    }
    return Agent(
      name: json['name'] as String,
      description: json['description'] as String?,
      mode: json['mode'] as String? ?? 'primary',
      hidden: json['hidden'] as bool? ?? false,
      color: json['color'] as String?,
      model: model,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'mode': mode,
    'hidden': hidden,
    'color': color,
    'model': model?.toJson(),
  };
}
