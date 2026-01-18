/// 提醒选择器组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_provider.dart';

class ReminderPicker extends ConsumerWidget {
  /// 选中的提醒时间列表
  final List<Duration> selectedReminders;

  /// 选择变更回调
  final ValueChanged<List<Duration>> onChanged;

  const ReminderPicker({
    super.key,
    required this.selectedReminders,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('提醒'),
      subtitle: Text(_getSubtitleText()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showReminderSheet(context),
    );
  }

  String _getSubtitleText() {
    if (selectedReminders.isEmpty) {
      return '无提醒';
    }
    if (selectedReminders.length == 1) {
      return ReminderOption.formatDuration(selectedReminders.first);
    }
    return '${selectedReminders.length}个提醒';
  }

  Future<void> _showReminderSheet(BuildContext context) async {
    final result = await showModalBottomSheet<List<Duration>>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _ReminderBottomSheet(selectedReminders: selectedReminders),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class _ReminderBottomSheet extends StatefulWidget {
  final List<Duration> selectedReminders;

  const _ReminderBottomSheet({required this.selectedReminders});

  @override
  State<_ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<_ReminderBottomSheet> {
  late List<Duration> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedReminders);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽手柄
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const Text(
                  '选择提醒',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 提醒选项列表
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // 无提醒选项
                CheckboxListTile(
                  title: const Text('无提醒'),
                  value: _selected.isEmpty,
                  onChanged: (value) {
                    if (value == true) {
                      setState(() {
                        _selected.clear();
                      });
                    }
                  },
                ),
                const Divider(),
                // 预设选项
                ...ReminderOption.presets.map((option) {
                  final isSelected = _selected.contains(option.duration);
                  return CheckboxListTile(
                    title: Text(option.label),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(option.duration);
                        } else {
                          _selected.remove(option.duration);
                        }
                        // 排序
                        _selected.sort((a, b) => a.compareTo(b));
                      });
                    },
                  );
                }),
                const Divider(),
                // 自定义选项
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('自定义提醒时间...'),
                  onTap: () => _showCustomReminderDialog(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomReminderDialog() async {
    int value = 30;
    String unit = 'minutes';

    final result = await showDialog<Duration>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('自定义提醒'),
              content: Row(
                children: [
                  // 数值输入
                  Expanded(
                    child: TextFormField(
                      initialValue: value.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '提前',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          value = parsed;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 单位选择
                  DropdownButton<String>(
                    value: unit,
                    items: const [
                      DropdownMenuItem(value: 'minutes', child: Text('分钟')),
                      DropdownMenuItem(value: 'hours', child: Text('小时')),
                      DropdownMenuItem(value: 'days', child: Text('天')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          unit = v;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Duration duration;
                    switch (unit) {
                      case 'minutes':
                        duration = Duration(minutes: value);
                        break;
                      case 'hours':
                        duration = Duration(hours: value);
                        break;
                      case 'days':
                        duration = Duration(days: value);
                        break;
                      default:
                        duration = Duration(minutes: value);
                    }
                    Navigator.pop(context, duration);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && !_selected.contains(result)) {
      setState(() {
        _selected.add(result);
        _selected.sort((a, b) => a.compareTo(b));
      });
    }
  }
}

/// 简单的提醒显示组件（用于事件详情页）
class ReminderChips extends StatelessWidget {
  final List<Duration> reminders;

  const ReminderChips({super.key, required this.reminders});

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Text('无提醒', style: TextStyle(color: Colors.grey.shade600));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: reminders.map((duration) {
        return Chip(
          avatar: const Icon(Icons.notifications_outlined, size: 16),
          label: Text(
            ReminderOption.formatDuration(duration),
            style: const TextStyle(fontSize: 12),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
