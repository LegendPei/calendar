/// 滚动式时间选择器（仅小时和分钟）
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// 滚动式时间选择器
class ScrollTimePicker extends StatefulWidget {
  /// 初始时间
  final TimeOfDay initialTime;

  /// 选择变化回调
  final ValueChanged<TimeOfDay> onTimeChanged;

  /// 分钟间隔（默认1分钟）
  final int minuteInterval;

  const ScrollTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.minuteInterval = 1,
  });

  @override
  State<ScrollTimePicker> createState() => _ScrollTimePickerState();
}

class _ScrollTimePickerState extends State<ScrollTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late int _selectedHour;
  late int _selectedMinute;

  static const double _itemExtent = 44.0;

  late List<int> _minuteValues;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;

    // 生成分钟列表
    _minuteValues = List.generate(
      60 ~/ widget.minuteInterval,
      (index) => index * widget.minuteInterval,
    );

    // 找到最接近的分钟值
    _selectedMinute = _findClosestMinuteIndex(widget.initialTime.minute);

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  int _findClosestMinuteIndex(int minute) {
    int closestIndex = 0;
    int minDiff = 60;
    for (int i = 0; i < _minuteValues.length; i++) {
      final diff = (minute - _minuteValues[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    final newTime = TimeOfDay(
      hour: _selectedHour,
      minute: _minuteValues[_selectedMinute],
    );
    widget.onTimeChanged(newTime);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 小时列
          SizedBox(
            width: 80,
            child: _buildWheelPicker(
              controller: _hourController,
              itemCount: 24,
              onSelectedItemChanged: (index) {
                setState(() => _selectedHour = index);
                _onTimeChanged();
              },
              itemBuilder: (index) => index.toString().padLeft(2, '0'),
              selectedIndex: _selectedHour,
            ),
          ),
          // 冒号分隔符
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // 分钟列
          SizedBox(
            width: 80,
            child: _buildWheelPicker(
              controller: _minuteController,
              itemCount: _minuteValues.length,
              onSelectedItemChanged: (index) {
                setState(() => _selectedMinute = index);
                _onTimeChanged();
              },
              itemBuilder: (index) =>
                  _minuteValues[index].toString().padLeft(2, '0'),
              selectedIndex: _selectedMinute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String Function(int) itemBuilder,
    required int selectedIndex,
  }) {
    return Stack(
      children: [
        // 选中项背景
        Center(
          child: Container(
            height: _itemExtent,
            decoration: BoxDecoration(
              color: SoftMinimalistColors.softRedBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // 滚轮选择器
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _itemExtent,
          perspective: 0.005,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected = index == selectedIndex;
              return Center(
                child: Text(
                  itemBuilder(index),
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? SoftMinimalistColors.textPrimary
                        : SoftMinimalistColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 显示滚动式时间选择器的底部弹窗
Future<TimeOfDay?> showScrollTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  int minuteInterval = 1,
  String? title,
}) async {
  TimeOfDay selectedTime = initialTime;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: SoftMinimalistColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽指示条
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SoftMinimalistColors.badgeGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题栏
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            color: SoftMinimalistColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        title ?? '选择时间',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          '确定',
                          style: TextStyle(
                            color: SoftMinimalistColors.accentRed,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 时间选择器
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: ScrollTimePicker(
                    initialTime: selectedTime,
                    minuteInterval: minuteInterval,
                    onTimeChanged: (time) {
                      selectedTime = time;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );

  if (result == true) {
    return selectedTime;
  }
  return null;
}
