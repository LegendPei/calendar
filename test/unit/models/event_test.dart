// Event模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/event.dart';

void main() {
  group('Event', () {
    test('should create event with Event.create', () {
      final event = Event.create(
        title: '测试事件',
        description: '测试描述',
        location: '测试地点',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 27, 11, 0),
        color: 0xFF1976D2,
      );

      expect(event.title, '测试事件');
      expect(event.description, '测试描述');
      expect(event.location, '测试地点');
      expect(event.allDay, false);
      expect(event.id, isNotEmpty);
      expect(event.uid, contains('@calendarapp'));
    });

    test('should serialize to map correctly', () {
      final event = Event.create(
        title: '测试事件',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 27, 11, 0),
      );

      final map = event.toMap();

      expect(map['title'], '测试事件');
      expect(map['id'], event.id);
      expect(map['uid'], event.uid);
      expect(map['start_time'], event.startTime.millisecondsSinceEpoch);
      expect(map['end_time'], event.endTime.millisecondsSinceEpoch);
      expect(map['all_day'], 0);
    });

    test('should deserialize from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'uid': 'test-uid@calendarapp',
        'title': '测试事件',
        'description': '测试描述',
        'location': '测试地点',
        'start_time': DateTime(2025, 12, 27, 10, 0).millisecondsSinceEpoch,
        'end_time': DateTime(2025, 12, 27, 11, 0).millisecondsSinceEpoch,
        'all_day': 0,
        'rrule': null,
        'color': 0xFF1976D2,
        'calendar_id': 'default',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final event = Event.fromMap(map);

      expect(event.id, 'test-id');
      expect(event.uid, 'test-uid@calendarapp');
      expect(event.title, '测试事件');
      expect(event.description, '测试描述');
      expect(event.location, '测试地点');
      expect(event.allDay, false);
      expect(event.color, 0xFF1976D2);
    });

    test('should generate valid UID', () {
      final uid = Event.generateUid();
      expect(uid, contains('@calendarapp'));
      expect(uid.length, greaterThan(10));
    });

    test('copyWith should create new instance with updated fields', () {
      final event = Event.create(
        title: '原始标题',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 27, 11, 0),
      );

      final updatedEvent = event.copyWith(title: '新标题');

      expect(updatedEvent.title, '新标题');
      expect(updatedEvent.id, event.id);
      expect(updatedEvent.startTime, event.startTime);
    });

    test('duration should return correct time difference', () {
      final event = Event.create(
        title: '测试事件',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 27, 12, 30),
      );

      expect(event.duration, const Duration(hours: 2, minutes: 30));
    });

    test('isMultiDay should return true for multi-day events', () {
      final event = Event.create(
        title: '多天事件',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 28, 10, 0),
      );

      expect(event.isMultiDay, true);
    });

    test('isMultiDay should return false for same-day events', () {
      final event = Event.create(
        title: '单天事件',
        startTime: DateTime(2025, 12, 27, 10, 0),
        endTime: DateTime(2025, 12, 27, 12, 0),
      );

      expect(event.isMultiDay, false);
    });
  });
}
