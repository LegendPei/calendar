/// 事件业务服务
import '../core/constants/db_constants.dart';
import '../core/database/database_helper.dart';
import '../models/event.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

class EventService {
  final DatabaseHelper _db;

  EventService(this._db);

  /// 获取所有事件
  Future<List<Event>> getAllEvents() async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 根据ID获取事件
  Future<Event?> getEventById(String id) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  /// 根据UID获取事件
  Future<Event?> getEventByUid(String uid) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  /// 根据日期获取事件
  Future<List<Event>> getEventsByDate(DateTime date) async {
    final dayStart = app_date_utils.DateUtils.dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final maps = await _db.query(
      DbConstants.tableEvents,
      where: '(start_time >= ? AND start_time < ?) OR (all_day = 1 AND start_time >= ? AND start_time < ?)',
      whereArgs: [
        dayStart.millisecondsSinceEpoch,
        dayEnd.millisecondsSinceEpoch,
        dayStart.millisecondsSinceEpoch,
        dayEnd.millisecondsSinceEpoch,
      ],
      orderBy: 'all_day DESC, start_time ASC',
    );

    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 根据日期范围获取事件
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    final startMs = app_date_utils.DateUtils.dateOnly(start).millisecondsSinceEpoch;
    final endMs = app_date_utils.DateUtils.dateOnly(end).add(const Duration(days: 1)).millisecondsSinceEpoch;

    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'start_time >= ? AND start_time < ?',
      whereArgs: [startMs, endMs],
      orderBy: 'start_time ASC',
    );

    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 根据月份获取事件Map
  Future<Map<DateTime, List<Event>>> getEventsByMonth(int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final events = await getEventsByDateRange(firstDay, lastDay);

    final Map<DateTime, List<Event>> result = {};
    for (final event in events) {
      final dateKey = app_date_utils.DateUtils.dateOnly(event.startTime);
      result.putIfAbsent(dateKey, () => []).add(event);
    }
    return result;
  }

  /// 根据日历ID获取事件
  Future<List<Event>> getEventsByCalendarId(String calendarId) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'calendar_id = ?',
      whereArgs: [calendarId],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 插入事件
  Future<String> insertEvent(Event event) async {
    await _db.insert(DbConstants.tableEvents, event.toMap());
    return event.id;
  }

  /// 更新事件
  Future<void> updateEvent(Event event) async {
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    await _db.update(
      DbConstants.tableEvents,
      updatedEvent.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// 删除事件
  Future<void> deleteEvent(String id) async {
    await _db.delete(
      DbConstants.tableEvents,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除日历的所有事件
  Future<void> deleteEventsByCalendarId(String calendarId) async {
    await _db.delete(
      DbConstants.tableEvents,
      where: 'calendar_id = ?',
      whereArgs: [calendarId],
    );
  }

  /// 搜索事件
  Future<List<Event>> searchEvents(String query) async {
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'start_time DESC',
    );
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 获取即将到来的事件
  Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await _db.query(
      DbConstants.tableEvents,
      where: 'start_time >= ?',
      whereArgs: [now],
      orderBy: 'start_time ASC',
      limit: limit,
    );
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 获取事件总数
  Future<int> getEventCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM ${DbConstants.tableEvents}');
    return result.first['count'] as int;
  }
}

