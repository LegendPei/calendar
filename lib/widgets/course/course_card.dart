// 课程卡片组件
import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/course_status_utils.dart';
import '../../models/course.dart';
import '../../models/course_schedule.dart';

/// 课程卡片 - 用于课程表网格中显示
class CourseCard extends StatelessWidget {
  /// 课程
  final Course course;

  /// 课程表配置
  final CourseSchedule? schedule;

  /// 课程状态（可选，用于显示不同样式）
  final CourseStatus? status;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  const CourseCard({
    super.key,
    required this.course,
    this.schedule,
    this.status,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(course.color);
    final isCompleted = status == CourseStatus.completed;
    final isOngoing = status == CourseStatus.ongoing;
    final isToday = status == CourseStatus.today;

    // 根据状态调整颜色
    final color = isCompleted ? _getCompletedColor(baseColor) : baseColor;
    final textColor = _getTextColor(color, isCompleted: isCompleted);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: _getBorder(isOngoing, isToday, baseColor),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 状态标签（正在上课/即将开始）
                if (isOngoing || isToday) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isOngoing
                          ? SoftMinimalistColors.success
                          : CalendarColors.today,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOngoing ? '上课中' : '今日',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                // 课程名称
                Text(
                  course.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.2,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 地点
                if (course.location != null && course.location!.isNotEmpty)
                  Text(
                    course.location!,
                    style: TextStyle(
                      fontSize: 9,
                      color: textColor.withValues(alpha: 0.85),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // 教师
                if (course.teacher != null && course.teacher!.isNotEmpty)
                  Text(
                    course.teacher!,
                    style: TextStyle(
                      fontSize: 9,
                      color: textColor.withValues(alpha: 0.85),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            // 正在上课脉冲指示器
            if (isOngoing)
              Positioned(
                top: 0,
                right: 0,
                child: _OngoingIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取已完成课程的颜色（置灰）
  Color _getCompletedColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withSaturation((hsl.saturation * 0.3).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.9 + 0.1).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.6);
  }

  /// 根据背景色计算文字颜色
  Color _getTextColor(Color backgroundColor, {bool isCompleted = false}) {
    final luminance = backgroundColor.computeLuminance();
    final baseTextColor = luminance > 0.5 ? Colors.black87 : Colors.white;
    return isCompleted ? baseTextColor.withValues(alpha: 0.6) : baseTextColor;
  }

  /// 获取边框样式
  Border? _getBorder(bool isOngoing, bool isToday, Color baseColor) {
    if (isOngoing) {
      return Border.all(
        color: SoftMinimalistColors.success,
        width: 2,
      );
    }
    if (isToday) {
      return Border.all(
        color: CalendarColors.today,
        width: 2,
      );
    }
    return null;
  }
}

/// 正在上课指示器（带脉冲动画）
class _OngoingIndicator extends StatefulWidget {
  @override
  State<_OngoingIndicator> createState() => _OngoingIndicatorState();
}

class _OngoingIndicatorState extends State<_OngoingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: SoftMinimalistColors.success.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: SoftMinimalistColors.success.withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 课程详情卡片 - 用于列表展示
class CourseDetailCard extends StatelessWidget {
  /// 课程
  final Course course;

  /// 课程表配置
  final CourseSchedule? schedule;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 编辑回调
  final VoidCallback? onEdit;

  const CourseDetailCard({
    super.key,
    required this.course,
    this.schedule,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(course.color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 课程名称
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SoftMinimalistColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 时间
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: SoftMinimalistColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.dayOfWeekName} ${course.sectionDescription}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.weeksDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // 地点
                    if (course.location != null &&
                        course.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course.location!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: SoftMinimalistColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 教师
                    if (course.teacher != null &&
                        course.teacher!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.teacher!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: SoftMinimalistColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // 提醒
                    if (course.reminderMinutes != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            size: 14,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.reminderDescription,
                            style: const TextStyle(
                              fontSize: 13,
                              color: SoftMinimalistColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 操作按钮
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: SoftMinimalistColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '删除',
                              style: TextStyle(color: SoftMinimalistColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              else
                const Icon(
                  Icons.chevron_right,
                  color: SoftMinimalistColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
