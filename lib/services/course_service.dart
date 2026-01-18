import 'package:uuid/uuid.dart';

import '../core/constants/db_constants.dart';
import '../core/database/database_helper.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/course_time.dart';
import '../models/semester.dart';

/// 课程业务服务
class CourseService {
  final DatabaseHelper _db;

  CourseService(this._db);

  // ==================== 学期相关 ====================

  /// 获取所有学期
  Future<List<Semester>> getAllSemesters() async {
    final maps = await _db.query(
      DbConstants.tableSemesters,
      orderBy: 'start_date DESC',
    );
    return maps.map((m) => Semester.fromMap(m)).toList();
  }

  /// 获取当前学期
  Future<Semester?> getCurrentSemester() async {
    final maps = await _db.query(
      DbConstants.tableSemesters,
      where: 'is_current = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  /// 根据ID获取学期
  Future<Semester?> getSemesterById(String id) async {
    final maps = await _db.query(
      DbConstants.tableSemesters,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Semester.fromMap(maps.first);
  }

  /// 添加学期
  Future<String> insertSemester(Semester semester) async {
    // 如果设为当前学期，先取消其他学期的当前状态
    if (semester.isCurrent) {
      await _db.update(
        DbConstants.tableSemesters,
        {'is_current': 0},
        where: 'is_current = ?',
        whereArgs: [1],
      );
    }
    await _db.insert(DbConstants.tableSemesters, semester.toMap());
    return semester.id;
  }

  /// 更新学期
  Future<void> updateSemester(Semester semester) async {
    if (semester.isCurrent) {
      await _db.update(
        DbConstants.tableSemesters,
        {'is_current': 0},
        where: 'is_current = ? AND id != ?',
        whereArgs: [1, semester.id],
      );
    }
    await _db.update(
      DbConstants.tableSemesters,
      semester.toMap(),
      where: 'id = ?',
      whereArgs: [semester.id],
    );
  }

  /// 删除学期
  Future<void> deleteSemester(String id) async {
    await _db.delete(
      DbConstants.tableSemesters,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 设置当前学期
  Future<void> setCurrentSemester(String id) async {
    await _db.update(
      DbConstants.tableSemesters,
      {'is_current': 0},
      where: 'is_current = ?',
      whereArgs: [1],
    );
    await _db.update(
      DbConstants.tableSemesters,
      {'is_current': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 课程表相关 ====================

  /// 获取学期的课程表
  Future<CourseSchedule?> getScheduleBySemester(String semesterId) async {
    final maps = await _db.query(
      DbConstants.tableCourseSchedules,
      where: 'semester_id = ?',
      whereArgs: [semesterId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CourseSchedule.fromMap(maps.first);
  }

  /// 根据ID获取课程表
  Future<CourseSchedule?> getScheduleById(String id) async {
    final maps = await _db.query(
      DbConstants.tableCourseSchedules,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CourseSchedule.fromMap(maps.first);
  }

  /// 添加课程表
  Future<String> insertSchedule(CourseSchedule schedule) async {
    await _db.insert(DbConstants.tableCourseSchedules, schedule.toMap());
    return schedule.id;
  }

  /// 更新课程表
  Future<void> updateSchedule(CourseSchedule schedule) async {
    await _db.update(
      DbConstants.tableCourseSchedules,
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// 删除课程表
  Future<void> deleteSchedule(String id) async {
    await _db.delete(
      DbConstants.tableCourseSchedules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 创建默认课程表
  Future<CourseSchedule> createDefaultSchedule(
    String semesterId,
    String name,
  ) async {
    final now = DateTime.now();
    final schedule = CourseSchedule(
      id: const Uuid().v4(),
      name: name,
      semesterId: semesterId,
      timeSlots: CourseTime.defaultSchedule,
      daysPerWeek: 5,
      lunchAfterSection: CourseTime.defaultLunchAfterSection,
      createdAt: now,
      updatedAt: now,
    );
    await insertSchedule(schedule);
    return schedule;
  }

  // ==================== 课程相关 ====================

  /// 获取课程表的所有课程
  Future<List<Course>> getCoursesBySchedule(String scheduleId) async {
    final maps = await _db.query(
      DbConstants.tableCourses,
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      orderBy: 'day_of_week, start_section',
    );
    return maps.map((m) => Course.fromMap(m)).toList();
  }

  /// 获取指定周的课程
  Future<List<Course>> getCoursesForWeek(String scheduleId, int week) async {
    final allCourses = await getCoursesBySchedule(scheduleId);
    return allCourses.where((c) => c.hasClassInWeek(week)).toList();
  }

  /// 获取指定周某天的课程
  Future<List<Course>> getCoursesForDay(
    String scheduleId,
    int week,
    int dayOfWeek,
  ) async {
    final weekCourses = await getCoursesForWeek(scheduleId, week);
    return weekCourses.where((c) => c.dayOfWeek == dayOfWeek).toList();
  }

  /// 根据ID获取课程
  Future<Course?> getCourseById(String id) async {
    final maps = await _db.query(
      DbConstants.tableCourses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// 添加课程
  Future<String> insertCourse(Course course) async {
    await _db.insert(DbConstants.tableCourses, course.toMap());
    return course.id;
  }

  /// 更新课程
  Future<void> updateCourse(Course course) async {
    await _db.update(
      DbConstants.tableCourses,
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// 删除课程
  Future<void> deleteCourse(String id) async {
    await _db.delete(
      DbConstants.tableCourses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量导入课程
  Future<void> importCourses(List<Course> courses) async {
    for (final course in courses) {
      await insertCourse(course);
    }
  }

  /// 删除课程表的所有课程
  Future<void> deleteAllCoursesInSchedule(String scheduleId) async {
    await _db.delete(
      DbConstants.tableCourses,
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );
  }

  /// 检查时间冲突
  Future<List<Course>> checkConflicts(Course course) async {
    final existingCourses = await getCoursesBySchedule(course.scheduleId);
    final conflicts = <Course>[];

    for (final existing in existingCourses) {
      // 跳过自身
      if (existing.id == course.id) continue;

      // 不同天不冲突
      if (existing.dayOfWeek != course.dayOfWeek) continue;

      // 检查节次是否重叠
      final sectionsOverlap =
          !(course.endSection < existing.startSection ||
              course.startSection > existing.endSection);
      if (!sectionsOverlap) continue;

      // 检查周次是否重叠
      final weeksOverlap = course.weeks.any((w) => existing.weeks.contains(w));
      if (!weeksOverlap) continue;

      conflicts.add(existing);
    }

    return conflicts;
  }

  // ==================== 快捷操作 ====================

  /// 快速创建学期和课程表
  Future<({Semester semester, CourseSchedule schedule})> quickSetup({
    required String semesterName,
    required DateTime startDate,
    int totalWeeks = 20,
  }) async {
    final now = DateTime.now();

    // 创建学期
    final semester = Semester(
      id: const Uuid().v4(),
      name: semesterName,
      startDate: startDate,
      totalWeeks: totalWeeks,
      isCurrent: true,
      createdAt: now,
    );
    await insertSemester(semester);

    // 创建默认课程表
    final schedule = await createDefaultSchedule(semester.id, semesterName);

    return (semester: semester, schedule: schedule);
  }

  /// 获取当前周次（根据当前学期）
  Future<int> getCurrentWeek() async {
    final semester = await getCurrentSemester();
    if (semester == null) return 1;
    return semester.getWeekNumber(DateTime.now());
  }
}
