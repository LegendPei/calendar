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
}
