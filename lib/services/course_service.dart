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

  /// 添加课程（带验证）
  Future<String> insertCourse(Course course) async {
    // 验证课程数据
    final error = course.validate();
    if (error != null) {
      throw CourseValidationException(error);
    }

    // 验证课程表是否存在
    final schedule = await getScheduleById(course.scheduleId);
    if (schedule == null) {
      throw CourseValidationException('课程表不存在');
    }

    await _db.insert(DbConstants.tableCourses, course.toMap());
    return course.id;
  }

  /// 更新课程（带验证）
  Future<void> updateCourse(Course course) async {
    // 验证课程数据
    final error = course.validate();
    if (error != null) {
      throw CourseValidationException(error);
    }

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

  /// 批量导入课程（使用事务，全部成功或全部失败）
  Future<CourseImportReport> importCourses(List<Course> courses) async {
    if (courses.isEmpty) {
      return CourseImportReport(
        totalCount: 0,
        successCount: 0,
        failedCount: 0,
        errors: [],
      );
    }

    // 先验证所有课程
    final errors = <String>[];
    final validCourses = <Course>[];

    for (int i = 0; i < courses.length; i++) {
      final course = courses[i];
      final error = course.validate();
      if (error != null) {
        errors.add('第${i + 1}门课程(${course.name}): $error');
      } else {
        validCourses.add(course);
      }
    }

    // 如果有验证错误，返回报告但不导入
    if (errors.isNotEmpty) {
      return CourseImportReport(
        totalCount: courses.length,
        successCount: 0,
        failedCount: errors.length,
        errors: errors,
      );
    }

    // 验证课程表是否存在
    final scheduleId = courses.first.scheduleId;
    final schedule = await getScheduleById(scheduleId);
    if (schedule == null) {
      return CourseImportReport(
        totalCount: courses.length,
        successCount: 0,
        failedCount: courses.length,
        errors: ['课程表不存在'],
      );
    }

    // 使用批量插入（事务）
    try {
      await _db.batchInsert(
        DbConstants.tableCourses,
        validCourses.map((c) => c.toMap()).toList(),
      );

      return CourseImportReport(
        totalCount: courses.length,
        successCount: validCourses.length,
        failedCount: 0,
        errors: [],
      );
    } catch (e) {
      return CourseImportReport(
        totalCount: courses.length,
        successCount: 0,
        failedCount: courses.length,
        errors: ['导入失败: $e'],
      );
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

  // ==================== 数据完整性检查 ====================

  /// 检查数据完整性并返回报告
  Future<DataIntegrityReport> checkDataIntegrity() async {
    final issues = <String>[];
    int orphanedCourses = 0;
    int orphanedSchedules = 0;
    int invalidCourses = 0;

    // 检查孤儿课程（没有对应课程表的课程）
    final allCourses = await _db.rawQuery('''
      SELECT c.* FROM ${DbConstants.tableCourses} c
      LEFT JOIN ${DbConstants.tableCourseSchedules} s ON c.schedule_id = s.id
      WHERE s.id IS NULL
    ''');
    orphanedCourses = allCourses.length;
    if (orphanedCourses > 0) {
      issues.add('发现 $orphanedCourses 门孤儿课程（课程表已删除）');
    }

    // 检查孤儿课程表（没有对应学期的课程表）
    final orphanedSchedulesList = await _db.rawQuery('''
      SELECT cs.* FROM ${DbConstants.tableCourseSchedules} cs
      LEFT JOIN ${DbConstants.tableSemesters} s ON cs.semester_id = s.id
      WHERE s.id IS NULL
    ''');
    orphanedSchedules = orphanedSchedulesList.length;
    if (orphanedSchedules > 0) {
      issues.add('发现 $orphanedSchedules 个孤儿课程表（学期已删除）');
    }

    // 检查无效课程数据
    final allCoursesData = await _db.query(DbConstants.tableCourses);
    for (final map in allCoursesData) {
      try {
        final course = Course.fromMap(map);
        final error = course.validate();
        if (error != null) {
          invalidCourses++;
        }
      } catch (e) {
        invalidCourses++;
      }
    }
    if (invalidCourses > 0) {
      issues.add('发现 $invalidCourses 门数据无效的课程');
    }

    return DataIntegrityReport(
      isHealthy: issues.isEmpty,
      issues: issues,
      orphanedCourses: orphanedCourses,
      orphanedSchedules: orphanedSchedules,
      invalidCourses: invalidCourses,
    );
  }

  /// 清理孤儿数据
  Future<DataCleanupResult> cleanupOrphanedData() async {
    // 先查询孤儿课程数量
    final orphanedCourses = await _db.rawQuery('''
      SELECT id FROM ${DbConstants.tableCourses}
      WHERE schedule_id NOT IN (SELECT id FROM ${DbConstants.tableCourseSchedules})
    ''');
    final deletedCourses = orphanedCourses.length;
    if (deletedCourses > 0) {
      await _db.delete(
        DbConstants.tableCourses,
        where:
            'schedule_id NOT IN (SELECT id FROM ${DbConstants.tableCourseSchedules})',
      );
    }

    // 查询并删除孤儿课程表
    final orphanedSchedules = await _db.rawQuery('''
      SELECT id FROM ${DbConstants.tableCourseSchedules}
      WHERE semester_id NOT IN (SELECT id FROM ${DbConstants.tableSemesters})
    ''');
    final deletedSchedules = orphanedSchedules.length;
    if (deletedSchedules > 0) {
      await _db.delete(
        DbConstants.tableCourseSchedules,
        where:
            'semester_id NOT IN (SELECT id FROM ${DbConstants.tableSemesters})',
      );
    }

    return DataCleanupResult(
      deletedCourses: deletedCourses,
      deletedSchedules: deletedSchedules,
    );
  }

  /// 验证单个课程并修复简单问题
  Future<Course?> validateAndFixCourse(Course course) async {
    // 检查周次数据
    var weeks = course.weeks;
    if (weeks.isEmpty) {
      // 默认设置为1-16周
      weeks = Course.generateWeeks(1, 16);
    }

    // 确保周次排序并去重
    weeks = weeks.toSet().toList()..sort();

    // 检查节次
    var startSection = course.startSection;
    var endSection = course.endSection;
    if (startSection > endSection) {
      final temp = startSection;
      startSection = endSection;
      endSection = temp;
    }

    return course.copyWith(
      weeks: weeks,
      startSection: startSection,
      endSection: endSection,
      updatedAt: DateTime.now(),
    );
  }
}

/// 课程导入报告
class CourseImportReport {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> errors;

  const CourseImportReport({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  bool get isSuccess => failedCount == 0 && successCount > 0;
  bool get hasWarnings => errors.isNotEmpty;
}

/// 数据完整性报告
class DataIntegrityReport {
  final bool isHealthy;
  final List<String> issues;
  final int orphanedCourses;
  final int orphanedSchedules;
  final int invalidCourses;

  const DataIntegrityReport({
    required this.isHealthy,
    required this.issues,
    required this.orphanedCourses,
    required this.orphanedSchedules,
    required this.invalidCourses,
  });
}

/// 数据清理结果
class DataCleanupResult {
  final int deletedCourses;
  final int deletedSchedules;

  const DataCleanupResult({
    required this.deletedCourses,
    required this.deletedSchedules,
  });

  bool get hasCleanedUp => deletedCourses > 0 || deletedSchedules > 0;
}
