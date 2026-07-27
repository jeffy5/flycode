import 'dart:async'
    show Completer, Future, Stream, StreamController, StreamView;
import 'dart:collection' show Queue;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/global_event_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/global_api.dart';
import 'package:flycode/service/api/session_api.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(Queue<Stream<String>> streams)
    : _streams = streams,
      super(baseUrl: 'http://localhost');

  final Queue<Stream<String>> _streams;

  @override
  Stream<String> streamGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
    void Function()? onConnected,
  }) {
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

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi() : super(ApiClient(baseUrl: 'http://localhost'));

  int getSessionStatusCount = 0;

  @override
  Future<Map<String, dynamic>> getSessionStatus({String? directory}) async {
    getSessionStatusCount += 1;
    return <String, dynamic>{};
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

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'provider recovers after SSE closes and refreshes status snapshot',
    () async {
      final firstController = StreamController<String>();
      final secondController = StreamController<String>();
      final delay = _ControlledDelay();
      final globalApi = GlobalApi(
        _FakeApiClient(
          Queue<Stream<String>>.from(<Stream<String>>[
            _ConnectedTestStream(firstController.stream),
            _ConnectedTestStream(secondController.stream),
          ]),
        ),
        reconnectDelay: delay.call,
      );
      final sessionApi = _FakeSessionApi();
      final container = ProviderContainer(
        overrides: [
          globalApiProvider.overrideWith((ref) async => globalApi),
          sessionApiProvider.overrideWith((ref) async => sessionApi),
        ],
      );
      addTearDown(() async {
        await firstController.close();
        await secondController.close();
        container.dispose();
      });

      final eventSub = container.listen(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      final connectionSub = container.listen<GlobalEventConnectionState>(
        globalEventConnectionProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(eventSub.close);
      addTearDown(connectionSub.close);

      await _flushAsyncWork();
      expect(sessionApi.getSessionStatusCount, 1);
      expect(
        container.read(globalEventConnectionProvider).phase,
        GlobalEventConnectionPhase.connected,
      );

      await firstController.close();
      await _flushAsyncWork();

      expect(
        container.read(globalEventConnectionProvider).phase,
        GlobalEventConnectionPhase.reconnecting,
      );
      expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

      delay.completeNext();
      await _flushAsyncWork();
      await _flushAsyncWork();

      expect(sessionApi.getSessionStatusCount, 2);
      expect(
        container.read(globalEventConnectionProvider).phase,
        GlobalEventConnectionPhase.connected,
      );
    },
  );

  test(
    'provider does not refresh status snapshot while reconnect attempts keep failing',
    () async {
      final delay = _ControlledDelay();
      final globalApi = GlobalApi(
        _FakeApiClient(
          Queue<Stream<String>>.from(<Stream<String>>[
            Stream<String>.error(StateError('network down')),
            Stream<String>.error(StateError('still down')),
          ]),
        ),
        reconnectDelay: delay.call,
      );
      final sessionApi = _FakeSessionApi();
      final container = ProviderContainer(
        overrides: [
          globalApiProvider.overrideWith((ref) async => globalApi),
          sessionApiProvider.overrideWith((ref) async => sessionApi),
        ],
      );
      addTearDown(container.dispose);

      final eventSub = container.listen(
        globalEventListenerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(eventSub.close);

      await _flushAsyncWork();
      expect(sessionApi.getSessionStatusCount, 1);

      delay.completeNext();
      await _flushAsyncWork();
      await _flushAsyncWork();

      expect(sessionApi.getSessionStatusCount, 1);
    },
  );
}
