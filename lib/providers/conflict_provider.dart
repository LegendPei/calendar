/// 冲突检测状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/course.dart';
import '../models/course_schedule.dart';
import '../models/semester.dart';
import '../services/conflict_detection_service.dart';
import 'course_provider.dart';

/// 冲突检测服务Provider
final conflictDetectionServiceProvider = Provider<ConflictDetectionService>((
  ref,
) {
  final courseService = ref.watch(courseServiceProvider);
  return ConflictDetectionService(courseService);
});

/// 冲突检查参数
class ConflictCheckParams {
  final DateTime startTime;
  final DateTime endTime;
  final String? excludeEventId;

  const ConflictCheckParams({
    required this.startTime,
    required this.endTime,
    this.excludeEventId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConflictCheckParams &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.excludeEventId == excludeEventId;
  }

  @override
  int get hashCode => Object.hash(startTime, endTime, excludeEventId);
}

/// 检查日程时间段内的冲突课程
final conflictingCoursesProvider =
    FutureProvider.family<List<Course>, ConflictCheckParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(conflictDetectionServiceProvider);
      final semesterAsync = await ref.watch(currentSemesterProvider.future);
      final scheduleAsync = await ref.watch(currentScheduleProvider.future);

      // 如果没有学期或课程表配置，则无法检测冲突
      if (semesterAsync == null || scheduleAsync == null) {
        return [];
      }

      final conflictInfo = await service.checkEventConflicts(
        eventStartTime: params.startTime,
        eventEndTime: params.endTime,
        semester: semesterAsync,
        schedule: scheduleAsync,
        excludeEventId: params.excludeEventId,
      );

      return conflictInfo.conflictingCourses;
    });

/// 冲突状态 - 用于UI显示
class ConflictState {
  final bool isChecking;
  final List<Course> conflictingCourses;
  final String? error;

  const ConflictState({
    this.isChecking = false,
    this.conflictingCourses = const [],
    this.error,
  });

  bool get hasConflict => conflictingCourses.isNotEmpty;

  ConflictState copyWith({
    bool? isChecking,
    List<Course>? conflictingCourses,
    String? error,
  }) {
    return ConflictState(
      isChecking: isChecking ?? this.isChecking,
      conflictingCourses: conflictingCourses ?? this.conflictingCourses,
      error: error,
    );
  }

  /// 获取冲突描述
  String get description {
    if (conflictingCourses.isEmpty) return '';
    final names = conflictingCourses.map((c) => c.name).join('、');
    return '与课程【$names】冲突';
  }
}

/// 冲突状态Notifier
class ConflictNotifier extends StateNotifier<ConflictState> {
  final ConflictDetectionService _service;
  final Semester? _semester;
  final CourseSchedule? _schedule;

  ConflictNotifier(this._service, this._semester, this._schedule)
    : super(const ConflictState());

  /// 检查冲突
  Future<void> checkConflict({
    required DateTime startTime,
    required DateTime endTime,
    String? excludeEventId,
  }) async {
    // 如果没有学期或课程表，跳过检测
    final semester = _semester;
    final schedule = _schedule;
    if (semester == null || schedule == null) {
      state = const ConflictState();
      return;
    }

    state = state.copyWith(isChecking: true, error: null);

    try {
      final conflictInfo = await _service.checkEventConflicts(
        eventStartTime: startTime,
        eventEndTime: endTime,
        semester: semester,
        schedule: schedule,
        excludeEventId: excludeEventId,
      );

      state = state.copyWith(
        isChecking: false,
        conflictingCourses: conflictInfo.conflictingCourses,
      );
    } catch (e) {
      state = state.copyWith(isChecking: false, error: '冲突检测失败: $e');
    }
  }

  /// 清除冲突状态
  void clearConflict() {
    state = const ConflictState();
  }
}

/// 冲突Notifier Provider - 用于事件表单
final conflictNotifierProvider =
    StateNotifierProvider<ConflictNotifier, ConflictState>((ref) {
      final service = ref.watch(conflictDetectionServiceProvider);

      // 同步获取学期和课程表（可能为null）
      Semester? semester;
      CourseSchedule? schedule;

      ref.watch(currentSemesterProvider).whenData((data) {
        semester = data;
      });

      ref.watch(currentScheduleProvider).whenData((data) {
        schedule = data;
      });

      return ConflictNotifier(service, semester, schedule);
    });

/// 获取课程的时间字符串描述
String getCourseTimeDescription(Course course, CourseSchedule schedule) {
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
