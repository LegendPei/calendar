/// 事件详情页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/recurrence_rule.dart';
import '../../providers/event_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import 'event_form_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  /// 事件
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = event.color != null
        ? Color(event.color!)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('事件详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editEvent(context),
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(context, ref),
            tooltip: '删除',
          ),
        ],
      ),
      body: ListView(
        children: [
          // 颜色条和标题
          Container(
            color: color.withValues(alpha: 0.1),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (event.rrule != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getRecurrenceText(event.rrule!),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 时间信息
          _buildSection(
            icon: Icons.access_time,
            title: '时间',
            content: _getTimeText(),
          ),

          // 地点
          if (event.location != null && event.location!.isNotEmpty)
            _buildSection(
              icon: Icons.location_on_outlined,
              title: '地点',
              content: event.location!,
            ),

          // 描述
          if (event.description != null && event.description!.isNotEmpty)
            _buildSection(
              icon: Icons.notes,
              title: '描述',
              content: event.description!,
            ),

          // 日历
          _buildSection(
            icon: Icons.calendar_today,
            title: '日历',
            content: event.calendarId ?? '我的日历',
          ),

          const SizedBox(height: 16),

          // 创建和更新时间
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '创建于 ${app_date_utils.DateUtils.formatDateTime(event.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (event.updatedAt != event.createdAt) ...[
                  const SizedBox(height: 4),
                  Text(
                    '更新于 ${app_date_utils.DateUtils.formatDateTime(event.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建信息区块
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取时间文本
  String _getTimeText() {
    if (event.allDay) {
      if (app_date_utils.DateUtils.isSameDay(event.startTime, event.endTime)) {
        return '${app_date_utils.DateUtils.formatDate(event.startTime)} (全天)';
      }
      return '${app_date_utils.DateUtils.formatDate(event.startTime)} - ${app_date_utils.DateUtils.formatDate(event.endTime)} (全天)';
    }

    if (app_date_utils.DateUtils.isSameDay(event.startTime, event.endTime)) {
      return '${app_date_utils.DateUtils.formatDate(event.startTime)}\n'
          '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}';
    }

    return '${app_date_utils.DateUtils.formatDateTime(event.startTime)}\n'
        '至 ${app_date_utils.DateUtils.formatDateTime(event.endTime)}';
  }

  /// 获取重复规则文本
  String _getRecurrenceText(String rrule) {
    try {
      final rule = RecurrenceRule.fromRRule(rrule);
      return rule.displayText;
    } catch (e) {
      return rrule;
    }
  }

  /// 编辑事件
  void _editEvent(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除事件'),
        content: const Text('确定要删除这个事件吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(eventListProvider.notifier).deleteEvent(event.id);
      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('事件已删除')));
      }
    }
  }
}
