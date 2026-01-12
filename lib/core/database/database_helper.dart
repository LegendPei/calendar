/// 数据库帮助类
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/db_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.databaseName);

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建events表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableEvents} (
        id TEXT PRIMARY KEY,
        uid TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        all_day INTEGER DEFAULT 0,
        rrule TEXT,
        color INTEGER,
        calendar_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建reminders表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableReminders} (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        trigger_before INTEGER NOT NULL,
        trigger_time INTEGER NOT NULL,
        trigger_type TEXT DEFAULT 'DISPLAY',
        is_triggered INTEGER DEFAULT 0,
        FOREIGN KEY (event_id) REFERENCES ${DbConstants.tableEvents}(id) ON DELETE CASCADE
      )
    ''');

    // 创建calendars表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCalendars} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_visible INTEGER DEFAULT 1,
        is_default INTEGER DEFAULT 0,
        source TEXT DEFAULT 'local'
      )
    ''');

    // 创建subscriptions表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSubscriptions} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        color INTEGER,
        is_active INTEGER DEFAULT 1,
        last_sync INTEGER,
        last_sync_status INTEGER DEFAULT 0,
        last_sync_error TEXT,
        sync_interval INTEGER DEFAULT 3600000,
        event_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_events_start_time ON ${DbConstants.tableEvents}(start_time)
    ''');
    await db.execute('''
      CREATE INDEX idx_events_calendar_id ON ${DbConstants.tableEvents}(calendar_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_reminders_event_id ON ${DbConstants.tableReminders}(event_id)
    ''');

    // 插入默认日历
    await db.insert(DbConstants.tableCalendars, {
      'id': 'default',
      'name': '我的日历',
      'color': 0xFF1976D2,
      'is_visible': 1,
      'is_default': 1,
      'source': 'local',
    });
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
  }

  /// 插入数据
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 查询数据
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 更新数据
  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  /// 删除数据
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 执行原始SQL
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

