/// 可拖拽课程卡片组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/drag_utils.dart';
import '../../models/course.dart';
import '../../providers/drag_provider.dart';

/// 可拖拽课程卡片
class DraggableCourseCard extends ConsumerWidget {
  /// 课程数据
  final Course course;

  /// 子组件
  final Widget child;

  /// 是否启用拖拽
  final bool enabled;

  /// 每节课高度（用于计算反馈组件高度）
  final double sectionHeight;

  const DraggableCourseCard({
    super.key,
    required this.course,
    required this.child,
    this.enabled = true,
    this.sectionHeight = 60.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    final color = Color(course.color);

    return LongPressDraggable<DragData>(
      data: DragData.fromCourse(course),
      delay: DragUtils.longPressDuration,
      onDragStarted: () {
        ref.read(dragStateProvider.notifier).startDragCourse(course);
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          ref.read(dragStateProvider.notifier).cancelDrag();
        }
      },
      onDragUpdate: (details) {
        ref
            .read(dragStateProvider.notifier)
            .updatePosition(details.globalPosition);
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 80,
          height: sectionHeight * course.sectionSpan - 4,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(color),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (course.location != null && course.location!.isNotEmpty)
                Text(
                  course.location!,
                  style: TextStyle(
                    fontSize: 9,
                    color: _getTextColor(color).withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: DragUtils.sourceOpacity,
        child: child,
      ),
      child: child,
    );
  }

  /// 根据背景色计算文字颜色
  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// 课程放置目标
class CourseDropTarget extends ConsumerWidget {
  /// 星期几 (1-7)
  final int dayOfWeek;

  /// 节次
  final int section;

  /// 子组件
  final Widget child;

  /// 是否启用
  final bool enabled;

  const CourseDropTarget({
    super.key,
    required this.dayOfWeek,
    required this.section,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.isCourse;
      },
      onAcceptWithDetails: (details) async {
        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(DropTarget.courseCell(dayOfWeek, section));
        await ref.read(dragStateProvider.notifier).completeDrop();
      },
      onMove: (details) {
        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(DropTarget.courseCell(dayOfWeek, section));
      },
      onLeave: (data) {
        ref.read(dragStateProvider.notifier).updateHoverTarget(null);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: isHovering
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: DragUtils.targetHighlightOpacity,
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}
