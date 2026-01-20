/// 日程列表视图组件 - 按年度显示所有事件，支持搜索和月份折叠
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/event.dart';
import '../../providers/calendar_provider.dart';
import '../../screens/event/event_detail_screen.dart';

/// 搜索查询状态
final scheduleSearchQueryProvider = StateProvider<String>((ref) => '');

/// 折叠月份状态
final collapsedMonthsProvider = StateProvider<Set<String>>((ref) => {});

class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    return ScheduleViewForYear(year: selectedDate.year);
  }
}

/// 支持指定年份的日程视图组件
class ScheduleViewForYear extends ConsumerStatefulWidget {
  final int year;

  const ScheduleViewForYear({super.key, required this.year});

  @override
  ConsumerState<ScheduleViewForYear> createState() =>
      _ScheduleViewForYearState();
}

class _ScheduleViewForYearState extends ConsumerState<ScheduleViewForYear> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsByYearProvider(widget.year));
    final searchQuery = ref.watch(scheduleSearchQueryProvider);

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索日程...',
              hintStyle: TextStyle(
                color: SoftMinimalistColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: SoftMinimalistColors.textSecondary,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(scheduleSearchQueryProvider.notifier).state =
                            '';
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: SoftMinimalistColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              ref.read(scheduleSearchQueryProvider.notifier).state =
                  value.trim().toLowerCase();
            },
          ),
        ),
        // 事件列表
        Expanded(
          child: eventsAsync.when(
            data: (eventsByMonth) {
              if (eventsByMonth.isEmpty) {
                return _buildEmptyState(context, widget.year);
              }
              return _YearEventList(
                  year: widget.year, eventsByMonth: eventsByMonth);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, int year) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: SoftMinimalistColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '$year年暂无日程',
            style: TextStyle(
              fontSize: 16,
              color: SoftMinimalistColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加新日程',
            style: TextStyle(
              fontSize: 14,
              color: SoftMinimalistColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 年度事件列表
class _YearEventList extends ConsumerWidget {
  final int year;
  final Map<int, Map<DateTime, List<Event>>> eventsByMonth;

  const _YearEventList({required this.year, required this.eventsByMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(scheduleSearchQueryProvider);

    // 根据搜索过滤事件
    Map<int, Map<DateTime, List<Event>>> filteredEventsByMonth;
    if (searchQuery.isEmpty) {
      filteredEventsByMonth = eventsByMonth;
    } else {
      filteredEventsByMonth = {};
      for (final monthEntry in eventsByMonth.entries) {
        final month = monthEntry.key;
        final eventsByDate = monthEntry.value;
        final filteredEventsByDate = <DateTime, List<Event>>{};

        for (final dateEntry in eventsByDate.entries) {
          final date = dateEntry.key;
          final events = dateEntry.value;
          final filteredEvents = events.where((event) {
            return event.title.toLowerCase().contains(searchQuery) ||
                (event.description?.toLowerCase().contains(searchQuery) ??
                    false) ||
                (event.location?.toLowerCase().contains(searchQuery) ?? false);
          }).toList();

          if (filteredEvents.isNotEmpty) {
            filteredEventsByDate[date] = filteredEvents;
          }
        }

        if (filteredEventsByDate.isNotEmpty) {
          filteredEventsByMonth[month] = filteredEventsByDate;
        }
      }
    }

    if (filteredEventsByMonth.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: SoftMinimalistColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的日程',
              style: TextStyle(
                fontSize: 16,
                color: SoftMinimalistColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 获取有事件的月份列表
    final months = filteredEventsByMonth.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final eventsByDate = filteredEventsByMonth[month]!;
        return _MonthEventGroup(
          year: year,
          month: month,
          eventsByDate: eventsByDate,
          onEventTap: (event) => _onEventTap(context, ref, event),
        );
      },
    );
  }

  void _onEventTap(BuildContext context, WidgetRef ref, Event event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );

    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }
}

/// 月份事件分组
class _MonthEventGroup extends ConsumerWidget {
  final int year;
  final int month;
  final Map<DateTime, List<Event>> eventsByDate;
  final Function(Event) onEventTap;

  const _MonthEventGroup({
    required this.year,
    required this.month,
    required this.eventsByDate,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedDates = eventsByDate.keys.toList()..sort();
    final monthNames = [
      '',
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];

    // 月份折叠状态
    final monthKey = '$year-$month';
    final collapsedMonths = ref.watch(collapsedMonthsProvider);
    final isCollapsed = collapsedMonths.contains(monthKey);

    final eventCount =
        eventsByDate.values.fold<int>(0, (sum, list) => sum + list.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标题（可点击折叠）
        InkWell(
          onTap: () {
            final current = ref.read(collapsedMonthsProvider);
            final updated = Set<String>.from(current);
            if (isCollapsed) {
              updated.remove(monthKey);
            } else {
              updated.add(monthKey);
            }
            ref.read(collapsedMonthsProvider.notifier).state = updated;
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Row(
              children: [
                // 折叠/展开图标
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 20,
                  color: SoftMinimalistColors.accentRed,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SoftMinimalistColors.softRedBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    monthNames[month],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SoftMinimalistColors.accentRed,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$eventCount个日程',
                  style: TextStyle(
                    fontSize: 12,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  isCollapsed ? '展开' : '收起',
                  style: TextStyle(
                    fontSize: 12,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 日期事件列表（可折叠）
        if (!isCollapsed)
          ...sortedDates.map((date) {
            return _DateEventGroup(
              date: date,
              events: eventsByDate[date]!,
              onEventTap: onEventTap,
            );
          }),
      ],
    );
  }
}

/// 日期事件分组
class _DateEventGroup extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final Function(Event) onEventTap;

  const _DateEventGroup({
    required this.date,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isTomorrow = date.difference(today).inDays == 1;
    final isPast = date.isBefore(today);

    String dateLabel;
    if (isToday) {
      dateLabel = '今天';
    } else if (isTomorrow) {
      dateLabel = '明天';
    } else {
      dateLabel = '${date.day}日';
    }

    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    // 去重事件（同一个事件可能跨越多天，只显示一次）
    final uniqueEvents = <String, Event>{};
    for (final event in events) {
      uniqueEvents[event.id] = event;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday
                      ? SoftMinimalistColors.accentRed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday
                          ? Colors.white
                          : isPast
                          ? SoftMinimalistColors.textSecondary
                          : SoftMinimalistColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday || isTomorrow)
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? SoftMinimalistColors.accentRed
                            : SoftMinimalistColors.textPrimary,
                      ),
                    ),
                  Text(
                    weekdayNames[date.weekday],
                    style: TextStyle(
                      fontSize: 12,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 事件卡片列表
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Column(
            children: uniqueEvents.values
                .map(
                  (event) => _EventCard(
                    event: event,
                    onTap: () => onEventTap(event),
                    isPast: isPast && !isToday,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool isPast;

  const _EventCard({
    required this.event,
    required this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.color != null
        ? Color(event.color!)
        : SoftMinimalistColors.accentRed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isPast
              ? SoftMinimalistColors.surface.withOpacity(0.6)
              : SoftMinimalistColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [SoftMinimalistSizes.cardShadow],
        ),
        child: Row(
          children: [
            // 颜色条
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: isPast ? color.withOpacity(0.5) : color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isPast
                            ? SoftMinimalistColors.textSecondary
                            : SoftMinimalistColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: SoftMinimalistColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                        ),
                        if (event.location != null &&
                            event.location!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: SoftMinimalistColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 箭头
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: SoftMinimalistColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeText() {
    if (event.allDay) {
      // 检查是否是多天事件
      final startDate = app_date_utils.DateUtils.dateOnly(event.startTime);
      final endDate = app_date_utils.DateUtils.dateOnly(event.endTime);
      if (startDate != endDate) {
        return '全天 (${app_date_utils.DateUtils.formatMonthDay(event.startTime)} - ${app_date_utils.DateUtils.formatMonthDay(event.endTime)})';
      }
      return '全天';
    }
    return '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}';
  }
}
