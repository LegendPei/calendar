// 课程表状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_helper.dart';
import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/semester.dart';
import '../services/course_service.dart';

// 导出数据完整性相关类
export '../services/course_service.dart'
    show CourseImportReport, DataIntegrityReport, DataCleanupResult;

/// 课程服务Provider
final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService(DatabaseHelper());
});

// ==================== 学期相关 ====================

/// 所有学期列表
final semesterListProvider = FutureProvider<List<Semester>>((ref) async {
  final service = ref.watch(courseServiceProvider);
  return service.getAllSemesters();
});

/// 当前学期
final currentSemesterProvider = FutureProvider<Semester?>((ref) async {
  final service = ref.watch(courseServiceProvider);
  return service.getCurrentSemester();
});

/// 学期管理Notifier
class SemesterNotifier extends AsyncNotifier<List<Semester>> {
  @override
  Future<List<Semester>> build() async {
    return ref.watch(courseServiceProvider).getAllSemesters();
  }

  /// 添加学期
  Future<String> addSemester(Semester semester) async {
    final service = ref.read(courseServiceProvider);
    final id = await service.insertSemester(semester);
    ref.invalidateSelf();
    return id;
  }

  /// 更新学期
  Future<void> updateSemester(Semester semester) async {
    final service = ref.read(courseServiceProvider);
    await service.updateSemester(semester);
    ref.invalidateSelf();
  }

  /// 删除学期
  Future<void> deleteSemester(String id) async {
    final service = ref.read(courseServiceProvider);
    await service.deleteSemester(id);
    ref.invalidateSelf();
  }

  /// 设置当前学期
  Future<void> setCurrentSemester(String id) async {
    final service = ref.read(courseServiceProvider);
    await service.setCurrentSemester(id);
    ref.invalidateSelf();
  }
}

final semesterNotifierProvider =
    AsyncNotifierProvider<SemesterNotifier, List<Semester>>(() {
      return SemesterNotifier();
    });

// ==================== 课程表相关 ====================

/// 当前选中的课程表ID
final selectedScheduleIdProvider = StateProvider<String?>((ref) => null);

/// 当前学期的课程表
final currentScheduleProvider = FutureProvider<CourseSchedule?>((ref) async {
  final service = ref.watch(courseServiceProvider);
  final semester = await ref.watch(currentSemesterProvider.future);
  if (semester == null) return null;
  return service.getScheduleBySemester(semester.id);
});

/// 根据学期ID获取课程表
final scheduleBySemersterProvider =
    FutureProvider.family<CourseSchedule?, String>((ref, semesterId) async {
      final service = ref.watch(courseServiceProvider);
      return service.getScheduleBySemester(semesterId);
    });

/// 课程表管理Notifier
class ScheduleNotifier extends AsyncNotifier<CourseSchedule?> {
  @override
  Future<CourseSchedule?> build() async {
    final semester = await ref.watch(currentSemesterProvider.future);
    if (semester == null) return null;
    return ref.watch(courseServiceProvider).getScheduleBySemester(semester.id);
  }

  /// 创建课程表
  Future<CourseSchedule> createSchedule(String semesterId, String name) async {
    final service = ref.read(courseServiceProvider);
    final schedule = await service.createDefaultSchedule(semesterId, name);
    ref.invalidateSelf();
    return schedule;
  }

  /// 更新课程表
  Future<void> updateSchedule(CourseSchedule schedule) async {
    final service = ref.read(courseServiceProvider);
    await service.updateSchedule(schedule);
    ref.invalidateSelf();
  }

  /// 删除课程表
  Future<void> deleteSchedule(String id) async {
    final service = ref.read(courseServiceProvider);
    await service.deleteSchedule(id);
    ref.invalidateSelf();
  }
}

final scheduleNotifierProvider =
    AsyncNotifierProvider<ScheduleNotifier, CourseSchedule?>(() {
      return ScheduleNotifier();
    });

// ==================== 课程相关 ====================

/// 当前选中的周次
final selectedWeekProvider = StateProvider<int>((ref) => 1);

/// 当前选中的课程
final selectedCourseProvider = StateProvider<Course?>((ref) => null);

/// 课程表的所有课程
final coursesByScheduleProvider = FutureProvider.family<List<Course>, String>((
  ref,
  scheduleId,
) async {
  final service = ref.watch(courseServiceProvider);
  return service.getCoursesBySchedule(scheduleId);
});

