// 周次选择器组件
import 'package:flutter/material.dart';

import '../../core/constants/theme_constants.dart';

/// 周次选择器（横向滑动选择）
class WeekSelector extends StatefulWidget {
  /// 当前选中的周次
  final int selectedWeek;

  /// 总周数
  final int totalWeeks;

  /// 当前周次（用于高亮显示）
  final int? currentWeek;

  /// 选择回调
  final ValueChanged<int> onWeekSelected;

  const WeekSelector({
    super.key,
    required this.selectedWeek,
    required this.totalWeeks,
    this.currentWeek,
    required this.onWeekSelected,
  });

  @override
  State<WeekSelector> createState() => _WeekSelectorState();
}

class _WeekSelectorState extends State<WeekSelector> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 初始滚动到选中的周次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToWeek(widget.selectedWeek);
    });
  }

  @override
  void didUpdateWidget(WeekSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中周次变化时滚动到对应位置
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _scrollToWeek(widget.selectedWeek);
    }
  }

  void _scrollToWeek(int week) {
    if (!_scrollController.hasClients) return;
    // 每个chip大约80宽度，滚动到居中位置
    final targetOffset =
        (week - 1) * 80.0 - (MediaQuery.of(context).size.width / 2 - 40);
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CalendarSizes.capsuleTabHeight + 16,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.totalWeeks,
        itemBuilder: (context, index) {
          final week = index + 1;
          final isSelected = week == widget.selectedWeek;
          final isCurrent = week == widget.currentWeek;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: GestureDetector(
              onTap: () => widget.onWeekSelected(week),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: CalendarSizes.capsuleTabPaddingH,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // 胶囊标签样式
                  color: isSelected
                      ? CalendarColors.selected
                      : isCurrent
                      ? CalendarColors.selected.withValues(alpha: 0.5)
                      : SoftMinimalistColors.badgeGray,
                  borderRadius: BorderRadius.circular(
                    SoftMinimalistSizes.pillRadius,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 当前周指示点
                    if (isCurrent) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: CalendarColors.today,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isCurrent ? '第$week周(当前)' : '第$week周',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isCurrent
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: isSelected || isCurrent
                            ? CalendarColors.selectedText
                            : SoftMinimalistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 周次选择下拉菜单
class WeekDropdown extends StatelessWidget {
  /// 当前选中的周次
  final int selectedWeek;

  /// 总周数
  final int totalWeeks;

  /// 当前周次
  final int? currentWeek;

  /// 选择回调
  final ValueChanged<int> onWeekSelected;

  const WeekDropdown({
    super.key,
    required this.selectedWeek,
    required this.totalWeeks,
    this.currentWeek,
    required this.onWeekSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedWeek,
      underline: const SizedBox(),
      items: List.generate(totalWeeks, (index) {
        final week = index + 1;
        final isCurrent = week == currentWeek;

        return DropdownMenuItem(
          value: week,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('第$week周'),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '本周',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      onChanged: (value) {
        if (value != null) {
          onWeekSelected(value);
        }
      },
    );
  }
}

/// 周次范围选择器（用于添加课程时选择周次）
class WeekRangePicker extends StatefulWidget {
  /// 已选中的周次列表
  final List<int> selectedWeeks;

  /// 总周数
  final int totalWeeks;

  /// 选择回调
  final ValueChanged<List<int>> onChanged;

  const WeekRangePicker({
    super.key,
    required this.selectedWeeks,
    required this.totalWeeks,
    required this.onChanged,
  });

  @override
  State<WeekRangePicker> createState() => _WeekRangePickerState();
}

class _WeekRangePickerState extends State<WeekRangePicker> {
  late int _startWeek;
  late int _endWeek;
  int _weekType = 0; // 0: 每周, 1: 单周, 2: 双周

  @override
  void initState() {
    super.initState();
    _initFromSelectedWeeks();
  }

  @override
  void didUpdateWidget(WeekRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当selectedWeeks从外部更新时，重新初始化内部状态
    if (oldWidget.selectedWeeks != widget.selectedWeeks ||
        oldWidget.totalWeeks != widget.totalWeeks) {
      _initFromSelectedWeeks();
    }
  }

  void _initFromSelectedWeeks() {
    if (widget.selectedWeeks.isEmpty) {
      _startWeek = 1;
      _endWeek = widget.totalWeeks;
    } else {
      final sorted = List<int>.from(widget.selectedWeeks)..sort();
      _startWeek = sorted.first;
      _endWeek = sorted.last;

      // 判断周次类型
      if (sorted.length > 1) {
        final allOdd = sorted.every((w) => w % 2 == 1);
        final allEven = sorted.every((w) => w % 2 == 0);
        if (allOdd) {
          _weekType = 1;
        } else if (allEven) {
          _weekType = 2;
        }
      }
    }
  }

  void _updateWeeks() {
    final weeks = <int>[];
    for (int i = _startWeek; i <= _endWeek; i++) {
      if (_weekType == 0) {
        weeks.add(i);
      } else if (_weekType == 1 && i % 2 == 1) {
        weeks.add(i);
      } else if (_weekType == 2 && i % 2 == 0) {
        weeks.add(i);
      }
    }
    widget.onChanged(weeks);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 周次类型选择
        Row(
          children: [
            _buildTypeChip('每周', 0),
            const SizedBox(width: 8),
            _buildTypeChip('单周', 1),
            const SizedBox(width: 8),
            _buildTypeChip('双周', 2),
          ],
        ),
        const SizedBox(height: 16),
        // 周次范围
        Row(
          children: [
            const Text('从第'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _startWeek,
              items: List.generate(widget.totalWeeks, (i) {
                return DropdownMenuItem(value: i + 1, child: Text('${i + 1}'));
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _startWeek = value;
                    if (_endWeek < _startWeek) {
                      _endWeek = _startWeek;
                    }
                  });
                  _updateWeeks();
                }
              },
            ),
            const Text('周'),
            const SizedBox(width: 16),
            const Text('到第'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _endWeek,
              items: List.generate(widget.totalWeeks - _startWeek + 1, (i) {
                return DropdownMenuItem(
                  value: _startWeek + i,
                  child: Text('${_startWeek + i}'),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _endWeek = value;
                  });
                  _updateWeeks();
                }
              },
            ),
            const Text('周'),
          ],
        ),
        const SizedBox(height: 12),
        // 已选周次显示
        Text(
          '已选: ${_getWeeksDescription()}',
          style: const TextStyle(
            fontSize: 12,
            color: SoftMinimalistColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, int type) {
    final isSelected = _weekType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _weekType = type;
        });
        _updateWeeks();
      },
    );
  }

  String _getWeeksDescription() {
    if (widget.selectedWeeks.isEmpty) return '无';

    final sorted = List<int>.from(widget.selectedWeeks)..sort();
    if (sorted.length == 1) {
      return '第${sorted.first}周';
    }

    String suffix = '';
    if (_weekType == 1) {
      suffix = '(单)';
    } else if (_weekType == 2) {
      suffix = '(双)';
    }

    return '${sorted.first}-${sorted.last}周$suffix (共${sorted.length}周)';
  }
}

/// 周次网格选择器（多选）
class WeekGridPicker extends StatelessWidget {
  /// 已选中的周次
  final List<int> selectedWeeks;

  /// 总周数
  final int totalWeeks;

  /// 选择回调
  final ValueChanged<List<int>> onChanged;

  const WeekGridPicker({
    super.key,
    required this.selectedWeeks,
    required this.totalWeeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalWeeks, (index) {
        final week = index + 1;
        final isSelected = selectedWeeks.contains(week);

        return GestureDetector(
          onTap: () {
            final newSelection = List<int>.from(selectedWeeks);
            if (isSelected) {
              newSelection.remove(week);
            } else {
              newSelection.add(week);
            }
            newSelection.sort();
            onChanged(newSelection);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected
                  ? CalendarColors.selected
                  : SoftMinimalistColors.badgeGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$week',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected
                      ? CalendarColors.selectedText
                      : SoftMinimalistColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
