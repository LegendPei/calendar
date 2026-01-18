// CourseSchedule和CourseTime模型测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/course_schedule.dart';
import 'package:calender_app/models/course_time.dart';

void main() {
  group('CourseTime', () {
    test('should create course time with all fields', () {
      final courseTime = CourseTime(
        section: 1,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 45),
      );

      expect(courseTime.section, 1);
      expect(courseTime.startTime.hour, 8);
      expect(courseTime.startTime.minute, 0);
      expect(courseTime.endTime.hour, 8);
      expect(courseTime.endTime.minute, 45);
    });

    test('should serialize to map correctly', () {
      final courseTime = CourseTime(
        section: 1,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 45),
      );

      final map = courseTime.toMap();

      expect(map['section'], 1);
      expect(map['start_hour'], 8);
      expect(map['start_minute'], 0);
      expect(map['end_hour'], 8);
      expect(map['end_minute'], 45);
    });

    test('should deserialize from map correctly', () {
      final map = {
        'section': 1,
        'start_hour': 8,
        'start_minute': 0,
        'end_hour': 8,
        'end_minute': 45,
      };

      final courseTime = CourseTime.fromMap(map);

      expect(courseTime.section, 1);
      expect(courseTime.startTime.hour, 8);
      expect(courseTime.startTime.minute, 0);
      expect(courseTime.endTime.hour, 8);
      expect(courseTime.endTime.minute, 45);
    });

    test('startTimeString should return formatted time', () {
      final courseTime = CourseTime(
        section: 1,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 45),
      );

      expect(courseTime.startTimeString, '08:00');
    });

    test('endTimeString should return formatted time', () {
      final courseTime = CourseTime(
        section: 1,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 45),
      );

      expect(courseTime.endTimeString, '08:45');
    });

    test('timeRangeString should return formatted range', () {
      final courseTime = CourseTime(
        section: 1,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 45),
      );

      expect(courseTime.timeRangeString, '08:00-08:45');
    });

    group('defaultSchedule', () {
      test('should return 8 time slots', () {
        final schedule = CourseTime.defaultSchedule;
        expect(schedule.length, 8);
      });

      test('should have sequential sections', () {
        final schedule = CourseTime.defaultSchedule;
        for (int i = 0; i < schedule.length; i++) {
          expect(schedule[i].section, i + 1);
        }
      });

      test('first slot should start at 8:30', () {
        final schedule = CourseTime.defaultSchedule;
        expect(schedule.first.startTime.hour, 8);
        expect(schedule.first.startTime.minute, 30);
      });
    });

    test('defaultLunchAfterSection should be 4', () {
      expect(CourseTime.defaultLunchAfterSection, 4);
    });
  });

  group('CourseSchedule', () {
    test('should create schedule with all fields', () {
      final now = DateTime.now();
      final schedule = CourseSchedule(
        id: 'test-id',
        name: '测试课程表',
        semesterId: 'semester-id',
        timeSlots: CourseTime.defaultSchedule,
        daysPerWeek: 5,
        lunchAfterSection: 4,
        createdAt: now,
        updatedAt: now,
      );

      expect(schedule.id, 'test-id');
      expect(schedule.name, '测试课程表');
      expect(schedule.semesterId, 'semester-id');
      expect(schedule.daysPerWeek, 5);
      expect(schedule.lunchAfterSection, 4);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final schedule = CourseSchedule(
        id: 'test-id',
        name: '测试课程表',
        semesterId: 'semester-id',
        timeSlots: CourseTime.defaultSchedule,
        daysPerWeek: 5,
        lunchAfterSection: 4,
        createdAt: now,
        updatedAt: now,
      );

      final map = schedule.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], '测试课程表');
      expect(map['semester_id'], 'semester-id');
      expect(map['days_per_week'], 5);
      expect(map['lunch_after_section'], 4);
      expect(map['time_slots'], isNotNull);
    });

    test('should deserialize from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'name': '测试课程表',
        'semester_id': 'semester-id',
        'time_slots':
            '[{"section":1,"start_hour":8,"start_minute":0,"end_hour":8,"end_minute":45}]',
        'days_per_week': 5,
        'lunch_after_section': 4,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final schedule = CourseSchedule.fromMap(map);

      expect(schedule.id, 'test-id');
      expect(schedule.name, '测试课程表');
      expect(schedule.semesterId, 'semester-id');
      expect(schedule.daysPerWeek, 5);
      expect(schedule.timeSlots.length, 1);
    });

    group('totalSections', () {
      test('should return correct count', () {
        final schedule = _createTestSchedule();
        expect(schedule.totalSections, 8);
      });
    });

    group('getTimeSlot', () {
      test('should return correct time slot', () {
        final schedule = _createTestSchedule();
        final slot = schedule.getTimeSlot(1);

        expect(slot, isNotNull);
        expect(slot!.section, 1);
      });

      test('should return null for invalid section', () {
        final schedule = _createTestSchedule();
        final slot = schedule.getTimeSlot(100);

        expect(slot, isNull);
      });
    });

    group('morningSlots', () {
      test('should return slots before lunch', () {
        final schedule = _createTestSchedule();
        final morning = schedule.morningSlots;

        expect(morning.length, 4);
        expect(morning.every((s) => s.section <= 4), true);
      });
    });

    group('afternoonSlots', () {
      test('should return slots after lunch', () {
        final schedule = _createTestSchedule();
        final afternoon = schedule.afternoonSlots;

        expect(afternoon.length, 4);
        expect(afternoon.every((s) => s.section > 4), true);
      });
    });

    group('dayNames', () {
      test('should return 5 days for 5-day week', () {
        final schedule = _createTestSchedule(daysPerWeek: 5);
        expect(schedule.dayNames, ['周一', '周二', '周三', '周四', '周五']);
      });

      test('should return 7 days for 7-day week', () {
        final schedule = _createTestSchedule(daysPerWeek: 7);
        expect(schedule.dayNames, ['周一', '周二', '周三', '周四', '周五', '周六', '周日']);
      });
    });

    test('copyWith should create new instance with updated fields', () {
      final schedule = _createTestSchedule();

      final updated = schedule.copyWith(name: '新名称', daysPerWeek: 7);

      expect(updated.name, '新名称');
      expect(updated.daysPerWeek, 7);
      expect(updated.id, schedule.id);
      expect(updated.semesterId, schedule.semesterId);
    });
  });
}

/// 创建测试用CourseSchedule
CourseSchedule _createTestSchedule({
  int daysPerWeek = 5,
  int lunchAfterSection = 4,
}) {
  final now = DateTime.now();
  return CourseSchedule(
    id: 'test-id',
    name: '测试课程表',
    semesterId: 'semester-id',
    timeSlots: CourseTime.defaultSchedule,
    daysPerWeek: daysPerWeek,
    lunchAfterSection: lunchAfterSection,
    createdAt: now,
    updatedAt: now,
  );
}
