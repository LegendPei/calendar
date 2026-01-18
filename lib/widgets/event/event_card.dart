/// 事件卡片组件
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/event.dart';

class EventCard extends StatelessWidget {
  /// 事件
  final Event event;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否显示日期
  final bool showDate;

  /// 是否紧凑模式
  final bool compact;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showDate = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = event.color != null
        ? Color(event.color!)
        : CalendarColors.today;

    if (compact) {
      return _buildCompactCard(context, color);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 时间
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    // 地点
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 重复指示
              if (event.rrule != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.repeat,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              // 箭头
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建紧凑卡片
  Widget _buildCompactCard(BuildContext context, Color color) {
    // 使用对比度更好的文字颜色
    final textColor = ColorUtils.getEventTextColor(color);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!event.allDay)
              Text(
                app_date_utils.DateUtils.formatTime(event.startTime),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取时间文本
  String _getTimeText() {
    if (event.allDay) {
      return '全天';
    }

    final startStr = app_date_utils.DateUtils.formatTime(event.startTime);
    final endStr = app_date_utils.DateUtils.formatTime(event.endTime);

    if (showDate) {
      final dateStr = app_date_utils.DateUtils.formatMonthDay(event.startTime);
      return '$dateStr $startStr - $endStr';
    }

    return '$startStr - $endStr';
  }
}
