/// 可拖拽事件卡片组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/drag_utils.dart';
import '../../models/event.dart';
import '../../providers/drag_provider.dart';

/// 可拖拽事件卡片
class DraggableEventCard extends ConsumerWidget {
  /// 事件数据
  final Event event;

  /// 子组件
  final Widget child;

  /// 是否启用拖拽
  final bool enabled;

  /// 反馈组件宽度
  final double? feedbackWidth;

  /// 反馈组件高度
  final double? feedbackHeight;

  const DraggableEventCard({
    super.key,
    required this.event,
    required this.child,
    this.enabled = true,
    this.feedbackWidth,
    this.feedbackHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return LongPressDraggable<DragData>(
      data: DragData.fromEvent(event),
      delay: DragUtils.longPressDuration,
      onDragStarted: () {
        ref.read(dragStateProvider.notifier).startDragEvent(event);
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
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: feedbackWidth ?? 150,
          height: feedbackHeight,
          child: Opacity(opacity: DragUtils.feedbackOpacity, child: child),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: DragUtils.sourceOpacity,
        child: child,
      ),
      child: child,
    );
  }
}

/// 可拖拽事件指示器（用于月视图）
class DraggableEventIndicator extends ConsumerWidget {
  /// 事件数据
  final Event event;

  /// 事件颜色
  final Color color;

  /// 是否启用拖拽
  final bool enabled;

  /// 点击回调
  final VoidCallback? onTap;

  const DraggableEventIndicator({
    super.key,
    required this.event,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicator = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );

    if (!enabled) return indicator;

    return LongPressDraggable<DragData>(
      data: DragData.fromEvent(event),
      delay: DragUtils.longPressDuration,
      onDragStarted: () {
        ref.read(dragStateProvider.notifier).startDragEvent(event);
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            event.title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: DragUtils.sourceOpacity,
        child: indicator,
      ),
      child: indicator,
    );
  }
}

/// 可拖拽事件块（用于周/日视图）
class DraggableEventBlock extends ConsumerWidget {
  /// 事件数据
  final Event event;

  /// 子组件
  final Widget child;

  /// 是否启用拖拽
  final bool enabled;

  /// 点击回调
  final VoidCallback? onTap;

  const DraggableEventBlock({
    super.key,
    required this.event,
    required this.child,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = GestureDetector(onTap: onTap, child: child);

    if (!enabled) return content;

    final color = event.color != null
        ? Color(event.color!)
        : Theme.of(context).colorScheme.primary;

    return LongPressDraggable<DragData>(
      data: DragData.fromEvent(event),
      delay: DragUtils.longPressDuration,
      onDragStarted: () {
        ref.read(dragStateProvider.notifier).startDragEvent(event);
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
          width: 100,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${DragUtils.formatTime(TimeOfDay.fromDateTime(event.startTime))} - ${DragUtils.formatTime(TimeOfDay.fromDateTime(event.endTime))}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: DragUtils.sourceOpacity,
        child: child,
      ),
      child: content,
    );
  }
}
