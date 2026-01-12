# 模块01: 日历视图模块

## 1. 模块概述

日历视图模块负责提供月视图、周视图、日视图三种日历展示形式，支持视图切换、日期导航和农历显示。

## 2. 功能需求

### 2.1 月视图
- 显示完整月份的日历网格（6行7列）
- 每个日期格显示公历日期和农历信息
- 有事件的日期显示事件指示点
- 点击日期可查看当日事件列表
- 左右滑动切换月份

### 2.2 周视图
- 显示一周7天的日期
- 每天显示时间轴（0-24小时）
- 事件以时间块形式显示在对应时间段
- 左右滑动切换周

### 2.3 日视图
- 显示单日详细时间轴
- 24小时时间刻度
- 事件详细展示在对应时间段
- 左右滑动切换日期

### 2.4 通用功能
- 今日按钮快速返回当天
- 视图切换按钮（月/周/日）
- 日期选择器跳转到指定日期

## 3. 文件结构

```
lib/
├── screens/calendar/
│   ├── calendar_screen.dart      # 日历主页面（视图容器）
│   ├── month_view_screen.dart    # 月视图页面
│   ├── week_view_screen.dart     # 周视图页面
│   └── day_view_screen.dart      # 日视图页面
├── widgets/calendar/
│   ├── month_grid.dart           # 月视图网格组件
│   ├── week_row.dart             # 周视图行组件
│   ├── day_cell.dart             # 日期单元格组件
│   ├── day_timeline.dart         # 日视图时间轴组件
│   ├── event_indicator.dart      # 事件指示点组件
│   ├── time_slot.dart            # 时间槽组件
│   └── calendar_header.dart      # 日历头部导航组件
└── providers/
    └── calendar_provider.dart    # 日历状态管理
```

## 4. 数据模型

### 4.1 CalendarViewType 枚举

```dart
enum CalendarViewType {
  month,
  week,
  day,
}
```

### 4.2 CalendarState 状态类

```dart
class CalendarState {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final CalendarViewType viewType;
  final Map<DateTime, List<Event>> eventsCache;
}
```

## 5. Provider设计

```dart
// providers/calendar_provider.dart

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

/// 指定日期的事件列表
final eventsByDateProvider = FutureProvider.family<List<Event>, DateTime>((ref, date) async {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByDate(date);
});

/// 指定月份的事件Map（用于月视图事件指示）
final eventsByMonthProvider = FutureProvider.family<Map<DateTime, List<Event>>, DateTime>((ref, month) async {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByMonth(month.year, month.month);
});
```

## 6. Widget设计

### 6.1 MonthGrid 月视图网格

```dart
class MonthGrid extends ConsumerWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, List<Event>> events;
  
  // 构建6x7网格
  // 显示上月末尾日期 + 当月日期 + 下月开头日期
}
```

### 6.2 DayCell 日期单元格

```dart
class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;
  final LunarDate lunarDate;
  final int eventCount;
  final VoidCallback onTap;
  
  // 显示公历日期
  // 显示农历日期/节气/节日
  // 显示事件指示点
}
```

### 6.3 DayTimeline 日视图时间轴

```dart
class DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final Function(DateTime) onTimeSlotTap;
  
  // 24小时时间刻度
  // 事件块定位显示
}
```

### 6.4 CalendarHeader 日历头部

```dart
class CalendarHeader extends ConsumerWidget {
  // 显示当前年月
  // 左右箭头切换月份/周/日
  // 今日按钮
  // 视图切换按钮
}
```

## 7. 交互逻辑

### 7.1 视图切换

```dart
void switchView(CalendarViewType type) {
  ref.read(calendarViewTypeProvider.notifier).state = type;
}
```

### 7.2 日期导航

```dart
void goToDate(DateTime date) {
  ref.read(selectedDateProvider.notifier).state = date;
  ref.read(focusedDateProvider.notifier).state = date;
}

void goToToday() {
  goToDate(DateTime.now());
}

void goToPreviousMonth() {
  final current = ref.read(focusedDateProvider);
  ref.read(focusedDateProvider.notifier).state = DateTime(current.year, current.month - 1);
}

void goToNextMonth() {
  final current = ref.read(focusedDateProvider);
  ref.read(focusedDateProvider.notifier).state = DateTime(current.year, current.month + 1);
}
```

### 7.3 日期选择

```dart
void onDateSelected(DateTime date) {
  ref.read(selectedDateProvider.notifier).state = date;
  // 可选：显示当日事件列表底部弹窗
}
```

## 8. UI设计规范

### 8.1 颜色定义

```dart
// theme_constants.dart
const Color todayColor = Color(0xFF1976D2);
const Color selectedColor = Color(0xFF42A5F5);
const Color weekendColor = Color(0xFFE57373);
const Color lunarTextColor = Color(0xFF757575);
const Color eventIndicatorColor = Color(0xFF4CAF50);
```

### 8.2 尺寸规范

```dart
const double dayCellSize = 48.0;
const double dayCellPadding = 4.0;
const double lunarFontSize = 10.0;
const double solarFontSize = 16.0;
const double eventIndicatorSize = 6.0;
const double timeSlotHeight = 60.0;
```

## 9. 测试用例

### 9.1 单元测试

| 测试文件 | 测试内容 |
|---------|---------|
| `calendar_provider_test.dart` | Provider状态变更测试 |
| `date_utils_test.dart` | 日期计算工具测试 |

### 9.2 Widget测试

| 测试文件 | 测试内容 |
|---------|---------|
| `month_grid_test.dart` | 月视图渲染测试 |
| `day_cell_test.dart` | 日期单元格显示测试 |
| `calendar_header_test.dart` | 头部导航功能测试 |

### 9.3 测试用例清单

```dart
group('MonthGrid', () {
  testWidgets('should display 42 day cells', ...);
  testWidgets('should highlight today', ...);
  testWidgets('should highlight selected date', ...);
  testWidgets('should show event indicators', ...);
  testWidgets('should trigger onDateSelected when tapped', ...);
});

group('CalendarProvider', () {
  test('selectedDateProvider should update on date selection', ...);
  test('goToToday should set date to current date', ...);
  test('goToPreviousMonth should decrease month by 1', ...);
});
```

## 10. 依赖说明

```yaml
dependencies:
  table_calendar: ^3.0.9  # 可选：使用现成日历组件
  intl: ^0.18.0          # 日期格式化
```

## 11. 注意事项

1. 月视图需要预加载事件数据以显示指示点
2. 视图切换时保持选中日期不变
3. 农历信息通过LunarService计算获取
4. 考虑大量事件时的性能优化（虚拟列表）
5. 支持手势滑动切换月份/周/日

