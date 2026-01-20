// 可折叠的月视图组件 - 支持拖拽折叠到周视图
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/calendar_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/drag_provider.dart';
import '../../providers/lunar_provider.dart';
import '../../providers/settings_provider.dart';
import 'day_cell.dart';
import 'event_drop_targets.dart';

/// 可折叠月视图
class CollapsibleMonthView extends ConsumerStatefulWidget {
  final DateTime date;

  const CollapsibleMonthView({super.key, required this.date});

  @override
  ConsumerState<CollapsibleMonthView> createState() =>
      _CollapsibleMonthViewState();
}

class _CollapsibleMonthViewState extends ConsumerState<CollapsibleMonthView> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final collapseProgress = ref.watch(monthViewCollapseProvider);
    final dates = app_date_utils.DateUtils.getMonthViewDates(widget.date);
    final eventsByMonthAsync = ref.watch(
      calendarEventsByMonthProvider(widget.date),
    );
    final courseCountByMonthAsync = ref.watch(
      courseCountByMonthProvider(widget.date),
    );

    // 计算选中日期所在的周索引 (0-5)
    final selectedWeekIndex = _getWeekIndexForDate(dates, selectedDate);

    return Column(
      children: [
        // 星期标题行
        _buildWeekdayHeader(),
        const SizedBox(height: 8),
        // 日期网格 - 根据折叠进度显示
        Expanded(
          child: eventsByMonthAsync.when(
            data: (eventsByMonth) {
              final courseCountByMonth =
                  courseCountByMonthAsync.valueOrNull ?? {};
              return _buildCollapsibleGrid(
                context,
                dates,
                widget.date,
                selectedDate,
                eventsByMonth,
                courseCountByMonth,
                collapseProgress,
                selectedWeekIndex,
              );
            },
            loading: () => _buildCollapsibleGrid(
              context,
              dates,
              widget.date,
              selectedDate,
              {},
              {},
              collapseProgress,
              selectedWeekIndex,
            ),
            error: (e, _) => _buildCollapsibleGrid(
              context,
              dates,
              widget.date,
              selectedDate,
              {},
              {},
              collapseProgress,
              selectedWeekIndex,
            ),
          ),
        ),
      ],
    );
  }

  /// 获取日期所在的周索引
  int _getWeekIndexForDate(List<DateTime> dates, DateTime targetDate) {
    for (int i = 0; i < dates.length; i++) {
      if (app_date_utils.DateUtils.isSameDay(dates[i], targetDate)) {
        return i ~/ 7;
      }
    }
    // 如果没找到，返回当前月的第一周
    return 0;
  }

  /// 构建星期标题行
  Widget _buildWeekdayHeader() {
    return Container(
      height: CalendarSizes.weekdayRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: AppConstants.weekdayNames.map((name) {
          final isWeekend = name == '六' || name == '日';
          return Expanded(
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isWeekend
                      ? SoftMinimalistColors.accentRed
                      : SoftMinimalistColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建可折叠的日期网格
  Widget _buildCollapsibleGrid(
    BuildContext context,
    List<DateTime> dates,
    DateTime focusedDate,
    DateTime selectedDate,
    Map<DateTime, List<dynamic>> eventsByMonth,
    Map<DateTime, int> courseCountByMonth,
    double collapseProgress,
    int selectedWeekIndex,
  ) {
    if (dates.isEmpty) {
      return const Center(child: Text('没有日期数据'));
    }

    final isDragging = ref.watch(isDraggingProvider);
    final totalWeeks = (dates.length / 7).ceil();

    // 构建所有周的行
    final List<Widget> weekRows = [];
    for (int weekIndex = 0; weekIndex < totalWeeks; weekIndex++) {
      final startIdx = weekIndex * 7;
      final weekDates = dates.skip(startIdx).take(7).toList();

      final isSelectedWeek = weekIndex == selectedWeekIndex;

      // 计算该周的不透明度和高度因子
      // 选中的周始终显示，其他周根据折叠进度渐隐
      final weekOpacity = isSelectedWeek ? 1.0 : (1.0 - collapseProgress);
      // 非选中周在折叠时完全消失
      final weekFlex = isSelectedWeek
          ? 1.0
          : (1.0 - collapseProgress).clamp(0.0, 1.0);

      if (weekFlex > 0.01) {
        weekRows.add(
          Expanded(
            flex: (weekFlex * 100).round().clamp(1, 100),
            child: AnimatedOpacity(
              opacity: weekOpacity.clamp(0.0, 1.0),
              duration: const Duration(milliseconds: 50),
              child: _buildWeekRow(
                context,
                weekDates,
                focusedDate,
                selectedDate,
                eventsByMonth,
                courseCountByMonth,
                isDragging,
                isSelectedWeek && collapseProgress > 0.5,
              ),
            ),
          ),
        );
      }
    }

    return Column(children: weekRows);
  }

  /// 构建单周行
  Widget _buildWeekRow(
    BuildContext context,
    List<DateTime> weekDates,
    DateTime focusedDate,
    DateTime selectedDate,
    Map<DateTime, List<dynamic>> eventsByMonth,
    Map<DateTime, int> courseCountByMonth,
    bool isDragging,
    bool isHighlighted,
  ) {
    final cells = <Widget>[];

    for (final cellDate in weekDates) {
      final isCurrentMonth = cellDate.month == focusedDate.month;
      final isSelected = app_date_utils.DateUtils.isSameDay(
        cellDate,
        selectedDate,
      );
      final isToday = app_date_utils.DateUtils.isToday(cellDate);
      final dateOnly = app_date_utils.DateUtils.dateOnly(cellDate);
      final dayEvents = eventsByMonth[dateOnly] ?? [];
      final eventCount = dayEvents.length;
      final courseCount = courseCountByMonth[dateOnly] ?? 0;
      final eventColors = dayEvents.take(3).map((e) {
        final event = e as dynamic;
        return event.color != null
            ? Color(event.color as int)
            : SoftMinimalistColors.eventIndicator;
      }).toList();

      Widget cell = DayCell(
        date: cellDate,
        isSelected: isSelected,
        isToday: isToday,
        isCurrentMonth: isCurrentMonth,
        lunarText: _getLunarText(cellDate),
        eventCount: eventCount,
        eventColors: eventColors.cast<Color>(),
        courseCount: courseCount,
        onTap: () {
          ref.read(calendarControllerProvider).selectDate(cellDate);
        },
      );

      if (isDragging) {
        cell = DateDropTarget(date: cellDate, child: cell);
      }

      cells.add(Expanded(child: cell));
    }

    return Container(
      decoration: isHighlighted
          ? BoxDecoration(
              color: SoftMinimalistColors.softRedBg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cells,
      ),
    );
  }

  String? _getLunarText(DateTime date) {
    final showLunar = ref.watch(showLunarProvider);
    final showHoliday = ref.watch(showHolidayProvider);

    // 如果两个都关闭，不显示任何农历信息
    if (!showLunar && !showHoliday) {
      return null;
    }

    try {
      final lunar = ref.read(lunarDateProvider(date));

      // 如果是节日或节气
      final isSpecialDay = lunar.festival != null || lunar.solarTerm != null;

      if (isSpecialDay) {
        // 只有开启节假日显示才显示节日/节气
        if (showHoliday) {
          return lunar.displayText;
        } else if (showLunar) {
          // 节假日关闭但农历开启，显示普通农历日期
          return lunar.dayName;
        }
        return null;
      } else {
        // 普通农历日期，根据农历设置显示
        if (showLunar) {
          return lunar.displayText;
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
