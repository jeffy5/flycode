import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/api/file_api.dart';
import '../service/api/models/file_content.dart';
import '../service/api/models/file_node.dart';

part 'file_provider.g.dart';

@riverpod
Future<FileContent> fileContent(Ref ref, String path) async {
  final api = await ref.watch(fileApiProvider.future);
  return api.getFileContent(path);
}

@riverpod
Future<List<FileNode>> fileDirectoryListing(Ref ref, String directory) async {
  final api = await ref.watch(fileApiProvider.future);
  return api.listDirectory(directory);
}
