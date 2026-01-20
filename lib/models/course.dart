import 'dart:convert';

import 'package:flutter/material.dart';

/// 课程模型
class Course {
  final String id;
  final String scheduleId;
  final String name;
  final String? teacher;
  final String? location;
  final int dayOfWeek;
  final int startSection;
  final int endSection;
  final List<int> weeks;
  final int color;
  final String? note;
  /// 提醒提前时间（分钟），null表示不提醒
  final int? reminderMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Course({
    required this.id,
    required this.scheduleId,
    required this.name,
    this.teacher,
    this.location,
    required this.dayOfWeek,
    required this.startSection,
    required this.endSection,
    required this.weeks,
    required this.color,
    this.note,
    this.reminderMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建Course
  factory Course.fromMap(Map<String, dynamic> map) {
    List<int> weeksList;
    final weeksData = map['weeks'];
    if (weeksData is String) {
      weeksList = (jsonDecode(weeksData) as List).cast<int>();
    } else if (weeksData is List) {
      weeksList = weeksData.cast<int>();
    } else {
      weeksList = [];
    }

    return Course(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String,
      name: map['name'] as String,
      teacher: map['teacher'] as String?,
      location: map['location'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      startSection: map['start_section'] as int,
      endSection: map['end_section'] as int,
      weeks: weeksList,
      color: map['color'] as int,
      note: map['note'] as String?,
      reminderMinutes: map['reminder_minutes'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'name': name,
      'teacher': teacher,
      'location': location,
      'day_of_week': dayOfWeek,
      'start_section': startSection,
      'end_section': endSection,
      'weeks': jsonEncode(weeks),
      'color': color,
      'note': note,
      'reminder_minutes': reminderMinutes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改部分属性
  Course copyWith({
    String? id,
    String? scheduleId,
    String? name,
    String? teacher,
    String? location,
    int? dayOfWeek,
    int? startSection,
    int? endSection,
    List<int>? weeks,
    int? color,
    String? note,
    int? reminderMinutes,
    bool clearReminderMinutes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      weeks: weeks ?? this.weeks,
      color: color ?? this.color,
      note: note ?? this.note,
      reminderMinutes: clearReminderMinutes ? null : (reminderMinutes ?? this.reminderMinutes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 课程跨越的节数
  int get sectionSpan => endSection - startSection + 1;

  /// 判断指定周是否有课
  bool hasClassInWeek(int week) => weeks.contains(week);

  /// 获取颜色对象
  Color get colorValue => Color(color);

  /// 星期几的中文名称
  String get dayOfWeekName {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[dayOfWeek];
  }

  /// 节次描述，如"1-2节"
  String get sectionDescription {
    if (startSection == endSection) {
      return '第$startSection节';
    }
    return '第$startSection-$endSection节';
  }

  /// 周次范围描述，如"1-8周"、"1-16周(单)"、"2-16周(双)"
  String get weeksDescription {
    if (weeks.isEmpty) return '';

    final sorted = List<int>.from(weeks)..sort();

    // 检查是否是连续的
    bool isContinuous = true;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] - sorted[i - 1] != 1) {
        isContinuous = false;
        break;
      }
    }

    if (isContinuous) {
      if (sorted.length == 1) {
        return '第${sorted.first}周';
      }
      return '${sorted.first}-${sorted.last}周';
    }

    // 检查是否是单周
    bool isOdd = sorted.every((w) => w % 2 == 1);
    if (isOdd && sorted.length > 1) {
      return '${sorted.first}-${sorted.last}周(单)';
    }

    // 检查是否是双周
    bool isEven = sorted.every((w) => w % 2 == 0);
    if (isEven && sorted.length > 1) {
      return '${sorted.first}-${sorted.last}周(双)';
    }

    // 其他情况，直接列出
    if (sorted.length <= 3) {
      return sorted.map((w) => '第$w周').join('、');
    }

    return '${sorted.first}-${sorted.last}周';
  }

  /// 提醒描述
  String get reminderDescription {
    if (reminderMinutes == null) return '不提醒';
    if (reminderMinutes == 0) return '上课时';
    if (reminderMinutes! < 60) return '上课前$reminderMinutes分钟';
    final hours = reminderMinutes! ~/ 60;
    final mins = reminderMinutes! % 60;
    if (mins == 0) return '上课前$hours小时';
    return '上课前$hours小时$mins分钟';
  }

  /// 课程提醒预设选项（分钟）
  static const List<int?> presetReminderOptions = [
    null, // 不提醒
    0,    // 上课时
    5,    // 5分钟前
    10,   // 10分钟前
    15,   // 15分钟前
    30,   // 30分钟前
    60,   // 1小时前
  ];

  /// 获取提醒选项的描述
  static String getReminderOptionLabel(int? minutes) {
    if (minutes == null) return '不提醒';
    if (minutes == 0) return '上课时';
    if (minutes < 60) return '$minutes分钟前';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours小时前';
    return '$hours小时$mins分钟前';
  }

  /// 课程预设颜色列表
  static const List<int> presetColors = [
    0xFFFFCDD2, // 浅红
    0xFFF8BBD0, // 浅粉
    0xFFE1BEE7, // 浅紫
    0xFFC5CAE9, // 浅靛蓝
    0xFFBBDEFB, // 浅蓝
    0xFFB2EBF2, // 浅青
    0xFFB2DFDB, // 浅蓝绿
    0xFFC8E6C9, // 浅绿
    0xFFDCEDC8, // 浅黄绿
    0xFFFFF9C4, // 浅黄
    0xFFFFECB3, // 浅琥珀
    0xFFFFE0B2, // 浅橙
  ];

  /// 生成周次列表
  /// [start] 开始周, [end] 结束周, [type] 类型: 0-每周, 1-单周, 2-双周
  static List<int> generateWeeks(int start, int end, {int type = 0}) {
    final weeks = <int>[];
    for (int i = start; i <= end; i++) {
      if (type == 0) {
        weeks.add(i);
      } else if (type == 1 && i % 2 == 1) {
        weeks.add(i);
      } else if (type == 2 && i % 2 == 0) {
        weeks.add(i);
      }
    }
    return weeks;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, name: $name, day: $dayOfWeek, sections: $startSection-$endSection)';
  }

  // ==================== 数据验证 ====================

  /// 验证课程数据完整性
  /// 返回 null 表示验证通过，否则返回错误信息
  String? validate() {
    // 验证课程名称
    if (name.trim().isEmpty) {
      return '课程名称不能为空';
    }
    if (name.length > 50) {
      return '课程名称不能超过50个字符';
    }

    // 验证关联ID
    if (scheduleId.trim().isEmpty) {
      return '课程表ID不能为空';
    }

    // 验证星期
    if (dayOfWeek < 1 || dayOfWeek > 7) {
      return '星期必须在1-7之间';
    }

    // 验证节次
    if (startSection < 1) {
      return '开始节次必须大于0';
    }
    if (endSection < startSection) {
      return '结束节次不能小于开始节次';
    }
    if (endSection > 14) {
      return '结束节次不能超过14';
    }

    // 验证周次
    if (weeks.isEmpty) {
      return '上课周次不能为空';
    }
    for (final week in weeks) {
      if (week < 1 || week > 30) {
        return '周次必须在1-30之间';
      }
    }

    return null;
  }

  /// 验证课程数据并抛出异常
  void validateOrThrow() {
    final error = validate();
    if (error != null) {
      throw CourseValidationException(error);
    }
  }

  /// 检查数据是否完整（用于显示警告）
  List<String> getDataWarnings() {
    final warnings = <String>[];

    if (location == null || location!.isEmpty) {
      warnings.add('未设置上课地点');
    }
    if (teacher == null || teacher!.isEmpty) {
      warnings.add('未设置任课教师');
    }

    return warnings;
  }
}

/// 课程验证异常
class CourseValidationException implements Exception {
  final String message;

  const CourseValidationException(this.message);

  @override
  String toString() => 'CourseValidationException: $message';
}
