/// 事件列表底部区域 - 柔和极简主义风格（课程与日程融合展示）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../models/event.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/course_provider.dart';
import '../course/course_detail_screen.dart';
import '../course/course_form_screen.dart';
import '../event/event_detail_screen.dart';
import '../event/event_form_screen.dart';

class EventListBottomSheet extends ConsumerWidget {
  const EventListBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(calendarEventsByDateProvider(selectedDate));
    final coursesAsync = ref.watch(coursesByDateProvider(selectedDate));
    final scheduleAsync = ref.watch(currentScheduleProvider);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        child: Column(
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
            // 标题行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _getDateTitle(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  // 显示总数量（课程+日程）
                  _buildCountBadge(coursesAsync, eventsAsync),
                  const SizedBox(width: 8),
                  // 添加按钮（弹出菜单选择添加课程或日程）
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SoftMinimalistColors.badgeGray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: SoftMinimalistColors.textPrimary,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'event') {
                        _addEvent(context, selectedDate, ref);
                      } else if (value == 'course') {
                        _addCourse(context, selectedDate, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'event',
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 20,
                              color: SoftMinimalistColors.accentRed,
                            ),
                            const SizedBox(width: 8),
                            const Text('添加日程'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'course',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.menu_book,
                              size: 20,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 8),
                            const Text('添加课程'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 课程和日程分组列表
            Expanded(
              child: _buildGroupedList(
                context,
                ref,
                selectedDate,
                coursesAsync,
                eventsAsync,
                scheduleAsync,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建数量徽章
  Widget _buildCountBadge(
    AsyncValue<List<Course>> coursesAsync,
    AsyncValue<List<Event>> eventsAsync,
  ) {
    final courseCount = coursesAsync.valueOrNull?.length ?? 0;
    final eventCount = eventsAsync.valueOrNull?.length ?? 0;
    final totalCount = courseCount + eventCount;

    if (totalCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.softRedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$totalCount',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: SoftMinimalistColors.accentRed,
        ),
      ),
    );
  }

  /// 构建分组列表（课程 + 日程）
  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    AsyncValue<List<Course>> coursesAsync,
    AsyncValue<List<Event>> eventsAsync,
    AsyncValue<CourseSchedule?> scheduleAsync,
  ) {
    // 处理加载状态
    if (coursesAsync.isLoading || eventsAsync.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: SoftMinimalistColors.accentRed,
          strokeWidth: 2,
        ),
      );
    }

    // 处理错误状态
    if (coursesAsync.hasError || eventsAsync.hasError) {
      return Center(
        child: Text(
          '加载失败',
          style: TextStyle(color: SoftMinimalistColors.textSecondary),
        ),
      );
    }

    final courses = coursesAsync.valueOrNull ?? [];
    final events = eventsAsync.valueOrNull ?? [];
    final schedule = scheduleAsync.valueOrNull;

    // 全部为空时显示空状态
    if (courses.isEmpty && events.isEmpty) {
      return _buildEmptyState(context, selectedDate, ref);
    }

    // 按节次排序课程
    final sortedCourses = List<Course>.from(courses)
      ..sort((a, b) => a.startSection.compareTo(b.startSection));

