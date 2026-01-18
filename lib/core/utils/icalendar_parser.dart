/// iCalendar解析器
/// 遵循RFC5545标准
import '../../models/event.dart';
import '../../models/reminder.dart';

/// VAlarm组件
class VAlarm {
  final Duration trigger;
  final String action;
  final String? description;

  const VAlarm({
    required this.trigger,
    this.action = 'DISPLAY',
    this.description,
  });
}

/// VEvent组件
class VEvent {
  final String uid;
  final DateTime dtStart;
  final DateTime dtEnd;
  final String summary;
  final String? description;
  final String? location;
  final String? rrule;
  final bool allDay;
  final List<VAlarm> alarms;
  final DateTime? created;
  final DateTime? lastModified;

  const VEvent({
    required this.uid,
    required this.dtStart,
    required this.dtEnd,
    required this.summary,
    this.description,
    this.location,
    this.rrule,
    this.allDay = false,
    this.alarms = const [],
    this.created,
    this.lastModified,
  });

  /// 从Event创建VEvent
  factory VEvent.fromEvent(Event event, [List<Reminder> reminders = const []]) {
    return VEvent(
      uid: event.uid,
      dtStart: event.startTime,
      dtEnd: event.endTime,
      summary: event.title,
      description: event.description,
      location: event.location,
      rrule: event.rrule,
      allDay: event.allDay,
      alarms: reminders.map((r) => VAlarm(trigger: r.triggerBefore)).toList(),
      created: event.createdAt,
      lastModified: event.updatedAt,
    );
  }

  /// 转换为Event
  Event toEvent() {
    return Event.create(
      title: summary,
      description: description,
      location: location,
      startTime: dtStart,
      endTime: dtEnd,
      allDay: allDay,
      rrule: rrule,
    ).copyWith(uid: uid);
  }
}

/// iCalendar文档
class ICalendarDocument {
  final String version;
  final String prodId;
  final List<VEvent> events;

  const ICalendarDocument({
    this.version = '2.0',
    this.prodId = '-//CalendarApp//CN',
    this.events = const [],
  });

  /// 解析iCalendar内容
  factory ICalendarDocument.parse(String content) {
    return ICalendarParser.parse(content);
  }

  /// 序列化为iCalendar格式
  String serialize() {
    return ICalendarSerializer.serialize(this);
  }
}

