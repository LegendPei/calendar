/// 重复规则选择器组件
import 'package:flutter/material.dart';
import '../../models/recurrence_rule.dart';

/// 重复选项
class RecurrenceOption {
  final String label;
  final String? rrule;

  const RecurrenceOption(this.label, this.rrule);

  static const List<RecurrenceOption> presets = [
    RecurrenceOption('不重复', null),
    RecurrenceOption('每天', 'FREQ=DAILY'),
    RecurrenceOption('每周', 'FREQ=WEEKLY'),
    RecurrenceOption('每月', 'FREQ=MONTHLY'),
    RecurrenceOption('每年', 'FREQ=YEARLY'),
    RecurrenceOption('工作日', 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'),
  ];
}

class RecurrencePicker extends StatelessWidget {
  /// 当前选中的重复规则
  final String? selectedRRule;

  /// 选择回调
  final ValueChanged<String?> onChanged;

  const RecurrencePicker({
    super.key,
    this.selectedRRule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.repeat),
      title: const Text('重复'),
      subtitle: Text(_getDisplayText()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showRecurrenceSheet(context),
    );
  }

  String _getDisplayText() {
    if (selectedRRule == null || selectedRRule!.isEmpty) {
      return '不重复';
    }

    // 匹配预设选项
    for (final option in RecurrenceOption.presets) {
      if (option.rrule == selectedRRule) {
        return option.label;
      }
    }

    // 解析自定义规则
    try {
      final rule = RecurrenceRule.fromRRule(selectedRRule!);
      return rule.displayText;
    } catch (e) {
      return '自定义';
    }
  }

  Future<void> _showRecurrenceSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => _RecurrenceBottomSheet(
        selectedRRule: selectedRRule,
      ),
    );

    if (result != null || result == '') {
      onChanged(result?.isEmpty == true ? null : result);
    }
  }
}

class _RecurrenceBottomSheet extends StatelessWidget {
  final String? selectedRRule;

  const _RecurrenceBottomSheet({this.selectedRRule});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '选择重复规则',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...RecurrenceOption.presets.map((option) {
                  final isSelected = selectedRRule == option.rrule ||
                      (selectedRRule == null && option.rrule == null);
                  return ListTile(
                    title: Text(option.label),
                    trailing: isSelected
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, option.rrule ?? ''),
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('自定义...'),
                  onTap: () async {
                    // 关闭当前底部弹窗
                    Navigator.pop(context);
                    // 显示自定义对话框
                    final result = await _showCustomRecurrenceDialog(context);
                    if (result != null && context.mounted) {
                      Navigator.pop(context, result);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showCustomRecurrenceDialog(BuildContext context) async {
    RecurrenceFrequency frequency = RecurrenceFrequency.daily;
    int interval = 1;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('自定义重复'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 频率选择
                  DropdownButtonFormField<RecurrenceFrequency>(
                    value: frequency,
                    decoration: const InputDecoration(
                      labelText: '频率',
                      border: OutlineInputBorder(),
                    ),
                    items: RecurrenceFrequency.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(f.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          frequency = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // 间隔输入
                  TextFormField(
                    initialValue: interval.toString(),
                    decoration: InputDecoration(
                      labelText: '每隔',
                      suffixText: _getIntervalSuffix(frequency),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        interval = parsed;
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
                    final rule = RecurrenceRule(
                      frequency: frequency,
                      interval: interval,
                    );
                    Navigator.pop(context, rule.toRRule());
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getIntervalSuffix(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return '天';
      case RecurrenceFrequency.weekly:
        return '周';
      case RecurrenceFrequency.monthly:
        return '月';
      case RecurrenceFrequency.yearly:
        return '年';
    }
  }
}

