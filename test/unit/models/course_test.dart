// Course模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/course.dart';

void main() {
  group('Course', () {
    test('should create course with all fields', () {
      final now = DateTime.now();
      final course = Course(
        id: 'test-id',
        scheduleId: 'schedule-id',
        name: '高等数学',
        teacher: '张老师',
        location: 'A101',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        weeks: [1, 2, 3, 4, 5],
        color: 0xFFBBDEFB,
        note: '备注',
        createdAt: now,
        updatedAt: now,
      );

      expect(course.id, 'test-id');
      expect(course.name, '高等数学');
      expect(course.teacher, '张老师');
      expect(course.location, 'A101');
      expect(course.dayOfWeek, 1);
      expect(course.startSection, 1);
      expect(course.endSection, 2);
      expect(course.weeks, [1, 2, 3, 4, 5]);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final course = Course(
        id: 'test-id',
        scheduleId: 'schedule-id',
        name: '高等数学',
        teacher: '张老师',
        location: 'A101',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        weeks: [1, 2, 3],
        color: 0xFFBBDEFB,
        createdAt: now,
        updatedAt: now,
      );

      final map = course.toMap();

      expect(map['id'], 'test-id');
      expect(map['schedule_id'], 'schedule-id');
      expect(map['name'], '高等数学');
      expect(map['teacher'], '张老师');
      expect(map['location'], 'A101');
      expect(map['day_of_week'], 1);
      expect(map['start_section'], 1);
      expect(map['end_section'], 2);
      expect(map['weeks'], '[1,2,3]');
      expect(map['color'], 0xFFBBDEFB);
    });

    test('should deserialize from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'schedule_id': 'schedule-id',
        'name': '高等数学',
        'teacher': '张老师',
        'location': 'A101',
        'day_of_week': 1,
        'start_section': 1,
        'end_section': 2,
        'weeks': '[1,2,3,4,5]',
        'color': 0xFFBBDEFB,
        'note': null,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final course = Course.fromMap(map);

      expect(course.id, 'test-id');
      expect(course.name, '高等数学');
      expect(course.weeks, [1, 2, 3, 4, 5]);
      expect(course.dayOfWeek, 1);
    });

    group('sectionSpan', () {
      test('should return correct span for single section', () {
        final course = _createTestCourse(startSection: 1, endSection: 1);
        expect(course.sectionSpan, 1);
      });

      test('should return correct span for multiple sections', () {
        final course = _createTestCourse(startSection: 1, endSection: 2);
        expect(course.sectionSpan, 2);
      });

      test('should return correct span for 4 sections', () {
        final course = _createTestCourse(startSection: 3, endSection: 6);
        expect(course.sectionSpan, 4);
      });
    });

    group('hasClassInWeek', () {
      test('should return true for weeks in list', () {
        final course = _createTestCourse(weeks: [1, 3, 5, 7]);

        expect(course.hasClassInWeek(1), true);
        expect(course.hasClassInWeek(3), true);
        expect(course.hasClassInWeek(5), true);
        expect(course.hasClassInWeek(7), true);
      });

      test('should return false for weeks not in list', () {
        final course = _createTestCourse(weeks: [1, 3, 5, 7]);

        expect(course.hasClassInWeek(2), false);
        expect(course.hasClassInWeek(4), false);
        expect(course.hasClassInWeek(6), false);
        expect(course.hasClassInWeek(8), false);
      });
    });

    group('dayOfWeekName', () {
      test('should return correct name for each day', () {
        expect(_createTestCourse(dayOfWeek: 1).dayOfWeekName, '周一');
        expect(_createTestCourse(dayOfWeek: 2).dayOfWeekName, '周二');
        expect(_createTestCourse(dayOfWeek: 3).dayOfWeekName, '周三');
        expect(_createTestCourse(dayOfWeek: 4).dayOfWeekName, '周四');
        expect(_createTestCourse(dayOfWeek: 5).dayOfWeekName, '周五');
        expect(_createTestCourse(dayOfWeek: 6).dayOfWeekName, '周六');
        expect(_createTestCourse(dayOfWeek: 7).dayOfWeekName, '周日');
      });
    });

    group('sectionDescription', () {
      test('should return single section format', () {
        final course = _createTestCourse(startSection: 1, endSection: 1);
        expect(course.sectionDescription, '第1节');
      });

      test('should return range format', () {
        final course = _createTestCourse(startSection: 1, endSection: 2);
        expect(course.sectionDescription, '第1-2节');
      });
    });

    group('weeksDescription', () {
      test('should return continuous weeks format', () {
        final course = _createTestCourse(weeks: [1, 2, 3, 4, 5, 6, 7, 8]);
        expect(course.weeksDescription, '1-8周');
      });

      test('should return odd weeks format', () {
        final course = _createTestCourse(weeks: [1, 3, 5, 7, 9, 11, 13, 15]);
        expect(course.weeksDescription, '1-15周(单)');
      });

      test('should return even weeks format', () {
        final course = _createTestCourse(weeks: [2, 4, 6, 8, 10, 12, 14, 16]);
        expect(course.weeksDescription, '2-16周(双)');
      });

      test('should return single week format', () {
        final course = _createTestCourse(weeks: [5]);
        expect(course.weeksDescription, '第5周');
      });

      test('should return empty string for no weeks', () {
        final course = _createTestCourse(weeks: []);
        expect(course.weeksDescription, '');
      });
    });

    group('generateWeeks', () {
      test('should generate all weeks', () {
        final weeks = Course.generateWeeks(1, 16, type: 0);
        expect(weeks, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
      });

      test('should generate odd weeks only', () {
        final weeks = Course.generateWeeks(1, 16, type: 1);
        expect(weeks, [1, 3, 5, 7, 9, 11, 13, 15]);
      });

      test('should generate even weeks only', () {
        final weeks = Course.generateWeeks(1, 16, type: 2);
        expect(weeks, [2, 4, 6, 8, 10, 12, 14, 16]);
      });

      test('should respect start and end bounds', () {
        final weeks = Course.generateWeeks(5, 10, type: 0);
        expect(weeks, [5, 6, 7, 8, 9, 10]);
      });
    });

    test('copyWith should create new instance with updated fields', () {
      final course = _createTestCourse(name: '原始课程', dayOfWeek: 1);

      final updated = course.copyWith(name: '新课程名', dayOfWeek: 3);

      expect(updated.name, '新课程名');
      expect(updated.dayOfWeek, 3);
      expect(updated.id, course.id);
      expect(updated.scheduleId, course.scheduleId);
    });

    test('presetColors should contain 12 colors', () {
      expect(Course.presetColors.length, 12);
    });
  });
}

/// 创建测试用Course
Course _createTestCourse({
  String name = '测试课程',
  int dayOfWeek = 1,
  int startSection = 1,
  int endSection = 2,
  List<int> weeks = const [1, 2, 3, 4, 5, 6, 7, 8],
}) {
  final now = DateTime.now();
  return Course(
    id: 'test-id',
    scheduleId: 'schedule-id',
    name: name,
    dayOfWeek: dayOfWeek,
    startSection: startSection,
    endSection: endSection,
    weeks: weeks,
    color: 0xFFBBDEFB,
    createdAt: now,
    updatedAt: now,
  );
}
