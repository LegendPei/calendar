/// 订阅状态管理
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../providers/event_provider.dart';
import '../providers/calendar_provider.dart';

/// 订阅服务Provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final db = ref.watch(databaseProvider);
  final eventService = ref.watch(eventServiceProvider);
  return SubscriptionService(db, eventService);
});

/// 订阅列表Provider
final subscriptionListProvider =
    AsyncNotifierProvider<SubscriptionListNotifier, List<Subscription>>(() {
      return SubscriptionListNotifier();
    });

/// 订阅列表Notifier
class SubscriptionListNotifier extends AsyncNotifier<List<Subscription>> {
  @override
  Future<List<Subscription>> build() async {
    return _fetchSubscriptions();
  }

  Future<List<Subscription>> _fetchSubscriptions() async {
    final service = ref.read(subscriptionServiceProvider);
    return service.getAllSubscriptions();
  }

  /// 刷新订阅列表
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSubscriptions());
  }

  /// 添加订阅
  Future<void> addSubscription(Subscription subscription) async {
    final service = ref.read(subscriptionServiceProvider);
    await service.addSubscription(subscription);
    await refresh();
  }

  /// 更新订阅
  Future<void> updateSubscription(Subscription subscription) async {
    final service = ref.read(subscriptionServiceProvider);
    await service.updateSubscription(subscription);
    await refresh();
  }

  /// 删除订阅
  Future<void> deleteSubscription(String id) async {
    final service = ref.read(subscriptionServiceProvider);
    await service.deleteSubscription(id);
    await refresh();
  }

  /// 切换订阅显示状态
  Future<void> toggleVisibility(String id) async {
    final service = ref.read(subscriptionServiceProvider);
    final subscription = await service.getSubscriptionById(id);
    if (subscription != null) {
      final updated = subscription.copyWith(
        isVisible: !subscription.isVisible,
        updatedAt: DateTime.now(),
      );
      await service.updateSubscription(updated);
      await refresh();
      // 刷新日历视图中的事件
      ref.read(eventsRefreshTriggerProvider.notifier).state++;
    }
  }

  /// 同步单个订阅
  Future<SyncResult> syncSubscription(String id) async {
    final service = ref.read(subscriptionServiceProvider);

    // 更新状态为同步中
    ref.read(syncStatusProvider(id).notifier).state = SyncStatus.syncing;

    try {
      final result = await service.syncSubscription(id);

      // 更新状态
      ref.read(syncStatusProvider(id).notifier).state = result.hasErrors
          ? SyncStatus.error
          : SyncStatus.success;

      // 刷新订阅列表
      await refresh();

      // 刷新事件列表
      ref.invalidate(eventListProvider);

      // 刷新日历视图中的事件
      ref.read(eventsRefreshTriggerProvider.notifier).state++;

      return result;
    } catch (e) {
      ref.read(syncStatusProvider(id).notifier).state = SyncStatus.error;
      rethrow;
    }
  }

  /// 同步所有订阅
  Future<Map<String, SyncResult>> syncAllSubscriptions() async {
    final service = ref.read(subscriptionServiceProvider);
    final results = await service.syncAllSubscriptions();
    await refresh();
    ref.invalidate(eventListProvider);
    // 刷新日历视图中的事件
    ref.read(eventsRefreshTriggerProvider.notifier).state++;
    return results;
  }
}

/// 单个订阅的同步状态
final syncStatusProvider = StateProvider.family<SyncStatus, String>((ref, id) {
  return SyncStatus.idle;
});

/// 订阅详情Provider
final subscriptionDetailProvider = FutureProvider.family<Subscription?, String>(
  (ref, id) async {
    final service = ref.watch(subscriptionServiceProvider);
    return service.getSubscriptionById(id);
  },
);

/// 订阅统计Provider
final subscriptionStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionStats();
});

/// 自动同步管理器
class SyncManager {
  Timer? _timer;
  final Ref _ref;

  SyncManager(this._ref);

  /// 启动自动同步
  void startAutoSync({Duration interval = const Duration(minutes: 15)}) {
    stopAutoSync();
    _timer = Timer.periodic(interval, (_) {
      _ref.read(subscriptionListProvider.notifier).syncAllSubscriptions();
    });
  }

  /// 停止自动同步
  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// 是否正在运行
  bool get isRunning => _timer != null;
}

/// 同步管理器Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref);
  ref.onDispose(() => manager.stopAutoSync());
  return manager;
});

/// 订阅表单状态
class SubscriptionFormState {
  final String name;
  final String url;
  final int? color;
  final bool isActive;
  final Duration syncInterval;

  const SubscriptionFormState({
    this.name = '',
    this.url = '',
    this.color,
    this.isActive = true,
    this.syncInterval = const Duration(hours: 1),
  });

  SubscriptionFormState copyWith({
    String? name,
    String? url,
    int? color,
    bool? isActive,
    Duration? syncInterval,
  }) {
    return SubscriptionFormState(
      name: name ?? this.name,
      url: url ?? this.url,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      syncInterval: syncInterval ?? this.syncInterval,
    );
  }

  /// 验证表单
  String? validate() {
    if (name.trim().isEmpty) {
      return '请输入订阅名称';
    }
    if (url.trim().isEmpty) {
      return '请输入订阅URL';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return '请输入有效的URL';
    }
    return null;
  }

  /// 转换为Subscription
  Subscription toSubscription([Subscription? existing]) {
    if (existing != null) {
      return existing.copyWith(
        name: name,
        url: url,
        color: color,
        isActive: isActive,
        syncInterval: syncInterval,
        updatedAt: DateTime.now(),
      );
    }
    return Subscription.create(
      name: name,
      url: url,
      color: color,
      isActive: isActive,
      syncInterval: syncInterval,
    );
  }
}

/// 订阅表单Notifier
class SubscriptionFormNotifier extends StateNotifier<SubscriptionFormState> {
  SubscriptionFormNotifier() : super(const SubscriptionFormState());

  /// 初始化为新建模式
  void initForCreate() {
    state = const SubscriptionFormState();
  }

  /// 初始化为编辑模式
  void initForEdit(Subscription subscription) {
    state = SubscriptionFormState(
      name: subscription.name,
      url: subscription.url,
      color: subscription.color,
      isActive: subscription.isActive,
      syncInterval: subscription.syncInterval,
    );
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateUrl(String url) {
    state = state.copyWith(url: url);
  }

  void updateColor(int? color) {
    state = state.copyWith(color: color);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive);
  }

  void updateSyncInterval(Duration interval) {
    state = state.copyWith(syncInterval: interval);
  }
}

/// 订阅表单Provider
final subscriptionFormProvider =
    StateNotifierProvider<SubscriptionFormNotifier, SubscriptionFormState>((
      ref,
    ) {
      return SubscriptionFormNotifier();
    });
