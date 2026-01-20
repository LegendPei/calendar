/// 数据库常量定义
class DbConstants {
  DbConstants._();

  /// 数据库名称
  static const String databaseName = 'calendar_app.db';

  /// 数据库版本
  static const int databaseVersion = 3;

  /// 表名 - 日历相关
  static const String tableEvents = 'events';
  static const String tableReminders = 'reminders';
  static const String tableCalendars = 'calendars';
  static const String tableSubscriptions = 'subscriptions';

  /// 表名 - 课程表相关
  static const String tableSemesters = 'semesters';
  static const String tableCourseSchedules = 'course_schedules';
  static const String tableCourses = 'courses';
}
