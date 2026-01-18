/// 导入导出Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/icalendar_service.dart';
import '../services/event_service.dart';
import '../providers/event_provider.dart';
import '../providers/reminder_provider.dart';

/// iCalendar服务Provider
final icalendarServiceProvider = Provider<ICalendarService>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  final reminderService = ref.watch(reminderServiceProvider);
  return ICalendarService(eventService, reminderService);
});

/// 导入状态
enum ImportStatus { idle, loading, success, error }

/// 导入状态Notifier
class ImportNotifier extends StateNotifier<ImportState> {
  final ICalendarService _service;

  ImportNotifier(this._service) : super(const ImportState());

  /// 从文件选择器导入
  Future<void> importFromFilePicker() async {
    state = state.copyWith(status: ImportStatus.loading);

    try {
      final result = await _service.importFromFilePicker();

      if (result == null) {
        state = state.copyWith(status: ImportStatus.idle);
        return;
      }

      state = state.copyWith(
        status: result.hasErrors && result.importedCount == 0
            ? ImportStatus.error
            : ImportStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: ImportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const ImportState();
  }
}

/// 导入状态
class ImportState {
  final ImportStatus status;
  final ImportResult? result;
  final String? errorMessage;

  const ImportState({
    this.status = ImportStatus.idle,
    this.result,
    this.errorMessage,
  });

  ImportState copyWith({
    ImportStatus? status,
    ImportResult? result,
    String? errorMessage,
  }) {
    return ImportState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 导入状态Provider
final importNotifierProvider =
    StateNotifierProvider<ImportNotifier, ImportState>((ref) {
      return ImportNotifier(ref.watch(icalendarServiceProvider));
    });

/// 导出状态
enum ExportStatus { idle, loading, success, error }

/// 导出状态Notifier
class ExportNotifier extends StateNotifier<ExportState> {
  final ICalendarService _service;
  final EventService _eventService;

  ExportNotifier(this._service, this._eventService)
    : super(const ExportState());

  /// 导出全部事件
  Future<void> exportAll() async {
    state = state.copyWith(status: ExportStatus.loading);

    try {
      final events = await _eventService.getAllEvents();
      if (events.isEmpty) {
        state = state.copyWith(
          status: ExportStatus.error,
          errorMessage: '没有可导出的事件',
        );
        return;
      }

      final fileName = ICalendarService.generateFileName('calendar_export');
      await _service.exportAndShare(events, fileName);

      state = state.copyWith(
        status: ExportStatus.success,
        exportedCount: events.length,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 导出日期范围内的事件
  Future<void> exportDateRange(DateTime start, DateTime end) async {
    state = state.copyWith(status: ExportStatus.loading);

    try {
      final events = await _eventService.getEventsByDateRange(start, end);
      if (events.isEmpty) {
        state = state.copyWith(
          status: ExportStatus.error,
          errorMessage: '选定范围内没有事件',
        );
        return;
      }

      final fileName = ICalendarService.generateFileName('calendar_export');
      await _service.exportAndShare(events, fileName);

      state = state.copyWith(
        status: ExportStatus.success,
        exportedCount: events.length,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 重置状态
  void reset() {
    state = const ExportState();
  }
}

/// 导出状态
class ExportState {
  final ExportStatus status;
  final int? exportedCount;
  final String? errorMessage;

  const ExportState({
    this.status = ExportStatus.idle,
    this.exportedCount,
    this.errorMessage,
  });

  ExportState copyWith({
    ExportStatus? status,
    int? exportedCount,
    String? errorMessage,
  }) {
    return ExportState(
      status: status ?? this.status,
      exportedCount: exportedCount ?? this.exportedCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 导出状态Provider
final exportNotifierProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
      return ExportNotifier(
        ref.watch(icalendarServiceProvider),
        ref.watch(eventServiceProvider),
      );
    });
