/// 日历头部导航组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/calendar_view_type.dart';
import '../../providers/calendar_provider.dart';

class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(focusedDateProvider);
    final viewType = ref.watch(calendarViewTypeProvider);
    final controller = ref.read(calendarControllerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 左箭头
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _onPrevious(controller, viewType),
            tooltip: '上一${viewType.displayName}',
          ),
          // 年月显示
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatePicker(context, ref),
              child: Text(
                _getTitle(focusedDate, viewType, ref),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 右箭头
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _onNext(controller, viewType),
            tooltip: '下一${viewType.displayName}',
          ),
          const SizedBox(width: 8),
          // 今日按钮
          TextButton(
            onPressed: controller.goToToday,
            child: const Text('今天'),
          ),
          // 视图切换按钮
          PopupMenuButton<CalendarViewType>(
            icon: const Icon(Icons.view_module),
            tooltip: '切换视图',
            onSelected: controller.switchView,
            itemBuilder: (context) {
              return CalendarViewType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getViewIcon(type),
                        size: 20,
                        color: type == viewType
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${type.displayName}视图',
                        style: TextStyle(
                          color: type == viewType
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          fontWeight:
                              type == viewType ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  /// 获取标题文本
  String _getTitle(DateTime date, CalendarViewType viewType, WidgetRef ref) {
    switch (viewType) {
      case CalendarViewType.month:
        return app_date_utils.DateUtils.formatYearMonth(date);
      case CalendarViewType.week:
        final selectedDate = ref.read(selectedDateProvider);
        final weekDates = app_date_utils.DateUtils.getWeekViewDates(selectedDate);
        final firstDay = weekDates.first;
        final lastDay = weekDates.last;
        if (firstDay.month == lastDay.month) {
          return '${app_date_utils.DateUtils.formatYearMonth(firstDay)} ${firstDay.day}-${lastDay.day}日';
        }
        return '${firstDay.month}月${firstDay.day}日 - ${lastDay.month}月${lastDay.day}日';
      case CalendarViewType.day:
        final selectedDate = ref.read(selectedDateProvider);
        return '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日';
    }
  }

  /// 获取视图图标
  IconData _getViewIcon(CalendarViewType type) {
    switch (type) {
      case CalendarViewType.month:
        return Icons.calendar_view_month;
      case CalendarViewType.week:
        return Icons.calendar_view_week;
      case CalendarViewType.day:
        return Icons.calendar_view_day;
    }
  }

  /// 上一个
  void _onPrevious(CalendarController controller, CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.month:
        controller.goToPreviousMonth();
        break;
      case CalendarViewType.week:
        controller.goToPreviousWeek();
        break;
      case CalendarViewType.day:
        controller.goToPreviousDay();
        break;
    }
  }

  /// 下一个
  void _onNext(CalendarController controller, CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.month:
        controller.goToNextMonth();
        break;
      case CalendarViewType.week:
        controller.goToNextWeek();
        break;
      case CalendarViewType.day:
        controller.goToNextDay();
        break;
    }
  }

  /// 显示日期选择器
  Future<void> _showDatePicker(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(selectedDateProvider);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      ref.read(calendarControllerProvider).goToDate(pickedDate);
    }
  }
}