/// iCalendar解析器
class ICalendarParser {
  /// 解析iCalendar文本
  static ICalendarDocument parse(String content) {
    // 展开折叠行
    content = _unfoldLines(content);

    final lines = content.split(RegExp(r'\r?\n'));
    String version = '2.0';
    String prodId = '-//CalendarApp//CN';
    final List<VEvent> events = [];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.startsWith('VERSION:')) {
        version = line.substring(8);
      } else if (line.startsWith('PRODID:')) {
        prodId = line.substring(7);
      } else if (line == 'BEGIN:VEVENT') {
        final eventResult = _parseVEvent(lines, i);
        if (eventResult.event != null) {
          events.add(eventResult.event!);
        }
        i = eventResult.endIndex;
      }
      i++;
    }

    return ICalendarDocument(version: version, prodId: prodId, events: events);
  }

  /// 展开折叠行
  static String _unfoldLines(String content) {
    // RFC5545: 以空格或制表符开头的行是前一行的延续
    return content.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  }

  /// 解析VEvent
  static _ParseResult _parseVEvent(List<String> lines, int startIndex) {
    String? uid;
    DateTime? dtStart;
    DateTime? dtEnd;
    String? summary;
    String? description;
    String? location;
    String? rrule;
    bool allDay = false;
    final List<VAlarm> alarms = [];
    DateTime? created;
    DateTime? lastModified;

    int i = startIndex + 1;
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line == 'END:VEVENT') {
        break;
      }

      if (line == 'BEGIN:VALARM') {
        final alarmResult = _parseVAlarm(lines, i);
        if (alarmResult.alarm != null) {
          alarms.add(alarmResult.alarm!);
        }
        i = alarmResult.endIndex;
      } else if (line.startsWith('UID:')) {
        uid = _unescapeText(line.substring(4));
      } else if (line.startsWith('DTSTART')) {
        final parsed = _parseDateTimeProperty(line);
        dtStart = parsed.dateTime;
        allDay = parsed.isDate;
      } else if (line.startsWith('DTEND')) {
        final parsed = _parseDateTimeProperty(line);
        dtEnd = parsed.dateTime;
      } else if (line.startsWith('SUMMARY:')) {
        summary = _unescapeText(line.substring(8));
      } else if (line.startsWith('DESCRIPTION:')) {
        description = _unescapeText(line.substring(12));
      } else if (line.startsWith('LOCATION:')) {
        location = _unescapeText(line.substring(9));
      } else if (line.startsWith('RRULE:')) {
        rrule = line.substring(6);
      } else if (line.startsWith('CREATED:')) {
        created = parseDateTime(line.substring(8));
      } else if (line.startsWith('LAST-MODIFIED:')) {
        lastModified = parseDateTime(line.substring(14));
      }

      i++;
    }

    if (uid != null && dtStart != null && summary != null) {
      dtEnd ??= dtStart.add(const Duration(hours: 1));
      return _ParseResult(
        event: VEvent(
          uid: uid,
          dtStart: dtStart,
          dtEnd: dtEnd,
          summary: summary,
          description: description,
          location: location,
          rrule: rrule,
          allDay: allDay,
          alarms: alarms,
          created: created,
          lastModified: lastModified,
        ),
        endIndex: i,
      );
    }

    return _ParseResult(endIndex: i);
  }

  /// 解析VAlarm
  static _AlarmResult _parseVAlarm(List<String> lines, int startIndex) {
    Duration? trigger;
    String action = 'DISPLAY';
    String? description;

    int i = startIndex + 1;
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line == 'END:VALARM') {
        break;
      }

      if (line.startsWith('TRIGGER:')) {
        trigger = parseTrigger(line.substring(8));
      } else if (line.startsWith('ACTION:')) {
        action = line.substring(7);
      } else if (line.startsWith('DESCRIPTION:')) {
        description = _unescapeText(line.substring(12));
      }

      i++;
    }

    if (trigger != null) {
      return _AlarmResult(
        alarm: VAlarm(
          trigger: trigger,
          action: action,
          description: description,
        ),
        endIndex: i,
      );
    }

    return _AlarmResult(endIndex: i);
  }

  /// 解析日期时间属性
  static _DateTimeResult _parseDateTimeProperty(String line) {
    // 格式: DTSTART:20251227T090000 或 DTSTART;VALUE=DATE:20251227
    final colonIndex = line.indexOf(':');
    if (colonIndex == -1) {
      return _DateTimeResult(dateTime: DateTime.now(), isDate: false);
    }

    final params = line.substring(0, colonIndex);
    final value = line.substring(colonIndex + 1);
    final isDate =
        params.contains('VALUE=DATE') && !params.contains('VALUE=DATE-TIME');

    return _DateTimeResult(dateTime: parseDateTime(value), isDate: isDate);
  }

  /// 解析日期时间
  static DateTime parseDateTime(String value) {
    // 移除可能的参数
    value = value.trim();

    // 格式: 20251227T090000, 20251227T090000Z, 20251227
    try {
      final isUtc = value.endsWith('Z');
      value = value.replaceAll('Z', '');

      if (value.length == 8) {
        // 日期格式: 20251227
        final year = int.parse(value.substring(0, 4));
        final month = int.parse(value.substring(4, 6));
        final day = int.parse(value.substring(6, 8));
        return DateTime(year, month, day);
      } else if (value.length >= 15) {
        // 日期时间格式: 20251227T090000
        final year = int.parse(value.substring(0, 4));
        final month = int.parse(value.substring(4, 6));
        final day = int.parse(value.substring(6, 8));
        final hour = int.parse(value.substring(9, 11));
        final minute = int.parse(value.substring(11, 13));
        final second = int.parse(value.substring(13, 15));

        if (isUtc) {
          return DateTime.utc(year, month, day, hour, minute, second).toLocal();
        }
        return DateTime(year, month, day, hour, minute, second);
      }
    } catch (e) {
      // 解析失败
    }
    return DateTime.now();
  }

  /// 解析TRIGGER值
  static Duration parseTrigger(String value) {
    return Reminder.parseTrigger(value);
  }

  /// 反转义文本
  static String _unescapeText(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', '\\');
  }
}

/// iCalendar序列化器
class ICalendarSerializer {
  /// 序列化为iCalendar格式
  static String serialize(ICalendarDocument doc) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:${doc.version}');
    buffer.writeln('PRODID:${doc.prodId}');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    for (final event in doc.events) {
      _serializeVEvent(buffer, event);
    }

