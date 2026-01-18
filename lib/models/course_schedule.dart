import 'dart:convert';

import 'course_time.dart';

/// 课程表模型
class CourseSchedule {
  final String id;
  final String name;
  final String semesterId;
  final List<CourseTime> timeSlots;
  final int daysPerWeek;
  final int lunchAfterSection;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseSchedule({
    required this.id,
    required this.name,
    required this.semesterId,
    required this.timeSlots,
    this.daysPerWeek = 5,
    this.lunchAfterSection = 4,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建CourseSchedule
  factory CourseSchedule.fromMap(Map<String, dynamic> map) {
    List<CourseTime> slots;
    final timeSlotsData = map['time_slots'];
    if (timeSlotsData is String) {
      final List<dynamic> decoded = jsonDecode(timeSlotsData);
      slots = decoded
          .map((e) => CourseTime.fromMap(e as Map<String, dynamic>))
          .toList();
    } else if (timeSlotsData is List) {
      slots = timeSlotsData
          .map((e) => CourseTime.fromMap(e as Map<String, dynamic>))
          .toList();
    } else {
      slots = CourseTime.defaultSchedule;
    }

    return CourseSchedule(
      id: map['id'] as String,
      name: map['name'] as String,
      semesterId: map['semester_id'] as String,
      timeSlots: slots,
      daysPerWeek: map['days_per_week'] as int? ?? 5,
      lunchAfterSection: map['lunch_after_section'] as int? ?? 4,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'semester_id': semesterId,
      'time_slots': jsonEncode(timeSlots.map((e) => e.toMap()).toList()),
      'days_per_week': daysPerWeek,
      'lunch_after_section': lunchAfterSection,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改部分属性
  CourseSchedule copyWith({
    String? id,
    String? name,
    String? semesterId,
    List<CourseTime>? timeSlots,
    int? daysPerWeek,
    int? lunchAfterSection,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      semesterId: semesterId ?? this.semesterId,
      timeSlots: timeSlots ?? this.timeSlots,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      lunchAfterSection: lunchAfterSection ?? this.lunchAfterSection,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取指定节次的时间信息
  CourseTime? getTimeSlot(int section) {
    try {
      return timeSlots.firstWhere((t) => t.section == section);
    } catch (e) {
      return null;
    }
  }

  /// 总节数
  int get totalSections => timeSlots.length;

  /// 上午的节次
  List<CourseTime> get morningSlots {
    return timeSlots.where((t) => t.section <= lunchAfterSection).toList();
  }

  /// 下午的节次
  List<CourseTime> get afternoonSlots {
    return timeSlots.where((t) => t.section > lunchAfterSection).toList();
  }

  /// 星期名称列表
  List<String> get dayNames {
    const allDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return allDays.take(daysPerWeek).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CourseSchedule(id: $id, name: $name, sections: $totalSections, days: $daysPerWeek)';
  }
}
