// iCalendar解析器测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/core/utils/icalendar_parser.dart';

void main() {
  group('ICalendarParser', () {
    test('should parse simple VEVENT', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
UID:test-123@example.com
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:测试事件
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.version, '2.0');
      expect(doc.events.length, 1);
      expect(doc.events[0].uid, 'test-123@example.com');
      expect(doc.events[0].summary, '测试事件');
      expect(doc.events[0].dtStart, DateTime(2025, 12, 27, 9, 0));
      expect(doc.events[0].dtEnd, DateTime(2025, 12, 27, 10, 0));
    });

    test('should parse VEVENT with description and location', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:test-456@example.com
DTSTART:20251227T140000
DTEND:20251227T160000
SUMMARY:会议
DESCRIPTION:项目讨论会议
LOCATION:会议室A
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events[0].description, '项目讨论会议');
      expect(doc.events[0].location, '会议室A');
    });

    test('should parse VEVENT with RRULE', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:recurring@example.com
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:每周会议
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events[0].rrule, 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
    });

    test('should parse VEVENT with VALARM', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:alarm@example.com
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:带提醒的事件
BEGIN:VALARM
TRIGGER:-PT15M
ACTION:DISPLAY
DESCRIPTION:提醒
END:VALARM
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events[0].alarms.length, 1);
      expect(doc.events[0].alarms[0].trigger, const Duration(minutes: 15));
      expect(doc.events[0].alarms[0].action, 'DISPLAY');
    });

    test('should handle multiple events', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:event1@example.com
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:事件1
END:VEVENT
BEGIN:VEVENT
UID:event2@example.com
DTSTART:20251228T140000
DTEND:20251228T150000
SUMMARY:事件2
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events.length, 2);
      expect(doc.events[0].summary, '事件1');
      expect(doc.events[1].summary, '事件2');
    });

    test('should parse all-day event', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:allday@example.com
DTSTART;VALUE=DATE:20251227
DTEND;VALUE=DATE:20251228
SUMMARY:全天事件
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events[0].allDay, true);
      expect(doc.events[0].dtStart, DateTime(2025, 12, 27));
    });

    test('should parse UTC datetime', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:utc@example.com
DTSTART:20251227T090000Z
DTEND:20251227T100000Z
SUMMARY:UTC事件
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      // UTC时间会被转换为本地时间
      expect(doc.events[0].dtStart, isNotNull);
    });

    test('should unescape text correctly', () {
      const content = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
UID:escape@example.com
DTSTART:20251227T090000
DTEND:20251227T100000
SUMMARY:逗号\\,分号\\;和换行\\n测试
END:VEVENT
END:VCALENDAR
''';

      final doc = ICalendarDocument.parse(content);

      expect(doc.events[0].summary, '逗号,分号;和换行\n测试');
    });
  });

  group('ICalendarSerializer', () {
    test('should serialize VEvent correctly', () {
      final event = VEvent(
        uid: 'test@example.com',
        dtStart: DateTime(2025, 12, 27, 9, 0),
        dtEnd: DateTime(2025, 12, 27, 10, 0),
        summary: '测试事件',
        description: '事件描述',
        location: '测试地点',
      );

      final doc = ICalendarDocument(events: [event]);
      final output = doc.serialize();

      expect(output, contains('BEGIN:VCALENDAR'));
      expect(output, contains('VERSION:2.0'));
      expect(output, contains('BEGIN:VEVENT'));
      expect(output, contains('UID:test@example.com'));
      expect(output, contains('SUMMARY:测试事件'));
      expect(output, contains('DESCRIPTION:事件描述'));
      expect(output, contains('LOCATION:测试地点'));
      expect(output, contains('END:VEVENT'));
      expect(output, contains('END:VCALENDAR'));
    });

    test('should serialize all-day event correctly', () {
      final event = VEvent(
        uid: 'allday@example.com',
        dtStart: DateTime(2025, 12, 27),
        dtEnd: DateTime(2025, 12, 27),
        summary: '全天事件',
        allDay: true,
      );

      final doc = ICalendarDocument(events: [event]);
      final output = doc.serialize();

      expect(output, contains('DTSTART;VALUE=DATE:20251227'));
    });

    test('should serialize VALARM correctly', () {
      final event = VEvent(
        uid: 'alarm@example.com',
        dtStart: DateTime(2025, 12, 27, 9, 0),
        dtEnd: DateTime(2025, 12, 27, 10, 0),
        summary: '带提醒的事件',
        alarms: [const VAlarm(trigger: Duration(minutes: 15))],
      );

      final doc = ICalendarDocument(events: [event]);
      final output = doc.serialize();

      expect(output, contains('BEGIN:VALARM'));
      expect(output, contains('TRIGGER:-PT15M'));
      expect(output, contains('ACTION:DISPLAY'));
      expect(output, contains('END:VALARM'));
    });

    test('should escape special characters', () {
      final event = VEvent(
        uid: 'escape@example.com',
        dtStart: DateTime(2025, 12, 27, 9, 0),
        dtEnd: DateTime(2025, 12, 27, 10, 0),
        summary: '逗号,分号;测试',
      );

      final doc = ICalendarDocument(events: [event]);
      final output = doc.serialize();

      expect(output, contains(r'逗号\,分号\;测试'));
    });

    test('formatDateTime should format correctly', () {
      final dt = DateTime(2025, 12, 27, 9, 5, 30);
      final result = ICalendarSerializer.formatDateTime(dt);
      expect(result, '20251227T090530');
    });

    test('formatDate should format correctly', () {
      final dt = DateTime(2025, 12, 27);
      final result = ICalendarSerializer.formatDate(dt);
      expect(result, '20251227');
    });
  });

  group('ICalendarParser.parseDateTime', () {
    test('should parse date format', () {
      final result = ICalendarParser.parseDateTime('20251227');
      expect(result, DateTime(2025, 12, 27));
    });

    test('should parse datetime format', () {
      final result = ICalendarParser.parseDateTime('20251227T090530');
      expect(result, DateTime(2025, 12, 27, 9, 5, 30));
    });

    test('should parse UTC datetime format', () {
      final result = ICalendarParser.parseDateTime('20251227T090000Z');
      // UTC时间会被转换为本地时间
      expect(result, isNotNull);
    });
  });

  group('Round-trip test', () {
    test('should parse and serialize back to equivalent format', () {
      final original = VEvent(
        uid: 'roundtrip@example.com',
        dtStart: DateTime(2025, 12, 27, 9, 0),
        dtEnd: DateTime(2025, 12, 27, 10, 0),
        summary: '往返测试',
        description: '测试描述',
        location: '测试地点',
        rrule: 'FREQ=WEEKLY',
        alarms: [const VAlarm(trigger: Duration(minutes: 15))],
      );

      // 序列化
      final doc1 = ICalendarDocument(events: [original]);
      final serialized = doc1.serialize();

      // 反序列化
      final doc2 = ICalendarDocument.parse(serialized);

      expect(doc2.events.length, 1);
      expect(doc2.events[0].uid, original.uid);
      expect(doc2.events[0].summary, original.summary);
      expect(doc2.events[0].description, original.description);
      expect(doc2.events[0].location, original.location);
      expect(doc2.events[0].rrule, original.rrule);
      expect(doc2.events[0].alarms.length, 1);
    });
  });
}
