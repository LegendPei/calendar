# 日历App 项目架构文档

## 1. 项目概述

本项目是一个基于Flutter开发的Android日历应用，遵循RFC5545 iCalendar标准，提供完整的日程管理功能。

### 1.1 技术栈

| 类别 | 技术选型 | 版本 |
|------|---------|------|
| 框架 | Flutter | 3.38.5 |
| 语言 | Dart | 3.10.4 |
| 状态管理 | Riverpod | ^2.4.0 |
| 本地数据库 | sqflite | ^2.3.0 |
| 本地通知 | flutter_local_notifications | ^16.0.0 |
| 文件选择 | file_picker | ^6.0.0 |
| HTTP请求 | dio | ^5.3.0 |
| 日期处理 | intl | ^0.18.0 |

### 1.2 目标平台

- Android (minSdkVersion: 21, targetSdkVersion: 34)

## 2. 应用架构

采用Clean Architecture分层架构设计：

```
+-------------------------------------------+
|              表现层 (Presentation)         |
|  (Screens, Widgets, Providers)            |
+-------------------------------------------+
                    |
                    v
+-------------------------------------------+
|              领域层 (Domain)               |
|  (Models, Services, 业务逻辑)              |
+-------------------------------------------+
                    |
                    v
+-------------------------------------------+
|              数据层 (Data)                 |
|  (Database, 文件I/O, 网络)                 |
+-------------------------------------------+
```

### 2.1 层级职责

#### 表现层 (UI层)
- `screens/`: 页面级Widget
- `widgets/`: 可复用UI组件
- `providers/`: Riverpod状态管理

#### 领域层 (业务逻辑层)
- `models/`: 数据模型定义
- `services/`: 业务逻辑服务

#### 数据层
- `core/database/`: SQLite数据库操作
- `core/utils/`: 工具类

## 3. 目录结构规范

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # App配置(主题、路由)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── db_constants.dart
│   │   └── theme_constants.dart
│   ├── database/
│   │   ├── database_helper.dart
│   │   ├── tables/
│   │   │   ├── events_table.dart
│   │   │   ├── reminders_table.dart
│   │   │   └── subscriptions_table.dart
│   │   └── migrations/
│   │       └── migration_v1_v2.dart
│   └── utils/
│       ├── date_utils.dart
│       ├── icalendar_parser.dart
│       └── lunar_utils.dart
├── models/
│   ├── event.dart
│   ├── reminder.dart
│   ├── calendar.dart
│   ├── subscription.dart
│   └── lunar_date.dart
├── providers/
│   ├── calendar_provider.dart
│   ├── event_provider.dart
│   ├── reminder_provider.dart
│   ├── subscription_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── calendar/
│   │   ├── month_view_screen.dart
│   │   ├── week_view_screen.dart
│   │   └── day_view_screen.dart
│   ├── event/
│   │   ├── event_list_screen.dart
│   │   ├── event_detail_screen.dart
│   │   └── event_form_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── subscription/
│       └── subscription_screen.dart
├── widgets/
│   ├── calendar/
│   │   ├── month_grid.dart
│   │   ├── week_row.dart
│   │   ├── day_cell.dart
│   │   └── event_indicator.dart
│   ├── event/
│   │   ├── event_card.dart
│   │   ├── event_form.dart
│   │   └── reminder_picker.dart
│   └── common/
│       ├── loading_widget.dart
│       └── error_widget.dart
└── services/
    ├── event_service.dart
    ├── reminder_service.dart
    ├── notification_service.dart
    ├── icalendar_service.dart
    ├── subscription_service.dart
    └── lunar_service.dart
```

## 4. 数据库设计

### 4.1 events表 (日程事件)

```sql
CREATE TABLE events (
    id TEXT PRIMARY KEY,
    uid TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_time INTEGER NOT NULL,
    end_time INTEGER NOT NULL,
    all_day INTEGER DEFAULT 0,
    rrule TEXT,
    color INTEGER,
    calendar_id TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

### 4.2 reminders表 (提醒)

```sql
CREATE TABLE reminders (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    trigger_time INTEGER NOT NULL,
    trigger_type TEXT DEFAULT 'DISPLAY',
    is_triggered INTEGER DEFAULT 0,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);
```

### 4.3 subscriptions表 (订阅)

```sql
CREATE TABLE subscriptions (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    url TEXT NOT NULL,
    color INTEGER,
    is_active INTEGER DEFAULT 1,
    last_sync INTEGER,
    sync_interval INTEGER DEFAULT 3600000,
    created_at INTEGER NOT NULL
);
```

### 4.4 calendars表 (日历分类)

```sql
CREATE TABLE calendars (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    is_visible INTEGER DEFAULT 1,
    is_default INTEGER DEFAULT 0,
    source TEXT DEFAULT 'local'
);
```

## 5. 核心数据模型

### 5.1 Event模型 (遵循RFC5545 VEVENT)

```dart
class Event {
  final String id;
  final String uid;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? rrule;
  final int? color;
  final String? calendarId;
  final List<Reminder> reminders;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 5.2 Reminder模型 (遵循RFC5545 VALARM)

```dart
class Reminder {
  final String id;
  final String eventId;
  final DateTime triggerTime;
  final String triggerType; // DISPLAY, AUDIO, EMAIL
  final bool isTriggered;
}
```

### 5.3 LunarDate模型 (农历日期)

```dart
class LunarDate {
  final int year;           // 农历年
  final int month;          // 农历月
  final int day;            // 农历日
  final bool isLeapMonth;   // 是否闰月
  final String yearGanZhi;  // 干支纪年
  final String monthName;   // 农历月名
  final String dayName;     // 农历日名
  final String? solarTerm;  // 节气
  final String? festival;   // 节日
}
```

## 6. Riverpod状态管理规范

### 6.1 Provider命名规范

```dart
// 简单状态
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 复杂状态使用Notifier
final eventListProvider = AsyncNotifierProvider<EventListNotifier, List<Event>>(() {
  return EventListNotifier();
});

// 家族Provider用于参数化查询
final eventsByDateProvider = FutureProvider.family<List<Event>, DateTime>((ref, date) {
  return ref.watch(eventServiceProvider).getEventsByDate(date);
});
```

### 6.2 Provider文件结构

```dart
// providers/event_provider.dart

// 1. 服务Provider
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(ref.watch(databaseProvider));
});

