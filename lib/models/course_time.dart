import 'package:flutter/material.dart';

/// 课程时间/节次模型
class CourseTime {
  final int section;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const CourseTime({
    required this.section,
    required this.startTime,
    required this.endTime,
  });

  /// 从JSON Map创建
  factory CourseTime.fromMap(Map<String, dynamic> map) {
    return CourseTime(
      section: map['section'] as int,
      startTime: TimeOfDay(
        hour: map['start_hour'] as int,
        minute: map['start_minute'] as int,
      ),
      endTime: TimeOfDay(
        hour: map['end_hour'] as int,
        minute: map['end_minute'] as int,
      ),
    );
  }

  /// 转换为JSON Map
  Map<String, dynamic> toMap() {
    return {
      'section': section,
      'start_hour': startTime.hour,
      'start_minute': startTime.minute,
      'end_hour': endTime.hour,
      'end_minute': endTime.minute,
    };
  }

  /// 复制并修改
  CourseTime copyWith({
    int? section,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return CourseTime(
      section: section ?? this.section,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// 格式化时间范围字符串
  String get timeRangeString {
    return '${_formatTime(startTime)}-${_formatTime(endTime)}';
  }

  /// 格式化开始时间
  String get startTimeString => _formatTime(startTime);

  /// 格式化结束时间
  String get endTimeString => _formatTime(endTime);

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 课程时长（分钟）
  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// 默认作息时间表（8节课）
  static List<CourseTime> get defaultSchedule => [
    CourseTime(
      section: 1,
      startTime: const TimeOfDay(hour: 8, minute: 30),
      endTime: const TimeOfDay(hour: 9, minute: 15),
    ),
    CourseTime(
      section: 2,
      startTime: const TimeOfDay(hour: 9, minute: 25),
      endTime: const TimeOfDay(hour: 10, minute: 10),
    ),
    CourseTime(
      section: 3,
      startTime: const TimeOfDay(hour: 10, minute: 20),
      endTime: const TimeOfDay(hour: 11, minute: 5),
    ),
    CourseTime(
      section: 4,
      startTime: const TimeOfDay(hour: 11, minute: 15),
      endTime: const TimeOfDay(hour: 12, minute: 0),
    ),
    // 午休后
    CourseTime(
      section: 5,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 14, minute: 45),
    ),
    CourseTime(
      section: 6,
      startTime: const TimeOfDay(hour: 14, minute: 55),
      endTime: const TimeOfDay(hour: 15, minute: 40),
    ),
    CourseTime(
      section: 7,
      startTime: const TimeOfDay(hour: 15, minute: 50),
      endTime: const TimeOfDay(hour: 16, minute: 35),
    ),
    CourseTime(
      section: 8,
      startTime: const TimeOfDay(hour: 16, minute: 45),
      endTime: const TimeOfDay(hour: 17, minute: 30),
    ),
  ];

  /// 默认午休在第几节后
  static const int defaultLunchAfterSection = 4;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseTime &&
        other.section == section &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(section, startTime, endTime);

  @override
  String toString() {
    return 'CourseTime(section: $section, $timeRangeString)';
  }
}
