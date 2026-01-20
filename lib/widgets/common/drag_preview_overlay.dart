/// 拖拽预览覆盖层组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/drag_utils.dart';
import '../../providers/drag_provider.dart';

/// 拖拽预览覆盖层
/// 在拖拽过程中显示目标位置的预览信息
class DragPreviewOverlay extends ConsumerWidget {
  /// 子组件
  final Widget child;

  const DragPreviewOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(dragStateProvider);

    return Stack(
      children: [
        child,
        if (dragState.showPreview && dragState.hoverTarget != null)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildPreviewCard(context, dragState),
          ),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context, DragState state) {
    final target = state.hoverTarget!;
    final hasConflict = state.hasConflict;
    String previewText = _getPreviewText(target);

    // 根据是否有冲突选择颜色
    final backgroundColor = hasConflict
        ? SoftMinimalistColors.warningLight
        : Theme.of(context).colorScheme.primaryContainer;
    final iconColor = hasConflict
        ? SoftMinimalistColors.warning
        : Theme.of(context).colorScheme.primary;
    final textColor = hasConflict
        ? SoftMinimalistColors.textPrimary
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: backgroundColor,
      child: Container(
        decoration: hasConflict
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SoftMinimalistColors.warning,
                  width: 2,
                ),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasConflict ? Icons.warning_amber_rounded : Icons.location_on,
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 4),
                Text(
                  previewText,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // 冲突提示
            if (hasConflict && state.conflictCourseNames.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '⚠️ 与课程【${state.conflictCourseNames.join("、")}】冲突',
                style: TextStyle(
                  fontSize: 11,
                  color: SoftMinimalistColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPreviewText(DropTarget target) {
    switch (target.type) {
      case DropTargetType.date:
        return '移动到 ${DragUtils.formatDate(target.targetDate!)}';
      case DropTargetType.timeSlot:
        final time = target.alignedTime;
        return '移动到 ${DragUtils.formatDate(target.targetDate!)} ${DragUtils.formatTime(time)}';
      case DropTargetType.courseCell:
        return '移动到 周${DragUtils.weekdayName(target.targetDayOfWeek!)} 第${target.targetSection}节';
    }
  }
}

/// 简化版拖拽预览提示
/// 只在悬停时显示位置提示
class DragTargetHint extends ConsumerWidget {
  /// 子组件
  final Widget child;

  const DragTargetHint({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = ref.watch(isDraggingProvider);

    if (!isDragging) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '拖拽中...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
