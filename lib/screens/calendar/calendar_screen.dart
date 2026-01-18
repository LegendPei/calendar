/// 日历主页面 - 柔和极简主义风格
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../models/calendar_view_type.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/lunar_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/calendar/calendar_header.dart';
import '../../widgets/calendar/month_grid.dart';
import '../../widgets/calendar/week_view.dart';
import '../../widgets/calendar/day_timeline.dart';
import '../../widgets/calendar/year_view.dart';
import '../../widgets/calendar/schedule_view.dart';
import '../../widgets/calendar/semester_info_bar.dart';
import '../course/course_schedule_screen.dart';
import '../event/event_form_screen.dart';
import '../settings/import_export_screen.dart';
import '../subscription/subscription_list_screen.dart';
import 'event_list_bottom_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late PageController _pageController;
  static const int _initialPage = 500; // 中间页，可以左右滑动
  bool _isPageAnimating = false; // 防止循环更新的标志
  CalendarViewType? _lastViewType; // 记录上一次的视图类型

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 计算指定日期对应的页码
  int _getPageForDate(DateTime date, CalendarViewType viewType) {
    final now = DateTime.now();
    switch (viewType) {
      case CalendarViewType.year:
        return _initialPage + (date.year - now.year);
      case CalendarViewType.month:
        return _initialPage +
            (date.year - now.year) * 12 +
            (date.month - now.month);
      case CalendarViewType.week:
        final nowStart = DateTime(now.year, now.month, now.day);
        final dateStart = DateTime(date.year, date.month, date.day);
        final diff = dateStart.difference(nowStart).inDays;
        return _initialPage + (diff / 7).floor();
      case CalendarViewType.day:
        final nowStart = DateTime(now.year, now.month, now.day);
        final dateStart = DateTime(date.year, date.month, date.day);
        return _initialPage + dateStart.difference(nowStart).inDays;
      case CalendarViewType.schedule:
        // 日程视图按年导航
        return _initialPage + (date.year - now.year);
    }
  }

  /// 同步PageController到指定日期
  void _syncPageController(DateTime date, CalendarViewType viewType) {
    if (_isPageAnimating || !_pageController.hasClients) return;

    final targetPage = _getPageForDate(date, viewType);
    final currentPage = _pageController.page?.round() ?? _initialPage;

    if (targetPage != currentPage) {
      _isPageAnimating = true;
      _pageController
          .animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) {
            _isPageAnimating = false;
          });
    }
  }

  /// 计算页面偏移量对应的日期
  DateTime _getDateForPage(int page, CalendarViewType viewType) {
    final diff = page - _initialPage;
    final now = DateTime.now();
    switch (viewType) {
      case CalendarViewType.year:
        return DateTime(now.year + diff, now.month, 1);
      case CalendarViewType.month:
        return DateTime(now.year, now.month + diff, 1);
      case CalendarViewType.week:
        return now.add(Duration(days: diff * 7));
      case CalendarViewType.day:
        return now.add(Duration(days: diff));
      case CalendarViewType.schedule:
        // 日程视图按年导航
        return DateTime(now.year + diff, now.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewType = ref.watch(calendarViewTypeProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // 检测视图类型变化，重置PageController到当前选中日期对应的页面
    if (_lastViewType != null && _lastViewType != viewType) {
      // 使用microtask来避免在build期间同步更新，减少卡顿
      Future.microtask(() {
        if (mounted && _pageController.hasClients) {
          // 计算当前选中日期在新视图类型中对应的页码
          final currentDate = ref.read(selectedDateProvider);
          final targetPage = _getPageForDate(currentDate, viewType);
          // 使用jumpToPage而非animateToPage，避免动画开销
          _pageController.jumpToPage(targetPage);
        }
      });
    }
    _lastViewType = viewType;

    // 监听focusedDate变化，同步PageController（仅对月视图）
    ref.listen<DateTime>(focusedDateProvider, (previous, next) {
      if (viewType == CalendarViewType.month) {
        _syncPageController(next, viewType);
      }
    });

    // 监听selectedDate变化，同步PageController（对周/日视图）
    ref.listen<DateTime>(selectedDateProvider, (previous, next) {
      if (viewType == CalendarViewType.week ||
          viewType == CalendarViewType.day) {
        _syncPageController(next, viewType);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部工具栏（替代AppBar）
            _buildTopToolbar(context),
            // 学期周次信息栏
            const SemesterInfoBar(),
            // 日历头部导航（含胶囊切换器）
            const CalendarHeader(),
            // 农历详情行
            _buildLunarInfoRow(selectedDate),
            // 日历视图
            Expanded(child: _buildCalendarContent(viewType)),
          ],
        ),
      ),
      // FAB按钮 - 添加新事件
      floatingActionButton: _buildFab(context, selectedDate),
    );
  }

  /// 构建顶部工具栏
  Widget _buildTopToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.table_chart_outlined,
              color: SoftMinimalistColors.textSecondary,
            ),
            onPressed: () => _openCourseSchedule(context),
            tooltip: '课程表',
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.cloud_download_outlined,
              color: SoftMinimalistColors.textSecondary,
            ),
            onPressed: () => _openSubscriptions(context),
            tooltip: '订阅',
          ),
          IconButton(
            icon: Icon(
              Icons.swap_vert,
              color: SoftMinimalistColors.textSecondary,
            ),
            onPressed: () => _openImportExport(context),
            tooltip: '导入/导出',
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: SoftMinimalistColors.textSecondary,
            ),
            onPressed: () => _openSettings(context),
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  /// 构建农历详情行
  Widget _buildLunarInfoRow(DateTime selectedDate) {
    return Consumer(
      builder: (context, ref, child) {
        try {
          final lunar = ref.watch(lunarDateProvider(selectedDate));
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  lunar.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${lunar.yearGanZhi}年[${lunar.yearZodiac}]',
                  style: TextStyle(
                    fontSize: 12,
                    color: SoftMinimalistColors.textSecondary.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                if (lunar.solarTerm != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SoftMinimalistColors.softRedBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lunar.solarTerm!,
                      style: TextStyle(
                        fontSize: 11,
                        color: SoftMinimalistColors.accentRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  /// 构建日历内容区域
  Widget _buildCalendarContent(CalendarViewType viewType) {
    // 年视图不使用PageView
    if (viewType == CalendarViewType.year) {
      return const YearView();
    }

    // 其他视图使用PageView实现滑动
    return Column(
      children: [
        Expanded(
          flex: viewType == CalendarViewType.month ? 2 : 1,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (page) {
              // 标记为正在滑动，防止listener触发重复动画
              _isPageAnimating = true;

              final controller = ref.read(calendarControllerProvider);
              final targetDate = _getDateForPage(page, viewType);
              final currentSelected = ref.read(selectedDateProvider);

              // 更新焦点日期
              controller.setFocusedDate(targetDate);

              // 根据视图类型更新选中日期
              switch (viewType) {
                case CalendarViewType.month:
                  // 如果选中日期不在当前显示的月份内，同步更新选中日期
                  if (currentSelected.year != targetDate.year ||
                      currentSelected.month != targetDate.month) {
                    final daysInMonth = DateTime(
                      targetDate.year,
                      targetDate.month + 1,
                      0,
                    ).day;
                    final newDay = currentSelected.day <= daysInMonth
                        ? currentSelected.day
                        : 1;
                    controller.selectDate(
                      DateTime(targetDate.year, targetDate.month, newDay),
                    );
                  }
                  break;
                case CalendarViewType.day:
                  // 日视图：直接更新选中日期
                  controller.selectDate(targetDate);
                  break;
                case CalendarViewType.week:
                  // 周视图：更新选中日期到目标周的同一天（或周一）
                  final targetWeekStart = targetDate.subtract(
                    Duration(days: targetDate.weekday - 1),
                  );
                  final currentWeekday = currentSelected.weekday;
                  final newDate = targetWeekStart.add(
                    Duration(days: currentWeekday - 1),
                  );
                  controller.selectDate(newDate);
                  break;
                case CalendarViewType.schedule:
                  // 日程视图：更新选中日期为目标年份
                  controller.selectDate(
                    DateTime(
                      targetDate.year,
                      currentSelected.month,
                      currentSelected.day,
                    ),
                  );
                  break;
                default:
                  break;
              }

              // 延迟重置标志，确保状态更新完成
              Future.delayed(const Duration(milliseconds: 50), () {
                _isPageAnimating = false;
              });
            },
            itemBuilder: (context, index) {
              final date = _getDateForPage(index, viewType);
              return _buildCalendarViewForDate(viewType, date);
            },
          ),
        ),
        // 底部事件列表（月视图时显示）
        if (viewType == CalendarViewType.month)
          const Flexible(flex: 1, child: EventListBottomSheet()),
      ],
    );
  }

  /// 构建FAB按钮
  Widget _buildFab(BuildContext context, DateTime selectedDate) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [SoftMinimalistSizes.fabShadow],
      ),
      child: FloatingActionButton(
        onPressed: () => _addEvent(context, selectedDate),
        backgroundColor: SoftMinimalistColors.surface,
        child: Icon(Icons.add, color: SoftMinimalistColors.textPrimary),
      ),
    );
  }

  /// 添加事件
  Future<void> _addEvent(BuildContext context, DateTime date) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(initialDate: date),
      ),
    );

    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }

  /// 根据指定日期构建日历视图
  Widget _buildCalendarViewForDate(CalendarViewType viewType, DateTime date) {
    switch (viewType) {
      case CalendarViewType.year:
        return const YearView();
      case CalendarViewType.month:
        return _MonthViewPage(date: date);
      case CalendarViewType.week:
        return _WeekViewPage(date: date);
      case CalendarViewType.day:
        return _DayViewPage(date: date);
      case CalendarViewType.schedule:
        return _ScheduleViewPage(year: date.year);
    }
  }

  /// 打开设置页面
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SoftMinimalistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentTheme = ref.watch(themeModeProvider);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽指示条
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: SoftMinimalistColors.badgeGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '设置',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(
                  '主题设置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildThemeOption(
                      context,
                      ref,
                      '浅色',
                      ThemeMode.light,
                      currentTheme,
                      Icons.light_mode,
                    ),
                    const SizedBox(width: 12),
                    _buildThemeOption(
                      context,
                      ref,
                      '深色',
                      ThemeMode.dark,
                      currentTheme,
                      Icons.dark_mode,
                    ),
                    const SizedBox(width: 12),
                    _buildThemeOption(
                      context,
                      ref,
                      '跟随系统',
                      ThemeMode.system,
                      currentTheme,
                      Icons.settings_suggest,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                  title: const Text('关于'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        ),
        title: const Text('日历'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text('2025 Calendar App'),
            SizedBox(height: 16),
            Text(
              '一款简洁实用的日历应用，支持日程管理、提醒、农历显示等功能。',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建主题选项
  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
    IconData iconData,
  ) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeModeProvider.notifier).state = mode;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? SoftMinimalistColors.softRedBg
                : SoftMinimalistColors.badgeGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                iconData,
                color: isSelected
                    ? SoftMinimalistColors.accentRed
                    : SoftMinimalistColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? SoftMinimalistColors.accentRed
                      : SoftMinimalistColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开课程表页面
  void _openCourseSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CourseScheduleScreen()),
    );
  }

  /// 打开导入导出页面
  void _openImportExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportExportScreen()),
    );
  }

  /// 打开订阅管理页面
  void _openSubscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionListScreen()),
    );
  }
}

/// 月视图页面 - 显示指定月份
class _MonthViewPage extends ConsumerWidget {
  final DateTime date;

  const _MonthViewPage({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MonthGridForDate(date: date);
  }
}

/// 周视图页面 - 显示指定周
class _WeekViewPage extends ConsumerWidget {
  final DateTime date;

  const _WeekViewPage({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WeekViewForDate(date: date);
  }
}

/// 日视图页面 - 显示指定日期
class _DayViewPage extends ConsumerWidget {
  final DateTime date;

  const _DayViewPage({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DayTimelineForDate(date: date);
  }
}

/// 日程视图页面 - 显示指定年份
class _ScheduleViewPage extends ConsumerWidget {
  final int year;

  const _ScheduleViewPage({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScheduleViewForYear(year: year);
  }
}
