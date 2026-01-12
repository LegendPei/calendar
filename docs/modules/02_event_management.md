# 模块02: 日程管理模块

## 1. 模块概述

日程管理模块负责日程事件的增删改查（CRUD）操作，遵循RFC5545 VEVENT组件规范，支持重复事件（RRULE）处理。

## 2. 功能需求

### 2.1 添加日程
- 输入事件标题（必填）
- 设置开始/结束时间
- 全天事件开关
- 添加地点信息
- 添加事件描述
- 设置重复规则（不重复/每天/每周/每月/每年/自定义）
- 选择所属日历
- 设置事件颜色
- 添加提醒

### 2.2 编辑日程
- 修改所有事件属性
- 重复事件编辑选项（仅此事件/此后所有/全部事件）

### 2.3 查看日程
- 事件详情页展示
- 显示事件完整信息
- 显示农历日期

### 2.4 删除日程
- 确认删除对话框
- 重复事件删除选项（仅此事件/此后所有/全部事件）

## 3. 文件结构

```
lib/
├── models/
│   ├── event.dart              # 事件数据模型
│   └── recurrence_rule.dart    # 重复规则模型
├── screens/event/
│   ├── event_list_screen.dart  # 事件列表页面
│   ├── event_detail_screen.dart # 事件详情页面
│   └── event_form_screen.dart  # 事件表单页面（添加/编辑）
├── widgets/event/
│   ├── event_card.dart         # 事件卡片组件
│   ├── event_form.dart         # 事件表单组件
│   ├── reminder_picker.dart    # 提醒选择器
│   ├── recurrence_picker.dart  # 重复规则选择器
│   ├── color_picker.dart       # 颜色选择器
│   └── calendar_picker.dart    # 日历选择器
├── providers/
│   └── event_provider.dart     # 事件状态管理
└── services/
    └── event_service.dart      # 事件业务服务
```

## 4. 数据模型

### 4.1 Event 模型

```dart
class Event {
  final String id;
  final String uid;                 // RFC5545 UID
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? rrule;              // RFC5545 RRULE
  final int? color;
  final String? calendarId;
  final List<Reminder> reminders;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.rrule,
    this.color,
    this.calendarId,
    this.reminders = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建Event
  factory Event.fromMap(Map<String, dynamic> map);

  /// 转换为数据库Map
  Map<String, dynamic> toMap();

  /// 复制并修改部分属性
  Event copyWith({...});

  /// 生成RFC5545 UID
  static String generateUid() {
    return '${DateTime.now().millisecondsSinceEpoch}-${uuid.v4()}@calendarapp';
  }
}
```

### 4.2 RecurrenceRule 模型（RRULE解析）

```dart
enum RecurrenceFrequency {
  daily,    // FREQ=DAILY
  weekly,   // FREQ=WEEKLY
  monthly,  // FREQ=MONTHLY
  yearly,   // FREQ=YEARLY
}

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval;           // INTERVAL
  final DateTime? until;        // UNTIL
  final int? count;             // COUNT
  final List<int>? byDay;       // BYDAY (0=周日, 1=周一...)
  final List<int>? byMonthDay;  // BYMONTHDAY
  final List<int>? byMonth;     // BYMONTH

  /// 从RRULE字符串解析
  factory RecurrenceRule.fromRRule(String rrule);

  /// 转换为RRULE字符串
  String toRRule();

  /// 生成指定范围内的所有事件日期
  List<DateTime> generateOccurrences(DateTime start, DateTime rangeStart, DateTime rangeEnd);
}
```

## 5. Provider设计

```dart
// providers/event_provider.dart

/// 数据库Provider
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// 事件服务Provider
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref.watch(databaseProvider));
});

/// 当前选中的事件
final selectedEventProvider = StateProvider<Event?>((ref) => null);

/// 事件表单状态（用于添加/编辑）
final eventFormProvider = StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
  return EventFormNotifier();
});

/// 事件列表Notifier
class EventListNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return ref.watch(eventServiceProvider).getAllEvents();
  }

  Future<String> addEvent(Event event) async {
    final service = ref.read(eventServiceProvider);
    final id = await service.insertEvent(event);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateEvent(Event event) async {
    final service = ref.read(eventServiceProvider);
    await service.updateEvent(event);
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(String id) async {
    final service = ref.read(eventServiceProvider);
    await service.deleteEvent(id);
    ref.invalidateSelf();
  }
}

final eventListProvider = AsyncNotifierProvider<EventListNotifier, List<Event>>(() {
  return EventListNotifier();
});
```

## 6. Service设计

