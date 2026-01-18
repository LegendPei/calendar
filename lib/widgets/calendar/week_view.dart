/// 周视图组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/event.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/drag_provider.dart';
import '../../screens/event/event_detail_screen.dart';
import 'draggable_event_card.dart';
import 'event_drop_targets.dart';

class WeekView extends ConsumerWidget {
  const WeekView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekDates = ref.watch(weekViewDatesProvider);

    return Column(
      children: [
        // 星期标题和日期行
        _buildWeekHeader(context, ref, weekDates, selectedDate),
        // 全天事件区域
        _AllDayEventsSection(weekDates: weekDates),
        // 时间轴
        Expanded(child: _TimeGridSection(weekDates: weekDates)),
      ],
    );
  }

  /// 构建周头部
  Widget _buildWeekHeader(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> weekDates,
    DateTime selectedDate,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // 时间列占位
          const SizedBox(width: 50),
          // 日期列
          ...weekDates.map((date) {
            final isSelected = app_date_utils.DateUtils.isSameDay(
              date,
              selectedDate,
            );
            final isToday = app_date_utils.DateUtils.isToday(date);
            final isWeekend = app_date_utils.DateUtils.isWeekend(date);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(calendarControllerProvider).selectDate(date);
                },
                child: Column(
                  children: [
                    Text(
                      AppConstants.weekdayNames[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        color: isWeekend
                            ? CalendarColors.weekend
                            : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CalendarColors.selected
                            : isToday
                            ? CalendarColors.today.withValues(alpha: 0.1)
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : null,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? CalendarColors.today
                                : isWeekend
                                ? CalendarColors.weekend
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 全天事件区域
class _AllDayEventsSection extends ConsumerWidget {
  final List<DateTime> weekDates;

  const _AllDayEventsSection({required this.weekDates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 60),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标签
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '全天',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 每天的全天事件
          ...weekDates.map((date) {
            return Expanded(child: _AllDayEventColumn(date: date));
          }),
        ],
      ),
    );
  }
}

/// 每天的全天事件列
class _AllDayEventColumn extends ConsumerWidget {
  final DateTime date;

  const _AllDayEventColumn({required this.date});

  /// 判断事件是否为多天事件
  bool _isMultiDayEvent(Event event) {
    final startDate = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
    );
    final endDate = DateTime(
      event.endTime.year,
      event.endTime.month,
      event.endTime.day,
    );
    return endDate.isAfter(startDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsByDateProvider(date));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: eventsAsync.when(
        data: (events) {
          // 全天事件或多天事件都显示在全天栏
          final allDayEvents = events
              .where((e) => e.allDay || _isMultiDayEvent(e))
              .toList();
          if (allDayEvents.isEmpty) {
            return const SizedBox.shrink();
          }
          return SingleChildScrollView(
            child: Column(
              children: allDayEvents.map((event) {
                return _buildAllDayEventBlock(context, event, ref);
              }).toList(),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAllDayEventBlock(
    BuildContext context,
    Event event,
    WidgetRef ref,
  ) {
    final color = event.color != null
        ? Color(event.color!)
        : CalendarColors.today;
    final textColor = ColorUtils.getEventTextColor(color);
    return GestureDetector(
      onTap: () => _viewEvent(context, event, ref),
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          event.title,
          style: TextStyle(
            fontSize: 9,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _viewEvent(
    BuildContext context,
    Event event,
    WidgetRef ref,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }
}

/// 时间网格区域
class _TimeGridSection extends ConsumerWidget {
  final List<DateTime> weekDates;

  const _TimeGridSection({required this.weekDates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, hour) {
        return _TimeRow(weekDates: weekDates, hour: hour);
      },
    );
  }
}

/// 时间行
class _TimeRow extends ConsumerWidget {
  final List<DateTime> weekDates;
  final int hour;

  const _TimeRow({required this.weekDates, required this.hour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: CalendarSizes.timeSlotHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 每天的事件列
          ...weekDates.map((date) {
            return Expanded(
              child: _DayColumn(date: date, hour: hour),
            );
          }),
        ],
      ),
    );
  }
}

/// 每天的事件列
class _DayColumn extends ConsumerWidget {
  final DateTime date;
  final int hour;

  const _DayColumn({required this.date, required this.hour});

  /// 判断事件是否为多天事件
  bool _isMultiDayEvent(Event event) {
    final startDate = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
    );
    final endDate = DateTime(
      event.endTime.year,
      event.endTime.month,
      event.endTime.day,
    );
    return endDate.isAfter(startDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(calendarEventsByDateProvider(date));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDragging = ref.watch(isDraggingProvider);

    // 构建事件区域
    Widget eventArea = eventsAsync.when(
      data: (events) {
        final hourEvents = events.where((e) {
          // 排除全天事件和多天事件（它们显示在全天栏）
          if (e.allDay || _isMultiDayEvent(e)) return false;
          return e.startTime.hour == hour;
        }).toList();

        if (hourEvents.isEmpty) {
          return const SizedBox.expand();
        }

        // 显示第一个事件，如果有多个显示数量
        final eventBlock = _buildEventBlock(
          hourEvents.first,
          hourEvents.length,
        );

        return DraggableEventBlock(
          event: hourEvents.first,
          onTap: () => _showEventsDialog(context, hourEvents, ref),
          child: eventBlock,
        );
      },
      loading: () => const SizedBox.expand(),
      error: (_, __) => const SizedBox.expand(),
    );

    Widget content = Container(
      height: CalendarSizes.timeSlotHeight,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: eventArea,
    );

    // 拖拽时包装为放置目标
    if (isDragging) {
      content = TimeSlotDropTarget(
        date: date,
        hour: hour,
        slotHeight: CalendarSizes.timeSlotHeight,
        child: content,
      );
    }

    return content;
  }

  void _showEventsDialog(
    BuildContext context,
    List<Event> events,
    WidgetRef ref,
  ) {
    if (events.length == 1) {
      _viewEvent(context, events.first, ref);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hour.toString().padLeft(2, '0')}:00 的事件',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...events.map((event) {
              final color = event.color != null
                  ? Color(event.color!)
                  : CalendarColors.today;
              return ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(event.title),
                subtitle: Text(
                  '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewEvent(context, event, ref);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _viewEvent(
    BuildContext context,
    Event event,
    WidgetRef ref,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }

  Widget _buildEventBlock(Event event, int totalCount) {
    final color = event.color != null
        ? Color(event.color!)
        : CalendarColors.today;
    final textColor = ColorUtils.getEventTextColor(color);
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(fontSize: 9, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (totalCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${totalCount - 1}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 支持指定日期的周视图组件
class WeekViewForDate extends ConsumerWidget {
  final DateTime date;

  const WeekViewForDate({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekDates = app_date_utils.DateUtils.getWeekViewDates(date);

    return Column(
      children: [
        // 星期标题和日期行
        _buildWeekHeader(context, ref, weekDates, selectedDate),
        // 全天事件区域
        _AllDayEventsSectionForDate(weekDates: weekDates),
        // 时间轴
        Expanded(child: _TimeGridSectionForDate(weekDates: weekDates)),
      ],
    );
  }

  Widget _buildWeekHeader(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> weekDates,
    DateTime selectedDate,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50),
          ...weekDates.map((date) {
            final isSelected = app_date_utils.DateUtils.isSameDay(
              date,
              selectedDate,
            );
            final isToday = app_date_utils.DateUtils.isToday(date);
            final isWeekend = app_date_utils.DateUtils.isWeekend(date);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(calendarControllerProvider).selectDate(date);
                },
                child: Column(
                  children: [
                    Text(
                      AppConstants.weekdayNames[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        color: isWeekend
                            ? CalendarColors.weekend
                            : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CalendarColors.selected
                            : isToday
                            ? CalendarColors.today.withValues(alpha: 0.1)
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isToday || isSelected
                                ? FontWeight.bold
                                : null,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                ? CalendarColors.today
                                : isWeekend
                                ? CalendarColors.weekend
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 全天事件区域（支持指定日期）
class _AllDayEventsSectionForDate extends ConsumerWidget {
  final List<DateTime> weekDates;

  const _AllDayEventsSectionForDate({required this.weekDates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 60),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标签
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '全天',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 每天的全天事件
          ...weekDates.map((date) {
            return Expanded(child: _AllDayEventColumn(date: date));
          }),
        ],
      ),
    );
  }
}

/// 时间网格区域（支持指定日期）
class _TimeGridSectionForDate extends ConsumerWidget {
  final List<DateTime> weekDates;

  const _TimeGridSectionForDate({required this.weekDates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, hour) {
        return _TimeRowForDate(weekDates: weekDates, hour: hour);
      },
    );
  }
}

/// 时间行（支持指定日期）
class _TimeRowForDate extends ConsumerWidget {
  final List<DateTime> weekDates;
  final int hour;

  const _TimeRowForDate({required this.weekDates, required this.hour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: CalendarSizes.timeSlotHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 每天的事件列
          ...weekDates.map((date) {
            return Expanded(
              child: _DayColumn(date: date, hour: hour),
            );
          }),
        ],
      ),
    );
  }
}
