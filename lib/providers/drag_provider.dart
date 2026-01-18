/// 拖拽状态管理
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/drag_utils.dart';
import '../models/course.dart';
import '../models/event.dart';
import 'calendar_provider.dart';
import 'course_provider.dart';
import 'event_provider.dart';

/// 拖拽状态Provider
final dragStateProvider = StateNotifierProvider<DragStateNotifier, DragState>((
  ref,
) {
  return DragStateNotifier(ref);
});

/// 是否正在拖拽
final isDraggingProvider = Provider<bool>((ref) {
  return ref.watch(dragStateProvider).isDragging;
});

/// 拖拽状态管理器
class DragStateNotifier extends StateNotifier<DragState> {
  final Ref _ref;

  DragStateNotifier(this._ref) : super(const DragState());

  /// 开始拖拽事件
  void startDragEvent(Event event) {
    HapticFeedback.mediumImpact();
    state = DragState(
      status: DragStatus.dragging,
      dragData: DragData.fromEvent(event),
      showPreview: true,
    );
  }

  /// 开始拖拽课程
  void startDragCourse(Course course) {
    HapticFeedback.mediumImpact();
    state = DragState(
      status: DragStatus.dragging,
      dragData: DragData.fromCourse(course),
      showPreview: true,
    );
  }

  /// 更新悬停目标
  void updateHoverTarget(DropTarget? target) {
    if (state.status == DragStatus.idle) return;

    if (target != null && state.hoverTarget != target) {
      HapticFeedback.selectionClick();
    }

    state = state.copyWith(
      hoverTarget: target,
      status: target != null ? DragStatus.hovering : DragStatus.dragging,
      clearHoverTarget: target == null,
    );
  }

  /// 更新当前位置
  void updatePosition(Offset position) {
    state = state.copyWith(currentPosition: position);
  }

  /// 完成拖拽
  Future<bool> completeDrop() async {
    if (state.hoverTarget == null || state.dragData == null) {
      cancelDrag();
      return false;
    }

    // 检查位置是否改变
    if (!DragUtils.hasPositionChanged(
      dragData: state.dragData!,
      target: state.hoverTarget!,
    )) {
      cancelDrag();
      return false;
    }

    state = state.copyWith(status: DragStatus.dropping);

    try {
      if (state.dragData!.isEvent) {
        await _handleEventDrop();
      } else if (state.dragData!.isCourse) {
        await _handleCourseDrop();
      }

      HapticFeedback.lightImpact();
      state = const DragState();
      return true;
    } catch (e) {
      cancelDrag();
      return false;
    }
  }

  /// 取消拖拽
  void cancelDrag() {
    state = const DragState();
  }

  /// 处理事件放置
  Future<void> _handleEventDrop() async {
    final dragData = state.dragData!;
    final target = state.hoverTarget!;
    final event = dragData.event!;

    final eventService = _ref.read(eventServiceProvider);

    final newTime = DragUtils.calculateNewEventTime(
      event: event,
      targetDate: target.targetDate!,
      targetTime: target.type == DropTargetType.timeSlot
          ? target.targetTime
          : null,
    );

    final updatedEvent = event.copyWith(
      startTime: newTime.start,
      endTime: newTime.end,
      updatedAt: DateTime.now(),
    );

    await eventService.updateEvent(updatedEvent);
    _ref.read(calendarControllerProvider).refreshEvents();
  }

  /// 处理课程放置
  Future<void> _handleCourseDrop() async {
    final dragData = state.dragData!;
    final target = state.hoverTarget!;
    final course = dragData.course!;

    if (target.type != DropTargetType.courseCell) return;

    final courseService = _ref.read(courseServiceProvider);

    // 检查目标位置是否有冲突
    final newPosition = DragUtils.calculateNewCoursePosition(
      course: course,
      targetDayOfWeek: target.targetDayOfWeek!,
      targetSection: target.targetSection!,
    );

    // 创建临时课程用于冲突检测
    final tempCourse = course.copyWith(
      dayOfWeek: newPosition.dayOfWeek,
      startSection: newPosition.startSection,
      endSection: newPosition.endSection,
    );

    final conflicts = await courseService.checkConflicts(tempCourse);
    if (conflicts.isNotEmpty) {
      throw Exception('目标位置存在课程冲突');
    }

    final updatedCourse = course.copyWith(
      dayOfWeek: newPosition.dayOfWeek,
      startSection: newPosition.startSection,
      endSection: newPosition.endSection,
      updatedAt: DateTime.now(),
    );

    await courseService.updateCourse(updatedCourse);

    // 刷新课程列表
    _ref.read(courseListProvider.notifier).refresh();

    // 同时刷新当前周的课程视图（关键修复）
    final selectedWeek = _ref.read(selectedWeekProvider);
    _ref.invalidate(
      coursesForWeekProvider((
        scheduleId: course.scheduleId,
        week: selectedWeek,
      )),
    );
    // 刷新课程表的所有课程
    _ref.invalidate(coursesByScheduleProvider(course.scheduleId));
  }
}

/// 拖拽控制器
class DragController {
  final Ref ref;

  DragController(this.ref);

  /// 开始拖拽事件
  void startDragEvent(Event event) {
    ref.read(dragStateProvider.notifier).startDragEvent(event);
  }

  /// 开始拖拽课程
  void startDragCourse(Course course) {
    ref.read(dragStateProvider.notifier).startDragCourse(course);
  }

  /// 更新悬停目标
  void updateHoverTarget(DropTarget? target) {
    ref.read(dragStateProvider.notifier).updateHoverTarget(target);
  }

  /// 更新当前位置
  void updatePosition(Offset position) {
    ref.read(dragStateProvider.notifier).updatePosition(position);
  }

  /// 完成拖拽
  Future<bool> completeDrop() {
    return ref.read(dragStateProvider.notifier).completeDrop();
  }

  /// 取消拖拽
  void cancelDrag() {
    ref.read(dragStateProvider.notifier).cancelDrag();
  }

  /// 是否正在拖拽
  bool get isDragging {
    return ref.read(dragStateProvider).isDragging;
  }
}

/// 拖拽控制器Provider
final dragControllerProvider = Provider((ref) {
  return DragController(ref);
});
