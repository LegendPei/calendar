/// 事件列表底部区域 - 柔和极简主义风格
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
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        child: Column(
          children: [
            // 拖拽指示条
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SoftMinimalistColors.badgeGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _getDateTitle(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  eventsAsync.when(
                    data: (events) => events.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SoftMinimalistColors.softRedBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${events.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: SoftMinimalistColors.accentRed,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _addEvent(context, selectedDate, ref),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SoftMinimalistColors.badgeGray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: SoftMinimalistColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 事件列表
            Expanded(
              child: eventsAsync.when(
                data: (events) => events.isEmpty
                    ? _buildEmptyState(context, selectedDate, ref)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          return _buildEventItem(context, events[index], ref);
                        },
                      ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: SoftMinimalistColors.accentRed,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '加载失败',
                    style: TextStyle(color: SoftMinimalistColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getDateTitle(DateTime date) {
    final today = DateTime.now();
    if (app_date_utils.DateUtils.isSameDay(date, today)) {
      return '今天';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, tomorrow)) {
      return '明天';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, yesterday)) {
      return '昨天';
    }
    return '${date.month}月${date.day}日';
  }

  Widget _buildEmptyState(BuildContext context, DateTime date, WidgetRef ref) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available,
                size: 32,
                color: SoftMinimalistColors.textSecondary.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '暂无日程',
                style: TextStyle(
                  fontSize: 13,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _addEvent(context, date, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SoftMinimalistColors.softRedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 14,
                        color: SoftMinimalistColors.accentRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '添加日程',
                        style: TextStyle(
                          fontSize: 12,
                          color: SoftMinimalistColors.accentRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Event event, WidgetRef ref) {
    final color = event.color != null
        ? Color(event.color!)
        : SoftMinimalistColors.accentRed;

    return GestureDetector(
      onTap: () => _viewEvent(context, event, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 颜色条
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.allDay
                        ? '全天'
                        : '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right,
              size: 20,
              color: SoftMinimalistColors.textSecondary.withValues(alpha: 0.5),
            ),
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

  Future<void> _addEvent(
    BuildContext context,
    DateTime date,
    WidgetRef ref,
  ) async {
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