/// 指定周的课程
final coursesForWeekProvider =
    FutureProvider.family<List<Course>, ({String scheduleId, int week})>((
      ref,
      params,
    ) async {
      final service = ref.watch(courseServiceProvider);
      return service.getCoursesForWeek(params.scheduleId, params.week);
    });

/// 指定周某天的课程
final coursesForDayProvider =
    FutureProvider.family<
      List<Course>,
      ({String scheduleId, int week, int dayOfWeek})
    >((ref, params) async {
      final service = ref.watch(courseServiceProvider);
      return service.getCoursesForDay(
        params.scheduleId,
        params.week,
        params.dayOfWeek,
      );
    });

/// 课程管理Notifier
class CourseListNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    final schedule = await ref.watch(scheduleNotifierProvider.future);
    if (schedule == null) return [];
    return ref.watch(courseServiceProvider).getCoursesBySchedule(schedule.id);
  }

  /// 添加课程
  Future<String> addCourse(Course course) async {
    final service = ref.read(courseServiceProvider);
    final id = await service.insertCourse(course);
    ref.invalidateSelf();
    _triggerCalendarRefresh();
    return id;
  }

  /// 更新课程
  Future<void> updateCourse(Course course) async {
    final service = ref.read(courseServiceProvider);
    await service.updateCourse(course);
    ref.invalidateSelf();
    _triggerCalendarRefresh();
  }

  /// 删除课程
  Future<void> deleteCourse(String id) async {
    final service = ref.read(courseServiceProvider);
    await service.deleteCourse(id);
    ref.invalidateSelf();
    _triggerCalendarRefresh();
  }

  /// 批量导入课程
  Future<CourseImportReport> importCourses(List<Course> courses) async {
    final service = ref.read(courseServiceProvider);
    final report = await service.importCourses(courses);
    if (report.successCount > 0) {
      ref.invalidateSelf();
      // 刷新月视图课程指示器
      _triggerCalendarRefresh();
    }
    return report;
  }

  /// 触发日历视图刷新
  void _triggerCalendarRefresh() {
    Future.microtask(() {
      ref.invalidate(courseCountByMonthProvider);
      ref.invalidate(coursesByDateProvider);
    });
  }

  /// 删除所有课程
  Future<void> deleteAllCourses(String scheduleId) async {
    final service = ref.read(courseServiceProvider);
    await service.deleteAllCoursesInSchedule(scheduleId);
    ref.invalidateSelf();
    _triggerCalendarRefresh();
  }

  /// 检查冲突
  Future<List<Course>> checkConflicts(Course course) async {
    final service = ref.read(courseServiceProvider);
    return service.checkConflicts(course);
  }

  /// 刷新
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final courseListProvider =
    AsyncNotifierProvider<CourseListNotifier, List<Course>>(() {
      return CourseListNotifier();
    });

// ==================== 当前周次计算 ====================

/// 当前周次Provider
final currentWeekProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(courseServiceProvider);
  return service.getCurrentWeek();
});

// ==================== 课程表单状态 ====================

/// 课程表单状态
class CourseFormState {
  final String name;
  final String? teacher;
  final String? location;
  final int dayOfWeek;
  final int startSection;
  final int endSection;

  /// 选中的节次列表（支持非连续选择，如[1,2,3,7,8]）
  final List<int> selectedSections;
  final List<int> weeks;
  final int color;
  final String? note;

  /// 提醒提前时间（分钟），null表示不提醒
  final int? reminderMinutes;
  final bool isLoading;
  final String? error;

  const CourseFormState({
    this.name = '',
    this.teacher,
    this.location,
    this.dayOfWeek = 1,
    this.startSection = 1,
    this.endSection = 2,
    this.selectedSections = const [1, 2],
    this.weeks = const [],
    this.color = 0xFFBBDEFB,
    this.note,
    this.reminderMinutes,
    this.isLoading = false,
    this.error,
  });

