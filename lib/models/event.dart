/// 日程事件数据模型
/// 遵循RFC5545 VEVENT规范
import 'package:uuid/uuid.dart';

class Event {
  /// 事件ID
  final String id;

  /// RFC5545 UID
  final String uid;

  /// 事件标题
  final String title;

  /// 事件描述
  final String? description;

  /// 事件地点
  final String? location;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 是否全天事件
  final bool allDay;

  /// 重复规则 (RFC5545 RRULE)
  final String? rrule;

  /// 事件颜色
  final int? color;

  /// 所属日历ID
  final String? calendarId;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.uid,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.rrule,
    this.color,
    this.calendarId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建Event
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      uid: map['uid'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      allDay: (map['all_day'] as int) == 1,
      rrule: map['rrule'] as String?,
      color: map['color'] as int?,
      calendarId: map['calendar_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'all_day': allDay ? 1 : 0,
      'rrule': rrule,
      'color': color,
      'calendar_id': calendarId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改部分属性
  Event copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? rrule,
    int? color,
    String? calendarId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      rrule: rrule ?? this.rrule,
      color: color ?? this.color,
      calendarId: calendarId ?? this.calendarId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 生成RFC5545 UID
  static String generateUid() {
    const uuid = Uuid();
    return '${DateTime.now().millisecondsSinceEpoch}-${uuid.v4()}@calendarapp';
  }

  /// 创建新事件
  factory Event.create({
    required String title,
    String? description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
    bool allDay = false,
    String? rrule,
    int? color,
    String? calendarId,
  }) {
    final now = DateTime.now();
    const uuid = Uuid();
    return Event(
      id: uuid.v4(),
      uid: generateUid(),
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      allDay: allDay,
      rrule: rrule,
      color: color,
      calendarId: calendarId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 获取事件时长
  Duration get duration => endTime.difference(startTime);

  /// 判断事件是否跨越多天
  bool get isMultiDay {
    return startTime.year != endTime.year ||
        startTime.month != endTime.month ||
        startTime.day != endTime.day;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, startTime: $startTime, endTime: $endTime)';
  }
}

