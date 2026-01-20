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
      onConfigure: _onConfigure,
    );
  }

  /// 配置数据库（启用外键约束）
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
        is_visible INTEGER DEFAULT 1,
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

    // 创建课程表相关表
    await _createCourseTables(db);
  }

  /// 创建课程表相关表
  Future<void> _createCourseTables(Database db) async {
    // 创建semesters表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSemesters} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        total_weeks INTEGER DEFAULT 20,
        is_current INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建course_schedules表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCourseSchedules} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        semester_id TEXT NOT NULL,
        time_slots TEXT NOT NULL,
        days_per_week INTEGER DEFAULT 5,
        lunch_after_section INTEGER DEFAULT 4,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (semester_id) REFERENCES ${DbConstants.tableSemesters}(id) ON DELETE CASCADE
      )
    ''');

    // 创建courses表
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCourses} (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        name TEXT NOT NULL,
        teacher TEXT,
        location TEXT,
        day_of_week INTEGER NOT NULL,
        start_section INTEGER NOT NULL,
        end_section INTEGER NOT NULL,
        weeks TEXT NOT NULL,
        color INTEGER NOT NULL,
        note TEXT,
        reminder_minutes INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES ${DbConstants.tableCourseSchedules}(id) ON DELETE CASCADE
      )
    ''');

    // 创建课程表索引
    await db.execute('''
      CREATE INDEX idx_courses_schedule_id ON ${DbConstants.tableCourses}(schedule_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_courses_day_of_week ON ${DbConstants.tableCourses}(day_of_week)
    ''');
    await db.execute('''
      CREATE INDEX idx_course_schedules_semester_id ON ${DbConstants.tableCourseSchedules}(semester_id)
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本1 -> 版本2: 添加课程表功能
    if (oldVersion < 2) {
      await _createCourseTables(db);
    }
    // 版本2 -> 版本3: 课程表添加提醒字段
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE ${DbConstants.tableCourses} ADD COLUMN reminder_minutes INTEGER
      ''');
    }
    // 版本3 -> 版本4: 订阅表添加是否显示字段
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE ${DbConstants.tableSubscriptions} ADD COLUMN is_visible INTEGER DEFAULT 1
      ''');
    }
  }

  /// 插入数据
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 执行事务
  Future<T> transaction<T>(Future<T> Function(Database db) action) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 使用事务数据库执行操作
      return await action(txn as Database);
    });
  }

  /// 批量插入（使用事务）
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final data in dataList) {
        batch.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  /// 批量删除（使用事务）
  Future<void> batchDelete(String table, List<String> ids) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in ids) {
        batch.delete(table, where: 'id = ?', whereArgs: [id]);
      }
      await batch.commit(noResult: true);
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
