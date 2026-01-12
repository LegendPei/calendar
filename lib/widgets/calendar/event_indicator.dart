/// 事件指示点组件
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

class EventIndicator extends StatelessWidget {
  /// 事件颜色
  final Color? color;

  /// 指示点大小
  final double size;

  const EventIndicator({
    super.key,
    this.color,
    this.size = CalendarSizes.eventIndicatorSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? CalendarColors.eventIndicator,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 多事件指示点
class MultiEventIndicator extends StatelessWidget {
  /// 事件颜色列表
  final List<Color> colors;

  /// 最大显示数量
  final int maxCount;

  /// 指示点大小
  final double size;

  const MultiEventIndicator({
    super.key,
    required this.colors,
    this.maxCount = 3,
    this.size = CalendarSizes.eventIndicatorSize - 1,
  });

  @override
  Widget build(BuildContext context) {
    final displayColors = colors.take(maxCount).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: displayColors.map((color) {
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}

