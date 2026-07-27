import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'models/agent.dart';
import 'models/config.dart';
import 'models/global_event.dart';
import 'models/health.dart';

part 'global_api.g.dart';

@riverpod
Future<GlobalApi> globalApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return GlobalApi(client);
}

class GlobalApi {
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 5);

  final ApiClient _client;
  final Future<void> Function(Duration duration) _reconnectDelay;

  GlobalApi(
    this._client, {
    Future<void> Function(Duration duration)? reconnectDelay,
  }) : _reconnectDelay = reconnectDelay ?? Future<void>.delayed;

  Future<Health> getHealth() async {
    final json = await _client.get('/global/health');
    return Health.fromJson(json);
  }

  Future<Config> getConfig() async {
    final json = await _client.get('/global/config');
    return Config.fromJson(json);
  }

  Future<List<Agent>> getAgents({String? directory}) async {
    final queryParams = directory != null ? {'directory': directory} : null;
    final json = await _client.get('/agent', queryParameters: queryParams);
    if (json is! List) return [];
    return json.whereType<Map<String, dynamic>>().map(Agent.fromJson).toList();
  }

  Future<Config> updateConfig(Config config) async {
    final json = await _client.patch('/global/config', body: config.toJson());
    return Config.fromJson(json);
  }

  Stream<GlobalEvent> subscribeToGlobalEvents({
    void Function(GlobalEventConnectionState state)? onConnectionStateChanged,
  }) {
    final controller = StreamController<GlobalEvent>();
    StreamSubscription<String>? streamSubscription;
    Completer<_GlobalEventStreamExit>? streamExitCompleter;
    void Function()? cancelReconnectWait;
    Future<void>? reconnectWait;
    var isCancelled = false;
    var reconnectAttempt = 0;
    DateTime? lastConnectedAt;
    DateTime? lastEventAt;

    void emitState(
      GlobalEventConnectionPhase phase, {
      Object? lastError = _noStateUpdate,
      StackTrace? lastErrorStackTrace,
    }) {
      onConnectionStateChanged?.call(
        GlobalEventConnectionState(
          phase: phase,
          attempt: reconnectAttempt,
          lastError: identical(lastError, _noStateUpdate) ? null : lastError,
          lastErrorStackTrace: lastErrorStackTrace,
          lastConnectedAt: lastConnectedAt,
          lastEventAt: lastEventAt,
        ),
      );
    }

    Future<_GlobalEventStreamExit> consumeCurrentStream({
      required void Function() onConnected,
    }) async {
      final completer = Completer<_GlobalEventStreamExit>();
      streamExitCompleter = completer;

      streamSubscription = _client
          .streamGet('/global/event', onConnected: onConnected)
          .listen(
            (data) {
              if (data.trim().isEmpty) return;
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                lastEventAt = DateTime.now();
                controller.add(parseGlobalEvent(json));
                emitState(
                  GlobalEventConnectionPhase.connected,
                  lastError: null,
                );
              } catch (_) {
                // Skip invalid JSON payloads without breaking the SSE session.
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!completer.isCompleted) {
                completer.complete(
                  _GlobalEventStreamFailure(error, stackTrace),
                );
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(const _GlobalEventStreamClosed());
              }
            },
            cancelOnError: true,
          );

      return completer.future;
    }

    Future<void> reconnectAfter(_GlobalEventStreamExit exit) async {
      if (isCancelled || controller.isClosed) return;
      final inFlightReconnectWait = reconnectWait;
      if (inFlightReconnectWait != null) {
        await inFlightReconnectWait;
        return;
      }

      reconnectAttempt += 1;
      emitState(
        GlobalEventConnectionPhase.reconnecting,
        lastError: switch (exit) {
          _GlobalEventStreamFailure(:final error) => error,
          _ => null,
        },
        lastErrorStackTrace: switch (exit) {
          _GlobalEventStreamFailure(:final stackTrace) => stackTrace,
          _ => null,
        },
      );
      final waitCompleter = Completer<void>();
      late final Future<void> waitFuture;
      waitFuture = waitCompleter.future.whenComplete(() {
        if (identical(reconnectWait, waitFuture)) {
          reconnectWait = null;
          cancelReconnectWait = null;
        }
      });
      reconnectWait = waitFuture;
      cancelReconnectWait = () {
        if (!waitCompleter.isCompleted) {
          waitCompleter.complete();
        }
      };
      unawaited(
        _reconnectDelay(_retryDelayForAttempt(reconnectAttempt)).whenComplete(
          () {
            if (!waitCompleter.isCompleted) {
              waitCompleter.complete();
            }
          },
        ),
      );
      await waitFuture;
    }

    Future<void> run() async {
      emitState(GlobalEventConnectionPhase.connecting, lastError: null);

      while (!isCancelled && !controller.isClosed) {
        try {
          emitState(
            reconnectAttempt == 0
                ? GlobalEventConnectionPhase.connecting
                : GlobalEventConnectionPhase.reconnecting,
            lastError: null,
          );
          final exit = await consumeCurrentStream(
            onConnected: () {
              reconnectAttempt = 0;
              lastConnectedAt = DateTime.now();
              emitState(GlobalEventConnectionPhase.connected, lastError: null);
            },
          );
          await streamSubscription?.cancel();
          streamSubscription = null;
          streamExitCompleter = null;

          if (exit is _GlobalEventStreamCancelled) {
            break;
          }

          await reconnectAfter(exit);
          continue;
        } catch (error, stackTrace) {
          await streamSubscription?.cancel();
          streamSubscription = null;
          streamExitCompleter = null;

          await reconnectAfter(_GlobalEventStreamFailure(error, stackTrace));
          continue;
        }
      }

      emitState(GlobalEventConnectionPhase.disconnected, lastError: null);
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onListen = () {
      unawaited(run());
    };

    controller.onCancel = () async {
      isCancelled = true;
      cancelReconnectWait?.call();
      cancelReconnectWait = null;
      reconnectWait = null;
      if (streamExitCompleter case final completer?
          when !completer.isCompleted) {
        completer.complete(const _GlobalEventStreamCancelled());
      }
      await streamSubscription?.cancel();
      streamSubscription = null;
      streamExitCompleter = null;
    };

    return controller.stream;
  }

  Duration _retryDelayForAttempt(int attempt) {
    if (attempt <= 0) {
      return Duration.zero;
    }

    final exponent = math.min(attempt - 1, 4);
    final seconds = math.min(
      _initialReconnectDelay.inSeconds * (1 << exponent),
      _maxReconnectDelay.inSeconds,
    );
    return Duration(seconds: seconds);
  }
}

