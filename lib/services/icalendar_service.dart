/// iCalendar导入导出服务
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../core/utils/icalendar_parser.dart';
import '../models/event.dart';
import '../models/reminder.dart';
import 'event_service.dart';
import 'reminder_service.dart';

/// 导入结果
class ImportResult {
  final int totalCount;
  final int importedCount;
  final int skippedCount;
  final int updatedCount;
  final List<String> errors;

  const ImportResult({
    this.totalCount = 0,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.updatedCount = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => importedCount > 0 || updatedCount > 0;

  @override
  String toString() {
    return '导入完成: 共$totalCount个事件, 新增$importedCount个, 更新$updatedCount个, 跳过$skippedCount个';
  }
}

/// 导出选项
enum ExportScope {
  single, // 单个事件
  dateRange, // 日期范围
  all, // 全部
}

class ICalendarService {
  final EventService _eventService;
  final ReminderService? _reminderService;

  ICalendarService(this._eventService, [this._reminderService]);

  /// 导出单个事件
  Future<String> exportEvent(Event event) async {
    List<Reminder> reminders = [];
    if (_reminderService != null) {
      reminders = await _reminderService!.getRemindersByEventId(event.id);
    }

    final vevent = VEvent.fromEvent(event, reminders);
    final doc = ICalendarDocument(events: [vevent]);
    return doc.serialize();
  }

  /// 导出多个事件
  Future<String> exportEvents(List<Event> events) async {
    final vevents = <VEvent>[];

    for (final event in events) {
      List<Reminder> reminders = [];
      if (_reminderService != null) {
        reminders = await _reminderService!.getRemindersByEventId(event.id);
      }
      vevents.add(VEvent.fromEvent(event, reminders));
    }

    final doc = ICalendarDocument(events: vevents);
    return doc.serialize();
  }

  /// 导出全部事件
  Future<String> exportAllEvents() async {
    final events = await _eventService.getAllEvents();
    return exportEvents(events);
  }

  /// 导出日期范围内的事件
  Future<String> exportEventsByDateRange(DateTime start, DateTime end) async {
    final events = await _eventService.getEventsByDateRange(start, end);
    return exportEvents(events);
  }

  /// 导出到文件
  Future<File> exportToFile(List<Event> events, String fileName) async {
    final content = await exportEvents(events);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.ics');
    await file.writeAsString(content);
    return file;
  }

  /// 导出并分享
  Future<void> exportAndShare(List<Event> events, String fileName) async {
    final file = await exportToFile(events, fileName);
    await Share.shareXFiles([XFile(file.path)], text: '日历事件导出');
  }

  /// 从文件选择器导入
  Future<ImportResult?> importFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = File(result.files.first.path!);
    return importFromFile(file);
  }

  /// 从文件导入
  Future<ImportResult> importFromFile(File file) async {
    try {
      final content = await file.readAsString();
      return importFromContent(content);
    } catch (e) {
      return ImportResult(errors: ['读取文件失败: $e']);
    }
  }

  /// 从内容导入
  Future<ImportResult> importFromContent(String content) async {
    final List<String> errors = [];
    int imported = 0;
    int updated = 0;
    int skipped = 0;

    try {
      final doc = ICalendarDocument.parse(content);

      for (final vevent in doc.events) {
        try {
          // 检查是否已存在相同UID的事件
          final existingEvent = await _eventService.getEventByUid(vevent.uid);

          if (existingEvent != null) {
            // 更新现有事件
            final updatedEvent = existingEvent.copyWith(
              title: vevent.summary,
              description: vevent.description,
              location: vevent.location,
              startTime: vevent.dtStart,
              endTime: vevent.dtEnd,
              allDay: vevent.allDay,
              rrule: vevent.rrule,
              updatedAt: DateTime.now(),
            );
            await _eventService.updateEvent(updatedEvent);

            // 更新提醒
            if (_reminderService != null && vevent.alarms.isNotEmpty) {
              final triggerBefores = vevent.alarms
                  .map((a) => a.trigger)
                  .toList();
              await _reminderService!.setRemindersForEvent(
                updatedEvent,
                triggerBefores,
              );
            }

            updated++;
          } else {
            // 创建新事件
            final newEvent = vevent.toEvent();
            await _eventService.insertEvent(newEvent);

            // 添加提醒
            if (_reminderService != null && vevent.alarms.isNotEmpty) {
              final triggerBefores = vevent.alarms
                  .map((a) => a.trigger)
                  .toList();
              await _reminderService!.setRemindersForEvent(
                newEvent,
                triggerBefores,
              );
            }

            imported++;
          }
        } catch (e) {
          errors.add('导入事件"${vevent.summary}"失败: $e');
          skipped++;
        }
      }

      return ImportResult(
        totalCount: doc.events.length,
        importedCount: imported,
        updatedCount: updated,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(errors: ['解析iCalendar文件失败: $e']);
    }
  }

  /// 解析iCalendar内容
  ICalendarDocument parseICalendar(String content) {
    return ICalendarDocument.parse(content);
  }

  /// 验证iCalendar内容
  bool validateICalendar(String content) {
    try {
      final doc = ICalendarDocument.parse(content);
      return doc.events.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取导出文件名
  static String generateFileName([String? prefix]) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix ?? 'calendar'}_$dateStr$timeStr';
  }
}
