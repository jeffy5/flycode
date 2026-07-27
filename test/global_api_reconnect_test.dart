import 'dart:async'
    show Completer, Future, Stream, StreamController, StreamView;
import 'dart:collection' show Queue;
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/global_api.dart';
import 'package:flycode/service/api/models/global_event.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(Queue<Stream<String>> streams)
    : _streams = streams,
      super(baseUrl: 'http://localhost');

  final Queue<Stream<String>> _streams;
  int streamGetCount = 0;

  @override
  Stream<String> streamGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
    void Function()? onConnected,
  }) {
    streamGetCount += 1;
    if (_streams.isEmpty) {
      throw StateError('No SSE stream queued for $path');
    }
    final stream = _streams.removeFirst();
    if (stream is _ConnectedTestStream) {
      return stream.bind(onConnected);
    }
    return stream;
  }
}

class _ConnectedTestStream extends StreamView<String> {
  _ConnectedTestStream(super.stream) : _stream = stream;

  final Stream<String> _stream;

  Stream<String> bind(void Function()? onConnected) {
    return Stream<String>.multi((controller) {
      onConnected?.call();
      final subscription = _stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }
}

class _ControlledDelay {
  final List<Duration> durations = <Duration>[];
  final Queue<Completer<void>> _pending = Queue<Completer<void>>();

  Future<void> call(Duration duration) {
    durations.add(duration);
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() {
    if (_pending.isEmpty) {
      throw StateError('No pending reconnect delay');
    }
    _pending.removeFirst().complete();
  }
}

String _eventJson(String sessionID) {
  return jsonEncode(<String, dynamic>{
    'directory': '',
    'payload': <String, dynamic>{
      'type': 'session.idle',
      'properties': <String, dynamic>{'sessionID': sessionID},
    },
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Stream<String> _connectedStream(Stream<String> source) =>
    _ConnectedTestStream(source);

void main() {
  test('reconnects after server closes SSE stream', () async {
    final firstController = StreamController<String>();
    final secondController = StreamController<String>();
    final delay = _ControlledDelay();
    final api = GlobalApi(
      _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          _connectedStream(firstController.stream),
          _connectedStream(secondController.stream),
        ]),
      ),
      reconnectDelay: delay.call,
    );
    final states = <GlobalEventConnectionState>[];
    final events = <GlobalEvent>[];

    final subscription = api
        .subscribeToGlobalEvents(onConnectionStateChanged: states.add)
        .listen(events.add);

    await _flushAsyncWork();
    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);

    firstController.add(_eventJson('sess-1'));
    await _flushAsyncWork();

    expect(events, hasLength(1));
    expect(events.single.payload, isA<EventSessionIdle>());

    await firstController.close();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.reconnecting);
    expect(states.last.attempt, 1);
    expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

    delay.completeNext();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);

    secondController.add(_eventJson('sess-2'));
    await _flushAsyncWork();

    expect(events, hasLength(2));
    expect((events.last.payload as EventSessionIdle).sessionID, 'sess-2');

    await subscription.cancel();
    await secondController.close();
  });

  test('reconnects after stream error and exposes last error', () async {
    final secondController = StreamController<String>();
    final delay = _ControlledDelay();
    final api = GlobalApi(
      _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          Stream<String>.error(StateError('network down')),
          _connectedStream(secondController.stream),
        ]),
      ),
      reconnectDelay: delay.call,
    );
    final states = <GlobalEventConnectionState>[];

    final subscription = api
        .subscribeToGlobalEvents(onConnectionStateChanged: states.add)
        .listen((_) {});

    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.reconnecting);
    expect(states.last.attempt, 1);
    expect(states.last.lastError, isA<StateError>());
    expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

    delay.completeNext();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);
    expect(states.last.lastError, isNull);

    await subscription.cancel();
    await secondController.close();
  });

  test(
    'does not emit a fake connected state when connection never succeeds',
    () async {
      final delay = _ControlledDelay();
      final apiClient = _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          Stream<String>.error(StateError('network down')),
        ]),
      );
      final api = GlobalApi(apiClient, reconnectDelay: delay.call);
      final states = <GlobalEventConnectionState>[];

      final subscription = api
          .subscribeToGlobalEvents(onConnectionStateChanged: states.add)
          .listen((_) {});

      await _flushAsyncWork();

      expect(apiClient.streamGetCount, 1);
      expect(
        states.map((state) => state.phase).toList(),
        <GlobalEventConnectionPhase>[
          GlobalEventConnectionPhase.connecting,
          GlobalEventConnectionPhase.connecting,
          GlobalEventConnectionPhase.reconnecting,
        ],
      );

      await subscription.cancel();
    },
  );

  test('reconnect backoff is capped at 5 seconds', () async {
    final delay = _ControlledDelay();
    final api = GlobalApi(
      _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          Stream<String>.error(StateError('network down 1')),
          Stream<String>.error(StateError('network down 2')),
          Stream<String>.error(StateError('network down 3')),
          Stream<String>.error(StateError('network down 4')),
          Stream<String>.error(StateError('network down 5')),
          Stream<String>.error(StateError('network down 6')),
        ]),
      ),
      reconnectDelay: delay.call,
    );

    final subscription = api
        .subscribeToGlobalEvents(onConnectionStateChanged: (_) {})
        .listen((_) {});

    await _flushAsyncWork();
    expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

    for (var i = 0; i < 4; i++) {
      delay.completeNext();
      await _flushAsyncWork();
      await _flushAsyncWork();
    }

    expect(delay.durations, <Duration>[
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 5),
      const Duration(seconds: 5),
    ]);

    await subscription.cancel();
  });
}
