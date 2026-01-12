/// 重复规则模型
/// 遵循RFC5545 RRULE规范

/// 重复频率枚举
enum RecurrenceFrequency {
  daily,   // FREQ=DAILY
  weekly,  // FREQ=WEEKLY
  monthly, // FREQ=MONTHLY
  yearly,  // FREQ=YEARLY
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get rruleValue {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return '每天';
      case RecurrenceFrequency.weekly:
        return '每周';
      case RecurrenceFrequency.monthly:
        return '每月';
      case RecurrenceFrequency.yearly:
        return '每年';
    }
  }

  static RecurrenceFrequency? fromRRuleValue(String value) {
    switch (value.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      default:
        return null;
    }
  }
}

/// 重复规则模型
class RecurrenceRule {
  /// 重复频率
  final RecurrenceFrequency frequency;

  /// 间隔（默认1）
  final int interval;

  /// 结束日期
  final DateTime? until;

  /// 重复次数
  final int? count;

  /// 星期几（0=周日, 1=周一, ..., 6=周六）
  final List<int>? byDay;

  /// 每月的第几天
  final List<int>? byMonthDay;

  /// 每年的第几月
  final List<int>? byMonth;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
  });

  /// 从RRULE字符串解析
  factory RecurrenceRule.fromRRule(String rrule) {
    final parts = rrule.replaceFirst('RRULE:', '').split(';');
    final Map<String, String> params = {};

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        params[keyValue[0].toUpperCase()] = keyValue[1];
      }
    }

    // 解析FREQ
    final freqStr = params['FREQ'];
    final frequency = RecurrenceFrequencyExtension.fromRRuleValue(freqStr ?? 'DAILY')
        ?? RecurrenceFrequency.daily;

    // 解析INTERVAL
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

    // 解析UNTIL
    DateTime? until;
    if (params.containsKey('UNTIL')) {
      until = _parseDateTime(params['UNTIL']!);
    }

    // 解析COUNT
    final count = int.tryParse(params['COUNT'] ?? '');

    // 解析BYDAY
    List<int>? byDay;
    if (params.containsKey('BYDAY')) {
      byDay = _parseByDay(params['BYDAY']!);
    }

    // 解析BYMONTHDAY
    List<int>? byMonthDay;
    if (params.containsKey('BYMONTHDAY')) {
      byMonthDay = params['BYMONTHDAY']!.split(',').map((e) => int.parse(e)).toList();
    }

    // 解析BYMONTH
    List<int>? byMonth;
    if (params.containsKey('BYMONTH')) {
      byMonth = params['BYMONTH']!.split(',').map((e) => int.parse(e)).toList();
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      until: until,
      count: count,
      byDay: byDay,
      byMonthDay: byMonthDay,
      byMonth: byMonth,
    );
  }

  /// 转换为RRULE字符串
  String toRRule() {
    final parts = <String>[];

    parts.add('FREQ=${frequency.rruleValue}');

    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }

    if (until != null) {
      parts.add('UNTIL=${_formatDateTime(until!)}');
    }

    if (count != null) {
      parts.add('COUNT=$count');
    }

    if (byDay != null && byDay!.isNotEmpty) {
      parts.add('BYDAY=${_formatByDay(byDay!)}');
    }

    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      parts.add('BYMONTHDAY=${byMonthDay!.join(',')}');
    }

    if (byMonth != null && byMonth!.isNotEmpty) {
      parts.add('BYMONTH=${byMonth!.join(',')}');
    }

    return parts.join(';');
  }

  /// 生成指定范围内的所有事件日期
  List<DateTime> generateOccurrences(
    DateTime start,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final List<DateTime> occurrences = [];
    DateTime current = start;
    int generatedCount = 0;
    final maxIterations = 1000; // 防止无限循环

    for (int i = 0; i < maxIterations; i++) {
      // 检查是否超过结束条件
      if (until != null && current.isAfter(until!)) {
        break;
      }
      if (count != null && generatedCount >= count!) {
        break;
      }
      if (current.isAfter(rangeEnd)) {
        break;
      }

      // 检查是否在范围内
      if (!current.isBefore(rangeStart) && !current.isAfter(rangeEnd)) {
        if (_matchesRule(current)) {
          occurrences.add(current);
          generatedCount++;
        }
      }

      // 计算下一个日期
      current = _nextOccurrence(current);
    }

    return occurrences;
  }

  /// 检查日期是否符合规则
  bool _matchesRule(DateTime date) {
    // 检查BYDAY
    if (byDay != null && byDay!.isNotEmpty) {
      final weekday = date.weekday % 7; // 转换为0=周日
      if (!byDay!.contains(weekday)) {
        return false;
      }
    }

    // 检查BYMONTHDAY
    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      if (!byMonthDay!.contains(date.day)) {
        return false;
      }
    }

    // 检查BYMONTH
    if (byMonth != null && byMonth!.isNotEmpty) {
      if (!byMonth!.contains(date.month)) {
        return false;
      }
    }

    return true;
  }

  /// 计算下一个日期
  DateTime _nextOccurrence(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime(current.year, current.month + interval, current.day);
      case RecurrenceFrequency.yearly:
        return DateTime(current.year + interval, current.month, current.day);
    }
  }

  /// 解析RRULE日期时间
  static DateTime? _parseDateTime(String value) {
    try {
      // 格式: 20251231T235959Z 或 20251231
      if (value.length >= 8) {
        final year = int.parse(value.substring(0, 4));
        final month = int.parse(value.substring(4, 6));
        final day = int.parse(value.substring(6, 8));

        if (value.length >= 15) {
          final hour = int.parse(value.substring(9, 11));
          final minute = int.parse(value.substring(11, 13));
          final second = int.parse(value.substring(13, 15));
          return DateTime.utc(year, month, day, hour, minute, second);
        }
        return DateTime(year, month, day);
      }
    } catch (e) {
      // 解析失败
    }
    return null;
  }

  /// 格式化日期时间为RRULE格式
  static String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '${year}${month}${day}T${hour}${minute}${second}Z';
  }

  /// 解析BYDAY
  static List<int> _parseByDay(String value) {
    final dayMap = {
      'SU': 0, 'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6,
    };
    final days = <int>[];
    for (final part in value.split(',')) {
      final day = part.replaceAll(RegExp(r'[0-9+-]'), '').toUpperCase();
      if (dayMap.containsKey(day)) {
        days.add(dayMap[day]!);
      }
    }
    return days;
  }

  /// 格式化BYDAY
  static String _formatByDay(List<int> days) {
    final dayNames = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return days.map((d) => dayNames[d]).join(',');
  }

  /// 获取显示文本
  String get displayText {
    if (interval == 1) {
      return frequency.displayName;
    }
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return '每${interval}天';
      case RecurrenceFrequency.weekly:
        return '每${interval}周';
      case RecurrenceFrequency.monthly:
        return '每${interval}月';
      case RecurrenceFrequency.yearly:
        return '每${interval}年';
    }
  }

  /// 预设规则
  static RecurrenceRule get daily => const RecurrenceRule(frequency: RecurrenceFrequency.daily);
  static RecurrenceRule get weekly => const RecurrenceRule(frequency: RecurrenceFrequency.weekly);
  static RecurrenceRule get monthly => const RecurrenceRule(frequency: RecurrenceFrequency.monthly);
  static RecurrenceRule get yearly => const RecurrenceRule(frequency: RecurrenceFrequency.yearly);

  /// 工作日（周一到周五）
  static RecurrenceRule get weekdays => const RecurrenceRule(
    frequency: RecurrenceFrequency.weekly,
    byDay: [1, 2, 3, 4, 5],
  );

  @override
  String toString() => 'RecurrenceRule(${toRRule()})';
}

