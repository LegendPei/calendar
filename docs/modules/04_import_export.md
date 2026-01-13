# 模块04: 导入导出模块
## 1. 模块概述
导入导出模块负责iCalendar格式(.ics)文件的导入和导出，遵循RFC5545标准。
## 2. 功能需求
### 2.1 导出功能
- 导出单个事件为.ics文件
- 导出选定日期范围的事件
- 导出全部事件
- 支持分享到其他应用
### 2.2 导入功能
- 从文件选择器导入.ics文件
- 解析VEVENT组件
- 处理重复事件RRULE
- 处理提醒VALARM
- 导入冲突处理（基于UID判断）
## 3. 文件结构
lib/
├── core/utils/
│   └── icalendar_parser.dart    # iCalendar解析器
├── services/
│   └── icalendar_service.dart   # 导入导出服务
└── screens/
    └── settings/
        └── import_export_screen.dart
## 4. iCalendar格式参考(RFC5545)
### 4.1 基本结构
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//CalendarApp//CN
BEGIN:VEVENT
UID:event-123@calendarapp
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:会议标题
DESCRIPTION:会议描述
LOCATION:会议室A
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
BEGIN:VALARM
TRIGGER:-PT15M
ACTION:DISPLAY
DESCRIPTION:提醒
END:VALARM
END:VEVENT
END:VCALENDAR
## 5. 数据模型
### 5.1 ICalendarDocument
class ICalendarDocument {
  final String version;
  final String prodId;
  final List<VEvent> events;
  String serialize();
  factory ICalendarDocument.parse(String content);
}
### 5.2 VEvent
class VEvent {
  final String uid;
  final DateTime dtStart;
  final DateTime dtEnd;
  final String summary;
  final String? description;
  final String? location;
  final String? rrule;
  final List<VAlarm> alarms;
  Event toEvent();
  factory VEvent.fromEvent(Event event);
}
## 6. Service设计
class ICalendarService {
  final EventService _eventService;
  final ReminderService _reminderService;
  // 导出单个事件
  Future<String> exportEvent(Event event);
  // 导出多个事件
  Future<String> exportEvents(List<Event> events);
  // 导出到文件
  Future<File> exportToFile(List<Event> events, String fileName);
  // 从文件导入
  Future<ImportResult> importFromFile(File file);
  // 解析iCalendar内容
  ICalendarDocument parseICalendar(String content);
}
class ImportResult {
  final int totalCount;
  final int importedCount;
  final int skippedCount;
  final int updatedCount;
  final List<String> errors;
}
## 7. 解析器设计
class ICalendarParser {
  // 解析iCalendar文本
  static ICalendarDocument parse(String content) {
    final lines = content.split('\n');
    // 解析逻辑...
  }
  // 解析日期时间
  static DateTime parseDateTime(String value) {
    // 支持格式: 20251227T090000, 20251227T090000Z
  }
  // 解析RRULE
  static String? parseRRule(String line);
  // 解析TRIGGER
  static Duration parseTrigger(String value) {
    // 支持格式: -PT15M, -P1D
  }
}
class ICalendarSerializer {
  // 序列化为iCalendar格式
  static String serialize(ICalendarDocument doc);
  // 格式化日期时间
  static String formatDateTime(DateTime dt);
  // 折叠长行(每行不超过75字符)
  static String foldLine(String line);
}
## 8. 测试用例
### 8.1 单元测试
| 测试文件 | 测试内容 |
|---------|---------|
| icalendar_parser_test.dart | 解析测试 |
| icalendar_service_test.dart | 导入导出测试 |
### 8.2 测试用例清单
group('ICalendarParser', () {
  test('should parse simple VEVENT');
  test('should parse VEVENT with RRULE');
  test('should parse VEVENT with VALARM');
  test('should handle multiple events');
  test('should parse UTC datetime');
  test('should parse local datetime');
});
group('ICalendarSerializer', () {
  test('should serialize Event to VEVENT');
  test('should fold long lines');
  test('should escape special characters');
});
## 9. 依赖说明
dependencies:
  file_picker: ^6.0.0
  path_provider: ^2.1.0
  share_plus: ^7.2.0
## 10. 注意事项
1. 导入时根据UID判断是新增还是更新
2. 需要处理不同时区的日期时间
3. 长行需要按RFC5545规范折叠
4. 特殊字符需要转义处理
5. 导出时生成标准的PRODID
