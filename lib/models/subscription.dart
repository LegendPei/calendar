/// 订阅数据模型
import 'package:uuid/uuid.dart';

/// 同步状态
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// 同步间隔选项
class SyncIntervalOption {
  final String label;
  final Duration duration;

  const SyncIntervalOption(this.label, this.duration);

  static const List<SyncIntervalOption> presets = [
    SyncIntervalOption('手动', Duration.zero),
    SyncIntervalOption('每15分钟', Duration(minutes: 15)),
    SyncIntervalOption('每30分钟', Duration(minutes: 30)),
    SyncIntervalOption('每小时', Duration(hours: 1)),
    SyncIntervalOption('每6小时', Duration(hours: 6)),
    SyncIntervalOption('每天', Duration(days: 1)),
  ];

  static SyncIntervalOption? findByDuration(Duration duration) {
    for (final option in presets) {
      if (option.duration == duration) {
        return option;
      }
    }
    return null;
  }
}

/// 订阅模型
class Subscription {
  /// 订阅ID
  final String id;

  /// 订阅名称
  final String name;

  /// 订阅URL
  final String url;

  /// 颜色
  final int? color;

  /// 是否启用
  final bool isActive;

  /// 最后同步时间
  final DateTime? lastSync;

  /// 最后同步状态
  final SyncStatus lastSyncStatus;

  /// 最后同步错误信息
  final String? lastSyncError;

  /// 同步间隔
  final Duration syncInterval;

  /// 事件数量
  final int eventCount;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.color,
    this.isActive = true,
    this.lastSync,
    this.lastSyncStatus = SyncStatus.idle,
    this.lastSyncError,
    this.syncInterval = const Duration(hours: 1),
    this.eventCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库Map创建
  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      color: map['color'] as int?,
      isActive: (map['is_active'] as int?) == 1,
      lastSync: map['last_sync'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_sync'] as int)
          : null,
      lastSyncStatus: SyncStatus.values[map['last_sync_status'] as int? ?? 0],
      lastSyncError: map['last_sync_error'] as String?,
      syncInterval: Duration(milliseconds: map['sync_interval'] as int? ?? 3600000),
      eventCount: map['event_count'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'last_sync': lastSync?.millisecondsSinceEpoch,
      'last_sync_status': lastSyncStatus.index,
      'last_sync_error': lastSyncError,
      'sync_interval': syncInterval.inMilliseconds,
      'event_count': eventCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并修改
  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    int? color,
    bool? isActive,
    DateTime? lastSync,
    SyncStatus? lastSyncStatus,
    String? lastSyncError,
    Duration? syncInterval,
    int? eventCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      lastSync: lastSync ?? this.lastSync,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      syncInterval: syncInterval ?? this.syncInterval,
      eventCount: eventCount ?? this.eventCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 创建新订阅
  factory Subscription.create({
    required String name,
    required String url,
    int? color,
    bool isActive = true,
    Duration syncInterval = const Duration(hours: 1),
  }) {
    final now = DateTime.now();
    const uuid = Uuid();
    return Subscription(
      id: uuid.v4(),
      name: name,
      url: url,
      color: color,
      isActive: isActive,
      syncInterval: syncInterval,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 获取同步间隔文本
  String get syncIntervalText {
    final option = SyncIntervalOption.findByDuration(syncInterval);
    if (option != null) return option.label;
    if (syncInterval.inDays > 0) return '每${syncInterval.inDays}天';
    if (syncInterval.inHours > 0) return '每${syncInterval.inHours}小时';
    if (syncInterval.inMinutes > 0) return '每${syncInterval.inMinutes}分钟';
    return '手动';
  }

  /// 获取最后同步文本
  String get lastSyncText {
    if (lastSync == null) return '从未同步';
    final now = DateTime.now();
    final diff = now.difference(lastSync!);
    if (diff.inMinutes < 1) return '刚刚同步';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前同步';
    if (diff.inHours < 24) return '${diff.inHours}小时前同步';
    return '${diff.inDays}天前同步';
  }

  /// 是否需要同步
  bool get needsSync {
    if (!isActive) return false;
    if (syncInterval == Duration.zero) return false;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync!) >= syncInterval;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 同步结果
class SyncResult {
  final int syncedCount;
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final List<String> errors;
  final Duration duration;

  const SyncResult({
    this.syncedCount = 0,
    this.addedCount = 0,
    this.updatedCount = 0,
    this.deletedCount = 0,
    this.errors = const [],
    this.duration = Duration.zero,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors;

  @override
  String toString() {
    return '同步完成: 共$syncedCount个事件, 新增$addedCount个, 更新$updatedCount个';
  }
}

