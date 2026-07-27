/// Session status model — mirrors the backend SessionStatus type.
///
/// Backend definition:
///   { type: "idle" }
///   { type: "busy" }
///   { type: "retry", attempt: number, message: string, next: number }
sealed class SessionStatus {
  const SessionStatus();

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'idle':
        return const SessionStatusIdle();
      case 'busy':
        return const SessionStatusBusy();
      case 'retry':
        return SessionStatusRetry(
          attempt: (json['attempt'] as num?)?.toInt() ?? 0,
          message: json['message'] as String? ?? '',
          next: (json['next'] as num?)?.toInt() ?? 0,
        );
      default:
        // Treat unknown types as idle to be forward-compatible.
        return const SessionStatusIdle();
    }
  }

  /// Returns true when the session is actively processing (busy or retry).
  bool get isWorking => this is! SessionStatusIdle;
}

class SessionStatusIdle extends SessionStatus {
  const SessionStatusIdle();
}

class SessionStatusBusy extends SessionStatus {
  const SessionStatusBusy();
}

class SessionStatusRetry extends SessionStatus {
  /// Current retry attempt number (1-based).
  final int attempt;

  /// Human-readable error message that triggered the retry.
  final String message;

  /// Unix timestamp in milliseconds for when the next retry will occur.
  final int next;

  const SessionStatusRetry({
    required this.attempt,
    required this.message,
    required this.next,
  });
}
