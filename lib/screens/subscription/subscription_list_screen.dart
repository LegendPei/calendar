/// 订阅列表页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/subscription/subscription_card.dart';
import 'subscription_form_screen.dart';

class SubscriptionListScreen extends ConsumerWidget {
  const SubscriptionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历订阅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _syncAll(context, ref),
            tooltip: '同步全部',
          ),
        ],
      ),
      body: subscriptionsAsync.when(
        data: (subscriptions) => subscriptions.isEmpty
            ? _buildEmptyState(context)
            : _buildSubscriptionList(context, ref, subscriptions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(subscriptionListProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSubscription(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无订阅',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '添加日历订阅来同步远程日历',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addSubscription(context),
            icon: const Icon(Icons.add),
            label: const Text('添加订阅'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showPresetSubscriptions(context),
            child: const Text('查看常用订阅源'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList(
    BuildContext context,
    WidgetRef ref,
    List<Subscription> subscriptions,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(subscriptionListProvider.notifier)
            .syncAllSubscriptions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          return SubscriptionCard(
            subscription: subscription,
            onTap: () => _editSubscription(context, subscription),
            onSync: () => _syncSubscription(context, ref, subscription),
            onDelete: () => _deleteSubscription(context, ref, subscription),
            onToggleVisibility: () => _toggleVisibility(ref, subscription),
          );
        },
      ),
    );
  }

  Future<void> _addSubscription(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionFormScreen()),
    );
  }

  Future<void> _editSubscription(
    BuildContext context,
    Subscription subscription,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SubscriptionFormScreen(subscription: subscription),
      ),
    );
  }

  Future<void> _syncSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    try {
      final result = await ref
          .read(subscriptionListProvider.notifier)
          .syncSubscription(subscription.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.toString()),
            backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncAll(BuildContext context, WidgetRef ref) async {
    try {
      final results = await ref
          .read(subscriptionListProvider.notifier)
          .syncAllSubscriptions();

      if (context.mounted) {
        final total = results.values.fold<int>(
          0,
          (sum, r) => sum + r.syncedCount,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('同步完成, 共$total个事件')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleVisibility(WidgetRef ref, Subscription subscription) {
    ref
        .read(subscriptionListProvider.notifier)
        .toggleVisibility(subscription.id);
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅'),
        content: Text('确定要删除"${subscription.name}"吗？\n这将同时删除该订阅的所有事件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(subscriptionListProvider.notifier)
          .deleteSubscription(subscription.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('订阅已删除')));
      }
    }
  }

  void _showPresetSubscriptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '常用订阅源',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.celebration),
              title: const Text('中国节假日'),
              subtitle: const Text('Apple iCloud节假日日历'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubscriptionFormScreen(
                      initialUrl:
                          'https://calendars.icloud.com/holidays/cn_zh.ics',
                      initialName: '中国节假日',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
