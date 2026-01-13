# 模块05: 网络订阅模块
## 1. 模块概述
网络订阅模块负责远程日历URL订阅功能，支持订阅公共日历（如节假日日历）和iCalendar格式的远程日历。
## 2. 功能需求
### 2.1 添加订阅
- 输入日历订阅URL
- 设置订阅名称
- 设置日历颜色
- 设置同步间隔
### 2.2 管理订阅
- 查看订阅列表
- 手动刷新订阅
- 编辑订阅设置
- 删除订阅
### 2.3 自动同步
- 按设定间隔自动同步
- 后台同步支持
- 同步状态显示
## 3. 文件结构
lib/
├── models/
│   └── subscription.dart
├── screens/subscription/
│   ├── subscription_list_screen.dart
│   └── subscription_form_screen.dart
├── widgets/subscription/
│   └── subscription_card.dart
├── providers/
│   └── subscription_provider.dart
└── services/
    └── subscription_service.dart
## 4. 数据模型
### 4.1 Subscription模型
class Subscription {
  final String id;
  final String name;
  final String url;
  final int? color;
  final bool isActive;
  final DateTime? lastSync;
  final Duration syncInterval;
  final DateTime createdAt;
  factory Subscription.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
}
### 4.2 SyncStatus枚举
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}
## 5. Provider设计
// 订阅服务Provider
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService(
    ref.watch(databaseProvider),
    ref.watch(icalendarServiceProvider),
  );
});
// 订阅列表
final subscriptionListProvider = AsyncNotifierProvider<SubscriptionListNotifier, List<Subscription>>(() {
  return SubscriptionListNotifier();
});
// 同步状态
final syncStatusProvider = StateProvider.family<SyncStatus, String>((ref, subscriptionId) {
  return SyncStatus.idle;
});
class SubscriptionListNotifier extends AsyncNotifier<List<Subscription>> {
  Future<void> addSubscription(Subscription sub);
  Future<void> updateSubscription(Subscription sub);
  Future<void> deleteSubscription(String id);
  Future<void> syncSubscription(String id);
  Future<void> syncAllSubscriptions();
}
## 6. Service设计
class SubscriptionService {
  final DatabaseHelper _db;
  final ICalendarService _icalService;
  final Dio _dio = Dio();
  // 添加订阅
  Future<String> addSubscription(Subscription sub);
  // 同步订阅
  Future<SyncResult> syncSubscription(String id) async {
    final sub = await getSubscriptionById(id);
    if (sub == null) throw Exception('Subscription not found');
    // 1. 获取远程日历内容
    final response = await _dio.get(sub.url);
    final content = response.data as String;
    // 2. 解析iCalendar
    final doc = _icalService.parseICalendar(content);
    // 3. 更新本地事件
    for (final vevent in doc.events) {
      await _syncEvent(vevent, sub.id);
    }
    // 4. 更新最后同步时间
    await updateLastSync(id, DateTime.now());
    return SyncResult(syncedCount: doc.events.length);
  }
  // 删除订阅及其所有事件
  Future<void> deleteSubscription(String id) async {
    await _db.delete('events', where: 'calendar_id = ?', whereArgs: [id]);
    await _db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }
}
class SyncResult {
  final int syncedCount;
  final int addedCount;
  final int updatedCount;
  final List<String> errors;
}
## 7. 自动同步设计
class SyncManager {
  Timer? _timer;
  // 启动自动同步
  void startAutoSync(WidgetRef ref) {
    _timer = Timer.periodic(Duration(minutes: 15), (_) {
      ref.read(subscriptionListProvider.notifier).syncAllSubscriptions();
    });
  }
  // 停止自动同步
  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }
}
## 8. Widget设计
### 8.1 SubscriptionCard
class SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  // 显示内容:
  // - 颜色指示
  // - 订阅名称
  // - URL
  // - 最后同步时间
  // - 同步状态指示
  // - 同步按钮
}
### 8.2 SubscriptionForm
class SubscriptionForm extends StatefulWidget {
  final Subscription? initial;
  // 表单字段:
  // - URL输入框
  // - 名称输入框
  // - 颜色选择器
  // - 同步间隔选择
  // - 启用/禁用开关
}
## 9. 常用订阅源示例
// 中国节假日
https://calendars.icloud.com/holidays/cn_zh.ics
// Google日历公共订阅格式
https://calendar.google.com/calendar/ical/xxx/public/basic.ics
## 10. 测试用例
### 10.1 单元测试
| 测试文件 | 测试内容 |
|---------|---------|
| subscription_test.dart | 模型测试 |
| subscription_service_test.dart | 服务测试 |
### 10.2 测试用例清单
group('SubscriptionService', () {
  test('addSubscription should insert to database');
  test('syncSubscription should fetch and parse remote calendar');
  test('syncSubscription should update local events');
  test('deleteSubscription should remove events');
});
## 11. 依赖说明
dependencies:
  dio: ^5.3.0
## 12. 注意事项
1. 网络请求需要处理超时和错误
2. 大型日历文件需要分批处理
3. 同步时需要显示进度指示
4. 订阅的事件应标记来源以便区分
5. 删除订阅时需要清理关联的事件
