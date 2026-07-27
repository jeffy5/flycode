import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/permission.dart';

part 'permission_api.g.dart';

@Riverpod(keepAlive: true)
Future<PermissionApi> permissionApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return PermissionApi(client);
}

class PermissionApi {
  final ApiClient _client;

  PermissionApi(this._client);

  Future<List<PermissionRequest>> getPermissions({String? directory}) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/permission',
      queryParameters: queryParams,
      extraHeaders: extraHeaders,
    );

    return json
        .whereType<Map<String, dynamic>>()
        .map(PermissionRequest.fromJson)
        .toList();
  }

  Future<bool> replyPermission(
    String requestID, {
    required String sessionID,
    required PermissionReplyAction reply,
    String? message,
    String? directory,
  }) async {
    final extraHeaders = <String, String>{};
    if (directory != null) {
      extraHeaders['x-opencode-directory'] = directory;
    }

    try {
      final result = await _client.post(
        '/permission/$requestID/reply',
        body: {
          'reply': reply.name,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
        extraHeaders: extraHeaders,
      );
      return result == null || result == true;
    } on ApiException catch (e) {
      // Backward compatibility: fallback to legacy session endpoint when
      // new route does not exist on old backend versions.
      if (e.statusCode != 404 && e.statusCode != 405) {
        rethrow;
      }

      final queryParams = <String, String>{};
      if (directory != null) queryParams['directory'] = directory;

      await _client.post(
        '/session/$sessionID/permissions/$requestID',
        queryParameters: queryParams,
        body: {'response': reply.name},
        extraHeaders: extraHeaders,
      );
      return true;
    }
  }
}
