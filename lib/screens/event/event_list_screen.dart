// 日程列表页面 - 支持搜索和月份折叠
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

/// 日程列表页面
class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _collapsedMonths = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('全部日程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEvent(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索日程...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
          ),
          // 事件列表
          Expanded(
            child: eventsAsync.when(
              data: (events) => _buildEventList(events),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> allEvents) {
    // 过滤搜索结果
    List<Event> events = allEvents;
    if (_searchQuery.isNotEmpty) {
      events = allEvents.where((e) {
        return e.title.toLowerCase().contains(_searchQuery) ||
            (e.description?.toLowerCase().contains(_searchQuery) ?? false) ||
            (e.location?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.event_available,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '没有找到匹配的日程' : '暂无日程',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // 按月份分组
    final groupedEvents = <String, List<Event>>{};
    for (final event in events) {
      final monthKey = DateFormat('yyyy-MM').format(event.startTime);
      groupedEvents.putIfAbsent(monthKey, () => []).add(event);
    }

    // 按月份排序（最新的在前）
    final sortedMonths = groupedEvents.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final monthKey = sortedMonths[index];
        final monthEvents = groupedEvents[monthKey]!;
        final isCollapsed = _collapsedMonths.contains(monthKey);

        // 解析月份用于显示
        final monthDate = DateTime.parse('$monthKey-01');
        final monthTitle = DateFormat('yyyy年M月').format(monthDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月份标题（可折叠）
            InkWell(
              onTap: () {
                setState(() {
                  if (isCollapsed) {
                    _collapsedMonths.remove(monthKey);
                  } else {
                    _collapsedMonths.add(monthKey);
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      monthTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${monthEvents.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isCollapsed ? '展开' : '收起',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 事件列表（可折叠）
            if (!isCollapsed)
              ...monthEvents.map((event) => _buildEventItem(event)),
            if (index < sortedMonths.length - 1)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildEventItem(Event event) {
    final color = event.color != null ? Color(event.color!) : Colors.blue;
    final dateStr = DateFormat('M/d').format(event.startTime);
    final weekdayStr = _getWeekdayShort(event.startTime.weekday);
    final timeStr = event.allDay
        ? '全天'
        : '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _viewEvent(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 日期列
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      weekdayStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // 颜色条
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (event.location != null && event.location!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
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
              // 箭头
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday - 1];
  }

  Future<void> _viewEvent(Event event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );

    if (result == true) {
      ref.invalidate(eventListProvider);
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }

  Future<void> _addEvent(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EventFormScreen()),
    );

    if (result == true) {
      ref.invalidate(eventListProvider);
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }
}
