import 'package:sqflite/sqflite.dart';

class ProjectPinDao {
  static const String tableName = 'pinned_projects';
  static const String columnServerBaseUrl = 'server_base_url';
  static const String columnWorktree = 'worktree';
  static const String columnPinnedAt = 'pinned_at';

  final Database db;

  ProjectPinDao(this.db);

  Future<Map<String, int>> getPinnedProjects(String serverBaseUrl) async {
    final result = await db.query(
      tableName,
      columns: [columnWorktree, columnPinnedAt],
      where: '$columnServerBaseUrl = ?',
      whereArgs: [serverBaseUrl],
    );

    final pinnedProjects = <String, int>{};
    for (final row in result) {
      final worktree = row[columnWorktree] as String;
      final pinnedAt = (row[columnPinnedAt] as num).toInt();
      pinnedProjects[worktree] = pinnedAt;
    }

    return pinnedProjects;
  }

  Future<void> pinProject({
    required String serverBaseUrl,
    required String worktree,
    required int pinnedAt,
  }) async {
    await db.insert(tableName, {
      columnServerBaseUrl: serverBaseUrl,
      columnWorktree: worktree,
      columnPinnedAt: pinnedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unpinProject({
    required String serverBaseUrl,
    required String worktree,
  }) async {
    await db.delete(
      tableName,
      where: '$columnServerBaseUrl = ? AND $columnWorktree = ?',
      whereArgs: [serverBaseUrl, worktree],
    );
  }

  Future<bool> isPinned({
    required String serverBaseUrl,
    required String worktree,
  }) async {
    final result = await db.query(
      tableName,
      columns: [columnWorktree],
      where: '$columnServerBaseUrl = ? AND $columnWorktree = ?',
      whereArgs: [serverBaseUrl, worktree],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
