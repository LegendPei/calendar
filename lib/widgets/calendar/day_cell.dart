/// 日期单元格组件 - 柔和极简主义风格
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

  /// 是否是节假日（显示"休"）
  final bool isHoliday;

  /// 是否是调休工作日（显示"班"）
  final bool isWorkday;

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
    this.isHoliday = false,
    this.isWorkday = false,
    this.eventCount = 0,
    this.eventColors = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWeekend = app_date_utils.DateUtils.isWeekend(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日期区域（包含数字和底部下划线）
              Stack(
                alignment: Alignment.topRight,
                children: [
                  // 日期数字
                  Container(
                    width: 36,
                    height: 36,
                    decoration: _getDateDecoration(),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: isToday
                                    ? CalendarSizes.todaySolarFontSize
                                    : CalendarSizes.solarFontSize,
                                fontWeight: isToday || isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: _getTextColor(isWeekend),
                                height: 1.0,
                              ),
                            ),
                            // 今天的红色下划线
                            if (isToday)
                              Container(
                                width: 16,
                                height: 2,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: SoftMinimalistColors.accentRed,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 休/班标记
                  if (isHoliday || isWorkday)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isHoliday
                              ? SoftMinimalistColors.accentRed
                              : SoftMinimalistColors.badgeGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isHoliday ? '休' : '班',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: isHoliday
                                ? Colors.white
                                : SoftMinimalistColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // 农历日期
              if (lunarText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    lunarText!,
                    style: TextStyle(
                      fontSize: CalendarSizes.lunarFontSize,
                      color: _getLunarTextColor(),
                      fontWeight: _isSpecialLunarDay()
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // 事件指示点
              if (eventCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildEventDots(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取日期区域装饰
  BoxDecoration? _getDateDecoration() {
    if (isSelected && !isToday) {
      return BoxDecoration(
        color: SoftMinimalistColors.softRedBg,
        borderRadius: BorderRadius.circular(8),
      );
    }
    return null;
  }

  /// 获取文字颜色
  Color _getTextColor(bool isWeekend) {
    if (!isCurrentMonth) {
      return SoftMinimalistColors.textDisabled;
    }
    if (isSelected) {
      return SoftMinimalistColors.accentRed;
    }
    if (isToday) {
      return SoftMinimalistColors.textPrimary;
    }
    if (isWeekend) {
      return SoftMinimalistColors.accentRed;
    }
    return SoftMinimalistColors.textPrimary;
  }

  /// 获取农历文字颜色
  Color _getLunarTextColor() {
    if (!isCurrentMonth) {
      return SoftMinimalistColors.textDisabled;
    }
    // 节日用红色
    if (_isSpecialLunarDay()) {
      return SoftMinimalistColors.accentRed;
    }
    return SoftMinimalistColors.textSecondary;
  }

  /// 检查是否是特殊农历日期（节日/节气）
  bool _isSpecialLunarDay() {
    if (lunarText == null) return false;
    // 简单判断：如果不是普通日期格式（初一、初二等），则认为是节日或节气
    final ordinaryDays = [
      '初一',
      '初二',
      '初三',
      '初四',
      '初五',
      '初六',
      '初七',
      '初八',
      '初九',
      '初十',
      '十一',
      '十二',
      '十三',
      '十四',
      '十五',
      '十六',
      '十七',
      '十八',
      '十九',
      '二十',
      '廿一',
      '廿二',
      '廿三',
      '廿四',
      '廿五',
      '廿六',
      '廿七',
      '廿八',
      '廿九',
      '三十',
    ];
    return !ordinaryDays.contains(lunarText);
  }

  /// 构建事件颜色点（最多显示3个不同颜色）
  List<Widget> _buildEventDots() {
    // 获取唯一颜色（最多3个）
    final colors = eventColors.isNotEmpty
        ? eventColors.take(3).toList()
        : [SoftMinimalistColors.eventIndicator];

    return colors.map((color) {
      return Container(
        width: CalendarSizes.eventIndicatorSize,
        height: CalendarSizes.eventIndicatorSize,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }).toList();
  }
}
