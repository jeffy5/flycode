import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/api/file_api.dart';
import '../service/api/models/file_content.dart';

part 'file_provider.g.dart';

@riverpod
Future<FileContent> fileContent(Ref ref, String path) async {
  final api = await ref.watch(fileApiProvider.future);
  return api.getFileContent(path);
}
