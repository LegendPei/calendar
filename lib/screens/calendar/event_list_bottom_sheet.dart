import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/event.dart';
import '../../providers/calendar_provider.dart';
import '../event/event_detail_screen.dart';
import '../event/event_form_screen.dart';

class EventListBottomSheet extends ConsumerWidget {
  const EventListBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(calendarEventsByDateProvider(selectedDate));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _getDateTitle(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                eventsAsync.when(
                  data: (events) => Text(
                    '${events.length}个事件',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addEvent(context, selectedDate, ref),
                  tooltip: '添加事件',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) => events.isEmpty
                  ? _buildEmptyState(context, selectedDate, ref)
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _buildEventItem(context, events[index], ref);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateTitle(DateTime date) {
    final today = DateTime.now();
    if (app_date_utils.DateUtils.isSameDay(date, today)) {
      return '今天 - ${app_date_utils.DateUtils.formatMonthDay(date)}';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, tomorrow)) {
      return '明天 - ${app_date_utils.DateUtils.formatMonthDay(date)}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, yesterday)) {
      return '昨天 - ${app_date_utils.DateUtils.formatMonthDay(date)}';
    }
    return app_date_utils.DateUtils.formatMonthDay(date);
  }

  Widget _buildEmptyState(BuildContext context, DateTime date, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无事件',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addEvent(context, date, ref),
            icon: const Icon(Icons.add),
            label: const Text('添加新事件'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Event event, WidgetRef ref) {
    final color = event.color != null ? Color(event.color!) : CalendarColors.today;

    return ListTile(
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        event.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        event.allDay
            ? '全天'
            : '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      onTap: () => _viewEvent(context, event, ref),
    );
  }

  Future<void> _viewEvent(BuildContext context, Event event, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );

    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }

  Future<void> _addEvent(BuildContext context, DateTime date, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(initialDate: date),
      ),
    );

    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }
}

