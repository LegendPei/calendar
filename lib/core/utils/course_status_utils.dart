// 课程状态计算工具类
import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../models/semester.dart';

/// 课程状态枚举
enum CourseStatus {
  /// 已上课（过去的课程）
  completed,

  /// 今天的课程（但还没开始）
  today,

  /// 正在上课
  ongoing,

  /// 未来的课程
  upcoming,
}

/// 课程状态工具类
class CourseStatusUtils {
  CourseStatusUtils._();

  /// 获取课程在指定周的状态
  ///
  /// [course] 课程
  /// [semester] 学期信息
  /// [schedule] 课程表配置（用于获取时间）
  /// [targetWeek] 目标周次
  /// [now] 当前时间（可选，用于测试）
  static CourseStatus getCourseStatus({
    required Course course,
    required Semester semester,
    required CourseSchedule schedule,
    required int targetWeek,
    DateTime? now,
  }) {
    now ??= DateTime.now();

    // 获取当前周次
    final currentWeek = semester.getWeekNumber(now);

    // 如果目标周在当前周之前，课程已完成
    if (targetWeek < currentWeek) {
      return CourseStatus.completed;
    }

    // 如果目标周在当前周之后，课程是未来的
    if (targetWeek > currentWeek) {
      return CourseStatus.upcoming;
    }

    // 目标周是当前周，需要进一步判断
    final todayWeekday = now.weekday; // 1=周一, 7=周日

    // 如果课程在今天之前的日期
    if (course.dayOfWeek < todayWeekday) {
      return CourseStatus.completed;
    }

    // 如果课程在今天之后的日期
    if (course.dayOfWeek > todayWeekday) {
      return CourseStatus.upcoming;
    }

    // 课程是今天，检查时间
    final courseStartTime = schedule.getTimeSlot(course.startSection);
    final courseEndTime = schedule.getTimeSlot(course.endSection);

    if (courseStartTime == null || courseEndTime == null) {
      return CourseStatus.today;
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes =
        courseStartTime.startTime.hour * 60 + courseStartTime.startTime.minute;
    final endMinutes =
        courseEndTime.endTime.hour * 60 + courseEndTime.endTime.minute;

    // 判断当前时间与课程时间的关系
    if (nowMinutes < startMinutes) {
      // 还没开始
      return CourseStatus.today;
    } else if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
      // 正在上课
      return CourseStatus.ongoing;
    } else {
      // 已经结束
      return CourseStatus.completed;
    }
  }

  /// 判断课程是否是今天的课程（不考虑时间）
  static bool isCourseToday({
    required Course course,
    required Semester semester,
    required int targetWeek,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final currentWeek = semester.getWeekNumber(now);
    final todayWeekday = now.weekday;

    return targetWeek == currentWeek && course.dayOfWeek == todayWeekday;
  }

  /// 获取今天的所有课程
  static List<Course> getTodayCourses({
    required List<Course> courses,
    required Semester semester,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final currentWeek = semester.getWeekNumber(now);
    final todayWeekday = now.weekday;

    return courses.where((course) {
      // 检查课程是否在今天（星期几匹配）
      if (course.dayOfWeek != todayWeekday) return false;

      // 检查课程是否在当前周有课
      return course.hasClassInWeek(currentWeek);
    }).toList()..sort((a, b) => a.startSection.compareTo(b.startSection));
  }

  /// 获取课程的时间字符串
  static String getCourseTimeString({
    required Course course,
    required CourseSchedule schedule,
  }) {
    final startSlot = schedule.getTimeSlot(course.startSection);
    final endSlot = schedule.getTimeSlot(course.endSection);

    if (startSlot == null || endSlot == null) {
      return course.sectionDescription;
    }

    return '${startSlot.startTimeString}-${endSlot.endTimeString}';
  }

  /// 获取下一节课（今天还没上的课程中最近的一节）
  static Course? getNextCourse({
    required List<Course> todayCourses,
    required CourseSchedule schedule,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final course in todayCourses) {
      final startSlot = schedule.getTimeSlot(course.startSection);
      if (startSlot == null) continue;

      final startMinutes =
          startSlot.startTime.hour * 60 + startSlot.startTime.minute;
      if (nowMinutes < startMinutes) {
        return course;
      }
    }

    return null;
  }

  /// 获取正在上的课程
  static Course? getOngoingCourse({
    required List<Course> todayCourses,
    required CourseSchedule schedule,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final course in todayCourses) {
      final startSlot = schedule.getTimeSlot(course.startSection);
      final endSlot = schedule.getTimeSlot(course.endSection);
      if (startSlot == null || endSlot == null) continue;

      final startMinutes =
          startSlot.startTime.hour * 60 + startSlot.startTime.minute;
      final endMinutes = endSlot.endTime.hour * 60 + endSlot.endTime.minute;

      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        return course;
      }
    }

    return null;
  }

  /// 统计今日课程情况
  static ({int total, int completed, int remaining}) getTodayCourseSummary({
    required List<Course> todayCourses,
    required CourseSchedule schedule,
    DateTime? now,
  }) {
    now ??= DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    int completed = 0;
    int remaining = 0;

    for (final course in todayCourses) {
      final endSlot = schedule.getTimeSlot(course.endSection);
      if (endSlot == null) {
        remaining++;
        continue;
      }

      final endMinutes = endSlot.endTime.hour * 60 + endSlot.endTime.minute;
      if (nowMinutes > endMinutes) {
        completed++;
      } else {
        remaining++;
      }
    }

    return (
      total: todayCourses.length,
      completed: completed,
      remaining: remaining,
    );
  }
}
