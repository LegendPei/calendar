/// 本地通知服务
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 通知点击回调类型
typedef NotificationCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  NotificationCallback? _onNotificationTapped;

  /// 初始化通知服务
  Future<void> initialize({NotificationCallback? onTap}) async {
    if (_isInitialized) return;

    _onNotificationTapped = onTap;

    // 初始化时区
    tz_data.initializeTimeZones();
    // 设置本地时区为上海（中国标准时间）
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    // Android设置
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // 初始化设置
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 请求权限
    await _requestPermissions();

    _isInitialized = true;
  }

  /// 请求通知权限
  Future<bool> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      // 请求通知权限
      final granted = await android.requestNotificationsPermission();

      // 请求精确闹钟权限 (Android 12+)
      await android.requestExactAlarmsPermission();

      return granted ?? false;
    }
    return false;
  }

  /// 通知响应处理
  void _onNotificationResponse(NotificationResponse response) {
    _onNotificationTapped?.call(response.payload);
  }

  /// 调度提醒通知
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // 如果时间已过，不调度
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'calendar_reminders',
      '日程提醒',
      channelDescription: '日历应用的日程提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      when: scheduledTime.millisecondsSinceEpoch,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// 立即显示通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'calendar_reminders',
      '日程提醒',
      channelDescription: '日历应用的日程提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails, payload: payload);
  }

  /// 获取待处理的通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// 生成通知ID (基于事件ID和提醒ID)
  static int generateNotificationId(String eventId, String reminderId) {
    return (eventId.hashCode ^ reminderId.hashCode).abs() % 2147483647;
  }
}