  CourseFormState copyWith({
    String? name,
    String? teacher,
    String? location,
    int? dayOfWeek,
    int? startSection,
    int? endSection,
    List<int>? selectedSections,
    List<int>? weeks,
    int? color,
    String? note,
    int? reminderMinutes,
    bool clearReminderMinutes = false,
    bool? isLoading,
    String? error,
  }) {
    return CourseFormState(
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      selectedSections: selectedSections ?? this.selectedSections,
      weeks: weeks ?? this.weeks,
      color: color ?? this.color,
      note: note ?? this.note,
      reminderMinutes: clearReminderMinutes
          ? null
          : (reminderMinutes ?? this.reminderMinutes),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 从Course创建
  factory CourseFormState.fromCourse(Course course) {
    // 将连续范围转换为节次列表
    final sections = List<int>.generate(
      course.endSection - course.startSection + 1,
      (i) => course.startSection + i,
    );
    return CourseFormState(
      name: course.name,
      teacher: course.teacher,
      location: course.location,
      dayOfWeek: course.dayOfWeek,
      startSection: course.startSection,
      endSection: course.endSection,
      selectedSections: sections,
      weeks: course.weeks,
      color: course.color,
      note: course.note,
      reminderMinutes: course.reminderMinutes,
    );
  }

  /// 创建默认状态
  factory CourseFormState.initial({int totalWeeks = 20}) {
    return CourseFormState(
      selectedSections: const [1, 2],
      weeks: List.generate(totalWeeks, (i) => i + 1),
      color: Course.presetColors[0],
    );
  }

  /// 验证表单
  String? validate() {
    if (name.trim().isEmpty) {
      return '请输入课程名称';
    }
    if (name.length > 50) {
      return '课程名称不能超过50个字符';
    }
    if (weeks.isEmpty) {
      return '请选择上课周次';
    }
    if (selectedSections.isEmpty) {
      return '请选择上课节次';
    }
    return null;
  }

  /// 将选中的节次分组为连续范围
  /// 返回 [(start, end), ...] 的列表
  List<({int start, int end})> getSectionRanges() {
    if (selectedSections.isEmpty) return [];

    final sorted = List<int>.from(selectedSections)..sort();
    final ranges = <({int start, int end})>[];

    int rangeStart = sorted.first;
    int rangeEnd = sorted.first;

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == rangeEnd + 1) {
        // 连续
        rangeEnd = sorted[i];
      } else {
        // 不连续，保存当前范围，开始新范围
        ranges.add((start: rangeStart, end: rangeEnd));
        rangeStart = sorted[i];
        rangeEnd = sorted[i];
      }
    }

    // 添加最后一个范围
    ranges.add((start: rangeStart, end: rangeEnd));

    return ranges;
  }
}

/// 课程表单Notifier
class CourseFormNotifier extends StateNotifier<CourseFormState> {
  CourseFormNotifier([int totalWeeks = 20])
    : super(CourseFormState.initial(totalWeeks: totalWeeks));

  /// 初始化为编辑模式
  void initForEdit(Course course) {
    state = CourseFormState.fromCourse(course);
  }

  /// 初始化为新建模式
  void initForCreate({int totalWeeks = 20}) {
    state = CourseFormState.initial(totalWeeks: totalWeeks);
  }

  /// 更新名称
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  /// 更新教师
  void updateTeacher(String? teacher) {
    state = state.copyWith(teacher: teacher);
  }

  /// 更新地点
  void updateLocation(String? location) {
    state = state.copyWith(location: location);
  }

  /// 更新星期几
  void updateDayOfWeek(int dayOfWeek) {
    state = state.copyWith(dayOfWeek: dayOfWeek);
  }

  /// 更新开始节次
  void updateStartSection(int section) {
    var endSection = state.endSection;
    if (section > endSection) {
      endSection = section;
    }
    state = state.copyWith(startSection: section, endSection: endSection);
  }

  /// 更新结束节次
  void updateEndSection(int section) {
    state = state.copyWith(endSection: section);
  }

  /// 更新选中的节次列表
  void updateSelectedSections(List<int> sections) {
    final sorted = List<int>.from(sections)..sort();
    state = state.copyWith(
      selectedSections: sorted,
      startSection: sorted.isNotEmpty ? sorted.first : 1,
      endSection: sorted.isNotEmpty ? sorted.last : 1,
    );
  }

  /// 切换某个节次的选中状态
  void toggleSection(int section) {
    final current = List<int>.from(state.selectedSections);
    if (current.contains(section)) {
      current.remove(section);
    } else {
      current.add(section);
    }
    current.sort();
    state = state.copyWith(
      selectedSections: current,
      startSection: current.isNotEmpty ? current.first : 1,
      endSection: current.isNotEmpty ? current.last : 1,
    );
  }