enum GlobalEventConnectionPhase {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class GlobalEventConnectionState {
  const GlobalEventConnectionState({
    required this.phase,
    required this.attempt,
    this.lastError,
    this.lastErrorStackTrace,
    this.lastConnectedAt,
    this.lastEventAt,
  });

  const GlobalEventConnectionState.disconnected()
    : phase = GlobalEventConnectionPhase.disconnected,
      attempt = 0,
      lastError = null,
      lastErrorStackTrace = null,
      lastConnectedAt = null,
      lastEventAt = null;

  final GlobalEventConnectionPhase phase;
  final int attempt;
  final Object? lastError;
  final StackTrace? lastErrorStackTrace;
  final DateTime? lastConnectedAt;
  final DateTime? lastEventAt;

  bool get isConnected => phase == GlobalEventConnectionPhase.connected;

  @override
  bool operator ==(Object other) {
    return other is GlobalEventConnectionState &&
        other.phase == phase &&
        other.attempt == attempt &&
        other.lastError == lastError &&
        other.lastErrorStackTrace == lastErrorStackTrace &&
        other.lastConnectedAt == lastConnectedAt &&
        other.lastEventAt == lastEventAt;
  }

  @override
  int get hashCode => Object.hash(
    phase,
    attempt,
    lastError,
    lastErrorStackTrace,
    lastConnectedAt,
    lastEventAt,
  );
}

sealed class _GlobalEventStreamExit {
  const _GlobalEventStreamExit();
}

final class _GlobalEventStreamClosed extends _GlobalEventStreamExit {
  const _GlobalEventStreamClosed();
}

final class _GlobalEventStreamCancelled extends _GlobalEventStreamExit {
  const _GlobalEventStreamCancelled();
}

final class _GlobalEventStreamFailure extends _GlobalEventStreamExit {
  const _GlobalEventStreamFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

const Object _noStateUpdate = Object();
