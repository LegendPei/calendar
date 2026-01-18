/// 订阅表单页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/event/color_picker.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  final Subscription? subscription;
  final String? initialUrl;
  final String? initialName;

  const SubscriptionFormScreen({
    super.key,
    this.subscription,
    this.initialUrl,
    this.initialName,
  });

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.subscription != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(subscriptionFormProvider.notifier);
      if (_isEditing) {
        notifier.initForEdit(widget.subscription!);
        _nameController.text = widget.subscription!.name;
        _urlController.text = widget.subscription!.url;
      } else {
        notifier.initForCreate();
        if (widget.initialUrl != null) {
          _urlController.text = widget.initialUrl!;
          notifier.updateUrl(widget.initialUrl!);
        }
        if (widget.initialName != null) {
          _nameController.text = widget.initialName!;
          notifier.updateName(widget.initialName!);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(subscriptionFormProvider);
    final notifier = ref.read(subscriptionFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑订阅' : '添加订阅'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: '删除',
            ),
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // URL输入
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: '订阅URL',
                hintText: 'https://example.com/calendar.ics',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _isValidating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: _validateUrl,
                        tooltip: '验证URL',
                      ),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入订阅URL';
                }
                if (!Uri.tryParse(value)!.hasScheme) {
                  return '请输入有效的URL';
                }
                return null;
              },
              onChanged: notifier.updateUrl,
            ),
            const SizedBox(height: 16),

            // 名称输入
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '订阅名称',
                hintText: '例如：中国节假日',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入订阅名称';
                }
                return null;
              },
              onChanged: notifier.updateName,
            ),
            const SizedBox(height: 16),

            // 颜色选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '颜色',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    ColorPicker(
                      selectedColor: formState.color,
                      onColorSelected: (color) => notifier.updateColor(color),
                      showNone: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 同步间隔
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('同步间隔'),
                subtitle: Text(_getSyncIntervalText(formState.syncInterval)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSyncIntervalPicker(notifier),
              ),
            ),
            const SizedBox(height: 16),

            // 启用开关
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.power_settings_new),
                title: const Text('启用订阅'),
                subtitle: const Text('禁用后将不会自动同步'),
                value: formState.isActive,
                onChanged: notifier.updateIsActive,
              ),
            ),
            const SizedBox(height: 24),

            // 说明信息
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  String _getSyncIntervalText(Duration interval) {
    final option = SyncIntervalOption.findByDuration(interval);
    if (option != null) return option.label;
    if (interval.inDays > 0) return '每${interval.inDays}天';
    if (interval.inHours > 0) return '每${interval.inHours}小时';
    if (interval.inMinutes > 0) return '每${interval.inMinutes}分钟';
    return '手动';
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '关于日历订阅',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• 支持标准iCalendar(.ics)格式的URL\n'
              '• 订阅的事件会自动同步到本地\n'
              '• 删除订阅会同时删除相关事件\n'
              '• 建议使用HTTPS链接',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先输入URL')));
      return;
    }

    setState(() => _isValidating = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      final isValid = await service.validateUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValid ? 'URL有效，可以订阅' : 'URL无效或无法访问'),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('验证失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  Future<void> _showSyncIntervalPicker(
    SubscriptionFormNotifier notifier,
  ) async {
    final result = await showModalBottomSheet<Duration>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择同步间隔',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...SyncIntervalOption.presets.map(
              (option) => ListTile(
                title: Text(option.label),
                trailing:
                    ref.watch(subscriptionFormProvider).syncInterval ==
                        option.duration
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(context, option.duration),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      notifier.updateSyncInterval(result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(subscriptionFormProvider);
    final error = formState.validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final subscription = formState.toSubscription(widget.subscription);
      final notifier = ref.read(subscriptionListProvider.notifier);

      if (_isEditing) {
        await notifier.updateSubscription(subscription);
      } else {
        await notifier.addSubscription(subscription);
        // 立即同步新订阅
        await notifier.syncSubscription(subscription.id);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditing ? '订阅已更新' : '订阅已添加')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅'),
        content: const Text('确定要删除这个订阅吗？\n这将同时删除该订阅的所有事件。'),
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

    if (confirmed == true && mounted) {
      await ref
          .read(subscriptionListProvider.notifier)
          .deleteSubscription(widget.subscription!.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('订阅已删除')));
      }
    }
  }
}
