class ServerConfig {
  final String baseUrl;
  final String? username;
  final String? password;

  ServerConfig({required this.baseUrl, this.username, this.password});

  factory ServerConfig.defaultValue() {
    return ServerConfig(baseUrl: 'http://127.0.0.1:4096');
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      baseUrl: json['baseUrl'] as String? ?? 'http://127.0.0.1:4096',
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
    };
  }

  ServerConfig copyWith({
    String? baseUrl,
    String? username,
    String? password,
    bool clearUsername = false,
    bool clearPassword = false,
  }) {
    return ServerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      username: clearUsername ? null : (username ?? this.username),
      password: clearPassword ? null : (password ?? this.password),
    );
  }

  bool get hasAuth => username != null && username!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.baseUrl == baseUrl &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(baseUrl, username, password);
}
