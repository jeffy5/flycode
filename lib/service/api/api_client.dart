import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/server_config_provider.dart';

part 'api_client.g.dart';

typedef HttpClientFactory = http.Client Function();

@Riverpod(keepAlive: true)
HttpClientFactory apiHttpClientFactory(Ref ref) => http.Client.new;

enum ApiExceptionKind { http, timeout, network, cancelled, unknown }

class ApiException implements Exception {
  final int statusCode;
  final String? name;
  final dynamic data;
  final String message;
  final ApiExceptionKind kind;
  final bool retryable;
  final Object? cause;

  ApiException({
    required this.statusCode,
    this.name,
    this.data,
    required this.message,
    this.kind = ApiExceptionKind.http,
    bool? retryable,
    this.cause,
  }) : retryable = retryable ?? _defaultRetryable(kind, statusCode);

  static bool _defaultRetryable(ApiExceptionKind kind, int statusCode) {
    if (kind == ApiExceptionKind.timeout || kind == ApiExceptionKind.network) {
      return true;
    }
    if (kind != ApiExceptionKind.http) {
      return false;
    }
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  @override
  String toString() => 'ApiException: $statusCode $kind $name - $message';
}

@Riverpod(keepAlive: true)
Future<ApiClient> apiClient(Ref ref) async {
  final config = await ref.watch(serverConfigProvider.future);
  final clientFactory = ref.watch(apiHttpClientFactoryProvider);
  final client = ApiClient(
    baseUrl: config.baseUrl,
    username: config.username,
    password: config.password,
    client: clientFactory(),
    streamClientFactory: clientFactory,
  );
  ref.onDispose(client.close);
  return client;
}

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const int _timeoutStatusCode = 408;
  static const int _networkStatusCode = 503;
  static const int _unknownStatusCode = 500;

  final String _baseUrl;
  final String? _username;
  final String? _password;
  final http.Client _client;
  final HttpClientFactory _streamClientFactory;
  final Set<http.Client> _activeStreamClients = <http.Client>{};

  bool _isClosed = false;

  ApiClient({
    required String baseUrl,
    String? username,
    String? password,
    http.Client? client,
    HttpClientFactory? streamClientFactory,
  }) : _baseUrl = baseUrl,
       _username = username,
       _password = password,
       _client = client ?? http.Client(),
       _streamClientFactory = streamClientFactory ?? http.Client.new;

  String get baseUrl => _baseUrl;

  bool get isClosed => _isClosed;

  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _client.close();

    final activeStreamClients = List<http.Client>.of(_activeStreamClients);
    _activeStreamClients.clear();
    for (final streamClient in activeStreamClients) {
      streamClient.close();
    }
  }

  Uri _getUri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw StateError('ApiClient has been closed');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_username != null && _username.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String? errorName;
    dynamic errorData;
    String message = response.body;

    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        errorName = body['name']?.toString();
        errorData = body['data'];
        if (body.containsKey('message')) {
          message = body['message'].toString();
        }
      }
    } catch (_) {
      // Body 不是 JSON，保持原样
    }

    throw ApiException(
      statusCode: response.statusCode,
      name: errorName,
      data: errorData,
      message: message,
    );
  }

  Future<dynamic> _executeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(_requestTimeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        statusCode: _timeoutStatusCode,
        kind: ApiExceptionKind.timeout,
        message: 'Request timed out',
        cause: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        statusCode: _networkStatusCode,
        kind: ApiExceptionKind.network,
        message: error.message,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        statusCode: _networkStatusCode,
        kind: ApiExceptionKind.network,
        message: error.message,
        cause: error,
      );
    } catch (error) {
      throw ApiException(
        statusCode: _unknownStatusCode,
        kind: ApiExceptionKind.unknown,
        message: 'Unexpected network error',
        cause: error,
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    _ensureOpen();
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return _executeRequest(
      () => _client.get(
        _getUri(path, queryParameters: queryParameters),
        headers: headers,
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    _ensureOpen();
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return _executeRequest(
      () => _client.post(
        _getUri(path, queryParameters: queryParameters),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    _ensureOpen();
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return _executeRequest(
      () => _client.patch(
        _getUri(path, queryParameters: queryParameters),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    _ensureOpen();
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return _executeRequest(
      () => _client.delete(
        _getUri(path, queryParameters: queryParameters),
        headers: headers,
      ),
    );
  }

  Stream<String> streamGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
    void Function()? onConnected,
  }) {
    _ensureOpen();
    final uri = _getUri(path, queryParameters: queryParameters);
    final request = http.Request('GET', uri);
    final headers = _getHeaders()..['Accept'] = 'text/event-stream';
    if (extraHeaders != null) headers.addAll(extraHeaders);
    request.headers.addAll(headers);

    final streamClient = _streamClientFactory();
    _activeStreamClients.add(streamClient);
    StreamSubscription<List<int>>? streamedResponseSubscription;
    var isCancelled = false;
    var isStreamClientClosed = false;

    Future<void> closeStreamClient() async {
      if (isStreamClientClosed) return;
      isStreamClientClosed = true;
      final removed = _activeStreamClients.remove(streamClient);
      if (removed || !_isClosed) {
        streamClient.close();
      }
    }

    final controller = StreamController<String>();

    controller.onListen = () {
      unawaited(() async {
        try {
          final streamedResponse = await streamClient.send(request);
          if (isCancelled) {
            await closeStreamClient();
            return;
          }

          if (streamedResponse.statusCode < 200 ||
              streamedResponse.statusCode >= 300) {
            throw ApiException(
              statusCode: streamedResponse.statusCode,
              message: 'Stream request failed',
            );
          }

          onConnected?.call();

          final buffer = StringBuffer();
          var lineBuffer = StringBuffer();

          streamedResponseSubscription = streamedResponse.stream.listen(
            (chunk) {
              final text = utf8.decode(chunk);
              for (var i = 0; i < text.length; i++) {
                final char = text[i];
                if (char == '\n') {
                  final line = lineBuffer.toString();
                  lineBuffer.clear();

                  if (line.startsWith('data:')) {
                    buffer.write(line.substring(5).trim());
                  } else if (line.trim().isEmpty && buffer.isNotEmpty) {
                    controller.add(buffer.toString());
                    buffer.clear();
                  }
                  // ignore 'event:' and other SSE fields
                } else {
                  lineBuffer.write(char);
                }
              }
            },
            onError: (Object error, StackTrace stackTrace) async {
              if (!controller.isClosed) {
                controller.addError(error, stackTrace);
              }
              await closeStreamClient();
              if (!controller.isClosed) {
                await controller.close();
              }
            },
            onDone: () async {
              if (buffer.isNotEmpty && !controller.isClosed) {
                controller.add(buffer.toString());
              }
              await closeStreamClient();
              if (!controller.isClosed) {
                await controller.close();
              }
            },
            cancelOnError: false,
          );
        } catch (error, stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
            await controller.close();
          }
          await closeStreamClient();
        }
      }());
    };

    controller.onCancel = () async {
      isCancelled = true;
      await streamedResponseSubscription?.cancel();
      await closeStreamClient();
    };

    return controller.stream;
  }
}
