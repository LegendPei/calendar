/// 日历头部导航组件 - 柔和极简主义风格
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/calendar_view_type.dart';
import '../../providers/calendar_provider.dart';

class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(focusedDateProvider);
    final viewType = ref.watch(calendarViewTypeProvider);
    final controller = ref.read(calendarControllerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 第一行：年月标题 + 操作按钮
          Row(
            children: [
              // 年月标题
              GestureDetector(
                onTap: () => _showDatePicker(context, ref),
                child: Row(
                  children: [
                    Text(
                      _getHeaderTitle(focusedDate, viewType, ref),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: SoftMinimalistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 导航箭头
              _buildNavButton(
                icon: Icons.chevron_left,
                onTap: () => _onPrevious(controller, viewType),
              ),
              _buildNavButton(
                icon: Icons.chevron_right,
                onTap: () => _onNext(controller, viewType),
              ),
              const SizedBox(width: 8),
              // 今天按钮
              _TodayButton(onTap: controller.goToToday),
            ],
          ),
          const SizedBox(height: 12),
          // 第二行：胶囊切换器
          _CapsuleTabs(
            selectedType: viewType,
            onSelected: controller.switchView,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: SoftMinimalistColors.textSecondary),
      ),
    );
  }

  /// 获取标题文本
  String _getHeaderTitle(
    DateTime date,
    CalendarViewType viewType,
    WidgetRef ref,
  ) {
    final selectedDate = ref.watch(selectedDateProvider);
    switch (viewType) {
      case CalendarViewType.year:
        return '${date.year}年';
      case CalendarViewType.month:
        return '${date.year}/${date.month.toString().padLeft(2, '0')}';
      case CalendarViewType.week:
        // 显示周范围
        final weekDates = app_date_utils.DateUtils.getWeekViewDates(
          selectedDate,
        );
        final startDate = weekDates.first;
        final endDate = weekDates.last;
        if (startDate.month == endDate.month) {
          return '${startDate.year}/${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')} - ${endDate.day.toString().padLeft(2, '0')}';
        } else {
          return '${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}';
        }
      case CalendarViewType.day:
        // 显示完整日期和星期
        final weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
        return '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')} ${weekdayNames[selectedDate.weekday - 1]}';
      case CalendarViewType.schedule:
        // 显示年份
        return '${selectedDate.year}年';
    }
  }

  /// 上一个
  void _onPrevious(CalendarController controller, CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.year:
        controller.goToPreviousYear();
        break;
      case CalendarViewType.month:
        controller.goToPreviousMonth();
        break;
      case CalendarViewType.week:
        controller.goToPreviousWeek();
        break;
      case CalendarViewType.day:
        controller.goToPreviousDay();
        break;
      case CalendarViewType.schedule:
        // 日程视图按年导航
        controller.goToPreviousYear();
        break;
    }
  }

  /// 下一个
  void _onNext(CalendarController controller, CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.year:
        controller.goToNextYear();
        break;
      case CalendarViewType.month:
        controller.goToNextMonth();
        break;
      case CalendarViewType.week:
        controller.goToNextWeek();
        break;
      case CalendarViewType.day:
        controller.goToNextDay();
        break;
      case CalendarViewType.schedule:
        // 日程视图按年导航
        controller.goToNextYear();
        break;
    }
  }

  /// 显示日期选择器
  Future<void> _showDatePicker(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(selectedDateProvider);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );

    if (pickedDate != null) {
      ref.read(calendarControllerProvider).goToDate(pickedDate);
    }
  }
}

/// 今天按钮
class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.surface,
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.pillRadius),
          boxShadow: const [SoftMinimalistSizes.cardShadow],
        ),
        child: Text(
          '今天',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: SoftMinimalistColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// 胶囊切换器 - 使用滑动指示器避免闪烁
class _CapsuleTabs extends StatefulWidget {
  final CalendarViewType selectedType;
  final Function(CalendarViewType) onSelected;

  const _CapsuleTabs({required this.selectedType, required this.onSelected});

  @override
  State<_CapsuleTabs> createState() => _CapsuleTabsState();
}

class _CapsuleTabsState extends State<_CapsuleTabs> {
  final List<GlobalKey> _tabKeys = List.generate(
    CalendarViewType.values.length,
    (_) => GlobalKey(),
  );

  @override
  Widget build(BuildContext context) {
    final selectedIndex = CalendarViewType.values.indexOf(widget.selectedType);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.badgeGray,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.pillRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 滑动指示器背景
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: _getAlignment(selectedIndex),
                child: FractionallySizedBox(
                  widthFactor: 1.0 / CalendarViewType.values.length,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: SoftMinimalistColors.softRedBg,
                      borderRadius: BorderRadius.circular(
                        SoftMinimalistSizes.pillRadius - 2,
                      ),
                    ),
                  ),
                ),
              ),
              // 按钮行
              Row(
                mainAxisSize: MainAxisSize.min,
                children: CalendarViewType.values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value;
                  final isSelected = type == widget.selectedType;
                  return Expanded(
                    child: GestureDetector(
                      key: _tabKeys[index],
                      onTap: () => widget.onSelected(type),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CalendarSizes.capsuleTabPaddingH,
                          vertical: 6,
                        ),
                        child: Center(
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isSelected
                                  ? SoftMinimalistColors.accentRed
                                  : SoftMinimalistColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 计算指示器的对齐位置
  Alignment _getAlignment(int index) {
    final count = CalendarViewType.values.length;
    // 从-1到1的范围，根据index计算
    final position = (index / (count - 1)) * 2 - 1;
    return Alignment(position, 0);
  }
}
