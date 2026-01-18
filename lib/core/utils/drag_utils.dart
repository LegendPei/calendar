/// 拖拽功能工具类和数据模型
import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/event.dart';

/// 拖拽数据类型
enum DragDataType { event, course }

/// 放置目标类型
enum DropTargetType { date, timeSlot, courseCell }

/// 拖拽状态
enum DragStatus { idle, dragging, hovering, dropping }

/// 拖拽数据
class DragData {
  final DragDataType type;
  final dynamic data;
  final DateTime originalTime;
  final int? originalSection;
  final int? originalDayOfWeek;

  const DragData({
    required this.type,
    required this.data,
    required this.originalTime,
    this.originalSection,
    this.originalDayOfWeek,
  });

  /// 是否为事件拖拽
  bool get isEvent => type == DragDataType.event;

  /// 是否为课程拖拽
  bool get isCourse => type == DragDataType.course;

  /// 获取事件数据
  Event? get event => isEvent ? data as Event : null;

  /// 获取课程数据
  Course? get course => isCourse ? data as Course : null;

  /// 创建事件拖拽数据
  factory DragData.fromEvent(Event event) {
    return DragData(
      type: DragDataType.event,
      data: event,
      originalTime: event.startTime,
    );
  }

  /// 创建课程拖拽数据
  factory DragData.fromCourse(Course course) {
    return DragData(
      type: DragDataType.course,
      data: course,
      originalTime: DateTime.now(),
      originalSection: course.startSection,
      originalDayOfWeek: course.dayOfWeek,
    );
  }
}

/// 放置目标
class DropTarget {
  final DropTargetType type;
  final DateTime? targetDate;
  final TimeOfDay? targetTime;
  final int? targetSection;
  final int? targetDayOfWeek;

  const DropTarget({
    required this.type,
    this.targetDate,
    this.targetTime,
    this.targetSection,
    this.targetDayOfWeek,
  });

  /// 计算15分钟对齐的时间
  TimeOfDay get alignedTime {
    if (targetTime == null) return const TimeOfDay(hour: 0, minute: 0);
    final minute = (targetTime!.minute / 15).round() * 15;
    if (minute >= 60) {
      return TimeOfDay(hour: targetTime!.hour + 1, minute: 0);
    }
    return TimeOfDay(hour: targetTime!.hour, minute: minute);
  }

  /// 创建日期目标
  factory DropTarget.date(DateTime date) {
    return DropTarget(type: DropTargetType.date, targetDate: date);
  }

  /// 创建时间槽目标
  factory DropTarget.timeSlot(DateTime date, TimeOfDay time) {
    return DropTarget(
      type: DropTargetType.timeSlot,
      targetDate: date,
      targetTime: time,
    );
  }

  /// 创建课程单元格目标
  factory DropTarget.courseCell(int dayOfWeek, int section) {
    return DropTarget(
      type: DropTargetType.courseCell,
      targetDayOfWeek: dayOfWeek,
      targetSection: section,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DropTarget &&
        other.type == type &&
        other.targetDate == targetDate &&
        other.targetTime == targetTime &&
        other.targetSection == targetSection &&
        other.targetDayOfWeek == targetDayOfWeek;
  }

  @override
  int get hashCode =>
      Object.hash(type, targetDate, targetTime, targetSection, targetDayOfWeek);
}

/// 拖拽状态
class DragState {
  final DragStatus status;
  final DragData? dragData;
  final DropTarget? hoverTarget;
  final Offset? currentPosition;
  final bool showPreview;

  const DragState({
    this.status = DragStatus.idle,
    this.dragData,
    this.hoverTarget,
    this.currentPosition,
    this.showPreview = false,
  });

  /// 是否正在拖拽
  bool get isDragging => status != DragStatus.idle;

  /// 是否悬停在目标上
  bool get isHovering => status == DragStatus.hovering;

