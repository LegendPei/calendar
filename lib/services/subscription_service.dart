/// 订阅服务
import 'package:http/http.dart' as http;
import '../core/constants/db_constants.dart';
import '../core/database/database_helper.dart';
import '../core/utils/icalendar_parser.dart';
import '../models/subscription.dart';
import '../models/event.dart';
import 'event_service.dart';

class SubscriptionService {
  final DatabaseHelper _db;
  final EventService _eventService;

  SubscriptionService(this._db, this._eventService);

  /// 获取所有订阅
  Future<List<Subscription>> getAllSubscriptions() async {
    final maps = await _db.query(
      DbConstants.tableSubscriptions,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  /// 获取活跃的订阅
  Future<List<Subscription>> getActiveSubscriptions() async {
    final maps = await _db.query(
      DbConstants.tableSubscriptions,
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  /// 根据ID获取订阅
  Future<Subscription?> getSubscriptionById(String id) async {
    final maps = await _db.query(
      DbConstants.tableSubscriptions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Subscription.fromMap(maps.first);
  }

  /// 添加订阅
  Future<String> addSubscription(Subscription subscription) async {
    await _db.insert(DbConstants.tableSubscriptions, subscription.toMap());
    return subscription.id;
  }

  /// 更新订阅
  Future<void> updateSubscription(Subscription subscription) async {
    final updated = subscription.copyWith(updatedAt: DateTime.now());
    await _db.update(
      DbConstants.tableSubscriptions,
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  /// 删除订阅
  Future<void> deleteSubscription(String id) async {
    // 先删除订阅关联的所有事件
    await _eventService.deleteEventsByCalendarId(id);
    // 再删除订阅
    await _db.delete(
      DbConstants.tableSubscriptions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 同步订阅
  Future<SyncResult> syncSubscription(String id) async {
    final stopwatch = Stopwatch()..start();
    final List<String> errors = [];
    int added = 0;
    int updated = 0;

    try {
      final subscription = await getSubscriptionById(id);
      if (subscription == null) {
        throw Exception('订阅不存在');
      }

      // 更新同步状态为syncing
      await _updateSyncStatus(id, SyncStatus.syncing);

      // 获取远程日历内容
      final content = await _fetchCalendarContent(subscription.url);

      // 解析iCalendar
      final doc = ICalendarDocument.parse(content);

      // 同步每个事件
      for (final vevent in doc.events) {
        try {
          final result = await _syncEvent(vevent, id, subscription.color);
          if (result == 'added') {
            added++;
          } else if (result == 'updated') {
            updated++;
          }
        } catch (e) {
          errors.add('同步事件"${vevent.summary}"失败: $e');
        }
      }

      // 更新订阅信息
      stopwatch.stop();
      final updatedSub = subscription.copyWith(
        lastSync: DateTime.now(),
        lastSyncStatus: errors.isEmpty ? SyncStatus.success : SyncStatus.error,
        lastSyncError: errors.isEmpty ? null : errors.join('\n'),
        eventCount: doc.events.length,
        updatedAt: DateTime.now(),
      );
      await updateSubscription(updatedSub);

      return SyncResult(
        syncedCount: doc.events.length,
        addedCount: added,
        updatedCount: updated,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      await _updateSyncStatus(id, SyncStatus.error, e.toString());
      return SyncResult(errors: [e.toString()], duration: stopwatch.elapsed);
    }
  }

  /// 同步所有需要同步的订阅
  Future<Map<String, SyncResult>> syncAllSubscriptions() async {
    final subscriptions = await getActiveSubscriptions();
    final results = <String, SyncResult>{};

    for (final sub in subscriptions) {
      if (sub.needsSync) {
        results[sub.id] = await syncSubscription(sub.id);
      }
    }

    return results;
  }

  /// 获取远程日历内容
  Future<String> _fetchCalendarContent(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'text/calendar',
              'User-Agent': 'CalendarApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      return response.body;
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 同步单个事件
  Future<String> _syncEvent(
    VEvent vevent,
    String subscriptionId,
    int? color,
  ) async {
    // 检查是否已存在
    final existingEvent = await _eventService.getEventByUid(vevent.uid);

    if (existingEvent != null) {
      // 更新现有事件
      final updatedEvent = existingEvent.copyWith(
        title: vevent.summary,
        description: vevent.description,
        location: vevent.location,
        startTime: vevent.dtStart,
        endTime: vevent.dtEnd,
        allDay: vevent.allDay,
        rrule: vevent.rrule,
        color: color,
        updatedAt: DateTime.now(),
      );
      await _eventService.updateEvent(updatedEvent);
      return 'updated';
    } else {
      // 创建新事件
      final newEvent = Event.create(
        title: vevent.summary,
        description: vevent.description,
        location: vevent.location,
        startTime: vevent.dtStart,
        endTime: vevent.dtEnd,
        allDay: vevent.allDay,
        rrule: vevent.rrule,
        color: color,
        calendarId: subscriptionId,
      ).copyWith(uid: vevent.uid);
      await _eventService.insertEvent(newEvent);
      return 'added';
    }
  }

  /// 更新同步状态
  Future<void> _updateSyncStatus(
    String id,
    SyncStatus status, [
    String? error,
  ]) async {
    await _db.update(
      DbConstants.tableSubscriptions,
      {
        'last_sync_status': status.index,
        'last_sync_error': error,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 验证URL是否有效
  Future<bool> validateUrl(String url) async {
    try {
      final content = await _fetchCalendarContent(url);
      final doc = ICalendarDocument.parse(content);
      return doc.events.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 预览订阅内容
  Future<List<VEvent>> previewSubscription(String url) async {
    final content = await _fetchCalendarContent(url);
    final doc = ICalendarDocument.parse(content);
    return doc.events;
  }

  /// 获取订阅统计
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    final subscriptions = await getAllSubscriptions();
    final active = subscriptions.where((s) => s.isActive).length;
    final totalEvents = subscriptions.fold<int>(
      0,
      (sum, s) => sum + s.eventCount,
    );

    return {
      'total': subscriptions.length,
      'active': active,
      'inactive': subscriptions.length - active,
      'totalEvents': totalEvents,
    };
  }
}
