import 'package:flutter_test/flutter_test.dart';

import 'package:calender_app/core/utils/course_status_utils.dart';
import 'package:calender_app/models/course.dart';
import 'package:calender_app/models/course_schedule.dart';
import 'package:calender_app/models/course_time.dart';
import 'package:calender_app/models/semester.dart';

void main() {
  group('CourseStatusUtils', () {
    late Semester semester;
    late CourseSchedule schedule;
    late Course course;

    setUp(() {
      // 创建一个从2025-01-06开始的学期（周一）
      semester = Semester(
        id: 'test-semester',
        name: '2024-2025学年第二学期',
        startDate: DateTime(2025, 1, 6), // 周一
        totalWeeks: 20,
        isCurrent: true,
        createdAt: DateTime.now(),
      );

      // 创建课程表
      schedule = CourseSchedule(
        id: 'test-schedule',
        name: '默认课程表',
        semesterId: semester.id,
        timeSlots: CourseTime.defaultSchedule,
        daysPerWeek: 5,
        lunchAfterSection: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 创建一门课程：周一 1-2节，1-16周
      course = Course(
        id: 'test-course',
        scheduleId: schedule.id,
        name: '高等数学',
        teacher: '张老师',
        location: 'A101',
        dayOfWeek: 1, // 周一
        startSection: 1,
        endSection: 2,
        weeks: List.generate(16, (i) => i + 1), // 1-16周
        color: 0xFFBBDEFB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('getCourseStatus', () {
      test('应返回completed当目标周在当前周之前', () {
        // 当前是第3周
        final now = DateTime(2025, 1, 20, 10, 0); // 第3周周一

        final status = CourseStatusUtils.getCourseStatus(
          course: course,
          semester: semester,
          schedule: schedule,
          targetWeek: 1, // 第1周
          now: now,
        );

        expect(status, CourseStatus.completed);
      });

      test('应返回upcoming当目标周在当前周之后', () {
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final status = CourseStatusUtils.getCourseStatus(
          course: course,
          semester: semester,
          schedule: schedule,
          targetWeek: 5, // 第5周
          now: now,
        );

        expect(status, CourseStatus.upcoming);
      });

      test('应返回completed当课程在当前周今天之前的日期', () {
        // 创建周二的课程
        final tuesdayCourse = course.copyWith(dayOfWeek: 2);
        final now = DateTime(2025, 1, 8, 10, 0); // 第1周周三

        final status = CourseStatusUtils.getCourseStatus(
          course: tuesdayCourse,
          semester: semester,
          schedule: schedule,
          targetWeek: 1,
          now: now,
        );

        expect(status, CourseStatus.completed);
      });

      test('应返回upcoming当课程在当前周今天之后的日期', () {
        // 创建周五的课程
        final fridayCourse = course.copyWith(dayOfWeek: 5);
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final status = CourseStatusUtils.getCourseStatus(
          course: fridayCourse,
          semester: semester,
          schedule: schedule,
          targetWeek: 1,
          now: now,
        );

        expect(status, CourseStatus.upcoming);
      });

      test('应返回today当课程是今天但还没开始', () {
        // 今天是周一，课程8:30开始，当前时间是8:00
        final now = DateTime(2025, 1, 6, 8, 0); // 第1周周一 8:00

        final status = CourseStatusUtils.getCourseStatus(
          course: course,
          semester: semester,
          schedule: schedule,
          targetWeek: 1,
          now: now,
        );

        expect(status, CourseStatus.today);
      });

      test('应返回ongoing当正在上课', () {
        // 今天是周一，课程8:30-10:10，当前时间是9:00
        final now = DateTime(2025, 1, 6, 9, 0); // 第1周周一 9:00

        final status = CourseStatusUtils.getCourseStatus(
          course: course,
          semester: semester,
          schedule: schedule,
          targetWeek: 1,
          now: now,
        );

        expect(status, CourseStatus.ongoing);
      });

      test('应返回completed当今天的课程已经结束', () {
        // 今天是周一，课程8:30-10:10，当前时间是11:00
        final now = DateTime(2025, 1, 6, 11, 0); // 第1周周一 11:00

        final status = CourseStatusUtils.getCourseStatus(
          course: course,
          semester: semester,
          schedule: schedule,
          targetWeek: 1,
          now: now,
        );

        expect(status, CourseStatus.completed);
      });
    });

    group('isCourseToday', () {
      test('应返回true当课程是今天', () {
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.isCourseToday(
          course: course,
          semester: semester,
          targetWeek: 1,
          now: now,
        );

        expect(result, true);
      });

      test('应返回false当课程不是今天', () {
        // 创建周二的课程
        final tuesdayCourse = course.copyWith(dayOfWeek: 2);
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.isCourseToday(
          course: tuesdayCourse,
          semester: semester,
          targetWeek: 1,
          now: now,
        );

        expect(result, false);
      });

      test('应返回false当目标周不是当前周', () {
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.isCourseToday(
          course: course,
          semester: semester,
          targetWeek: 2, // 不是当前周
          now: now,
        );

        expect(result, false);
      });
    });

    group('getTodayCourses', () {
      test('应返回今天的课程并按节次排序', () {
        final courses = [
          course, // 周一 1-2节
          course.copyWith(id: 'c2', startSection: 5, endSection: 6), // 周一 5-6节
          course.copyWith(id: 'c3', dayOfWeek: 2), // 周二
        ];
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.getTodayCourses(
          courses: courses,
          semester: semester,
          now: now,
        );

        expect(result.length, 2);
        expect(result[0].id, 'test-course');
        expect(result[1].id, 'c2');
      });

      test('应返回空列表当今天没有课', () {
        final courses = [
          course.copyWith(dayOfWeek: 2), // 周二
        ];
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.getTodayCourses(
          courses: courses,
          semester: semester,
          now: now,
        );

        expect(result, isEmpty);
      });

      test('应过滤掉不在当前周的课程', () {
        final courses = [
          course.copyWith(weeks: [2, 3, 4]), // 只在2-4周有课
        ];
        final now = DateTime(2025, 1, 6, 10, 0); // 第1周周一

        final result = CourseStatusUtils.getTodayCourses(
          courses: courses,
          semester: semester,
          now: now,
        );

        expect(result, isEmpty);
      });
    });

    group('getCourseTimeString', () {
      test('应返回正确的时间字符串', () {
        final result = CourseStatusUtils.getCourseTimeString(
          course: course,
          schedule: schedule,
        );

        expect(result, '08:30-10:10');
      });
    });

    group('getTodayCourseSummary', () {
      test('应返回正确的课程统计', () {
        final todayCourses = [
          course, // 1-2节 8:30-10:10
          course.copyWith(id: 'c2', startSection: 3, endSection: 4), // 3-4节 10:20-12:00
          course.copyWith(id: 'c3', startSection: 5, endSection: 6), // 5-6节 14:00-15:40
        ];
        // 当前时间 11:00，第一节课已完成，第二节课正在上
        final now = DateTime(2025, 1, 6, 11, 0);

        final result = CourseStatusUtils.getTodayCourseSummary(
          todayCourses: todayCourses,
          schedule: schedule,
          now: now,
        );

        expect(result.total, 3);
        expect(result.completed, 1); // 第1-2节已完成
        expect(result.remaining, 2); // 第3-4节和5-6节还没完成
      });
    });

    group('getOngoingCourse', () {
      test('应返回正在上的课程', () {
        final todayCourses = [
          course, // 1-2节 8:30-10:10
          course.copyWith(id: 'c2', startSection: 3, endSection: 4), // 3-4节
        ];
        final now = DateTime(2025, 1, 6, 9, 0); // 9:00，在第1-2节时间内

        final result = CourseStatusUtils.getOngoingCourse(
          todayCourses: todayCourses,
          schedule: schedule,
          now: now,
        );

        expect(result, isNotNull);
        expect(result!.id, 'test-course');
      });

      test('应返回null当没有正在上的课程', () {
        final todayCourses = [
          course, // 1-2节 8:30-10:10
        ];
        final now = DateTime(2025, 1, 6, 12, 0); // 12:00，不在课程时间内

        final result = CourseStatusUtils.getOngoingCourse(
          todayCourses: todayCourses,
          schedule: schedule,
          now: now,
        );

        expect(result, isNull);
      });
    });

    group('getNextCourse', () {
      test('应返回下一节课', () {
        final todayCourses = [
          course, // 1-2节 8:30-10:10
          course.copyWith(id: 'c2', startSection: 3, endSection: 4), // 3-4节 10:20-12:00
        ];
        final now = DateTime(2025, 1, 6, 8, 0); // 8:00，还没开始

        final result = CourseStatusUtils.getNextCourse(
          todayCourses: todayCourses,
          schedule: schedule,
          now: now,
        );

        expect(result, isNotNull);
        expect(result!.id, 'test-course');
      });

      test('应返回null当没有下一节课', () {
        final todayCourses = [
          course, // 1-2节 8:30-10:10
        ];
        final now = DateTime(2025, 1, 6, 11, 0); // 11:00，课程已结束

        final result = CourseStatusUtils.getNextCourse(
          todayCourses: todayCourses,
          schedule: schedule,
          now: now,
        );

        expect(result, isNull);
      });
    });
  });
}
