import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/project.dart';
import 'models/session.dart';
import 'session_api.dart';

part 'project_api.g.dart';

@riverpod
Future<ProjectApi> projectApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return ProjectApi(client);
}

@riverpod
class Projects extends _$Projects {
  @override
  Future<List<Project>> build() async {
    final sessionApi = await ref.watch(sessionApiProvider.future);
    final projectApi = await ref.watch(projectApiProvider.future);

    final results = await Future.wait([
      sessionApi.getSessions(roots: true),
      projectApi.getProjects(),
    ]);

    final sessions = results[0] as List<Session>;
    final apiProjects = (results[1] as List<Project>)
        .where((p) => p.id != 'global')
        .toList();

    final Map<String, Project> projectsMap = {};

    // 1. 先把 API 返回的正式项目放进去
    for (final p in apiProjects) {
      projectsMap[p.worktree] = p;
    }

    // 2. 合并 Session 中的目录
    for (final s in sessions) {
      final dir = s.directory;
      final sessionUpdated = s.time.updated;

      if (projectsMap.containsKey(dir)) {
        final existing = projectsMap[dir]!;
        if (sessionUpdated > existing.time.updated) {
          projectsMap[dir] = existing.copyWith(
            time: existing.time.copyWith(updated: sessionUpdated),
          );
        }
      } else {
        projectsMap[dir] = Project.fromDirectory(
          dir,
          updatedAt: sessionUpdated,
        );
      }
    }

    // 3. 为每个项目获取最新的 session 更新时间作为项目的更新时间
    final mergedProjects = projectsMap.values.toList();
    final projectsWithLatestTime = await Future.wait(
      mergedProjects.map((p) async {
        try {
          final latestSessions = await sessionApi.getSessions(
            directory: p.worktree,
            limit: 1,
          );
          if (latestSessions.isNotEmpty) {
            final latestTime = latestSessions.first.time.updated;
            return p.copyWith(time: p.time.copyWith(updated: latestTime));
          }
        } catch (_) {
          // 忽略单个项目获取 session 失败的情况
        }
        return p;
      }),
    );

    final result = projectsWithLatestTime
      ..sort((a, b) => b.time.updated.compareTo(a.time.updated));
    return result;
  }

  Project addProjectByDirectory(String directory) {
    final current = state.asData?.value ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final existingIndex = current.indexWhere((p) => p.worktree == directory);

    if (existingIndex != -1) {
      final existing = current[existingIndex];
      final updatedProject = existing.copyWith(
        time: existing.time.copyWith(updated: now),
      );
      state = AsyncData([
        updatedProject,
        ...current.where((p) => p.worktree != directory),
      ]);
      return updatedProject;
    }

    final newProject = Project.fromDirectory(directory, updatedAt: now);
    state = AsyncData([newProject, ...current]);

    return newProject;
  }
}

class ProjectApi {
  final ApiClient _client;

  ProjectApi(this._client);

  Future<List<Project>> getProjects() async {
    final List<dynamic> json = await _client.get('/project');
    return json
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
