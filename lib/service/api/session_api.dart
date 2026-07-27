import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/current_directory_provider.dart';
import 'api_client.dart';
import 'models/global_event.dart' show Todo;
import 'models/session.dart';
import 'models/message.dart' hide FileDiff;
import 'models/prompt_input.dart';
import 'models/command_input.dart';

part 'session_api.g.dart';

@Riverpod(keepAlive: true)
Future<SessionApi> sessionApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return SessionApi(client);
}

@riverpod
Future<List<Session>> sessions(Ref ref) async {
  final api = await ref.watch(sessionApiProvider.future);
  final directory = ref.watch(currentDirectoryProvider);
  if (directory == null || directory.isEmpty) return [];

  final sessions = await api.getSessions(directory: directory, roots: true);
  return sessions;
}

class SessionApi {
  final ApiClient _client;

  SessionApi(this._client);

  Future<List<Session>> getSessions({
    String? directory,
    bool? roots,
    int? start,
    String? search,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;
    if (roots != null) queryParams['roots'] = roots.toString();
    if (start != null) queryParams['start'] = start.toString();
    if (search != null) queryParams['search'] = search;
    if (limit != null) queryParams['limit'] = limit.toString();

    final List<dynamic> json = await _client.get(
      '/session',
      queryParameters: queryParams,
    );
    return json.map((e) => Session.fromJson(e)).toList();
  }

  Future<Session> createSession({
    String? directory,
    String? parentID,
    String? title,
    PermissionRuleset? permission,
  }) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    final body = CreateSessionRequest(
      parentID: parentID,
      title: title,
      permission: permission,
    );

    final json = await _client.post(
      '/session',
      body: body.toJson(),
      extraHeaders: extraHeaders,
    );
    return Session.fromJson(json);
  }

  Future<Session> getSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final json = await _client.get(
      '/session/$id',
      queryParameters: queryParams,
    );
    return Session.fromJson(json);
  }

  Future<void> deleteSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.delete('/session/$id', queryParameters: queryParams);
  }

  Future<Session> updateSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final json = await _client.patch(
      '/session/$id',
      queryParameters: queryParams,
      body: data,
    );
    return Session.fromJson(json);
  }

  Future<void> abortSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post('/session/$id/abort', queryParameters: queryParams);
  }

  Future<List<Session>> getSessionChildren(
    String id, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/session/$id/children',
      queryParameters: queryParams,
    );
    return json.map((e) => Session.fromJson(e)).toList();
  }

  Future<List<MessageWithParts>> getSessionMessages(
    String id, {
    String? directory,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;
    if (limit != null) queryParams['limit'] = limit.toString();

    final List<dynamic> json = await _client.get(
      '/session/$id/message',
      queryParameters: queryParams,
    );
    return json
        .map((e) => MessageWithParts.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendPrompt(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    await _client.post(
      '/session/$id/message',
      queryParameters: queryParams,
      body: data,
      extraHeaders: extraHeaders,
    );
  }

  Future<void> sendCommand(
    String id, {
    String? directory,
    CommandInput? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    await _client.post(
      '/session/$id/command',
      queryParameters: queryParams,
      body: data?.toJson(),
      extraHeaders: extraHeaders,
    );
  }

  Future<void> summarizeSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post(
      '/session/$id/summarize',
      queryParameters: queryParams,
      body: data,
    );
  }

  Future<List<FileDiff>> getSessionDiff(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/session/$id/diff',
      queryParameters: queryParams,
    );
    return json
        .map((e) => FileDiff.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> forkSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post(
      '/session/$id/fork',
      queryParameters: queryParams,
      body: data,
    );
  }

  Future<void> initSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post(
      '/session/$id/init',
      queryParameters: queryParams,
      body: data,
    );
  }

  Future<MessageWithParts> getMessage(
    String id,
    String messageID, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final json = await _client.get(
      '/session/$id/message/$messageID',
      queryParameters: queryParams,
    );
    return MessageWithParts.fromJson(json as Map<String, dynamic>);
  }

  Future<void> revertMessage(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post(
      '/session/$id/revert',
      queryParameters: queryParams,
      body: data,
    );
  }

  Future<void> shareSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post('/session/$id/share', queryParameters: queryParams);
  }

  Future<void> unshareSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.delete('/session/$id/share', queryParameters: queryParams);
  }

  Future<List<Todo>> getSessionTodos(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final result = await _client.get(
      '/session/$id/todo',
      queryParameters: queryParams,
    );
    if (result == null) return [];
    final list = result as List<dynamic>;
    return list.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getSessionStatus({String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    return await _client.get('/session/status', queryParameters: queryParams);
  }

  Future<void> deleteMessage(
    String id,
    String messageID, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.delete(
      '/session/$id/message/$messageID',
      queryParameters: queryParams,
    );
  }

  Future<void> sendPromptAsync(
    String id, {
    String? directory,
    PromptAsyncInput? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    await _client.post(
      '/session/$id/prompt_async',
      queryParameters: queryParams,
      body: data?.toJson(),
      extraHeaders: extraHeaders,
    );
  }

  Future<void> runShell(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    await _client.post(
      '/session/$id/shell',
      queryParameters: queryParams,
      body: data,
      extraHeaders: extraHeaders,
    );
  }

  Future<void> unrevertSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post('/session/$id/unrevert', queryParameters: queryParams);
  }

  Future<void> respondToPermission(
    String id,
    String permissionID, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    await _client.post(
      '/session/$id/permissions/$permissionID',
      queryParameters: queryParams,
      body: data,
    );
  }
}
