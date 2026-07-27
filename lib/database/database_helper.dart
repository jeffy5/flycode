import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _dbVersion = 3;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'flycode.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE model_configs (
        provider_id TEXT NOT NULL,
        model_id TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (provider_id, model_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pinned_projects (
        server_base_url TEXT NOT NULL,
        worktree TEXT NOT NULL,
        pinned_at INTEGER NOT NULL,
        PRIMARY KEY (server_base_url, worktree)
      )
    ''');

    await db.execute('''
      CREATE TABLE session_cache (
        session_id TEXT NOT NULL,
        messages_json TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        PRIMARY KEY (session_id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE pinned_projects (
          server_base_url TEXT NOT NULL,
          worktree TEXT NOT NULL,
          pinned_at INTEGER NOT NULL,
          PRIMARY KEY (server_base_url, worktree)
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE session_cache (
          session_id TEXT NOT NULL,
          messages_json TEXT NOT NULL,
          cached_at INTEGER NOT NULL,
          PRIMARY KEY (session_id)
        )
      ''');
    }
  }

  Future<void> saveSessionCache(String sessionId, String messagesJson) async {
    final db = await database;
    await db.insert('session_cache', {
      'session_id': sessionId,
      'messages_json': messagesJson,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> loadSessionCache(String sessionId) async {
    final db = await database;
    final rows = await db.query(
      'session_cache',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['messages_json'] as String;
  }
}
