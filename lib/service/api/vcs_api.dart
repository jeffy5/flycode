import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'models/session.dart';

part 'vcs_api.g.dart';

enum VcsDiffMode { git, branch }

@Riverpod(keepAlive: true)
Future<VcsApi> vcsApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return VcsApi(client);
}

@riverpod
Future<List<FileDiff>> vcsDiff(
  Ref ref,
  VcsDiffMode mode,
  String directory,
) async {
  final api = await ref.watch(vcsApiProvider.future);
  return api.getDiff(mode: mode, directory: directory);
}

class VcsApi {
  VcsApi(this._client);

  final ApiClient _client;

  Future<List<FileDiff>> getDiff({
    required VcsDiffMode mode,
    required String directory,
  }) async {
    final List<dynamic> json = await _client.get(
      '/vcs/diff',
      queryParameters: {'mode': mode.name, 'directory': directory},
    );
    return json
        .map((item) => FileDiff.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