  /// 更新周次
  void updateWeeks(List<int> weeks) {
    state = state.copyWith(weeks: weeks);
  }

  /// 设置周次类型（每周/单周/双周）
  void setWeeksType(int startWeek, int endWeek, int type) {
    final weeks = Course.generateWeeks(startWeek, endWeek, type: type);
    state = state.copyWith(weeks: weeks);
  }

  /// 更新颜色
  void updateColor(int color) {
    state = state.copyWith(color: color);
  }

  /// 更新备注
  void updateNote(String? note) {
    state = state.copyWith(note: note);
  }

  /// 更新提醒时间
  void updateReminderMinutes(int? minutes) {
    if (minutes == null) {
      state = state.copyWith(clearReminderMinutes: true);
    } else {
      state = state.copyWith(reminderMinutes: minutes);
    }
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 设置错误
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// 重置表单
  void reset({int totalWeeks = 20}) {
    state = CourseFormState.initial(totalWeeks: totalWeeks);
  }
}

/// 课程表单Provider
final courseFormProvider =
    StateNotifierProvider<CourseFormNotifier, CourseFormState>((ref) {
      return CourseFormNotifier();
    });

// ==================== 快速设置 ====================

/// 快速设置Provider（创建学期和课程表）
final quickSetupProvider =
    FutureProvider.family<
      ({Semester semester, CourseSchedule schedule}),
      ({String name, DateTime startDate, int totalWeeks})
    >((ref, params) async {
      final service = ref.read(courseServiceProvider);
      return service.quickSetup(
        semesterName: params.name,
        startDate: params.startDate,
        totalWeeks: params.totalWeeks,
      );
    });

// ==================== 日历融合相关 ====================

/// 根据日期获取该天的课程列表
/// 会自动计算该日期属于哪个周次，并返回该周该天的课程
final coursesByDateProvider = FutureProvider.family<List<Course>, DateTime>((
  ref,
  date,
) async {
  final service = ref.watch(courseServiceProvider);
  final semester = await ref.watch(currentSemesterProvider.future);
  final schedule = await ref.watch(currentScheduleProvider.future);

  if (semester == null || schedule == null) return [];

  // 计算该日期属于第几周
  final week = semester.getWeekNumber(date);
  if (week < 1 || week > semester.totalWeeks) return [];

  // 获取该日期是周几 (1-7)
  final dayOfWeek = date.weekday;

  // 获取该周该天的课程
  return service.getCoursesForDay(schedule.id, week, dayOfWeek);
});

/// 获取一个月内每天的课程数量（用于月视图显示课程指示）
final courseCountByMonthProvider =
    FutureProvider.family<Map<DateTime, int>, DateTime>((ref, month) async {
      final service = ref.watch(courseServiceProvider);
      final semester = await ref.watch(currentSemesterProvider.future);
      final schedule = await ref.watch(currentScheduleProvider.future);

      if (semester == null || schedule == null) return {};

      // 获取该月的所有日期
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final result = <DateTime, int>{};

      // 获取课程表的所有课程
      final allCourses = await service.getCoursesBySchedule(schedule.id);

      // 遍历该月的每一天
      for (
        var date = firstDay;
        !date.isAfter(lastDay);
        date = date.add(const Duration(days: 1))
      ) {
        // 计算该日期属于第几周
        final week = semester.getWeekNumber(date);
        if (week < 1 || week > semester.totalWeeks) continue;

        // 获取该日期是周几 (1-7)
        final dayOfWeek = date.weekday;

        // 筛选该天的课程
        final dayCourses = allCourses.where((course) {
          return course.dayOfWeek == dayOfWeek && course.weeks.contains(week);
        }).toList();

        if (dayCourses.isNotEmpty) {
          final dateOnly = DateTime(date.year, date.month, date.day);
          result[dateOnly] = dayCourses.length;
        }
      }

      return result;
    });

// ==================== 数据完整性相关 ====================

/// 数据完整性检查 Provider
final dataIntegrityCheckProvider = FutureProvider<DataIntegrityReport>((
  ref,
) async {
  final service = ref.watch(courseServiceProvider);
  return service.checkDataIntegrity();
});

/// 数据清理 Provider（手动触发）
final dataCleanupProvider = FutureProvider.family<DataCleanupResult, void>((
  ref,
  _,
) async {
  final service = ref.read(courseServiceProvider);
  return service.cleanupOrphanedData();
});
