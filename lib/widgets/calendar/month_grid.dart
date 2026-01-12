/// 月视图网格组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../providers/calendar_provider.dart';
import '../../providers/lunar_provider.dart';
import 'day_cell.dart';

class MonthGrid extends ConsumerWidget {
  const MonthGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(focusedDateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dates = ref.watch(monthViewDatesProvider);
    final eventsByMonthAsync = ref.watch(calendarEventsByMonthProvider(focusedDate));

    return Column(
      children: [
        // 星期标题行
        _buildWeekdayHeader(),
        // 日期网格
        Expanded(
          child: eventsByMonthAsync.when(
            data: (eventsByMonth) => _buildDateGrid(
              context,
              ref,
              dates,
              focusedDate,
              selectedDate,
              eventsByMonth,
            ),
            loading: () => _buildDateGrid(
              context,
              ref,
              dates,
              focusedDate,
              selectedDate,
              {},
            ),
            error: (e, __) => _buildDateGrid(
              context,
              ref,
              dates,
              focusedDate,
              selectedDate,
              {},
            ),
          ),
        ),
      ],
    );
  }

  /// 构建星期标题行
  Widget _buildWeekdayHeader() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: CalendarSizes.weekdayRowHeight,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          child: Row(
            children: AppConstants.weekdayNames.map((name) {
              final isWeekend = name == '六' || name == '日';
              return Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isWeekend
                          ? CalendarColors.weekend
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 构建日期网格
  Widget _buildDateGrid(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> dates,
    DateTime focusedDate,
    DateTime selectedDate,
    Map<DateTime, List<dynamic>> eventsByMonth,
  ) {
    if (dates.isEmpty) {
      return const Center(child: Text('没有日期数据'));
    }

    // 使用Column + Row构建简单的网格
    final rows = <Widget>[];
    for (int i = 0; i < dates.length; i += 7) {
      final cells = <Widget>[];
      for (int j = 0; j < 7 && i + j < dates.length; j++) {
        final date = dates[i + j];
        final isCurrentMonth = date.month == focusedDate.month;
        final isSelected = app_date_utils.DateUtils.isSameDay(date, selectedDate);
        final isToday = app_date_utils.DateUtils.isToday(date);
        final dateOnly = app_date_utils.DateUtils.dateOnly(date);
        final dayEvents = eventsByMonth[dateOnly] ?? [];
        final eventCount = dayEvents.length;
        // 获取事件颜色列表
        final eventColors = dayEvents.take(3).map((e) {
          final event = e as dynamic;
          return event.color != null ? Color(event.color as int) : CalendarColors.today;
        }).toList();

        cells.add(
          Expanded(
            child: DayCell(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
              isCurrentMonth: isCurrentMonth,
              lunarText: _getLunarText(ref, date),
              eventCount: eventCount,
              eventColors: eventColors.cast<Color>(),
              onTap: () {
                ref.read(calendarControllerProvider).selectDate(date);
              },
            ),
          ),
        );
      }
      rows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }

    return Column(
      children: rows,
    );
  }

  /// 获取农历文本
  String _getLunarText(WidgetRef ref, DateTime date) {
    try {
      final lunar = ref.read(lunarDateProvider(date));
      return lunar.displayText;
    } catch (e) {
      return '';
    }
  }
}

/// 支持指定日期的月视图网格组件
class MonthGridForDate extends ConsumerWidget {
  final DateTime date;

  const MonthGridForDate({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dates = app_date_utils.DateUtils.getMonthViewDates(date);
    final eventsByMonthAsync = ref.watch(calendarEventsByMonthProvider(date));

    return Column(
      children: [
        // 星期标题行
        _buildWeekdayHeader(context),
        // 日期网格
        Expanded(
          child: eventsByMonthAsync.when(
            data: (eventsByMonth) => _buildDateGrid(
              context,
              ref,
              dates,
              date,
              selectedDate,
              eventsByMonth,
            ),
            loading: () => _buildDateGrid(
              context,
              ref,
              dates,
              date,
              selectedDate,
              {},
            ),
            error: (e, __) => _buildDateGrid(
              context,
              ref,
              dates,
              date,
              selectedDate,
              {},
            ),
          ),
        ),
      ],
    );
  }

  /// 构建星期标题行
  Widget _buildWeekdayHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: CalendarSizes.weekdayRowHeight,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      child: Row(
        children: AppConstants.weekdayNames.map((name) {
          final isWeekend = name == '六' || name == '日';
          return Expanded(
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isWeekend
                      ? CalendarColors.weekend
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建日期网格
  Widget _buildDateGrid(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> dates,
    DateTime focusedDate,
    DateTime selectedDate,
    Map<DateTime, List<dynamic>> eventsByMonth,
  ) {
    if (dates.isEmpty) {
      return const Center(child: Text('没有日期数据'));
    }

    final rows = <Widget>[];
    for (int i = 0; i < dates.length; i += 7) {
      final cells = <Widget>[];
      for (int j = 0; j < 7 && i + j < dates.length; j++) {
        final cellDate = dates[i + j];
        final isCurrentMonth = cellDate.month == focusedDate.month;
        final isSelected = app_date_utils.DateUtils.isSameDay(cellDate, selectedDate);
        final isToday = app_date_utils.DateUtils.isToday(cellDate);
        final dateOnly = app_date_utils.DateUtils.dateOnly(cellDate);
        final dayEvents = eventsByMonth[dateOnly] ?? [];
        final eventCount = dayEvents.length;
        final eventColors = dayEvents.take(3).map((e) {
          final event = e as dynamic;
          return event.color != null ? Color(event.color as int) : CalendarColors.today;
        }).toList();

        cells.add(
          Expanded(
            child: DayCell(
              date: cellDate,
              isSelected: isSelected,
              isToday: isToday,
              isCurrentMonth: isCurrentMonth,
              lunarText: _getLunarText(ref, cellDate),
              eventCount: eventCount,
              eventColors: eventColors.cast<Color>(),
              onTap: () {
                ref.read(calendarControllerProvider).selectDate(cellDate);
              },
            ),
          ),
        );
      }
      rows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }

    return Column(
      children: rows,
    );
  }

  String _getLunarText(WidgetRef ref, DateTime date) {
    try {
      final lunar = ref.read(lunarDateProvider(date));
      return lunar.displayText;
    } catch (e) {
      return '';
    }
  }
}

