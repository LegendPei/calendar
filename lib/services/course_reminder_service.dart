/// 课程提醒服务 - 管理课程的提醒通知
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/semester.dart';
import 'notification_service.dart';

/// 课程提醒服务
class CourseReminderService {
  final NotificationService _notificationService;

  CourseReminderService(this._notificationService);

  /// 为课程调度所有提醒
  ///
  /// [course] 课程
  /// [schedule] 课程表配置
  /// [semester] 学期信息
  Future<void> scheduleCourseReminders({
    required Course course,
    required CourseSchedule schedule,
    required Semester semester,
  }) async {
    // 如果没有设置提醒，直接返回
    if (course.reminderMinutes == null) {
      return;
    }

    final now = DateTime.now();
    final reminderMinutes = course.reminderMinutes!;

    // 获取课程开始时间的时间槽
    final startSlot = schedule.getTimeSlot(course.startSection);
    if (startSlot == null) return;

    // 遍历所有周次
    for (final week in course.weeks) {
      // 计算这一周的上课日期
      final classDate = _getClassDateForWeek(
        semester: semester,
        week: week,
        dayOfWeek: course.dayOfWeek,
      );

      if (classDate == null) continue;

      // 计算上课时间
      final classTime = DateTime(
        classDate.year,
        classDate.month,
        classDate.day,
        startSlot.startTime.hour,
        startSlot.startTime.minute,
      );

      // 计算提醒时间
      final reminderTime = classTime.subtract(Duration(minutes: reminderMinutes));

      // 如果提醒时间已过，跳过
      if (reminderTime.isBefore(now)) continue;

      // 生成通知ID
      final notificationId = _generateNotificationId(course.id, week);

      // 构建通知内容
      final title = '课程提醒：${course.name}';
      final body = _buildNotificationBody(
        course: course,
        schedule: schedule,
        reminderMinutes: reminderMinutes,
      );

      // 调度通知
      await _notificationService.scheduleReminder(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: reminderTime,
        payload: 'course:${course.id}',
      );
    }
  }

  /// 取消课程的所有提醒
  Future<void> cancelCourseReminders(Course course) async {
    for (final week in course.weeks) {
      final notificationId = _generateNotificationId(course.id, week);
      await _notificationService.cancelNotification(notificationId);
    }
  }

  /// 更新课程提醒（先取消旧的，再调度新的）
  Future<void> updateCourseReminders({
    required Course course,
    required CourseSchedule schedule,
    required Semester semester,
    Course? oldCourse,
  }) async {
    // 取消旧的提醒
    if (oldCourse != null) {
      await cancelCourseReminders(oldCourse);
    } else {
      await cancelCourseReminders(course);
    }

    // 调度新的提醒
    await scheduleCourseReminders(
      course: course,
      schedule: schedule,
      semester: semester,
    );
  }

  /// 重新调度所有课程的提醒
  Future<void> rescheduleAllReminders({
    required List<Course> courses,
    required CourseSchedule schedule,
    required Semester semester,
  }) async {
    for (final course in courses) {
      if (course.reminderMinutes != null) {
        await scheduleCourseReminders(
          course: course,
          schedule: schedule,
          semester: semester,
        );
      }
    }
  }

  /// 获取下一次提醒时间
  DateTime? getNextReminderTime({
    required Course course,
    required CourseSchedule schedule,
    required Semester semester,
  }) {
    if (course.reminderMinutes == null) return null;

    final now = DateTime.now();
    final reminderMinutes = course.reminderMinutes!;
    final startSlot = schedule.getTimeSlot(course.startSection);
    if (startSlot == null) return null;

    for (final week in course.weeks) {
      final classDate = _getClassDateForWeek(
        semester: semester,
        week: week,
        dayOfWeek: course.dayOfWeek,
      );

      if (classDate == null) continue;

      final classTime = DateTime(
        classDate.year,
        classDate.month,
        classDate.day,
        startSlot.startTime.hour,
        startSlot.startTime.minute,
      );

      final reminderTime = classTime.subtract(Duration(minutes: reminderMinutes));

      if (reminderTime.isAfter(now)) {
        return reminderTime;
      }
    }

    return null;
  }

  /// 计算指定周次的上课日期
  DateTime? _getClassDateForWeek({
    required Semester semester,
    required int week,
    required int dayOfWeek,
  }) {
    if (week < 1 || week > semester.totalWeeks) return null;

    // 计算学期开始日期所在周的周一
    final semesterStart = semester.startDate;
    final weekdayOfStart = semesterStart.weekday;
    final firstMonday = semesterStart.subtract(Duration(days: weekdayOfStart - 1));

    // 计算目标周的日期
    final targetWeekMonday = firstMonday.add(Duration(days: (week - 1) * 7));
    final targetDate = targetWeekMonday.add(Duration(days: dayOfWeek - 1));

    return targetDate;
  }

  /// 生成通知ID（基于课程ID和周次）
  int _generateNotificationId(String courseId, int week) {
    return (courseId.hashCode ^ week.hashCode).abs() % 2147483647;
  }

  /// 构建通知内容
  String _buildNotificationBody({
    required Course course,
    required CourseSchedule schedule,
    required int reminderMinutes,
  }) {
    final parts = <String>[];

    // 时间描述
    final startSlot = schedule.getTimeSlot(course.startSection);
    if (startSlot != null) {
      final timeStr = '${startSlot.startTime.hour.toString().padLeft(2, '0')}:'
          '${startSlot.startTime.minute.toString().padLeft(2, '0')}';
      parts.add(timeStr);
    }

    // 地点
    if (course.location != null && course.location!.isNotEmpty) {
      parts.add(course.location!);
    }

    // 提醒时间描述
    if (reminderMinutes > 0) {
      parts.add(Course.getReminderOptionLabel(reminderMinutes));
    }

    return parts.join(' ');
  }
}
