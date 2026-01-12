/// 日期单元格组件
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

class DayCell extends StatelessWidget {
  /// 日期
  final DateTime date;

  /// 是否选中
  final bool isSelected;

  /// 是否是今天
  final bool isToday;

  /// 是否是当前月
  final bool isCurrentMonth;

  /// 农历日期文本
  final String? lunarText;

  /// 事件数量
  final int eventCount;

  /// 事件颜色列表（用于显示多个颜色点）
  final List<Color> eventColors;

  /// 点击回调
  final VoidCallback? onTap;

  const DayCell({
    super.key,
    required this.date,
    this.isSelected = false,
    this.isToday = false,
    this.isCurrentMonth = true,
    this.lunarText,
    this.eventCount = 0,
    this.eventColors = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWeekend = app_date_utils.DateUtils.isWeekend(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 公历日期
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: _getTextColor(isWeekend, isDark),
                  ),
                ),
                // 农历日期（简化显示）
                if (lunarText != null)
                  Text(
                    lunarText!,
                    style: TextStyle(
                      fontSize: 9,
                      color: _getLunarTextColor(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // 事件指示点（显示多个颜色）
                if (eventCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildEventDots(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color? _getBackgroundColor() {
    if (isSelected) {
      return CalendarColors.selected.withValues(alpha: 0.2);
    }
    if (isToday) {
      return CalendarColors.today.withValues(alpha: 0.1);
    }
    return null;
  }

  /// 获取文字颜色
  Color _getTextColor(bool isWeekend, bool isDark) {
    if (!isCurrentMonth) {
      return isDark ? Colors.grey.shade600 : CalendarColors.otherMonth;
    }
    if (isSelected) {
      return CalendarColors.selected;
    }
    if (isToday) {
      return CalendarColors.today;
    }
    if (isWeekend) {
      return CalendarColors.weekend;
    }
    return isDark ? Colors.white : Colors.black87;
  }

  /// 获取农历文字颜色
  Color _getLunarTextColor(bool isDark) {
    if (!isCurrentMonth) {
      return isDark ? Colors.grey.shade700 : CalendarColors.otherMonth;
    }
    return isDark ? Colors.grey.shade400 : CalendarColors.lunarText;
  }

  /// 构建事件颜色点（最多显示3个不同颜色）
  List<Widget> _buildEventDots() {
    // 获取唯一颜色（最多3个）
    final colors = eventColors.isNotEmpty
        ? eventColors.take(3).toList()
        : [CalendarColors.today];

    return colors.map((color) {
      return Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }).toList();
  }
}

