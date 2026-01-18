/// 日视图时间轴组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/event.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/drag_provider.dart';
import '../../screens/event/event_detail_screen.dart';
import 'draggable_event_card.dart';
import 'event_drop_targets.dart';

class DayTimeline extends ConsumerWidget {
  const DayTimeline({super.key});

  /// 判断是否为多天事件
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
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(calendarEventsByDateProvider(selectedDate));

    return eventsAsync.when(
      data: (events) {
        // 全天事件和多天事件都显示在全天区域
        final allDayEvents = events
            .where((e) => e.allDay || _isMultiDayEvent(e))
            .toList();
        return Column(
          children: [
            // 全天事件区域
            if (allDayEvents.isNotEmpty)
              _buildAllDaySection(context, allDayEvents, ref),
            // 时间轴
            Expanded(
              child: ListView.builder(
                itemCount: 24,
                itemBuilder: (context, hour) {
                  final hourEvents = _getEventsForHour(
                    events,
                    selectedDate,
                    hour,
                  );
                  return _buildTimeSlot(context, ref, hour, hourEvents);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  /// 构建全天事件区域
  Widget _buildAllDaySection(
    BuildContext context,
    List<Event> allDayEvents,
    WidgetRef ref,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全天事件',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          ...allDayEvents.map(
            (event) => _buildAllDayEventItem(context, event, ref),
          ),
        ],
      ),
    );
  }

  /// 构建全天事件项
  Widget _buildAllDayEventItem(
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
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Text(
          event.title,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 获取指定小时的事件（排除全天事件和多天事件）
  List<Event> _getEventsForHour(List<Event> events, DateTime date, int hour) {
    return events.where((event) {
      // 排除全天事件和多天事件
      if (event.allDay || _isMultiDayEvent(event)) return false;
      final eventHour = event.startTime.hour;
      return eventHour == hour;
    }).toList();
  }

  /// 构建时间槽
  Widget _buildTimeSlot(
    BuildContext context,
    WidgetRef ref,
    int hour,
    List<Event> events,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDate = ref.watch(selectedDateProvider);
    final isDragging = ref.watch(isDraggingProvider);

    Widget eventArea = events.isEmpty
        ? const SizedBox.shrink()
        : DraggableEventBlock(
            event: events.first,
            onTap: () => _showEventsDialog(context, ref, hour, events),
            child: _buildEventCard(context, events.first, events.length),
          );

    Widget content = Container(
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
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          // 事件区域
          Expanded(child: eventArea),
        ],
      ),
    );

    // 拖拽时包装为放置目标
    if (isDragging) {
      content = TimeSlotDropTarget(
        date: selectedDate,
        hour: hour,
        slotHeight: CalendarSizes.timeSlotHeight,
        child: content,
      );
    }

    return content;
  }

  /// 显示事件列表弹窗
  void _showEventsDialog(
    BuildContext context,
    WidgetRef ref,
    int hour,
    List<Event> events,
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

  /// 查看事件详情
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

  /// 构建事件卡片
  Widget _buildEventCard(BuildContext context, Event event, int totalCount) {
    final color = event.color != null
        ? Color(event.color!)
        : CalendarColors.today;
    final textColor = ColorUtils.getEventTextColor(color);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // 如果有多个事件，显示数量
          if (totalCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${totalCount - 1}',
                style: const TextStyle(
                  fontSize: 10,
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

/// 支持指定日期的日视图时间轴组件
class DayTimelineForDate extends ConsumerWidget {
  final DateTime date;

  const DayTimelineForDate({super.key, required this.date});

  /// 判断是否为多天事件
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

    return eventsAsync.when(
      data: (events) {
        // 全天事件和多天事件都显示在全天区域
        final allDayEvents = events
            .where((e) => e.allDay || _isMultiDayEvent(e))
            .toList();
        return Column(
          children: [
            // 全天事件区域
            if (allDayEvents.isNotEmpty)
              _buildAllDaySection(context, allDayEvents, ref),
            // 时间轴
            Expanded(
              child: ListView.builder(
                itemCount: 24,
                itemBuilder: (context, hour) {
                  final hourEvents = _getEventsForHour(events, date, hour);
                  return _buildTimeSlot(context, ref, hour, hourEvents);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  Widget _buildAllDaySection(
    BuildContext context,
    List<Event> allDayEvents,
    WidgetRef ref,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全天事件',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          ...allDayEvents.map(
            (event) => _buildAllDayEventItem(context, event, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayEventItem(
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
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Text(
          event.title,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 获取指定小时的事件（排除全天事件和多天事件）
  List<Event> _getEventsForHour(List<Event> events, DateTime date, int hour) {
    return events.where((event) {
      // 排除全天事件和多天事件
      if (event.allDay || _isMultiDayEvent(event)) return false;
      return event.startTime.hour == hour;
    }).toList();
  }

  Widget _buildTimeSlot(
    BuildContext context,
    WidgetRef ref,
    int hour,
    List<Event> events,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDragging = ref.watch(isDraggingProvider);

    Widget eventArea = events.isEmpty
        ? const SizedBox.shrink()
        : DraggableEventBlock(
            event: events.first,
            onTap: () => _showEventsDialog(context, ref, hour, events),
            child: _buildEventCard(context, events.first, events.length),
          );

    Widget content = Container(
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
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Expanded(child: eventArea),
        ],
      ),
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
    WidgetRef ref,
    int hour,
    List<Event> events,
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

  Widget _buildEventCard(BuildContext context, Event event, int totalCount) {
    final color = event.color != null
        ? Color(event.color!)
        : CalendarColors.today;
    final textColor = ColorUtils.getEventTextColor(color);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${totalCount - 1}',
                style: const TextStyle(
                  fontSize: 10,
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
