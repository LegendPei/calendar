# 模块03: 提醒功能模块

## 1. 模块概述

提醒功能模块负责日程事件的本地通知提醒，遵循RFC5545 VALARM组件规范，支持多种提醒方式和时间设置。

## 2. 功能需求

### 2.1 提醒设置
- 支持多个提醒（每个事件可设置多个提醒）
- 提醒时间选项：准时、5分钟前、15分钟前、30分钟前、1小时前、1天前、自定义
- 提醒类型：通知（DISPLAY）

### 2.2 通知显示
- 显示事件标题
- 显示事件时间
- 显示事件地点（如有）
- 点击通知跳转到事件详情

### 2.3 后台提醒
- 应用关闭后仍能触发提醒
- 设备重启后恢复提醒

## 3. 文件结构

```
lib/
├── models/
│   └── reminder.dart            # 提醒数据模型
├── widgets/event/
│   └── reminder_picker.dart     # 提醒选择器组件
├── providers/
│   └── reminder_provider.dart   # 提醒状态管理
└── services/
    ├── reminder_service.dart    # 提醒业务服务
    └── notification_service.dart # 本地通知服务

android/
└── app/src/main/
    ├── AndroidManifest.xml      # 权限配置
    └── java/.../
        └── MainActivity.java    # 原生代码（如需要）
```

## 4. 数据模型

### 4.1 Reminder 模型

```dart
class Reminder {
  final String id;
  final String eventId;
  final Duration triggerBefore;   // 提前多久提醒
  final DateTime triggerTime;     // 实际触发时间
  final ReminderType type;
  final bool isTriggered;

  const Reminder({
    required this.id,
    required this.eventId,
    required this.triggerBefore,
    required this.triggerTime,
    this.type = ReminderType.display,
    this.isTriggered = false,
  });

  factory Reminder.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();

  /// 计算触发时间
  static DateTime calculateTriggerTime(DateTime eventStart, Duration before) {
    return eventStart.subtract(before);
  }
}

enum ReminderType {
  display,  // 通知提醒
  // audio, // 声音提醒（可扩展）
}
```

### 4.2 ReminderOption 预设选项

```dart
class ReminderOption {
  final String label;
  final Duration duration;

  const ReminderOption(this.label, this.duration);

  static const List<ReminderOption> presets = [
    ReminderOption('准时', Duration.zero),
    ReminderOption('5分钟前', Duration(minutes: 5)),
    ReminderOption('15分钟前', Duration(minutes: 15)),
    ReminderOption('30分钟前', Duration(minutes: 30)),
    ReminderOption('1小时前', Duration(hours: 1)),
    ReminderOption('2小时前', Duration(hours: 2)),
    ReminderOption('1天前', Duration(days: 1)),
    ReminderOption('2天前', Duration(days: 2)),
    ReminderOption('1周前', Duration(days: 7)),
  ];
}
```

## 5. 通知服务设计

### 5.1 NotificationService

```dart
// services/notification_service.dart

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化通知服务
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 请求通知权限
    await _requestPermissions();
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  /// 调度提醒通知
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'calendar_reminders',
      '日程提醒',
      channelDescription: '日历应用的日程提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      ticker: title,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// 取消提醒通知
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  /// 通知点击回调
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // 解析payload，导航到事件详情页
      // NavigationService.navigateToEventDetail(payload);
    }
  }
}
```

### 5.2 ReminderService

