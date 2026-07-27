class CommandInput {
  final String command;
  final String arguments;
  final String? model;
  final String? agent;
  final String? messageID;
  final String? variant;

  const CommandInput({
    required this.command,
    required this.arguments,
    this.model,
    this.agent,
    this.messageID,
    this.variant,
  });

  Map<String, dynamic> toJson() => {
    'command': command,
    'arguments': arguments,
    if (model != null) 'model': model,
    if (agent != null) 'agent': agent,
    if (messageID != null) 'messageID': messageID,
    if (variant != null) 'variant': variant,
  };
}
