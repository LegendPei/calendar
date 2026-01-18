/// 年视图组件 - 显示12个月的缩略图
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../models/calendar_view_type.dart';
import '../../providers/calendar_provider.dart';

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(focusedDateProvider);
    final year = focusedDate.year;
    final controller = ref.read(calendarControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return _MonthThumbnail(
            year: year,
            month: month,
            onTap: () {
              // 切换到该月的月视图
              controller.goToDate(DateTime(year, month, 1));
              controller.switchView(CalendarViewType.month);
            },
          );
        },
      ),
    );
  }
}

class _MonthThumbnail extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onTap;

  const _MonthThumbnail({
    required this.year,
    required this.month,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: SoftMinimalistColors.surface,
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
          boxShadow: const [SoftMinimalistSizes.cardShadow],
        ),
        child: Column(
          children: [
            // 月份标题
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$month月',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentMonth
                      ? SoftMinimalistColors.accentRed
                      : SoftMinimalistColors.textPrimary,
                ),
              ),
            ),
            // 简化的日期网格
            Expanded(child: _buildMiniCalendar()),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // 调整为周一开始 (1=周一, 7=周日)
    int startWeekday = firstDayOfMonth.weekday; // 1-7

    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: 42, // 6 rows x 7 days
        itemBuilder: (context, index) {
          final dayOffset = index - (startWeekday - 1);
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox.shrink();
          }
          final day = dayOffset + 1;
          final isToday =
              now.year == year && now.month == month && now.day == day;

          return Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: isToday
                  ? BoxDecoration(
                      color: SoftMinimalistColors.accentRed,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 7,
                    color: isToday
                        ? Colors.white
                        : SoftMinimalistColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
