import 'package:flutter/material.dart';

/// 学期信息模型
class Semester {
  final String id;
  final String name;
  final DateTime startDate;
  final int totalWeeks;
  final bool isCurrent;
  final DateTime createdAt;

  const Semester({
    required this.id,
    required this.name,
    required this.startDate,
    this.totalWeeks = 20,
    this.isCurrent = false,
    required this.createdAt,
  });

  /// 从数据库Map创建Semester
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      totalWeeks: map['total_weeks'] as int? ?? 20,
      isCurrent: (map['is_current'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.millisecondsSinceEpoch,
      'total_weeks': totalWeeks,
      'is_current': isCurrent ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改部分属性
  Semester copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    int? totalWeeks,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 根据日期计算当前是第几周
  int getWeekNumber(DateTime date) {
    // 获取学期开始日期所在周的周一
    final semesterStartMonday = _getMonday(startDate);
    final targetMonday = _getMonday(date);

    final diff = targetMonday.difference(semesterStartMonday).inDays;
    final week = (diff ~/ 7) + 1;

    // 限制在有效范围内
    if (week < 1) return 1;
    if (week > totalWeeks) return totalWeeks;
    return week;
  }

  /// 获取指定周的日期范围
  DateTimeRange getWeekDateRange(int weekNumber) {
    final semesterStartMonday = _getMonday(startDate);
    final weekStart = semesterStartMonday.add(
      Duration(days: (weekNumber - 1) * 7),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    return DateTimeRange(start: weekStart, end: weekEnd);
  }

  /// 获取指定周某一天的日期
  DateTime getDateForWeekDay(int weekNumber, int dayOfWeek) {
    final semesterStartMonday = _getMonday(startDate);
    return semesterStartMonday.add(
      Duration(days: (weekNumber - 1) * 7 + (dayOfWeek - 1)),
    );
  }

  /// 获取日期所在的周一
  DateTime _getMonday(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  /// 获取学期结束日期
  DateTime get endDate {
    final semesterStartMonday = _getMonday(startDate);
    return semesterStartMonday.add(Duration(days: totalWeeks * 7 - 1));
  }

  /// 判断日期是否在学期范围内
  bool isDateInSemester(DateTime date) {
    final week = getWeekNumber(date);
    return week >= 1 && week <= totalWeeks;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Semester && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Semester(id: $id, name: $name, startDate: $startDate, totalWeeks: $totalWeeks)';
  }
}
