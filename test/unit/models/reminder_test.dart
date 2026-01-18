// Reminder模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/reminder.dart';

void main() {
  group('Reminder', () {
    test('should create reminder with Reminder.create', () {
      final eventStartTime = DateTime(2025, 12, 27, 10, 0);
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(minutes: 15),
        eventStartTime: eventStartTime,
      );

      expect(reminder.eventId, 'event-123');
      expect(reminder.triggerBefore, const Duration(minutes: 15));
      expect(reminder.triggerTime, DateTime(2025, 12, 27, 9, 45));
      expect(reminder.isTriggered, false);
      expect(reminder.type, ReminderType.display);
    });

    test('should calculate trigger time correctly', () {
      final eventStart = DateTime(2025, 12, 27, 10, 0);

      expect(
        Reminder.calculateTriggerTime(eventStart, Duration.zero),
        DateTime(2025, 12, 27, 10, 0),
      );
      expect(
        Reminder.calculateTriggerTime(eventStart, const Duration(minutes: 15)),
        DateTime(2025, 12, 27, 9, 45),
      );
      expect(
        Reminder.calculateTriggerTime(eventStart, const Duration(hours: 1)),
        DateTime(2025, 12, 27, 9, 0),
      );
      expect(
        Reminder.calculateTriggerTime(eventStart, const Duration(days: 1)),
        DateTime(2025, 12, 26, 10, 0),
      );
    });

    test('should serialize to map correctly', () {
      final triggerTime = DateTime(2025, 12, 27, 9, 45);
      final reminder = Reminder(
        id: 'reminder-123',
        eventId: 'event-456',
        triggerBefore: const Duration(minutes: 15),
        triggerTime: triggerTime,
        type: ReminderType.display,
        isTriggered: false,
      );

      final map = reminder.toMap();

      expect(map['id'], 'reminder-123');
      expect(map['event_id'], 'event-456');
      expect(map['trigger_before'], 15 * 60 * 1000); // milliseconds
      expect(map['trigger_time'], triggerTime.millisecondsSinceEpoch);
      expect(map['trigger_type'], 'DISPLAY');
      expect(map['is_triggered'], 0);
    });

    test('should deserialize from map correctly', () {
      final triggerTime = DateTime(2025, 12, 27, 9, 45);
      final map = {
        'id': 'reminder-123',
        'event_id': 'event-456',
        'trigger_before': 15 * 60 * 1000,
        'trigger_time': triggerTime.millisecondsSinceEpoch,
        'trigger_type': 'DISPLAY',
        'is_triggered': 0,
      };

      final reminder = Reminder.fromMap(map);

      expect(reminder.id, 'reminder-123');
      expect(reminder.eventId, 'event-456');
      expect(reminder.triggerBefore, const Duration(minutes: 15));
      expect(reminder.triggerTime, triggerTime);
      expect(reminder.type, ReminderType.display);
      expect(reminder.isTriggered, false);
    });

    test('copyWith should create new instance with updated fields', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(minutes: 15),
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      final updated = reminder.copyWith(isTriggered: true);

      expect(updated.isTriggered, true);
      expect(updated.id, reminder.id);
      expect(updated.eventId, reminder.eventId);
    });

    test('displayText should return correct text', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(minutes: 15),
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      expect(reminder.displayText, '15分钟前');
    });
  });

  group('ReminderOption', () {
    test('presets should contain common options', () {
      expect(ReminderOption.presets.length, greaterThan(5));

      final labels = ReminderOption.presets.map((o) => o.label).toList();
      expect(labels, contains('准时'));
      expect(labels, contains('15分钟前'));
      expect(labels, contains('1小时前'));
      expect(labels, contains('1天前'));
    });

    test('findByDuration should find matching option', () {
      final option = ReminderOption.findByDuration(const Duration(minutes: 15));
      expect(option, isNotNull);
      expect(option!.label, '15分钟前');
    });

    test('findByDuration should return null for non-preset', () {
      final option = ReminderOption.findByDuration(const Duration(minutes: 17));
      expect(option, isNull);
    });

    test('formatDuration should format correctly', () {
      expect(ReminderOption.formatDuration(Duration.zero), '准时');
      expect(
        ReminderOption.formatDuration(const Duration(minutes: 15)),
        '15分钟前',
      );
      expect(ReminderOption.formatDuration(const Duration(hours: 1)), '1小时前');
      expect(ReminderOption.formatDuration(const Duration(days: 1)), '1天前');
      expect(
        ReminderOption.formatDuration(const Duration(minutes: 45)),
        '45分钟前',
      );
      expect(ReminderOption.formatDuration(const Duration(hours: 3)), '3小时前');
      expect(ReminderOption.formatDuration(const Duration(days: 3)), '3天前');
    });
  });

  group('Reminder trigger value (RFC5545)', () {
    test('should generate correct trigger value for zero duration', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: Duration.zero,
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      expect(reminder.triggerValue, 'PT0S');
    });

    test('should generate correct trigger value for minutes', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(minutes: 15),
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      expect(reminder.triggerValue, '-PT15M');
    });

    test('should generate correct trigger value for hours', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(hours: 2),
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      expect(reminder.triggerValue, '-PT2H');
    });

    test('should generate correct trigger value for days', () {
      final reminder = Reminder.create(
        eventId: 'event-123',
        triggerBefore: const Duration(days: 1),
        eventStartTime: DateTime(2025, 12, 27, 10, 0),
      );

      expect(reminder.triggerValue, '-P1D');
    });

    test('parseTrigger should parse -PT15M correctly', () {
      final duration = Reminder.parseTrigger('-PT15M');
      expect(duration, const Duration(minutes: 15));
    });

    test('parseTrigger should parse -P1D correctly', () {
      final duration = Reminder.parseTrigger('-P1D');
      expect(duration, const Duration(days: 1));
    });

    test('parseTrigger should parse -PT2H30M correctly', () {
      final duration = Reminder.parseTrigger('-PT2H30M');
      expect(duration, const Duration(hours: 2, minutes: 30));
    });

    test('parseTrigger should parse PT0S correctly', () {
      final duration = Reminder.parseTrigger('PT0S');
      expect(duration, Duration.zero);
    });
  });
}
