/// 日历主页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/calendar_view_type.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/calendar/calendar_header.dart';
import '../../widgets/calendar/month_grid.dart';
import '../../widgets/calendar/week_view.dart';
import '../../widgets/calendar/day_timeline.dart';
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

  /// 计算页面偏移量对应的日期
  DateTime _getDateForPage(int page, CalendarViewType viewType) {
    final diff = page - _initialPage;
    final now = DateTime.now();
    switch (viewType) {
      case CalendarViewType.month:
        return DateTime(now.year, now.month + diff, 1);
      case CalendarViewType.week:
        return now.add(Duration(days: diff * 7));
      case CalendarViewType.day:
        return now.add(Duration(days: diff));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewType = ref.watch(calendarViewTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () => _openSubscriptions(context),
            tooltip: '订阅管理',
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: () => _openImportExport(context),
            tooltip: '导入/导出',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
            tooltip: '设置',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 日历头部导航
            const CalendarHeader(),
            // 日历视图 - 使用PageView实现平滑滑动
            Flexible(
              flex: 2,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  final controller = ref.read(calendarControllerProvider);
                  final targetDate = _getDateForPage(page, viewType);
                  // 直接设置日期
                  controller.goToDate(targetDate);
                },
                itemBuilder: (context, index) {
                  // 根据页面索引计算该页应该显示的日期
                  final date = _getDateForPage(index, viewType);
                  return _buildCalendarViewForDate(viewType, date);
                },
              ),
            ),
            // 底部事件列表（月视图时显示）
            if (viewType == CalendarViewType.month)
              const Flexible(
                flex: 1,
                child: EventListBottomSheet(),
              ),
          ],
        ),
      ),
    );
  }

  /// 根据指定日期构建日历视图
  Widget _buildCalendarViewForDate(CalendarViewType viewType, DateTime date) {
    switch (viewType) {
      case CalendarViewType.month:
        return _MonthViewPage(date: date);
      case CalendarViewType.week:
        return _WeekViewPage(date: date);
      case CalendarViewType.day:
        return _DayViewPage(date: date);
    }
  }


  /// 打开设置页面
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentTheme = ref.watch(themeModeProvider);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  '主题设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('日历'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('版本：1.0.0'),
                            SizedBox(height: 8),
                            Text('© 2025 Calendar App'),
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
                  },
                ),
              ],
            ),
          );
        },
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
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                iconData,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开导入导出页面
  void _openImportExport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImportExportScreen(),
      ),
    );
  }

  /// 打开订阅管理页面
  void _openSubscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionListScreen(),
      ),
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