```dart
// services/reminder_service.dart

class ReminderService {
  final DatabaseHelper _db;
  final NotificationService _notificationService;

  ReminderService(this._db, this._notificationService);

  /// 为事件添加提醒
  Future<void> addReminder(Reminder reminder) async {
    await _db.insert('reminders', reminder.toMap());
    await _scheduleNotification(reminder);
  }

  /// 调度通知
  Future<void> _scheduleNotification(Reminder reminder) async {
    if (reminder.triggerTime.isBefore(DateTime.now())) {
      return; // 过期的提醒不调度
    }

    final event = await _getEvent(reminder.eventId);
    if (event == null) return;

    await _notificationService.scheduleReminder(
      id: reminder.id.hashCode,
      title: event.title,
      body: _buildNotificationBody(event),
      scheduledTime: reminder.triggerTime,
      payload: event.id,
    );
  }

  String _buildNotificationBody(Event event) {
    final timeStr = DateFormat('HH:mm').format(event.startTime);
    if (event.location != null && event.location!.isNotEmpty) {
      return '$timeStr - ${event.location}';
    }
    return timeStr;
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    await _db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await _notificationService.cancelReminder(id.hashCode);
  }

  /// 删除事件的所有提醒
  Future<void> deleteRemindersByEventId(String eventId) async {
    final reminders = await getRemindersByEventId(eventId);
    for (final reminder in reminders) {
      await _notificationService.cancelReminder(reminder.id.hashCode);
    }
    await _db.delete('reminders', where: 'event_id = ?', whereArgs: [eventId]);
  }

  /// 获取事件的所有提醒
  Future<List<Reminder>> getRemindersByEventId(String eventId) async {
    final maps = await _db.query('reminders', where: 'event_id = ?', whereArgs: [eventId]);
    return maps.map((m) => Reminder.fromMap(m)).toList();
  }

  /// 重新调度所有未触发的提醒（应用启动或设备重启时调用）
  Future<void> rescheduleAllReminders() async {
    final now = DateTime.now();
    final maps = await _db.query(
      'reminders',
      where: 'is_triggered = 0 AND trigger_time > ?',
      whereArgs: [now.millisecondsSinceEpoch],
    );

    for (final map in maps) {
      final reminder = Reminder.fromMap(map);
      await _scheduleNotification(reminder);
    }
  }
}
```

## 6. Provider设计

```dart
// providers/reminder_provider.dart

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

/// 事件的提醒列表
final eventRemindersProvider = FutureProvider.family<List<Reminder>, String>((ref, eventId) {
  return ref.watch(reminderServiceProvider).getRemindersByEventId(eventId);
});
```

## 7. Widget设计

### 7.1 ReminderPicker

```dart
class ReminderPicker extends StatelessWidget {
  final List<Duration> selectedReminders;
  final ValueChanged<List<Duration>> onChanged;

  // 显示已选提醒列表
  // 添加提醒按钮
  // 点击已选提醒可删除
}
```

### 7.2 ReminderOptionSheet

```dart
class ReminderOptionSheet extends StatelessWidget {
  final ValueChanged<Duration> onSelected;

  // 显示预设选项列表
  // 自定义选项打开时间选择器
}
```

## 8. Android配置

### 8.1 AndroidManifest.xml 权限

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 通知权限 -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <!-- 精确闹钟权限 -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    
    <!-- 开机启动权限（用于恢复提醒） -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <!-- 振动权限 -->
    <uses-permission android:name="android.permission.VIBRATE"/>

    <application ...>
        <!-- 开机广播接收器 -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

## 9. 初始化流程

```dart
// main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化时区
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  
  // 初始化通知服务
  await NotificationService().initialize();
  
  // 重新调度所有提醒
  final container = ProviderContainer();
  await container.read(reminderServiceProvider).rescheduleAllReminders();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}
```

## 10. 测试用例

### 10.1 单元测试

| 测试文件 | 测试内容 |
|---------|---------|
| `reminder_test.dart` | Reminder模型测试 |
| `reminder_service_test.dart` | 提醒服务测试 |

### 10.2 测试用例清单

```dart
group('Reminder', () {
  test('should calculate trigger time correctly', ...);
  test('should serialize to map correctly', ...);
  test('should deserialize from map correctly', ...);
});

group('ReminderService', () {
  test('addReminder should insert and schedule notification', ...);
  test('deleteReminder should remove and cancel notification', ...);
  test('deleteRemindersByEventId should remove all reminders for event', ...);
  test('rescheduleAllReminders should skip past reminders', ...);
});

group('NotificationService', () {
  test('scheduleReminder should create scheduled notification', ...);
  test('cancelReminder should remove scheduled notification', ...);
});
```

## 11. 依赖说明

```yaml
dependencies:
  flutter_local_notifications: ^16.0.0
  timezone: ^0.9.2
```

## 12. 注意事项

1. Android 13+ 需要运行时请求通知权限
2. Android 12+ 需要请求精确闹钟权限
3. 应用启动时需要重新调度所有未触发的提醒
4. 设备重启后需要通过BOOT_COMPLETED广播恢复提醒
5. 提醒ID使用reminder.id的hashCode，需确保不冲突
6. 删除事件时需要同时删除关联的提醒和取消通知

