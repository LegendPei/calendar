// 冲突检测服务 - 检测日程与课程之间的时间冲突
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/event.dart';
import '../models/semester.dart';
import 'course_service.dart';

/// 冲突信息
class ConflictInfo {
  /// 冲突的课程列表
  final List<Course> conflictingCourses;

  /// 冲突的日程列表
  final List<Event> conflictingEvents;

  const ConflictInfo({
    this.conflictingCourses = const [],
    this.conflictingEvents = const [],
  });

  /// 是否有冲突
  bool get hasConflict =>
      conflictingCourses.isNotEmpty || conflictingEvents.isNotEmpty;

  /// 冲突总数
  int get totalConflicts =>
      conflictingCourses.length + conflictingEvents.length;

  /// 获取冲突描述
  String get description {
    final parts = <String>[];
    if (conflictingCourses.isNotEmpty) {
      final courseNames = conflictingCourses.map((c) => c.name).join('、');
      parts.add('课程【$courseNames】');
    }
    if (conflictingEvents.isNotEmpty) {
      final eventNames = conflictingEvents.map((e) => e.title).join('、');
      parts.add('日程【$eventNames】');
    }
    return parts.join(' 和 ');
  }
}

/// 冲突检测服务
class ConflictDetectionService {
  final CourseService _courseService;

  ConflictDetectionService(this._courseService);

  /// 检测日程与课程的冲突
  ///
  /// [eventStartTime] 日程开始时间
  /// [eventEndTime] 日程结束时间
  /// [semester] 当前学期
  /// [schedule] 课程表
  /// [excludeEventId] 要排除的日程ID（编辑时排除自身）
  Future<ConflictInfo> checkEventConflicts({
    required DateTime eventStartTime,
    required DateTime eventEndTime,
    required Semester semester,
    required CourseSchedule schedule,
    String? excludeEventId,
  }) async {
    final conflictingCourses = <Course>[];

    // 获取日程所在的周次和星期
    final eventWeek = semester.getWeekNumber(eventStartTime);
    final eventDayOfWeek = eventStartTime.weekday;

    // 检查日程是否在学期范围内
    if (!semester.isDateInSemester(eventStartTime)) {
      return const ConflictInfo();
    }

    // 获取该周该天的所有课程
    final courses = await _courseService.getCoursesForDay(
      schedule.id,
      eventWeek,
      eventDayOfWeek,
    );

    // 检查每门课程是否与日程时间冲突
    for (final course in courses) {
      final courseTimeRange = _getCourseTimeRange(
        course: course,
        schedule: schedule,
        date: eventStartTime,
      );

      if (courseTimeRange != null) {
        // 检查时间是否重叠
        if (_isTimeOverlap(
          eventStartTime,
          eventEndTime,
          courseTimeRange.start,
          courseTimeRange.end,
        )) {
          conflictingCourses.add(course);
        }
      }
    }

    return ConflictInfo(conflictingCourses: conflictingCourses);
  }

  /// 检测指定时间段是否有课程
  ///
  /// 用于在日程表单中实时显示冲突
  Future<List<Course>> getCoursesInTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    required Semester semester,
    required CourseSchedule schedule,
  }) async {
    final result = await checkEventConflicts(
      eventStartTime: startTime,
      eventEndTime: endTime,
      semester: semester,
      schedule: schedule,
    );
    return result.conflictingCourses;
  }

  /// 检测课程与其他课程的冲突
  ///
  /// 用于新建/编辑课程时检测
  Future<List<Course>> checkCourseConflicts(Course course) async {
    return _courseService.checkConflicts(course);
  }

  /// 获取课程在指定日期的时间范围
  ({DateTime start, DateTime end})? _getCourseTimeRange({
    required Course course,
    required CourseSchedule schedule,
    required DateTime date,
  }) {
    final startSlot = schedule.getTimeSlot(course.startSection);
    final endSlot = schedule.getTimeSlot(course.endSection);

    if (startSlot == null || endSlot == null) {
      return null;
    }

    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      startSlot.startTime.hour,
      startSlot.startTime.minute,
    );

    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      endSlot.endTime.hour,
      endSlot.endTime.minute,
    );

    return (start: startTime, end: endTime);
  }

  /// 判断两个时间段是否重叠
  bool _isTimeOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    // 如果时间段1结束时间 <= 时间段2开始时间，不重叠
    // 如果时间段1开始时间 >= 时间段2结束时间，不重叠
    return !(end1.compareTo(start2) <= 0 || start1.compareTo(end2) >= 0);
  }

  /// 获取课程的实际时间字符串
  String getCourseTimeString({
    required Course course,
    required CourseSchedule schedule,
  }) {
    final startSlot = schedule.getTimeSlot(course.startSection);
    final endSlot = schedule.getTimeSlot(course.endSection);

    if (startSlot == null || endSlot == null) {
      return course.sectionDescription;
    }

    final startStr =
        '${startSlot.startTime.hour.toString().padLeft(2, '0')}:${startSlot.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endSlot.endTime.hour.toString().padLeft(2, '0')}:${endSlot.endTime.minute.toString().padLeft(2, '0')}';

    return '$startStr-$endStr';
  }

  /// 将课程转换为日程时间格式的描述
  String getCourseConflictDescription({
    required Course course,
    required CourseSchedule schedule,
  }) {
    final timeStr = getCourseTimeString(course: course, schedule: schedule);
    return '${course.name} ($timeStr) @ ${course.location ?? '未知地点'}';
  }
}
