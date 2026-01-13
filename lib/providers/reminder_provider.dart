/// 提醒状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import 'event_provider.dart';

/// 通知服务Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 提醒服务Provider
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    ref.watch(databaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

/// 事件的提醒列表Provider
final remindersByEventProvider = FutureProvider.family<List<Reminder>, String>((ref, eventId) async {
  final service = ref.watch(reminderServiceProvider);
  return service.getRemindersByEventId(eventId);
});

/// 即将到来的提醒Provider
final upcomingRemindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final service = ref.watch(reminderServiceProvider);
  return service.getUpcomingReminders(hours: 24);
});

/// 提醒统计Provider
final reminderStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(reminderServiceProvider);
  return service.getReminderStats();
});

/// 提醒管理Notifier
class ReminderNotifier extends AsyncNotifier<List<Reminder>> {
  String? _currentEventId;

  @override
  Future<List<Reminder>> build() async {
    return [];
  }

  /// 加载事件的提醒
  Future<void> loadReminders(String eventId) async {
    _currentEventId = eventId;
    state = const AsyncValue.loading();

    try {
      final service = ref.read(reminderServiceProvider);
      final reminders = await service.getRemindersByEventId(eventId);
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 添加提醒
  Future<void> addReminder(Duration triggerBefore, DateTime eventStartTime) async {
    if (_currentEventId == null) return;

    final reminder = Reminder.create(
      eventId: _currentEventId!,
      triggerBefore: triggerBefore,
      eventStartTime: eventStartTime,
    );

    final service = ref.read(reminderServiceProvider);
    await service.addReminder(reminder);

    // 刷新列表
    await loadReminders(_currentEventId!);
  }

  /// 删除提醒
  Future<void> deleteReminder(String reminderId) async {
    final service = ref.read(reminderServiceProvider);
    await service.deleteReminder(reminderId);

    if (_currentEventId != null) {
      await loadReminders(_currentEventId!);
    }
  }

  /// 清除所有提醒
  Future<void> clearReminders() async {
    if (_currentEventId == null) return;

    final service = ref.read(reminderServiceProvider);
    await service.deleteRemindersByEventId(_currentEventId!);

    state = const AsyncValue.data([]);
  }
}

/// 提醒管理Provider
final reminderNotifierProvider = AsyncNotifierProvider<ReminderNotifier, List<Reminder>>(() {
  return ReminderNotifier();
});

/// 选中的提醒时间列表（用于事件表单）
final selectedRemindersProvider = StateProvider<List<Duration>>((ref) {
  return [const Duration(minutes: 15)]; // 默认15分钟前提醒
});

/// 提醒选项是否已选中
final isReminderSelectedProvider = Provider.family<bool, Duration>((ref, duration) {
  final selected = ref.watch(selectedRemindersProvider);
  return selected.contains(duration);
});

