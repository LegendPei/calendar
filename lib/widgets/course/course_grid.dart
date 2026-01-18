/// 课程表网格组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course.dart';
import '../../models/course_schedule.dart';
import 'course_card.dart';
import 'draggable_course_card.dart';

/// 课程表网格
class CourseGrid extends ConsumerWidget {
  /// 课程表配置
  final CourseSchedule schedule;

  /// 当前周的课程列表
  final List<Course> courses;

  /// 当前周次
  final int currentWeek;

  /// 课程点击回调
  final void Function(Course course)? onCourseTap;

  /// 课程长按回调
  final void Function(Course course)? onCourseLongPress;

  /// 空格子点击回调
  final void Function(int dayOfWeek, int section)? onEmptyCellTap;

  /// 每节课的高度
  final double sectionHeight;

  /// 左侧时间列宽度
  final double timeColumnWidth;

  /// 顶部星期行高度
  final double weekdayRowHeight;

  /// 是否启用拖拽
  final bool enableDrag;

  const CourseGrid({
    super.key,
    required this.schedule,
    required this.courses,
    required this.currentWeek,
    this.onCourseTap,
    this.onCourseLongPress,
    this.onEmptyCellTap,
    this.sectionHeight = 60.0,
    this.timeColumnWidth = 40.0,
    this.weekdayRowHeight = 40.0,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 星期行
          _buildWeekdayRow(context),
          // 课程网格
          _buildGrid(context, ref),
        ],
      ),
    );
  }

  /// 构建星期行
  Widget _buildWeekdayRow(BuildContext context) {
    final dayNames = schedule.dayNames;
    final today = DateTime.now().weekday;

    return Container(
      height: weekdayRowHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 左上角空白
          SizedBox(
            width: timeColumnWidth,
            child: Center(
              child: Text(
                '周$currentWeek',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 星期列
          ...List.generate(schedule.daysPerWeek, (index) {
            final isToday = (index + 1) == today;
            return Expanded(
              child: Container(
                decoration: isToday
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                      )
                    : null,
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建课程网格
  Widget _buildGrid(BuildContext context, WidgetRef ref) {
    final totalSections = schedule.totalSections;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 左侧时间列
        SizedBox(
          width: timeColumnWidth,
          child: Column(
            children: List.generate(totalSections, (index) {
              final timeSlot = schedule.getTimeSlot(index + 1);
              final isAfternoon = index + 1 > schedule.lunchAfterSection;

              return Container(
                height: sectionHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  color: isAfternoon
                      ? Colors.orange.shade50.withValues(alpha: 0.3)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (timeSlot != null) ...[
                      Text(
                        timeSlot.startTimeString,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
        // 课程列
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(schedule.daysPerWeek, (dayIndex) {
              return Expanded(
                child: _buildDayColumn(
                  context,
                  ref,
                  dayIndex + 1,
                  totalSections,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// 构建某天的课程列
  Widget _buildDayColumn(
    BuildContext context,
    WidgetRef ref,
    int dayOfWeek,
    int totalSections,
  ) {
    // 获取这一天的课程
    final dayCourses = courses.where((c) => c.dayOfWeek == dayOfWeek).toList();

    // 构建节次占用表
    final occupied = <int, Course>{};
    for (final course in dayCourses) {
      for (int s = course.startSection; s <= course.endSection; s++) {
        occupied[s] = course;
      }
    }

    final widgets = <Widget>[];
    int section = 1;

    while (section <= totalSections) {
      if (occupied.containsKey(section)) {
        final course = occupied[section]!;
        // 这是课程的第一节
        if (course.startSection == section) {
          widgets.add(_buildCourseCell(context, ref, course));
          section = course.endSection + 1;
        } else {
          section++;
        }
      } else {
        // 空白格子
        widgets.add(_buildEmptyCell(context, ref, dayOfWeek, section));
        section++;
      }
    }

    return Column(children: widgets);
  }

  /// 构建课程格子
  Widget _buildCourseCell(BuildContext context, WidgetRef ref, Course course) {
    final height = sectionHeight * course.sectionSpan;

    final courseCard = CourseCard(
      course: course,
      schedule: schedule,
      onTap: onCourseTap != null ? () => onCourseTap!(course) : null,
      onLongPress: onCourseLongPress != null
          ? () => onCourseLongPress!(course)
          : null,
    );

    // 如果启用拖拽，包装为可拖拽组件
    if (enableDrag) {
      return SizedBox(
        height: height,
        child: DraggableCourseCard(
          course: course,
          sectionHeight: sectionHeight,
          child: courseCard,
        ),
      );
    }

    return SizedBox(height: height, child: courseCard);
  }

  /// 构建空白格子
  Widget _buildEmptyCell(
    BuildContext context,
    WidgetRef ref,
    int dayOfWeek,
    int section,
  ) {
    final isAfternoon = section > schedule.lunchAfterSection;

    Widget cell = GestureDetector(
      onTap: onEmptyCellTap != null
          ? () => onEmptyCellTap!(dayOfWeek, section)
          : null,
      child: Container(
        height: sectionHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            right: BorderSide(color: Colors.grey.shade100, width: 0.5),
          ),
          color: isAfternoon
              ? Colors.orange.shade50.withValues(alpha: 0.15)
              : null,
        ),
      ),
    );

    // 始终包装为放置目标（DragTarget需要在拖拽开始前就存在）
    if (enableDrag) {
      cell = CourseDropTarget(
        dayOfWeek: dayOfWeek,
        section: section,
        child: cell,
      );
    }

    return cell;
  }
}
