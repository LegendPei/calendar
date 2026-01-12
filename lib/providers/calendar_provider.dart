/// 日历状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_view_type.dart';
import '../models/event.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import 'event_provider.dart';

/// 事件刷新触发器
final eventsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 当前选中日期
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 当前焦点日期（用于月视图导航）
final focusedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 当前视图类型
final calendarViewTypeProvider = StateProvider<CalendarViewType>((ref) {
  return CalendarViewType.month;
});

/// 月视图需要显示的所有日期
final monthViewDatesProvider = Provider<List<DateTime>>((ref) {
  final focusedDate = ref.watch(focusedDateProvider);
  return app_date_utils.DateUtils.getMonthViewDates(focusedDate);
});

/// 周视图需要显示的日期
final weekViewDatesProvider = Provider<List<DateTime>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return app_date_utils.DateUtils.getWeekViewDates(selectedDate);
});

/// 指定日期的事件列表（从数据库获取）
final calendarEventsByDateProvider = FutureProvider.family<List<Event>, DateTime>((ref, date) async {
  // 监听刷新触发器
  ref.watch(eventsRefreshTriggerProvider);
  final service = ref.watch(eventServiceProvider);
  return service.getEventsByDate(date);
});

/// 指定月份的事件Map（从数据库获取）
final calendarEventsByMonthProvider = FutureProvider.family<Map<DateTime, List<Event>>, DateTime>((ref, month) async {
  // 监听刷新触发器
  ref.watch(eventsRefreshTriggerProvider);
  final service = ref.watch(eventServiceProvider);
  return service.getEventsByMonth(month.year, month.month);
});

/// 日历控制器
class CalendarController {
  final Ref ref;

  CalendarController(this.ref);

  /// 切换视图类型
  void switchView(CalendarViewType type) {
    ref.read(calendarViewTypeProvider.notifier).state = type;
  }

  /// 跳转到指定日期
  void goToDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
    ref.read(focusedDateProvider.notifier).state = date;
  }

  /// 跳转到今天
  void goToToday() {
    goToDate(DateTime.now());
  }

  /// 跳转到上一个月
  void goToPreviousMonth() {
    final current = ref.read(focusedDateProvider);
    ref.read(focusedDateProvider.notifier).state = DateTime(
      current.year,
      current.month - 1,
      1,
    );
  }

  /// 跳转到下一个月
  void goToNextMonth() {
    final current = ref.read(focusedDateProvider);
    ref.read(focusedDateProvider.notifier).state = DateTime(
      current.year,
      current.month + 1,
      1,
    );
  }

  /// 跳转到上一周
  void goToPreviousWeek() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.subtract(
      const Duration(days: 7),
    );
  }

  /// 跳转到下一周
  void goToNextWeek() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.add(
      const Duration(days: 7),
    );
  }

  /// 跳转到前一天
  void goToPreviousDay() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.subtract(
      const Duration(days: 1),
    );
  }

  /// 跳转到后一天
  void goToNextDay() {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = current.add(
      const Duration(days: 1),
    );
  }

  /// 跳转到指定月份偏移量
  void goToMonth(int offset) {
    if (offset > 0) {
      goToNextMonth();
    } else if (offset < 0) {
      goToPreviousMonth();
    }
  }

  /// 跳转到指定周偏移量
  void goToWeek(int offset) {
    if (offset > 0) {
      goToNextWeek();
    } else if (offset < 0) {
      goToPreviousWeek();
    }
  }

  /// 跳转到指定天偏移量
  void goToDay(int offset) {
    if (offset > 0) {
      goToNextDay();
    } else if (offset < 0) {
      goToPreviousDay();
    }
  }

  /// 选择日期
  void selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
  }

  /// 刷新事件数据
  void refreshEvents() {
    // 刷新事件列表
    ref.invalidate(eventListProvider);
    // 通过增加触发器值来刷新所有事件Provider
    ref.read(eventsRefreshTriggerProvider.notifier).state++;
  }
}

/// 日历控制器Provider
final calendarControllerProvider = Provider((ref) {
  return CalendarController(ref);
});