  DragState copyWith({
    DragStatus? status,
    DragData? dragData,
    DropTarget? hoverTarget,
    Offset? currentPosition,
    bool? showPreview,
    bool clearHoverTarget = false,
  }) {
    return DragState(
      status: status ?? this.status,
      dragData: dragData ?? this.dragData,
      hoverTarget: clearHoverTarget ? null : (hoverTarget ?? this.hoverTarget),
      currentPosition: currentPosition ?? this.currentPosition,
      showPreview: showPreview ?? this.showPreview,
    );
  }
}

/// 拖拽工具类
class DragUtils {
  /// 时间刻度（分钟）
  static const int timeGranularity = 15;

  /// 拖拽反馈透明度
  static const double feedbackOpacity = 0.9;

  /// 拖拽源透明度
  static const double sourceOpacity = 0.3;

  /// 放置目标高亮透明度
  static const double targetHighlightOpacity = 0.15;

  /// 长按触发延迟
  static const Duration longPressDuration = Duration(milliseconds: 300);

  /// 计算在时间槽内的分钟偏移
  static int calculateMinuteOffset(double relativeY, double slotHeight) {
    final fraction = (relativeY / slotHeight).clamp(0.0, 1.0);
    final minute = (fraction * 60).round();
    return (minute / timeGranularity).round() * timeGranularity;
  }

  /// 对齐到15分钟刻度
  static TimeOfDay alignToQuarterHour(TimeOfDay time) {
    final minute = (time.minute / timeGranularity).round() * timeGranularity;
    if (minute >= 60) {
      return TimeOfDay(hour: time.hour + 1, minute: 0);
    }
    return TimeOfDay(hour: time.hour, minute: minute);
  }

  /// 是否为有效的放置目标
  static bool isValidDropTarget({
    required DragData dragData,
    required DropTarget target,
  }) {
    if (dragData.isEvent) {
      return target.type == DropTargetType.date ||
          target.type == DropTargetType.timeSlot;
    }
    if (dragData.isCourse) {
      return target.type == DropTargetType.courseCell;
    }
    return false;
  }

  /// 判断位置是否改变
  static bool hasPositionChanged({
    required DragData dragData,
    required DropTarget target,
  }) {
    if (dragData.isEvent) {
      final event = dragData.event!;
      if (target.type == DropTargetType.date) {
        return !_isSameDay(event.startTime, target.targetDate!);
      }
      if (target.type == DropTargetType.timeSlot) {
        return !_isSameDay(event.startTime, target.targetDate!) ||
            event.startTime.hour != target.alignedTime.hour ||
            event.startTime.minute != target.alignedTime.minute;
      }
    }
    if (dragData.isCourse) {
      return dragData.originalDayOfWeek != target.targetDayOfWeek ||
          dragData.originalSection != target.targetSection;
    }
    return false;
  }

  /// 计算拖拽后的事件时间
  static ({DateTime start, DateTime end}) calculateNewEventTime({
    required Event event,
    required DateTime targetDate,
    TimeOfDay? targetTime,
  }) {
    final duration = event.endTime.difference(event.startTime);

    DateTime newStart;
    if (targetTime != null) {
      final aligned = alignToQuarterHour(targetTime);
      newStart = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        aligned.hour,
        aligned.minute,
      );
    } else {
      newStart = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        event.startTime.hour,
        event.startTime.minute,
      );
    }

    return (start: newStart, end: newStart.add(duration));
  }

  /// 计算拖拽后的课程位置
  static ({int dayOfWeek, int startSection, int endSection})
  calculateNewCoursePosition({
    required Course course,
    required int targetDayOfWeek,
    required int targetSection,
  }) {
    final span = course.sectionSpan;
    return (
      dayOfWeek: targetDayOfWeek,
      startSection: targetSection,
      endSection: targetSection + span - 1,
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 格式化日期
  static String formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  /// 格式化时间
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 获取星期名称
  static String weekdayName(int dayOfWeek) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    if (dayOfWeek < 1 || dayOfWeek > 7) return '';
    return names[dayOfWeek - 1];
  }
}
