/// 提醒数据模型
/// 遵循RFC5545 VALARM规范
import 'package:uuid/uuid.dart';

/// 提醒类型
enum ReminderType {
  display, // 通知提醒
}

extension ReminderTypeExtension on ReminderType {
  String get value {
    switch (this) {
      case ReminderType.display:
        return 'DISPLAY';
    }
  }

  static ReminderType fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'DISPLAY':
        return ReminderType.display;
      default:
        return ReminderType.display;
    }
  }
}

/// 预设提醒选项
class ReminderOption {
  final String label;
  final Duration duration;

  const ReminderOption(this.label, this.duration);

  static const List<ReminderOption> presets = [
    ReminderOption('准时', Duration.zero),
    ReminderOption('5分钟前', Duration(minutes: 5)),
    ReminderOption('10分钟前', Duration(minutes: 10)),
    ReminderOption('15分钟前', Duration(minutes: 15)),
    ReminderOption('30分钟前', Duration(minutes: 30)),
    ReminderOption('1小时前', Duration(hours: 1)),
    ReminderOption('2小时前', Duration(hours: 2)),
    ReminderOption('1天前', Duration(days: 1)),
    ReminderOption('2天前', Duration(days: 2)),
    ReminderOption('1周前', Duration(days: 7)),
  ];

  /// 根据Duration查找预设选项
  static ReminderOption? findByDuration(Duration duration) {
    for (final option in presets) {
      if (option.duration == duration) {
        return option;
      }
    }
    return null;
  }

  /// 格式化Duration为显示文本
  static String formatDuration(Duration duration) {
    final option = findByDuration(duration);
    if (option != null) return option.label;

    if (duration == Duration.zero) return '准时';
    if (duration.inDays > 0) return '${duration.inDays}天前';
    if (duration.inHours > 0) return '${duration.inHours}小时前';
    if (duration.inMinutes > 0) return '${duration.inMinutes}分钟前';
    return '${duration.inSeconds}秒前';
  }
}

/// 提醒模型
class Reminder {
  /// 提醒ID
  final String id;

  /// 关联的事件ID
  final String eventId;

  /// 提前多久提醒
  final Duration triggerBefore;

  /// 实际触发时间
  final DateTime triggerTime;

  /// 提醒类型
  final ReminderType type;

  /// 是否已触发
  final bool isTriggered;

  const Reminder({
    required this.id,
    required this.eventId,
    required this.triggerBefore,
    required this.triggerTime,
    this.type = ReminderType.display,
    this.isTriggered = false,
  });

  /// 从数据库Map创建Reminder
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      triggerBefore: Duration(milliseconds: map['trigger_before'] as int? ?? 0),
      triggerTime: DateTime.fromMillisecondsSinceEpoch(map['trigger_time'] as int),
      type: ReminderTypeExtension.fromValue(map['trigger_type'] as String? ?? 'DISPLAY'),
      isTriggered: (map['is_triggered'] as int?) == 1,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'trigger_before': triggerBefore.inMilliseconds,
      'trigger_time': triggerTime.millisecondsSinceEpoch,
      'trigger_type': type.value,
      'is_triggered': isTriggered ? 1 : 0,
    };
  }

  /// 复制并修改部分属性
  Reminder copyWith({
    String? id,
    String? eventId,
    Duration? triggerBefore,
    DateTime? triggerTime,
    ReminderType? type,
    bool? isTriggered,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      triggerBefore: triggerBefore ?? this.triggerBefore,
      triggerTime: triggerTime ?? this.triggerTime,
      type: type ?? this.type,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }

  /// 创建新提醒
  factory Reminder.create({
    required String eventId,
    required Duration triggerBefore,
    required DateTime eventStartTime,
    ReminderType type = ReminderType.display,
  }) {
    const uuid = Uuid();
    return Reminder(
      id: uuid.v4(),
      eventId: eventId,
      triggerBefore: triggerBefore,
      triggerTime: calculateTriggerTime(eventStartTime, triggerBefore),
      type: type,
      isTriggered: false,
    );
  }

  /// 计算触发时间
  static DateTime calculateTriggerTime(DateTime eventStart, Duration before) {
    return eventStart.subtract(before);
  }

  /// 获取显示文本
  String get displayText => ReminderOption.formatDuration(triggerBefore);

  /// 转换为RFC5545 VALARM格式的TRIGGER值
  String get triggerValue {
    if (triggerBefore == Duration.zero) {
      return 'PT0S';
    }

    final StringBuffer buffer = StringBuffer('-P');

    if (triggerBefore.inDays > 0) {
      buffer.write('${triggerBefore.inDays}D');
      final remainingHours = triggerBefore.inHours % 24;
      if (remainingHours > 0) {
        buffer.write('T${remainingHours}H');
      }
    } else if (triggerBefore.inHours > 0) {
      buffer.write('T${triggerBefore.inHours}H');
      final remainingMinutes = triggerBefore.inMinutes % 60;
      if (remainingMinutes > 0) {
        buffer.write('${remainingMinutes}M');
      }
    } else if (triggerBefore.inMinutes > 0) {
      buffer.write('T${triggerBefore.inMinutes}M');
    } else {
      buffer.write('T${triggerBefore.inSeconds}S');
    }

    return buffer.toString();
  }

  /// 从RFC5545 TRIGGER值解析Duration
  static Duration parseTrigger(String value) {
    // 格式: -PT15M, -P1D, PT0S 等
    final isNegative = value.startsWith('-');
    final cleanValue = value.replaceFirst('-', '').replaceFirst('P', '');

    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    final hasTime = cleanValue.contains('T');
    final parts = cleanValue.split('T');

    // 解析日期部分
    if (parts[0].isNotEmpty) {
      final dayMatch = RegExp(r'(\d+)D').firstMatch(parts[0]);
      if (dayMatch != null) {
        days = int.parse(dayMatch.group(1)!);
      }
    }

    // 解析时间部分
    if (hasTime && parts.length > 1) {
      final timePart = parts[1];
      final hourMatch = RegExp(r'(\d+)H').firstMatch(timePart);
      final minuteMatch = RegExp(r'(\d+)M').firstMatch(timePart);
      final secondMatch = RegExp(r'(\d+)S').firstMatch(timePart);

      if (hourMatch != null) hours = int.parse(hourMatch.group(1)!);
      if (minuteMatch != null) minutes = int.parse(minuteMatch.group(1)!);
      if (secondMatch != null) seconds = int.parse(secondMatch.group(1)!);
    }

    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Reminder(id: $id, eventId: $eventId, triggerBefore: $triggerBefore)';
  }
}

