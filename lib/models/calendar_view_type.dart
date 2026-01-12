/// 日历视图类型枚举
enum CalendarViewType {
  /// 月视图
  month,

  /// 周视图
  week,

  /// 日视图
  day,
}

/// 日历视图类型扩展
extension CalendarViewTypeExtension on CalendarViewType {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case CalendarViewType.month:
        return '月';
      case CalendarViewType.week:
        return '周';
      case CalendarViewType.day:
        return '日';
    }
  }

  /// 获取图标
  String get iconName {
    switch (this) {
      case CalendarViewType.month:
        return 'calendar_view_month';
      case CalendarViewType.week:
        return 'calendar_view_week';
      case CalendarViewType.day:
        return 'calendar_view_day';
    }
  }
}

