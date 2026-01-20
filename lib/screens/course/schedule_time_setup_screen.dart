/// 作息时间设置页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course_schedule.dart';
import '../../models/course_time.dart';
import '../../providers/course_provider.dart';
import '../../widgets/common/scroll_time_picker.dart';

class ScheduleTimeSetupScreen extends ConsumerStatefulWidget {
  /// 要编辑的课程表
  final CourseSchedule schedule;

  const ScheduleTimeSetupScreen({super.key, required this.schedule});

  @override
  ConsumerState<ScheduleTimeSetupScreen> createState() =>
      _ScheduleTimeSetupScreenState();
}

class _ScheduleTimeSetupScreenState
    extends ConsumerState<ScheduleTimeSetupScreen> {
  late List<CourseTime> _timeSlots;
  late int _lunchAfterSection;
  late int _daysPerWeek;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timeSlots = List.from(widget.schedule.timeSlots);
    _lunchAfterSection = widget.schedule.lunchAfterSection;
    _daysPerWeek = widget.schedule.daysPerWeek;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作息时间设置'),
        actions: [
          TextButton(onPressed: _resetToDefault, child: const Text('恢复默认')),
        ],
      ),
      body: Column(
        children: [
          // 说明卡片
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '设置每天的课程节次和时间，点击时间可以修改',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 每周天数设置
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_view_week, size: 20),
                const SizedBox(width: 8),
                const Text('每周上课天数'),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 5,
                        label: Text('5天'),
                        tooltip: '周一至周五',
                      ),
                      ButtonSegment(
                        value: 6,
                        label: Text('6天'),
                        tooltip: '周一至周六',
                      ),
                      ButtonSegment(
                        value: 7,
                        label: Text('7天'),
                        tooltip: '周一至周日',
                      ),
                    ],
                    selected: {_daysPerWeek},
                    onSelectionChanged: (value) {
                      setState(() => _daysPerWeek = value.first);
                    },
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 午休设置
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.restaurant, size: 20),
                const SizedBox(width: 8),
                const Text('午休在第'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _lunchAfterSection,
                  items: List.generate(_timeSlots.length, (i) => i + 1)
                      .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _lunchAfterSection = value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text('节后'),
                const Spacer(),
                // 添加/删除节次按钮
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _timeSlots.length > 1 ? _removeSection : null,
                  tooltip: '删除最后一节',
                ),
                Text(
                  '${_timeSlots.length}节',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _timeSlots.length < 12 ? _addSection : null,
                  tooltip: '添加一节',
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // 节次列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isAfternoon = slot.section > _lunchAfterSection;

                return Column(
                  children: [
                    // 午休分隔
                    if (index == _lunchAfterSection)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.orange.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '午 休',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 节次行
                    _buildTimeSlotRow(slot, isAfternoon),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存设置'),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotRow(CourseTime slot, bool isAfternoon) {
    return Container(
      color: isAfternoon ? Colors.orange.shade50.withValues(alpha: 0.3) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAfternoon
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Text(
            '${slot.section}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAfternoon
                  ? Colors.orange.shade700
                  : Colors.blue.shade700,
            ),
          ),
        ),
        title: Row(
          children: [
            // 开始时间
            InkWell(
              onTap: () => _selectTime(slot.section, isStart: true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.startTimeString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—'),
            ),
            // 结束时间
            InkWell(
              onTap: () => _selectTime(slot.section, isStart: false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.endTimeString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '时长 ${slot.durationMinutes} 分钟',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ),
    );
  }

  /// 选择时间
  Future<void> _selectTime(int section, {required bool isStart}) async {
    final slot = _timeSlots.firstWhere((s) => s.section == section);
    final initialTime = isStart ? slot.startTime : slot.endTime;

    final time = await showScrollTimePicker(
      context: context,
      initialTime: initialTime,
      minuteInterval: 5, // 5分钟间隔，方便选择
      title: isStart ? '选择开始时间' : '选择结束时间',
    );

    if (time != null) {
      setState(() {
        final index = _timeSlots.indexWhere((s) => s.section == section);
        if (isStart) {
          _timeSlots[index] = slot.copyWith(startTime: time);
        } else {
          _timeSlots[index] = slot.copyWith(endTime: time);
        }
      });
    }
  }

  /// 添加一节
  void _addSection() {
    final lastSlot = _timeSlots.last;
    // 新节次开始时间 = 上一节结束时间 + 10分钟
    final newStartMinutes =
        lastSlot.endTime.hour * 60 + lastSlot.endTime.minute + 10;
    // 新节次时长 = 45分钟
    final newEndMinutes = newStartMinutes + 45;

    final newSlot = CourseTime(
      section: lastSlot.section + 1,
      startTime: TimeOfDay(
        hour: newStartMinutes ~/ 60,
        minute: newStartMinutes % 60,
      ),
      endTime: TimeOfDay(hour: newEndMinutes ~/ 60, minute: newEndMinutes % 60),
    );

    setState(() {
      _timeSlots.add(newSlot);
    });
  }

  /// 删除最后一节
  void _removeSection() {
    if (_timeSlots.length <= 1) return;

    setState(() {
      _timeSlots.removeLast();
      // 调整午休位置
      if (_lunchAfterSection > _timeSlots.length) {
        _lunchAfterSection = _timeSlots.length;
      }
    });
  }

  /// 恢复默认
  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认'),
        content: const Text('确定要恢复为默认作息时间吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _timeSlots = List.from(CourseTime.defaultSchedule);
                _lunchAfterSection = CourseTime.defaultLunchAfterSection;
                _daysPerWeek = 5; // 默认5天
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 保存
  Future<void> _save() async {
    // 验证时间逻辑
    for (final slot in _timeSlots) {
      final startMinutes = slot.startTime.hour * 60 + slot.startTime.minute;
      final endMinutes = slot.endTime.hour * 60 + slot.endTime.minute;
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('第${slot.section}节的结束时间必须晚于开始时间')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final updatedSchedule = widget.schedule.copyWith(
        timeSlots: _timeSlots,
        lunchAfterSection: _lunchAfterSection,
        daysPerWeek: _daysPerWeek,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(scheduleNotifierProvider.notifier)
          .updateSchedule(updatedSchedule);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('作息时间已保存')));
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
}