```dart
// services/event_service.dart

class EventService {
  final DatabaseHelper _db;

  EventService(this._db);

  /// 获取所有事件
  Future<List<Event>> getAllEvents() async {
    final maps = await _db.query('events');
    return maps.map((m) => Event.fromMap(m)).toList();
  }

  /// 根据ID获取事件
  Future<Event?> getEventById(String id) async {
    final maps = await _db.query('events', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  /// 根据日期获取事件（包括重复事件展开）
  Future<List<Event>> getEventsByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    // 1. 获取普通事件
    final normalEvents = await _getNormalEventsByDateRange(dayStart, dayEnd);
    
    // 2. 获取重复事件并展开
    final recurringEvents = await _getRecurringEventsForDate(date);
    
    return [...normalEvents, ...recurringEvents];
  }

  /// 根据月份获取事件Map
  Future<Map<DateTime, List<Event>>> getEventsByMonth(int year, int month) async {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    final events = await getEventsByDateRange(firstDay, lastDay);
    
    final Map<DateTime, List<Event>> result = {};
    for (final event in events) {
      final dateKey = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      result.putIfAbsent(dateKey, () => []).add(event);
    }
    return result;
  }

  /// 插入事件
  Future<String> insertEvent(Event event) async {
    await _db.insert('events', event.toMap());
    return event.id;
  }

  /// 更新事件
  Future<void> updateEvent(Event event) async {
    await _db.update('events', event.toMap(), where: 'id = ?', whereArgs: [event.id]);
  }

  /// 删除事件
  Future<void> deleteEvent(String id) async {
    await _db.delete('events', where: 'id = ?', whereArgs: [id]);
  }
}
```

## 7. Widget设计

### 7.1 EventForm 事件表单

```dart
class EventForm extends ConsumerStatefulWidget {
  final Event? initialEvent;  // null表示新建，非null表示编辑
  final VoidCallback onSaved;
  final VoidCallback onCanceled;

  // 表单字段
  // - 标题输入框
  // - 全天开关
  // - 开始时间选择器
  // - 结束时间选择器
  // - 地点输入框
  // - 描述输入框
  // - 重复规则选择器
  // - 日历选择器
  // - 颜色选择器
  // - 提醒列表
}
```

### 7.2 EventCard 事件卡片

```dart
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  // 显示内容
  // - 颜色条
  // - 标题
  // - 时间范围
  // - 地点（可选）
}
```

### 7.3 RecurrencePicker 重复规则选择器

```dart
class RecurrencePicker extends StatelessWidget {
  final RecurrenceRule? value;
  final ValueChanged<RecurrenceRule?> onChanged;

  // 选项
  // - 不重复
  // - 每天
  // - 每周
  // - 每月
  // - 每年
  // - 自定义...（打开详细设置对话框）
}
```

## 8. 表单验证规则

```dart
class EventFormValidator {
  /// 验证标题
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入事件标题';
    }
    if (value.length > 100) {
      return '标题不能超过100个字符';
    }
    return null;
  }

  /// 验证时间范围
  static String? validateTimeRange(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return '结束时间不能早于开始时间';
    }
    return null;
  }
}
```

## 9. 测试用例

### 9.1 单元测试

| 测试文件 | 测试内容 |
|---------|---------|
| `event_test.dart` | Event模型序列化/反序列化 |
| `recurrence_rule_test.dart` | RRULE解析和生成 |
| `event_service_test.dart` | CRUD操作测试 |

### 9.2 Widget测试

| 测试文件 | 测试内容 |
|---------|---------|
| `event_form_test.dart` | 表单验证和提交 |
| `event_card_test.dart` | 卡片渲染和交互 |

### 9.3 测试用例清单

```dart
group('Event', () {
  test('should serialize to map correctly', ...);
  test('should deserialize from map correctly', ...);
  test('should generate valid UID', ...);
  test('copyWith should create new instance with updated fields', ...);
});

group('RecurrenceRule', () {
  test('should parse FREQ=DAILY correctly', ...);
  test('should parse FREQ=WEEKLY;BYDAY=MO,WE,FR correctly', ...);
  test('should generate correct occurrences for daily rule', ...);
  test('should respect UNTIL date', ...);
  test('should respect COUNT limit', ...);
});

group('EventService', () {
  test('insertEvent should add event to database', ...);
  test('getEventsByDate should return events for specific date', ...);
  test('getEventsByDate should expand recurring events', ...);
  test('updateEvent should modify existing event', ...);
  test('deleteEvent should remove event from database', ...);
});
```

## 10. RFC5545 RRULE 参考

### 10.1 常见RRULE示例

```
# 每天重复
RRULE:FREQ=DAILY

# 每周一、三、五重复
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR

# 每月15日重复
RRULE:FREQ=MONTHLY;BYMONTHDAY=15

# 每年1月1日重复
RRULE:FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1

# 每天重复，共10次
RRULE:FREQ=DAILY;COUNT=10

# 每周重复，直到2025年12月31日
RRULE:FREQ=WEEKLY;UNTIL=20251231T235959Z
```

## 11. 注意事项

1. UID必须全局唯一，用于iCalendar导入导出时识别事件
2. 重复事件展开时需要考虑性能，建议限制展开范围
3. 编辑重复事件时需要处理三种情况：仅此事件、此后所有、全部事件
4. 删除事件时需要同时删除关联的提醒
5. 时间存储使用UTC时间戳，显示时转换为本地时间

