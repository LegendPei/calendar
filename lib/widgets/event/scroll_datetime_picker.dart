/// 滚动式日期时间选择器
import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// 滚动式日期时间选择器
class ScrollDateTimePicker extends StatefulWidget {
  /// 初始日期时间
  final DateTime initialDateTime;

  /// 选择变化回调
  final ValueChanged<DateTime> onDateTimeChanged;

  /// 是否只选择日期（全天事件）
  final bool dateOnly;

  /// 最小日期
  final DateTime? minDate;

  /// 最大日期
  final DateTime? maxDate;

  const ScrollDateTimePicker({
    super.key,
    required this.initialDateTime,
    required this.onDateTimeChanged,
    this.dateOnly = false,
    this.minDate,
    this.maxDate,
  });

  @override
  State<ScrollDateTimePicker> createState() => _ScrollDateTimePickerState();
}

class _ScrollDateTimePickerState extends State<ScrollDateTimePicker> {
  late FixedExtentScrollController _dateController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late List<DateTime> _dates;
  late int _selectedDateIndex;
  late int _selectedHour;
  late int _selectedMinute;

  static const int _daysRange = 365; // 前后各365天
  static const double _itemExtent = 44.0;

  @override
  void initState() {
    super.initState();
    _initDates();
    _selectedHour = widget.initialDateTime.hour;
    _selectedMinute = widget.initialDateTime.minute;

    _dateController = FixedExtentScrollController(
      initialItem: _selectedDateIndex,
    );
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  void _initDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );

    _dates = List.generate(
      _daysRange * 2 + 1,
      (index) => today.add(Duration(days: index - _daysRange)),
    );

    _selectedDateIndex = _dates.indexWhere(
      (date) =>
          date.year == initialDate.year &&
          date.month == initialDate.month &&
          date.day == initialDate.day,
    );
    if (_selectedDateIndex == -1) {
      _selectedDateIndex = _daysRange; // 默认今天
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onDateTimeChanged() {
    final selectedDate = _dates[_selectedDateIndex];
    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      widget.dateOnly ? 0 : _selectedHour,
      widget.dateOnly ? 0 : _selectedMinute,
    );
    widget.onDateTimeChanged(newDateTime);
  }

  String _formatDate(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日$weekday';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * 5,
      child: Row(
        children: [
          // 日期列
          Expanded(
            flex: 3,
            child: _buildWheelPicker(
              controller: _dateController,
              itemCount: _dates.length,
              onSelectedItemChanged: (index) {
                setState(() => _selectedDateIndex = index);
                _onDateTimeChanged();
              },
              itemBuilder: (index) => _formatDate(_dates[index]),
              selectedIndex: _selectedDateIndex,
            ),
          ),
          // 小时列
          if (!widget.dateOnly)
            Expanded(
              flex: 2,
              child: _buildWheelPicker(
                controller: _hourController,
                itemCount: 24,
                onSelectedItemChanged: (index) {
                  setState(() => _selectedHour = index);
                  _onDateTimeChanged();
                },
                itemBuilder: (index) => index.toString().padLeft(2, '0'),
                selectedIndex: _selectedHour,
              ),
            ),
          // 分钟列
          if (!widget.dateOnly)
            Expanded(
              flex: 2,
              child: _buildWheelPicker(
                controller: _minuteController,
                itemCount: 60,
                onSelectedItemChanged: (index) {
                  setState(() => _selectedMinute = index);
                  _onDateTimeChanged();
                },
                itemBuilder: (index) => index.toString().padLeft(2, '0'),
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
                    fontSize: isSelected ? 18 : 14,
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

/// 显示滚动式日期时间选择器的底部弹窗
Future<DateTime?> showScrollDateTimePicker({
  required BuildContext context,
  required DateTime initialDateTime,
  bool dateOnly = false,
  DateTime? minDate,
  DateTime? maxDate,
}) async {
  DateTime selectedDateTime = initialDateTime;

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
                        dateOnly ? '选择日期' : '选择时间',
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
                  child: ScrollDateTimePicker(
                    initialDateTime: selectedDateTime,
                    dateOnly: dateOnly,
                    minDate: minDate,
                    maxDate: maxDate,
                    onDateTimeChanged: (dt) {
                      selectedDateTime = dt;
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
    return selectedDateTime;
  }
  return null;
}
