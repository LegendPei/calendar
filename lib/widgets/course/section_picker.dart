/// 节次选择器组件
import 'package:flutter/material.dart';

import '../../models/course_schedule.dart';
import '../../models/course_time.dart';

/// 节次范围选择器
class SectionPicker extends StatelessWidget {
  /// 开始节次
  final int startSection;

  /// 结束节次
  final int endSection;

  /// 课程表配置（用于获取总节数和时间信息）
  final CourseSchedule? schedule;

  /// 总节数（如果没有schedule则使用此值）
  final int totalSections;

  /// 开始节次变化回调
  final ValueChanged<int> onStartChanged;

  /// 结束节次变化回调
  final ValueChanged<int> onEndChanged;

  const SectionPicker({
    super.key,
    required this.startSection,
    required this.endSection,
    this.schedule,
    this.totalSections = 8,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  int get _totalSections => schedule?.totalSections ?? totalSections;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('第'),
        const SizedBox(width: 8),
        _buildDropdown(
          context,
          value: startSection,
          maxValue: endSection,
          minValue: 1,
          onChanged: onStartChanged,
        ),
        const Text('节'),
        const SizedBox(width: 16),
        const Text('到第'),
        const SizedBox(width: 8),
        _buildDropdown(
          context,
          value: endSection,
          maxValue: _totalSections,
          minValue: startSection,
          onChanged: onEndChanged,
        ),
        const Text('节'),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      items: List.generate(maxValue - minValue + 1, (i) {
        final section = minValue + i;
        final timeSlot = schedule?.getTimeSlot(section);

        return DropdownMenuItem(
          value: section,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$section'),
              if (timeSlot != null) ...[
                const SizedBox(width: 4),
                Text(
                  '(${timeSlot.startTimeString})',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        );
      }),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

/// 节次网格选择器（复选框多选模式）
/// 支持选择非连续的节次，如1,2,3和7,8
class SectionGridPicker extends StatefulWidget {
  /// 开始节次（兼容旧接口）
  final int startSection;

  /// 结束节次（兼容旧接口）
  final int endSection;

  /// 已选中的节次列表
  final List<int>? selectedSections;

  /// 课程表配置
  final CourseSchedule? schedule;

  /// 总节数
  final int totalSections;

  /// 午休后的节次
  final int lunchAfterSection;

  /// 选择变化回调（兼容旧接口）
  final void Function(int start, int end)? onChanged;

  /// 新的多选回调
  final void Function(List<int> sections)? onSectionsChanged;

  const SectionGridPicker({
    super.key,
    required this.startSection,
    required this.endSection,
    this.selectedSections,
    this.schedule,
    this.totalSections = 8,
    this.lunchAfterSection = 4,
    this.onChanged,
    this.onSectionsChanged,
  });

  @override
  State<SectionGridPicker> createState() => _SectionGridPickerState();
}

class _SectionGridPickerState extends State<SectionGridPicker> {
  late Set<int> _selectedSections;

  int get _totalSections =>
      widget.schedule?.totalSections ?? widget.totalSections;
  int get _lunchAfter =>
      widget.schedule?.lunchAfterSection ?? widget.lunchAfterSection;

  @override
  void initState() {
    super.initState();
    _initSelectedSections();
  }

  void _initSelectedSections() {
    if (widget.selectedSections != null) {
      _selectedSections = Set<int>.from(widget.selectedSections!);
    } else {
      // 从startSection到endSection生成列表
      _selectedSections = {};
      for (int i = widget.startSection; i <= widget.endSection; i++) {
        _selectedSections.add(i);
      }
    }
  }

  @override
  void didUpdateWidget(SectionGridPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSections != oldWidget.selectedSections) {
      if (widget.selectedSections != null) {
        _selectedSections = Set<int>.from(widget.selectedSections!);
      }
    } else if (oldWidget.startSection != widget.startSection ||
        oldWidget.endSection != widget.endSection) {
      _initSelectedSections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = widget.schedule?.timeSlots ?? CourseTime.defaultSchedule;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上午
        Row(
          children: [
            const Text(
              '上午',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _selectRange(1, _lunchAfter),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('全选', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSectionRow(1, _lunchAfter, timeSlots),
        const SizedBox(height: 16),
        // 下午
        Row(
          children: [
            const Text(
              '下午',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _selectRange(_lunchAfter + 1, _totalSections),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('全选', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSectionRow(_lunchAfter + 1, _totalSections, timeSlots),
        const SizedBox(height: 12),
        // 已选节次显示
        _buildSelectedInfo(),
      ],
    );
  }

  Widget _buildSelectedInfo() {
    if (_selectedSections.isEmpty) {
      return Text(
        '请选择上课节次',
        style: TextStyle(fontSize: 12, color: Colors.red.shade400),
      );
    }

    final sorted = _selectedSections.toList()..sort();
    final description = _formatSectionDescription(sorted);

    return Row(
      children: [
        Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
        const SizedBox(width: 4),
        Text(
          '已选: $description (共${sorted.length}节)',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const Spacer(),
        TextButton(
          onPressed: _clearAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '清空',
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          ),
        ),
      ],
    );
  }

  /// 格式化节次描述，如 "1-3节, 7-8节"
  String _formatSectionDescription(List<int> sections) {
    if (sections.isEmpty) return '';

    final ranges = <String>[];
    int rangeStart = sections.first;
    int rangeEnd = sections.first;

    for (int i = 1; i < sections.length; i++) {
      if (sections[i] == rangeEnd + 1) {
        rangeEnd = sections[i];
      } else {
        ranges.add(_formatRange(rangeStart, rangeEnd));
        rangeStart = sections[i];
        rangeEnd = sections[i];
      }
    }
    ranges.add(_formatRange(rangeStart, rangeEnd));

    return ranges.join(', ');
  }

  String _formatRange(int start, int end) {
    if (start == end) {
      return '第$start节';
    }
    return '第$start-$end节';
  }

  Widget _buildSectionRow(int from, int to, List<CourseTime> timeSlots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(to - from + 1, (index) {
        final section = from + index;
        final timeSlot = section <= timeSlots.length
            ? timeSlots[section - 1]
            : null;
        final isSelected = _selectedSections.contains(section);

        return GestureDetector(
          onTap: () => _toggleSection(section),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$section',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (timeSlot != null)
                  Text(
                    timeSlot.startTimeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _toggleSection(int section) {
    setState(() {
      if (_selectedSections.contains(section)) {
        _selectedSections.remove(section);
      } else {
        _selectedSections.add(section);
      }
    });
    _notifyChange();
  }

  void _selectRange(int from, int to) {
    setState(() {
      for (int i = from; i <= to; i++) {
        _selectedSections.add(i);
      }
    });
    _notifyChange();
  }

  void _clearAll() {
    setState(() {
      _selectedSections.clear();
    });
    _notifyChange();
  }

  void _notifyChange() {
    final sorted = _selectedSections.toList()..sort();

    // 调用新接口
    widget.onSectionsChanged?.call(sorted);

    // 兼容旧接口
    if (widget.onChanged != null && sorted.isNotEmpty) {
      widget.onChanged!(sorted.first, sorted.last);
    }
  }
}
