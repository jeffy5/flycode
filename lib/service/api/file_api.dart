import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/current_directory_provider.dart';
import 'api_client.dart';
import 'models/file_content.dart';
import 'models/file_node.dart';

part 'file_api.g.dart';

@riverpod
Future<FileApi> fileApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  final directory = ref.watch(currentDirectoryProvider);
  return FileApi(client, directory: directory);
}

class FileApi {
  final ApiClient _client;
  final String? _directory;

  FileApi(this._client, {String? directory}) : _directory = directory;

  Map<String, String> get _extraHeaders {
    final headers = <String, String>{};
    final dir = _directory;
    if (dir != null) {
      headers['x-opencode-directory'] = dir;
    }
    return headers;
  }

  Future<FileContent> getFileContent(String path) async {
    final Map<String, dynamic> json = await _client.get(
      '/file/content',
      queryParameters: {'path': path},
      extraHeaders: _extraHeaders,
    );
    return FileContent.fromJson(json);
  }

  /// Search for files matching [query] in the project.
  ///
  /// Returns a list of relative paths from the project root.
  /// Pass [dirs] = true to include directories in results.
  /// Pass [limit] to cap the result count.
  Future<List<String>> findFile(
    String query, {
    bool dirs = true,
    int? limit,
  }) async {
    final params = <String, String>{
      'query': query,
      'dirs': dirs ? 'true' : 'false',
    };
    if (limit != null) params['limit'] = limit.toString();

    final result = await _client.get(
      '/find/file',
      queryParameters: params,
      extraHeaders: _extraHeaders,
    );
    return List<String>.from(result as List);
  }

  /// 在 [searchRoot] 目录下关键词搜索子目录（[GET /find/file]）。
  ///
  /// 与 [findFile] 不同，此方法接受任意 [searchRoot] 作为搜索根目录，
  /// 用于目录选择器场景（搜索根固定，不依赖当前已选项目）。
  /// [searchRoot] 为 null 时不传 directory，服务端用 process.cwd()。
  /// 返回相对路径列表。
  Future<List<String>> findDirectory(
    String query, {
    String? searchRoot,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'query': query,
      'type': 'directory',
      'limit': limit.toString(),
      'dirs': 'true',
    };
    if (searchRoot != null && searchRoot.isNotEmpty) {
      params['directory'] = searchRoot;
    }

    final result = await _client.get('/find/file', queryParameters: params);
    return List<String>.from(result as List);
  }

  /// 列出 [directory] 目录的直接子内容（[GET /file]）。
  ///
  /// 用于路径导航模式，每次导航一层目录。
  /// 只返回 [FileNode] 列表，客户端按需过滤目录。
  Future<List<FileNode>> listDirectory(String directory) async {
    final result = await _client.get(
      '/file',
      queryParameters: {'path': '', 'directory': directory},
    );
    if (result is! List) return [];
    return result
        .whereType<Map<String, dynamic>>()
        .map(FileNode.fromJson)
        .toList();
  }

  /// 获取当前服务端路径信息，并尽力解析出 home 目录。
  ///
  /// 优先读取 `/path` 返回中的 `home` 字段。
  /// 若不存在，则回退为从 `cwd` 推导 `/Users/<name>` 或 `/home/<name>`。
  Future<String?> resolveHomeDirectory() async {
    final result = await _client.get('/path', extraHeaders: _extraHeaders);
    if (result is! Map<String, dynamic>) return null;

    String? pickString(dynamic value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return trimmed.replaceAll('\\', '/');
    }

    final explicitHome =
        pickString(result['home']) ??
        pickString(result['homeDir']) ??
        pickString(result['homedir']) ??
        pickString(result['HOME']);
    if (explicitHome != null) return explicitHome;

    final cwd = pickString(result['cwd']);
    if (cwd == null) return null;

    final parts = cwd.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2 && parts.first == 'Users') {
      return '/Users/${parts[1]}';
    }
    if (parts.length >= 2 && parts.first == 'home') {
      return '/home/${parts[1]}';
    }
    if (parts.length >= 3 && parts[0].endsWith(':') && parts[1] == 'Users') {
      return '${parts[0]}/Users/${parts[2]}';
    }

    return null;
  }
}
