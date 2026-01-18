/// 事件放置目标组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/drag_utils.dart';
import '../../providers/drag_provider.dart';

/// 日期放置目标（用于月视图）
class DateDropTarget extends ConsumerWidget {
  /// 目标日期
  final DateTime date;

  /// 子组件
  final Widget child;

  /// 是否启用
  final bool enabled;

  const DateDropTarget({
    super.key,
    required this.date,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.isEvent;
      },
      onAcceptWithDetails: (details) async {
        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(DropTarget.date(date));
        await ref.read(dragStateProvider.notifier).completeDrop();
      },
      onMove: (details) {
        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(DropTarget.date(date));
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
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}

/// 时间槽放置目标（用于周/日视图）
class TimeSlotDropTarget extends ConsumerWidget {
  /// 目标日期
  final DateTime date;

  /// 目标小时
  final int hour;

  /// 子组件
  final Widget child;

  /// 是否启用
  final bool enabled;

  /// 时间槽高度
  final double slotHeight;

  const TimeSlotDropTarget({
    super.key,
    required this.date,
    required this.hour,
    required this.child,
    this.enabled = true,
    this.slotHeight = 60.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.isEvent;
      },
      onAcceptWithDetails: (details) async {
        // 计算精确的分钟偏移
        final dragState = ref.read(dragStateProvider);
        final position = dragState.currentPosition;

        int minute = 0;
        if (position != null) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(position);
            minute = DragUtils.calculateMinuteOffset(
              localPosition.dy,
              slotHeight,
            );
          }
        }

        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(
              DropTarget.timeSlot(date, TimeOfDay(hour: hour, minute: minute)),
            );
        await ref.read(dragStateProvider.notifier).completeDrop();
      },
      onMove: (details) {
        ref
            .read(dragStateProvider.notifier)
            .updateHoverTarget(
              DropTarget.timeSlot(date, TimeOfDay(hour: hour, minute: 0)),
            );
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
                    width: 1,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }
}