    // 按时间排序日程
    final sortedEvents = List<Event>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // 课程分组
        if (sortedCourses.isNotEmpty) ...[
          _buildSectionHeader(
            icon: Icons.menu_book,
            title: '课程',
            count: sortedCourses.length,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 6),
          ...sortedCourses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildCourseItem(context, course, schedule, ref),
            ),
          ),
        ],
        // 日程分组
        if (sortedEvents.isNotEmpty) ...[
          if (sortedCourses.isNotEmpty) const SizedBox(height: 8),
          _buildSectionHeader(
            icon: Icons.event,
            title: '日程',
            count: sortedEvents.length,
            color: SoftMinimalistColors.accentRed,
          ),
          const SizedBox(height: 6),
          ...sortedEvents.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildEventItem(context, event, ref),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SoftMinimalistColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建课程项
  Widget _buildCourseItem(
    BuildContext context,
    Course course,
    CourseSchedule? schedule,
    WidgetRef ref,
  ) {
    final color = Color(course.color);
    // 获取课程时间
    String timeText = '第${course.startSection}-${course.endSection}节';
    if (schedule != null) {
      final startSlot = schedule.getTimeSlot(course.startSection);
      final endSlot = schedule.getTimeSlot(course.endSection);
      if (startSlot != null && endSlot != null) {
        timeText =
            '${startSlot.startTimeString}-${endSlot.endTimeString} ($timeText)';
      }
    }

    return GestureDetector(
      onTap: () => _viewCourse(context, course, schedule, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 颜色条
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 课程图标
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.menu_book, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ),
                  if (course.location != null && course.location!.isNotEmpty)
                    Text(
                      course.location!,
                      style: TextStyle(
                        fontSize: 11,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right,
              size: 20,
              color: SoftMinimalistColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateTitle(DateTime date) {
    final today = DateTime.now();
    if (app_date_utils.DateUtils.isSameDay(date, today)) {
      return '今天';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, tomorrow)) {
      return '明天';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (app_date_utils.DateUtils.isSameDay(date, yesterday)) {
      return '昨天';
    }
    return '${date.month}月${date.day}日';
  }

  Widget _buildEmptyState(BuildContext context, DateTime date, WidgetRef ref) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available,
                size: 32,
                color: SoftMinimalistColors.textSecondary.withValues(
                  alpha: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '暂无课程和日程',
                style: TextStyle(
                  fontSize: 13,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // 添加日程按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _addEvent(context, date, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SoftMinimalistColors.softRedBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 14,
                            color: SoftMinimalistColors.accentRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '添加日程',
                            style: TextStyle(
                              fontSize: 12,
                              color: SoftMinimalistColors.accentRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 添加课程按钮
                  GestureDetector(
                    onTap: () => _addCourse(context, date, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 14,
                            color: Color(0xFF1976D2),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '添加课程',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Event event, WidgetRef ref) {
    final color = event.color != null
        ? Color(event.color!)
        : SoftMinimalistColors.accentRed;

    return GestureDetector(
      onTap: () => _viewEvent(context, event, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 颜色条
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.allDay
                        ? '全天'
                        : '${app_date_utils.DateUtils.formatTime(event.startTime)} - ${app_date_utils.DateUtils.formatTime(event.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.chevron_right,
              size: 20,
              color: SoftMinimalistColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewEvent(
    BuildContext context,
    Event event,
    WidgetRef ref,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );

    if (result == true) {
      ref.read(calendarControllerProvider).refreshEvents();
    }
  }

  Future<void> _addEvent(
    BuildContext context,
    DateTime date,
    WidgetRef ref,
  ) async {
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

  Future<void> _viewCourse(
    BuildContext context,
    Course course,
    CourseSchedule? schedule,
    WidgetRef ref,
  ) async {
    if (schedule == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('课程表信息不可用')));
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseDetailScreen(course: course, schedule: schedule),
      ),
    );

    if (result == true) {
      // 刷新课程数据
      ref.invalidate(coursesByDateProvider);
      ref.invalidate(courseCountByMonthProvider);
    }
  }

  Future<void> _addCourse(
    BuildContext context,
    DateTime date,
    WidgetRef ref,
  ) async {
    // 获取当前学期和课程表
    final schedule = ref.read(currentScheduleProvider).valueOrNull;

    if (schedule == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先设置学期和课程表')));
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CourseFormScreen(
          schedule: schedule,
          initialDayOfWeek: date.weekday,
        ),
      ),
    );

    if (result == true) {
      // 刷新课程数据
      ref.invalidate(coursesByDateProvider);
      ref.invalidate(courseCountByMonthProvider);
      ref.invalidate(courseListProvider);
    }
  }
}
