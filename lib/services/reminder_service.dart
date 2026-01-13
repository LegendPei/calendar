/// 提醒业务服务
import '../core/constants/db_constants.dart';
import '../core/database/database_helper.dart';
import '../models/reminder.dart';
import '../models/event.dart';
import 'notification_service.dart';

class ReminderService {
  final DatabaseHelper _db;
  final NotificationService _notificationService;

  ReminderService(this._db, this._notificationService);

  /// 获取事件的所有提醒
  Future<List<Reminder>> getRemindersByEventId(String eventId) async {
    final maps = await _db.query(
      DbConstants.tableReminders,
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'trigger_time ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// 获取指定ID的提醒
  Future<Reminder?> getReminderById(String id) async {
    final maps = await _db.query(
      DbConstants.tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Reminder.fromMap(maps.first);
  }

  /// 获取即将触发的提醒
  Future<List<Reminder>> getUpcomingReminders({int hours = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final future = DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch;

    final maps = await _db.query(
      DbConstants.tableReminders,
      where: 'trigger_time >= ? AND trigger_time <= ? AND is_triggered = 0',
      whereArgs: [now, future],
      orderBy: 'trigger_time ASC',
    );
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// 添加提醒
  Future<String> addReminder(Reminder reminder) async {
    await _db.insert(DbConstants.tableReminders, reminder.toMap());

    // 调度通知
    await _scheduleNotification(reminder);

    return reminder.id;
  }

  /// 批量添加提醒
  Future<void> addReminders(List<Reminder> reminders) async {
    for (final reminder in reminders) {
      await addReminder(reminder);
    }
  }

  /// 更新提醒
  Future<void> updateReminder(Reminder reminder) async {
    await _db.update(
      DbConstants.tableReminders,
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );

    // 重新调度通知
    await _cancelNotification(reminder);
    if (!reminder.isTriggered) {
      await _scheduleNotification(reminder);
    }
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    final reminder = await getReminderById(id);
    if (reminder != null) {
      await _cancelNotification(reminder);
    }

    await _db.delete(
      DbConstants.tableReminders,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除事件的所有提醒
  Future<void> deleteRemindersByEventId(String eventId) async {
    final reminders = await getRemindersByEventId(eventId);
    for (final reminder in reminders) {
      await _cancelNotification(reminder);
    }

    await _db.delete(
      DbConstants.tableReminders,
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  /// 标记提醒为已触发
  Future<void> markAsTriggered(String id) async {
    await _db.update(
      DbConstants.tableReminders,
      {'is_triggered': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 为事件设置提醒
  Future<void> setRemindersForEvent(Event event, List<Duration> triggerBefores) async {
    // 先删除现有提醒
    await deleteRemindersByEventId(event.id);

    // 添加新提醒
    for (final triggerBefore in triggerBefores) {
      final reminder = Reminder.create(
        eventId: event.id,
        triggerBefore: triggerBefore,
        eventStartTime: event.startTime,
      );
      await addReminder(reminder);
    }
  }

  /// 更新事件时间时更新提醒
  Future<void> updateRemindersForEvent(Event event) async {
    final reminders = await getRemindersByEventId(event.id);

    for (final reminder in reminders) {
      final newTriggerTime = Reminder.calculateTriggerTime(
        event.startTime,
        reminder.triggerBefore,
      );

      final updatedReminder = reminder.copyWith(
        triggerTime: newTriggerTime,
        isTriggered: false,
      );

      await updateReminder(updatedReminder);
    }
  }

  /// 调度通知
  Future<void> _scheduleNotification(Reminder reminder) async {
    // 获取事件信息用于通知内容
    final eventMaps = await _db.query(
      DbConstants.tableEvents,
      where: 'id = ?',
      whereArgs: [reminder.eventId],
    );

    if (eventMaps.isEmpty) return;

    final event = Event.fromMap(eventMaps.first);

    final notificationId = NotificationService.generateNotificationId(
      reminder.eventId,
      reminder.id,
    );

    String body = _formatEventTime(event);
    if (event.location != null && event.location!.isNotEmpty) {
      body += '\n📍 ${event.location}';
    }

    await _notificationService.scheduleReminder(
      id: notificationId,
      title: '📅 ${event.title}',
      body: body,
      scheduledTime: reminder.triggerTime,
      payload: 'event:${event.id}',
    );
  }

  /// 取消通知
  Future<void> _cancelNotification(Reminder reminder) async {
    final notificationId = NotificationService.generateNotificationId(
      reminder.eventId,
      reminder.id,
    );
    await _notificationService.cancelNotification(notificationId);
  }

  /// 格式化事件时间
  String _formatEventTime(Event event) {
    if (event.allDay) {
      return '全天事件';
    }

    final start = event.startTime;
    final hour = start.hour.toString().padLeft(2, '0');
    final minute = start.minute.toString().padLeft(2, '0');
    return '${start.month}月${start.day}日 $hour:$minute';
  }

  /// 恢复所有待触发的提醒通知（用于开机后恢复）
  Future<void> rescheduleAllReminders() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final maps = await _db.query(
      DbConstants.tableReminders,
      where: 'trigger_time > ? AND is_triggered = 0',
      whereArgs: [now],
    );

    for (final map in maps) {
      final reminder = Reminder.fromMap(map);
      await _scheduleNotification(reminder);
    }
  }

  /// 获取提醒统计
  Future<Map<String, int>> getReminderStats() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final totalResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableReminders}',
    );

    final upcomingResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableReminders} WHERE trigger_time > ? AND is_triggered = 0',
      [now],
    );

    final triggeredResult = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableReminders} WHERE is_triggered = 1',
    );

    return {
      'total': totalResult.first['count'] as int,
      'upcoming': upcomingResult.first['count'] as int,
      'triggered': triggeredResult.first['count'] as int,
    };
  }
}

