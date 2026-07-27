import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/dao/project_pin_dao.dart';
import '../database/database_helper.dart';
import '../service/api/models/project.dart';
import 'server_config_provider.dart';

part 'project_pin_provider.g.dart';

@riverpod
DatabaseHelper projectPinDatabaseHelper(Ref ref) {
  return DatabaseHelper();
}

@riverpod
Future<ProjectPinDao> projectPinDao(Ref ref) async {
  final dbHelper = ref.watch(projectPinDatabaseHelperProvider);
  final db = await dbHelper.database;
  return ProjectPinDao(db);
}

@riverpod
class ProjectPins extends _$ProjectPins {
  @override
  Future<Map<String, int>> build() async {
    final serverConfig = await ref.watch(serverConfigProvider.future);
    final dao = await ref.watch(projectPinDaoProvider.future);
    return dao.getPinnedProjects(serverConfig.baseUrl);
  }

  Future<void> setPinned(Project project, bool pinned) async {
    final serverConfig = await ref.read(serverConfigProvider.future);
    final dao = await ref.read(projectPinDaoProvider.future);

    if (pinned) {
      await dao.pinProject(
        serverBaseUrl: serverConfig.baseUrl,
        worktree: project.worktree,
        pinnedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      await dao.unpinProject(
        serverBaseUrl: serverConfig.baseUrl,
        worktree: project.worktree,
      );
    }

    ref.invalidateSelf();
  }

  Future<void> togglePin(Project project) async {
    final current = state.asData?.value ?? const <String, int>{};
    final pinned = current.containsKey(project.worktree);
    await setPinned(project, !pinned);
  }
}
