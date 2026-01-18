/// 订阅卡片组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final VoidCallback? onTap;
  final VoidCallback? onSync;
  final VoidCallback? onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
    this.onSync,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider(subscription.id));
    final color = subscription.color != null
        ? Color(subscription.color!)
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  // 颜色指示
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 订阅信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subscription.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!subscription.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '已禁用',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subscription.url,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 同步按钮
                  _buildSyncButton(context, syncStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // 底部信息行
              Row(
                children: [
                  // 事件数量
                  _buildInfoChip(
                    icon: Icons.event,
                    label: '${subscription.eventCount}个事件',
                  ),
                  const SizedBox(width: 16),
                  // 同步间隔
                  _buildInfoChip(
                    icon: Icons.sync,
                    label: subscription.syncIntervalText,
                  ),
                  const Spacer(),
                  // 最后同步状态
                  _buildSyncStatusIndicator(subscription.lastSyncStatus),
                  const SizedBox(width: 8),
                  Text(
                    subscription.lastSyncText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, SyncStatus status) {
    if (status == SyncStatus.syncing) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.sync),
      onPressed: onSync,
      tooltip: '立即同步',
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSyncStatusIndicator(SyncStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case SyncStatus.idle:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case SyncStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }
}
