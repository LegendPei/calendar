/// 事件状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

/// 数据库Provider
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// 事件服务Provider
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref.watch(databaseProvider));
});

/// 当前选中的事件
final selectedEventProvider = StateProvider<Event?>((ref) => null);

/// 事件列表Notifier
class EventListNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return ref.watch(eventServiceProvider).getAllEvents();
  }

  /// 添加事件
  Future<String> addEvent(Event event) async {
    final service = ref.read(eventServiceProvider);
    final id = await service.insertEvent(event);
    ref.invalidateSelf();
    return id;
  }

  /// 更新事件
  Future<void> updateEvent(Event event) async {
    final service = ref.read(eventServiceProvider);
    await service.updateEvent(event);
    ref.invalidateSelf();
  }

  /// 删除事件
  Future<void> deleteEvent(String id) async {
    final service = ref.read(eventServiceProvider);
    await service.deleteEvent(id);
    ref.invalidateSelf();
  }

  /// 刷新事件列表
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// 事件列表Provider
final eventListProvider = AsyncNotifierProvider<EventListNotifier, List<Event>>(
  () {
    return EventListNotifier();
  },
);

/// 指定日期的事件列表Provider
final eventsByDateProvider = FutureProvider.family<List<Event>, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(eventServiceProvider);
  return service.getEventsByDate(date);
});

/// 指定月份的事件Map Provider
final eventsByMonthProvider =
    FutureProvider.family<Map<DateTime, List<Event>>, DateTime>((
      ref,
      month,
    ) async {
      final service = ref.watch(eventServiceProvider);
      return service.getEventsByMonth(month.year, month.month);
    });

/// 即将到来的事件Provider
final upcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final service = ref.watch(eventServiceProvider);
  return service.getUpcomingEvents(limit: 10);
});

/// 事件搜索结果Provider
final eventSearchResultsProvider = FutureProvider.family<List<Event>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final service = ref.watch(eventServiceProvider);
  return service.searchEvents(query);
});

/// 事件表单初始值（用于从课程创建日程）
class EventFormInitialValues {
  final String? title;
  final String? description;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? color;

  const EventFormInitialValues({
    this.title,
    this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.color,
  });
}

/// 事件表单状态
class EventFormState {
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? rrule;
  final int? color;
  final String? calendarId;
  final bool isLoading;
  final String? error;

  const EventFormState({
    this.title = '',
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.rrule,
    this.color,
    this.calendarId,
    this.isLoading = false,
    this.error,
  });

  EventFormState copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? rrule,
    int? color,
    String? calendarId,
    bool? isLoading,
    String? error,
  }) {
    return EventFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      rrule: rrule ?? this.rrule,
      color: color ?? this.color,
      calendarId: calendarId ?? this.calendarId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 从Event创建表单状态
  factory EventFormState.fromEvent(Event event) {
    return EventFormState(
      title: event.title,
      description: event.description,
      location: event.location,
      startTime: event.startTime,
      endTime: event.endTime,
      allDay: event.allDay,
      rrule: event.rrule,
      color: event.color,
      calendarId: event.calendarId,
    );
  }

  /// 创建默认状态
  factory EventFormState.initial([DateTime? date]) {
    final now = date ?? DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, now.hour + 1);
    final endTime = startTime.add(const Duration(hours: 1));
    return EventFormState(
      startTime: startTime,
      endTime: endTime,
      calendarId: 'default',
    );
  }

  /// 验证表单
  String? validate() {
    if (title.trim().isEmpty) {
      return '请输入事件标题';
    }
    if (title.length > 100) {
      return '标题不能超过100个字符';
    }
    if (endTime.isBefore(startTime)) {
      return '结束时间不能早于开始时间';
    }
    return null;
  }

  /// 转换为Event
  Event toEvent([Event? existing]) {
    if (existing != null) {
      return existing.copyWith(
        title: title.trim(),
        description: description?.trim(),
        location: location?.trim(),
        startTime: startTime,
        endTime: endTime,
        allDay: allDay,
        rrule: rrule,
        color: color,
        calendarId: calendarId,
        updatedAt: DateTime.now(),
      );
    }
    return Event.create(
      title: title.trim(),
      description: description?.trim(),
      location: location?.trim(),
      startTime: startTime,
      endTime: endTime,
      allDay: allDay,
      rrule: rrule,
      color: color,
      calendarId: calendarId,
    );
  }
}

/// 事件表单Notifier
class EventFormNotifier extends StateNotifier<EventFormState> {
  EventFormNotifier([DateTime? initialDate])
    : super(EventFormState.initial(initialDate));

  /// 初始化为编辑模式
  void initForEdit(Event event) {
    state = EventFormState.fromEvent(event);
  }

  /// 初始化为新建模式
  void initForCreate([DateTime? date]) {
    state = EventFormState.initial(date);
  }

  /// 初始化为新建模式（带初始值，用于从课程创建日程）
  void initForCreateWithValues(EventFormInitialValues values) {
    final now = DateTime.now();
    final startTime = values.startTime ?? DateTime(now.year, now.month, now.day, now.hour + 1);
    final endTime = values.endTime ?? startTime.add(const Duration(hours: 1));

    state = EventFormState(
      title: values.title ?? '',
      description: values.description,
      location: values.location,
      startTime: startTime,
      endTime: endTime,
      color: values.color,
      calendarId: 'default',
    );
  }

  /// 更新标题
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// 更新描述
  void updateDescription(String? description) {
    state = state.copyWith(description: description);
  }

  /// 更新地点
  void updateLocation(String? location) {
    state = state.copyWith(location: location);
  }

  /// 更新开始时间
  void updateStartTime(DateTime startTime) {
    var endTime = state.endTime;
    // 如果开始时间晚于结束时间，自动调整结束时间
    if (startTime.isAfter(endTime)) {
      endTime = startTime.add(const Duration(hours: 1));
    }
    state = state.copyWith(startTime: startTime, endTime: endTime);
  }

  /// 更新结束时间
  void updateEndTime(DateTime endTime) {
    state = state.copyWith(endTime: endTime);
  }

  /// 更新全天事件
  void updateAllDay(bool allDay) {
    if (allDay) {
      final startDate = app_date_utils.DateUtils.dateOnly(state.startTime);
      final endDate = app_date_utils.DateUtils.dateOnly(state.endTime);
      state = state.copyWith(
        allDay: true,
        startTime: startDate,
        endTime: endDate.add(const Duration(hours: 23, minutes: 59)),
      );
    } else {
      state = state.copyWith(allDay: false);
    }
  }

  /// 更新重复规则
  void updateRRule(String? rrule) {
    state = state.copyWith(rrule: rrule);
  }

  /// 更新颜色
  void updateColor(int? color) {
    state = state.copyWith(color: color);
  }

  /// 更新日历ID
  void updateCalendarId(String? calendarId) {
    state = state.copyWith(calendarId: calendarId);
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 设置错误
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// 重置表单
  void reset([DateTime? date]) {
    state = EventFormState.initial(date);
  }
}

/// 事件表单Provider
final eventFormProvider =
    StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
      return EventFormNotifier();
    });