// 2. 状态Provider
final selectedEventProvider = StateProvider<Event?>((ref) => null);

// 3. 异步Notifier
class EventListNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return ref.watch(eventServiceProvider).getAllEvents();
  }
  
  Future<void> addEvent(Event event) async { ... }
  Future<void> updateEvent(Event event) async { ... }
  Future<void> deleteEvent(String id) async { ... }
}
```

## 7. 编码规范

### 7.1 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | snake_case | `event_service.dart` |
| 类名 | PascalCase | `EventService` |
| 变量/方法 | camelCase | `getEventById` |
| 常量 | camelCase或SCREAMING_SNAKE_CASE | `defaultColor` |
| Provider | camelCase + Provider后缀 | `eventListProvider` |

### 7.2 文件组织规范

- 每个文件只包含一个公共类
- 相关的私有类可以放在同一文件
- import顺序: dart: -> package: -> 相对路径

### 7.3 注释规范

```dart
/// 事件服务类
/// 
/// 提供事件的CRUD操作和业务逻辑
class EventService {
  /// 根据日期获取事件列表
  /// 
  /// [date] 查询日期
  /// 返回该日期的所有事件
  Future<List<Event>> getEventsByDate(DateTime date) async { ... }
}
```

## 8. 测试规范

### 8.1 测试目录结构

```
test/
├── unit/                          # 单元测试
│   ├── models/
│   │   ├── event_test.dart
│   │   ├── reminder_test.dart
│   │   └── lunar_date_test.dart
│   ├── services/
│   │   ├── event_service_test.dart
│   │   ├── icalendar_service_test.dart
│   │   └── lunar_service_test.dart
│   └── utils/
│       ├── date_utils_test.dart
│       └── icalendar_parser_test.dart
├── widget/                        # Widget测试
│   ├── calendar/
│   │   ├── month_grid_test.dart
│   │   └── day_cell_test.dart
│   └── event/
│       └── event_card_test.dart
└── integration/                   # 集成测试
    └── app_test.dart
```

### 8.2 测试命名规范

```dart
void main() {
  group('EventService', () {
    test('getEventsByDate 应该返回指定日期的事件', () async {
      // Arrange - 准备
      // Act - 执行
      // Assert - 断言
    });
    
    test('addEvent 应该插入事件并返回id', () async { ... });
  });
}
```

### 8.3 测试覆盖率目标

- Models: 90%+
- Services: 80%+
- Utils: 90%+
- Widgets: 70%+

## 9. 依赖包清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # 数据库
  sqflite: ^2.3.0
  path: ^1.8.0
  
  # 本地通知
  flutter_local_notifications: ^16.0.0
  
  # 网络请求
  dio: ^5.3.0
  
  # 文件操作
  file_picker: ^6.0.0
  path_provider: ^2.1.0
  share_plus: ^7.2.0
  
  # 日期时间
  intl: ^0.18.0
  
  # UI组件
  table_calendar: ^3.0.9
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  mockito: ^5.4.0
  sqflite_common_ffi: ^2.3.0
```

## 10. 功能模块概览

| 模块 | 文档 | 说明 |
|------|------|------|
| 日历视图 | [01_calendar_view.md](docs/modules/01_calendar_view.md) | 月/周/日视图展示 |
| 日程管理 | [02_event_management.md](docs/modules/02_event_management.md) | CRUD操作 |
| 提醒功能 | [03_reminder.md](docs/modules/03_reminder.md) | 本地通知提醒 |
| 导入导出 | [04_import_export.md](docs/modules/04_import_export.md) | iCalendar格式 |
| 网络订阅 | [05_subscription.md](docs/modules/05_subscription.md) | 远程日历订阅 |
| 农历功能 | [06_lunar_calendar.md](docs/modules/06_lunar_calendar.md) | 农历/节气/节日 |

## 11. 开发流程

1. 阅读对应模块设计文档
2. 按照目录结构创建文件
3. 实现功能代码
4. 编写单元测试
5. 更新开发日志
6. 代码审查与合并

## 12. 参考标准

- [RFC 5545 - iCalendar规范](https://tools.ietf.org/html/rfc5545)
- [RFC 4791 - CalDAV协议](https://tools.ietf.org/html/rfc4791)

