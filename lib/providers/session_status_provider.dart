import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'current_directory_provider.dart';
import '../service/api/session_api.dart';
import '../service/api/models/session_status.dart';

part 'session_status_provider.g.dart';

/// Tracks the backend-reported status for each session.
///
/// The map only contains entries for sessions that are non-idle.
/// A missing key is equivalent to [SessionStatusIdle].
@Riverpod()
class SessionStatusNotifier extends _$SessionStatusNotifier {
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  Future<void>? _refreshFuture;

  @override
  Map<String, SessionStatus> build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    unawaited(refreshFromServer());
    return const {};
  }

  void updateStatus(String sessionID, SessionStatus status) {
    if (status is SessionStatusIdle) {
      // Remove idle entries to keep the map small.
      if (state.containsKey(sessionID)) {
        state = Map.unmodifiable({
          for (final entry in state.entries)
            if (entry.key != sessionID) entry.key: entry.value,
        });
      }
    } else {
      state = Map.unmodifiable({...state, sessionID: status});
    }
    _syncPolling();
  }

  /// Replaces local session-status cache with server snapshot.
  ///
  /// This is used as a reconciliation fallback when SSE misses an update.
  Future<void> refreshFromServer() async {
    final inFlightRefresh = _refreshFuture;
    if (inFlightRefresh != null) {
      await inFlightRefresh;
      return;
    }

    final refresh = _refreshFromServerInternal();
    _refreshFuture = refresh;

    try {
      await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
      if (ref.mounted) {
        _syncPolling();
      }
    }
  }

  Future<void> _refreshFromServerInternal() async {
    try {
      final api = await ref.read(sessionApiProvider.future);
      if (!ref.mounted) return;
      final directory = ref.read(currentDirectoryProvider);
      if (!ref.mounted) return;
      final raw = await api.getSessionStatus(directory: directory);
      if (!ref.mounted) return;
      state = Map.unmodifiable(_parseStatusSnapshot(raw));
    } catch (_) {
      // Keep current state when snapshot fetch fails.
    }
  }

  /// Returns true when the given session is busy or retrying.
  bool isWorking(String sessionID) {
    final s = state[sessionID];
    return s != null && s.isWorking;
  }

  /// Returns the status for a given session, defaulting to [SessionStatusIdle].
  SessionStatus statusFor(String sessionID) {
    return state[sessionID] ?? const SessionStatusIdle();
  }

  void _syncPolling() {
    if (!ref.mounted) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    final hasWorking = state.values.any((status) => status.isWorking);
    if (!hasWorking) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    _pollTimer ??= Timer.periodic(_pollInterval, (_) {
      unawaited(refreshFromServer());
    });
  }
}

Map<String, SessionStatus> _parseStatusSnapshot(Map<String, dynamic> raw) {
  final result = <String, SessionStatus>{};

  void tryInsert(String sessionID, Object? statusLike) {
    final status = _parseStatusValue(statusLike);
    if (status == null || status is SessionStatusIdle) {
      return;
    }
    result[sessionID] = status;
  }

  void parseMap(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        final sid = value['sessionID'];
        final nestedStatus = value['status'];
        if (sid is String && sid.isNotEmpty && nestedStatus != null) {
          tryInsert(sid, nestedStatus);
          continue;
        }

        if (value.containsKey('type')) {
          tryInsert(key, value);
          continue;
        }

        parseMap(value);
        continue;
      }

      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final sid = item['sessionID'];
            final status = item['status'];
            if (sid is String && sid.isNotEmpty && status != null) {
              tryInsert(sid, status);
            }
          }
        }
        continue;
      }

      tryInsert(key, value);
    }
  }

  parseMap(raw);
  return result;
}

SessionStatus? _parseStatusValue(Object? value) {
  if (value is Map<String, dynamic> && value.containsKey('type')) {
    return SessionStatus.fromJson(value);
  }

  if (value is String) {
    return SessionStatus.fromJson({'type': value});
  }

  return null;
}
