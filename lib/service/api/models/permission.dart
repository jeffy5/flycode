class PermissionToolRef {
  final String messageID;
  final String callID;

  PermissionToolRef({required this.messageID, required this.callID});

  factory PermissionToolRef.fromJson(Map<String, dynamic> json) {
    return PermissionToolRef(
      messageID: json['messageID'] as String? ?? '',
      callID: json['callID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'messageID': messageID, 'callID': callID};
}

class PermissionRequest {
  final String id;
  final String sessionID;
  final String permission;
  final List<String> patterns;
  final List<String> always;
  final Map<String, dynamic>? metadata;
  final PermissionToolRef? tool;

  PermissionRequest({
    required this.id,
    required this.sessionID,
    required this.permission,
    required this.patterns,
    required this.always,
    this.metadata,
    this.tool,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    final rawPatterns = (json['patterns'] as List<dynamic>? ?? const []);
    final rawAlways = (json['always'] as List<dynamic>? ?? const []);
    final toolJson = json['tool'] as Map<String, dynamic>?;

    return PermissionRequest(
      id: json['id'] as String? ?? json['requestID'] as String? ?? '',
      sessionID: json['sessionID'] as String? ?? '',
      permission: json['permission'] as String? ?? '',
      patterns: rawPatterns.map((e) => e.toString()).toList(),
      always: rawAlways.map((e) => e.toString()).toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      tool: toolJson == null ? null : PermissionToolRef.fromJson(toolJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionID': sessionID,
    'permission': permission,
    'patterns': patterns,
    'always': always,
    if (metadata != null) 'metadata': metadata,
    if (tool != null) 'tool': tool!.toJson(),
  };
}

enum PermissionReplyAction { once, always, reject }
