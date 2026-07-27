import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/models/server_config.dart';
import 'package:flycode/providers/server_config_provider.dart';
import 'package:flycode/service/api/api_client.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    Future<http.StreamedResponse> Function(http.BaseRequest request)? onSend,
  }) : _onSend = onSend;

  final Future<http.StreamedResponse> Function(http.BaseRequest request)?
  _onSend;

  int closeCount = 0;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (_onSend != null) {
      return _onSend(request);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      request: request,
    );
  }

  @override
  void close() {
    closeCount += 1;
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
    'apiClientProvider closes replaced client and closes active one on dispose',
    () async {
      final firstRawClient = _FakeHttpClient();
      final secondRawClient = _FakeHttpClient();
      final createdClients = Queue<_FakeHttpClient>.from(<_FakeHttpClient>[
        firstRawClient,
        secondRawClient,
      ]);
      final container = ProviderContainer(
        overrides: [
          apiHttpClientFactoryProvider.overrideWith(
            (ref) =>
                () => createdClients.removeFirst(),
          ),
        ],
      );

      await container
          .read(serverConfigProvider.notifier)
          .save(ServerConfig(baseUrl: 'http://server-one.test'));
      final firstApiClient = await container.read(apiClientProvider.future);

      await container
          .read(serverConfigProvider.notifier)
          .save(ServerConfig(baseUrl: 'http://server-two.test'));
      await _flushAsyncWork();
      final secondApiClient = await container.read(apiClientProvider.future);

      expect(firstApiClient.baseUrl, 'http://server-one.test');
      expect(secondApiClient.baseUrl, 'http://server-two.test');
      expect(identical(firstApiClient, secondApiClient), isFalse);
      expect(firstApiClient.isClosed, isTrue);
      expect(firstRawClient.closeCount, 1);
      expect(secondRawClient.closeCount, 0);

      container.dispose();

      expect(secondApiClient.isClosed, isTrue);
      expect(secondRawClient.closeCount, 1);
    },
  );

  test('get returns decoded json response', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(),
    );

    final result = await apiClient.get('/global/health');

    expect(result, <String, dynamic>{});
  });

  test('post encodes request body and merges headers', () async {
    final client = _FakeHttpClient();
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      username: 'user',
      password: 'pass',
      client: client,
    );

    await apiClient.post(
      '/session',
      body: <String, dynamic>{'name': 'demo'},
      extraHeaders: <String, String>{'x-test': '1'},
    );

    final request = client.requests.single as http.Request;
    expect(request.method, 'POST');
    expect(request.headers['x-test'], '1');
    expect(
      request.headers['authorization'],
      'Basic ${base64Encode(utf8.encode('user:pass'))}',
    );
    expect(request.body, '{"name":"demo"}');
  });

  test('http errors are parsed into ApiException', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(
        onSend: (request) async => http.StreamedResponse(
          Stream<List<int>>.value(
            utf8.encode(
              '{"name":"bad_request","message":"Nope","data":{"field":"id"}}',
            ),
          ),
          400,
          request: request,
        ),
      ),
    );

    final matcher = throwsA(
      isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiExceptionKind.http)
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.name, 'name', 'bad_request')
          .having((e) => e.message, 'message', 'Nope')
          .having((e) => e.retryable, 'retryable', isFalse)
          .having((e) => e.data, 'data', <String, dynamic>{'field': 'id'}),
    );

    await expectLater(apiClient.get('/fail'), matcher);
  });

  test('http non-json errors preserve body text', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(
        onSend: (request) async => http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode('server exploded')),
          500,
          request: request,
        ),
      ),
    );

    final matcher = throwsA(
      isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 500)
          .having((e) => e.message, 'message', 'server exploded')
          .having((e) => e.retryable, 'retryable', isTrue),
    );

    await expectLater(apiClient.get('/fail'), matcher);
  });

  test('request timeout is mapped to retryable ApiException', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(
        onSend: (request) async {
          throw TimeoutException('slow request');
        },
      ),
    );

    final matcher = throwsA(
      isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiExceptionKind.timeout)
          .having((e) => e.statusCode, 'statusCode', 408)
          .having((e) => e.message, 'message', 'Request timed out')
          .having((e) => e.retryable, 'retryable', isTrue)
          .having((e) => e.cause, 'cause', isA<TimeoutException>()),
    );

    await expectLater(apiClient.get('/slow'), matcher);
  });

  test('socket exceptions are mapped to retryable network errors', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(
        onSend: (request) async {
          throw const SocketException('network down');
        },
      ),
    );

    final matcher = throwsA(
      isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiExceptionKind.network)
          .having((e) => e.statusCode, 'statusCode', 503)
          .having((e) => e.message, 'message', contains('network down'))
          .having((e) => e.retryable, 'retryable', isTrue)
          .having((e) => e.cause, 'cause', isA<SocketException>()),
    );

    await expectLater(apiClient.get('/offline'), matcher);
  });

  test('client exceptions are mapped to retryable network errors', () async {
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: _FakeHttpClient(
        onSend: (request) async {
          throw http.ClientException('connection reset');
        },
      ),
    );

    final matcher = throwsA(
      isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiExceptionKind.network)
          .having((e) => e.statusCode, 'statusCode', 503)
          .having((e) => e.message, 'message', 'connection reset')
          .having((e) => e.retryable, 'retryable', isTrue)
          .having((e) => e.cause, 'cause', isA<http.ClientException>()),
    );

    await expectLater(apiClient.get('/offline'), matcher);
  });

  test(
    'unexpected exceptions are mapped to non-retryable unknown errors',
    () async {
      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: _FakeHttpClient(
          onSend: (request) async {
            throw StateError('boom');
          },
        ),
      );

      final matcher = throwsA(
        isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiExceptionKind.unknown)
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'Unexpected network error')
            .having((e) => e.retryable, 'retryable', isFalse)
            .having((e) => e.cause, 'cause', isA<StateError>()),
      );

      await expectLater(apiClient.get('/boom'), matcher);
    },
  );

  test(
    'streamGet closes dedicated stream client when subscription is cancelled',
    () async {
      final baseClient = _FakeHttpClient();
      final responseController = StreamController<List<int>>();
      final streamClient = _FakeHttpClient(
        onSend: (request) async => http.StreamedResponse(
          responseController.stream,
          200,
          request: request,
        ),
      );
      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: baseClient,
        streamClientFactory: () => streamClient,
      );
      addTearDown(() async {
        await responseController.close();
      });

      final received = <String>[];
      final subscription = apiClient
          .streamGet('/global/event')
          .listen(received.add);

      await _flushAsyncWork();
      responseController.add(utf8.encode('data: hello\n\n'));
      await _flushAsyncWork();

      expect(received, <String>['hello']);
      expect(streamClient.closeCount, 0);

      await subscription.cancel();
      await _flushAsyncWork();

      expect(streamClient.closeCount, 1);
      expect(baseClient.closeCount, 0);
    },
  );

  test('streamGet calls onConnected after a successful SSE response', () async {
    final baseClient = _FakeHttpClient();
    final responseController = StreamController<List<int>>();
    final streamClient = _FakeHttpClient(
      onSend: (request) async => http.StreamedResponse(
        responseController.stream,
        200,
        request: request,
      ),
    );
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: baseClient,
      streamClientFactory: () => streamClient,
    );
    addTearDown(() async {
      await responseController.close();
    });

    var connectedCount = 0;
    final subscription = apiClient
        .streamGet(
          '/global/event',
          onConnected: () {
            connectedCount += 1;
          },
        )
        .listen((_) {});

    await _flushAsyncWork();

    expect(connectedCount, 1);

    await subscription.cancel();
  });

  test('close shuts down active SSE clients immediately', () async {
    final baseClient = _FakeHttpClient();
    final responseController = StreamController<List<int>>();
    final streamClient = _FakeHttpClient(
      onSend: (request) async => http.StreamedResponse(
        responseController.stream,
        200,
        request: request,
      ),
    );
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: baseClient,
      streamClientFactory: () => streamClient,
    );
    addTearDown(() async {
      await responseController.close();
    });

    final subscription = apiClient.streamGet('/global/event').listen((_) {});
    await _flushAsyncWork();

    apiClient.close();
    await _flushAsyncWork();

    expect(apiClient.isClosed, isTrue);
    expect(baseClient.closeCount, 1);
    expect(streamClient.closeCount, 1);

    await subscription.cancel();
  });
}
