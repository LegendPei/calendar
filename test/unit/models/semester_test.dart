// Semester模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/semester.dart';

void main() {
  group('Semester', () {
    test('should create semester with all fields', () {
      final semester = Semester(
        id: 'test-id',
        name: '2025春季学期',
        startDate: DateTime(2025, 2, 17),
        totalWeeks: 20,
        isCurrent: true,
        createdAt: DateTime.now(),
      );

      expect(semester.id, 'test-id');
      expect(semester.name, '2025春季学期');
      expect(semester.totalWeeks, 20);
      expect(semester.isCurrent, true);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final startDate = DateTime(2025, 2, 17);
      final semester = Semester(
        id: 'test-id',
        name: '2025春季学期',
        startDate: startDate,
        totalWeeks: 20,
        isCurrent: true,
        createdAt: now,
      );

      final map = semester.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], '2025春季学期');
      expect(map['start_date'], startDate.millisecondsSinceEpoch);
      expect(map['total_weeks'], 20);
      expect(map['is_current'], 1);
      expect(map['created_at'], now.millisecondsSinceEpoch);
    });

    test('should deserialize from map correctly', () {
      final now = DateTime.now();
      final startDate = DateTime(2025, 2, 17);
      final map = {
        'id': 'test-id',
        'name': '2025春季学期',
        'start_date': startDate.millisecondsSinceEpoch,
        'total_weeks': 20,
        'is_current': 1,
        'created_at': now.millisecondsSinceEpoch,
      };

      final semester = Semester.fromMap(map);

      expect(semester.id, 'test-id');
      expect(semester.name, '2025春季学期');
      expect(semester.totalWeeks, 20);
      expect(semester.isCurrent, true);
    });

    group('getWeekNumber', () {
      test('should return 1 for dates in first week', () {
        final semester = Semester(
          id: 'test-id',
          name: '测试学期',
          startDate: DateTime(2025, 2, 17), // 周一
          totalWeeks: 20,
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        // 开学第一天
        expect(semester.getWeekNumber(DateTime(2025, 2, 17)), 1);
        // 开学第一周周日
        expect(semester.getWeekNumber(DateTime(2025, 2, 23)), 1);
      });

      test('should return correct week for later weeks', () {
        final semester = Semester(
          id: 'test-id',
          name: '测试学期',
          startDate: DateTime(2025, 2, 17),
          totalWeeks: 20,
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        // 第二周周一
        expect(semester.getWeekNumber(DateTime(2025, 2, 24)), 2);
        // 第三周
        expect(semester.getWeekNumber(DateTime(2025, 3, 3)), 3);
        // 第十周
        expect(semester.getWeekNumber(DateTime(2025, 4, 21)), 10);
      });

      test(
        'should return 1 for dates before semester start (clamped to valid range)',
        () {
          final semester = Semester(
            id: 'test-id',
            name: '测试学期',
            startDate: DateTime(2025, 2, 17),
            totalWeeks: 20,
            isCurrent: true,
            createdAt: DateTime.now(),
          );

          // 实现会将周次限制在有效范围[1, totalWeeks]内
          expect(semester.getWeekNumber(DateTime(2025, 2, 16)), 1);
          expect(semester.getWeekNumber(DateTime(2025, 1, 1)), 1);
        },
      );

      test(
        'should return totalWeeks for dates after semester end (clamped to valid range)',
        () {
          final semester = Semester(
            id: 'test-id',
            name: '测试学期',
            startDate: DateTime(2025, 2, 17),
            totalWeeks: 20,
            isCurrent: true,
            createdAt: DateTime.now(),
          );

          // 实现会将周次限制在有效范围[1, totalWeeks]内
          expect(semester.getWeekNumber(DateTime(2025, 7, 14)), 20);
        },
      );
      test(
        'should return 1 for dates before semester start (clamped to valid range)',
        () {
          final semester = Semester(
            id: 'test-id',
            name: '测试学期',
            startDate: DateTime(2025, 2, 17),
            totalWeeks: 20,
            isCurrent: true,
            createdAt: DateTime.now(),
          );

          // 实现会将周次限制在有效范围[1, totalWeeks]内
          expect(semester.getWeekNumber(DateTime(2025, 2, 16)), 1);
          expect(semester.getWeekNumber(DateTime(2025, 1, 1)), 1);
        },
      );

      test(
        'should return totalWeeks for dates after semester end (clamped to valid range)',
        () {
          final semester = Semester(
            id: 'test-id',
            name: '测试学期',
            startDate: DateTime(2025, 2, 17),
            totalWeeks: 20,
            isCurrent: true,
            createdAt: DateTime.now(),
          );

          // 实现会将周次限制在有效范围[1, totalWeeks]内
          expect(semester.getWeekNumber(DateTime(2025, 7, 14)), 20);
        },
      );
    });

    group('getWeekDateRange', () {
      test('should return correct date range for week 1', () {
        final semester = Semester(
          id: 'test-id',
          name: '测试学期',
          startDate: DateTime(2025, 2, 17),
          totalWeeks: 20,
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        final range = semester.getWeekDateRange(1);

        expect(range.start, DateTime(2025, 2, 17));
        expect(range.end.day, 23);
        expect(range.end.month, 2);
      });

      test('should return correct date range for week 10', () {
        final semester = Semester(
          id: 'test-id',
          name: '测试学期',
          startDate: DateTime(2025, 2, 17),
          totalWeeks: 20,
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        final range = semester.getWeekDateRange(10);
        final expectedStart = DateTime(
          2025,
          2,
          17,
        ).add(const Duration(days: 63));

        expect(range.start, expectedStart);
      });
    });

    group('endDate', () {
      test('should return correct end date', () {
        final semester = Semester(
          id: 'test-id',
          name: '测试学期',
          startDate: DateTime(2025, 2, 17),
          totalWeeks: 20,
          isCurrent: true,
          createdAt: DateTime.now(),
        );

        // 20周 = 140天 - 1天（最后一天）
        final expectedEnd = DateTime(
          2025,
          2,
          17,
        ).add(const Duration(days: 139));
        expect(semester.endDate, expectedEnd);
      });
    });

    test('copyWith should create new instance with updated fields', () {
      final semester = Semester(
        id: 'test-id',
        name: '原始名称',
        startDate: DateTime(2025, 2, 17),
        totalWeeks: 20,
        isCurrent: false,
        createdAt: DateTime.now(),
      );

      final updated = semester.copyWith(name: '新名称', isCurrent: true);

      expect(updated.name, '新名称');
      expect(updated.isCurrent, true);
      expect(updated.id, 'test-id');
      expect(updated.totalWeeks, 20);
    });
  });
}