    buffer.writeln('END:VCALENDAR');

    return buffer.toString();
  }

  /// 序列化VEvent
  static void _serializeVEvent(StringBuffer buffer, VEvent event) {
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:${event.uid}');

    if (event.allDay) {
      buffer.writeln('DTSTART;VALUE=DATE:${formatDate(event.dtStart)}');
      buffer.writeln(
        'DTEND;VALUE=DATE:${formatDate(event.dtEnd.add(const Duration(days: 1)))}',
      );
    } else {
      buffer.writeln('DTSTART:${formatDateTime(event.dtStart)}');
      buffer.writeln('DTEND:${formatDateTime(event.dtEnd)}');
    }

    buffer.writeln(_foldLine('SUMMARY:${_escapeText(event.summary)}'));

    if (event.description != null && event.description!.isNotEmpty) {
      buffer.writeln(
        _foldLine('DESCRIPTION:${_escapeText(event.description!)}'),
      );
    }

    if (event.location != null && event.location!.isNotEmpty) {
      buffer.writeln(_foldLine('LOCATION:${_escapeText(event.location!)}'));
    }

    if (event.rrule != null && event.rrule!.isNotEmpty) {
      buffer.writeln('RRULE:${event.rrule}');
    }

    if (event.created != null) {
      buffer.writeln('CREATED:${formatDateTime(event.created!)}');
    }

    if (event.lastModified != null) {
      buffer.writeln('LAST-MODIFIED:${formatDateTime(event.lastModified!)}');
    }

    buffer.writeln('DTSTAMP:${formatDateTime(DateTime.now())}');

    // 序列化提醒
    for (final alarm in event.alarms) {
      _serializeVAlarm(buffer, alarm);
    }

    buffer.writeln('END:VEVENT');
  }

  /// 序列化VAlarm
  static void _serializeVAlarm(StringBuffer buffer, VAlarm alarm) {
    buffer.writeln('BEGIN:VALARM');
    buffer.writeln('ACTION:${alarm.action}');
    buffer.writeln('TRIGGER:${_formatTrigger(alarm.trigger)}');
    if (alarm.description != null) {
      buffer.writeln('DESCRIPTION:${_escapeText(alarm.description!)}');
    } else {
      buffer.writeln('DESCRIPTION:Reminder');
    }
    buffer.writeln('END:VALARM');
  }

  /// 格式化日期
  static String formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '${year}${month}${day}T$hour$minute$second';
  }

  /// 格式化TRIGGER
  static String _formatTrigger(Duration duration) {
    if (duration == Duration.zero) {
      return 'PT0S';
    }

    final buffer = StringBuffer('-P');

    if (duration.inDays > 0) {
      buffer.write('${duration.inDays}D');
      final remainingHours = duration.inHours % 24;
      if (remainingHours > 0) {
        buffer.write('T${remainingHours}H');
      }
    } else if (duration.inHours > 0) {
      buffer.write('T${duration.inHours}H');
      final remainingMinutes = duration.inMinutes % 60;
      if (remainingMinutes > 0) {
        buffer.write('${remainingMinutes}M');
      }
    } else if (duration.inMinutes > 0) {
      buffer.write('T${duration.inMinutes}M');
    } else {
      buffer.write('T${duration.inSeconds}S');
    }

    return buffer.toString();
  }

  /// 转义文本
  static String _escapeText(String text) {
    return text
        .replaceAll('\\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }

  /// 折叠长行 (每行不超过75字符)
  static String _foldLine(String line) {
    if (line.length <= 75) {
      return line;
    }

    final buffer = StringBuffer();
    int start = 0;

    while (start < line.length) {
      final end = (start + 75).clamp(0, line.length);
      buffer.write(line.substring(start, end));
      if (end < line.length) {
        buffer.write('\r\n '); // 折叠标记
      }
      start = end;
    }

    return buffer.toString();
  }
}

/// 解析结果
class _ParseResult {
  final VEvent? event;
  final int endIndex;

  _ParseResult({this.event, required this.endIndex});
}

/// 闹钟解析结果
class _AlarmResult {
  final VAlarm? alarm;
  final int endIndex;

  _AlarmResult({this.alarm, required this.endIndex});
}

/// 日期时间解析结果
class _DateTimeResult {
  final DateTime dateTime;
  final bool isDate;

  _DateTimeResult({required this.dateTime, required this.isDate});
}
