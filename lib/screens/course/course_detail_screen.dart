// 课程详情页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../models/event.dart';
import '../../models/semester.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/reminder_provider.dart';
import '../event/event_detail_screen.dart';
import '../event/event_form_screen.dart';
import 'course_form_screen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  /// 课程
  final Course course;

  /// 课程表配置
  final CourseSchedule schedule;

  /// 学期信息（可选，用于计算具体日期）
  final Semester? semester;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.schedule,
    this.semester,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  late Course _course;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_course.color);
    final textColor = _getTextColor(color);

    return Scaffold(
      backgroundColor: SoftMinimalistColors.background,
      body: CustomScrollView(
        slivers: [
          // 顶部应用栏
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: color,
            foregroundColor: textColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _course.name,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _editCourse,
                tooltip: '编辑',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _showDeleteConfirmation,
                tooltip: '删除',
              ),
            ],
          ),

          // 内容
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  _buildInfoCard(),
                  const SizedBox(height: 16),

                  // 时间信息卡片
                  _buildTimeCard(),
                  const SizedBox(height: 16),

                  // 提醒卡片
                  _buildReminderCard(),
                  const SizedBox(height: 16),

                  // 备注卡片
                  if (_course.note != null && _course.note!.isNotEmpty)
                    _buildNoteCard(),
                  if (_course.note != null && _course.note!.isNotEmpty)
                    const SizedBox(height: 16),

                  // 相关日程卡片
                  _buildRelatedEventsCard(),
                  const SizedBox(height: 16),

                  // 添加相关日程按钮
                  _buildAddEventButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 地点
          if (_course.location != null && _course.location!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: '上课地点',
              value: _course.location!,
            ),
          if (_course.location != null && _course.location!.isNotEmpty)
            const SizedBox(height: 12),

          // 教师
          if (_course.teacher != null && _course.teacher!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.person_outline,
              label: '授课教师',
              value: _course.teacher!,
            ),

          // 如果没有地点和教师
          if ((_course.location == null || _course.location!.isEmpty) &&
              (_course.teacher == null || _course.teacher!.isEmpty))
            _buildInfoRow(
              icon: Icons.info_outline,
              label: '暂无详细信息',
              value: '点击右上角编辑按钮添加',
              valueColor: SoftMinimalistColors.textSecondary,
            ),
        ],
      ),
    );
  }

  /// 构建时间卡片
  Widget _buildTimeCard() {
    final startSlot = widget.schedule.getTimeSlot(_course.startSection);
    final endSlot = widget.schedule.getTimeSlot(_course.endSection);
    final timeStr = startSlot != null && endSlot != null
        ? '${startSlot.startTimeString} - ${endSlot.endTimeString}'
        : _course.sectionDescription;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '上课时间',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SoftMinimalistColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 星期和节次
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(_course.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _course.dayOfWeekName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorUtils.getContrastingTextColor(
                      Color(_course.color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _course.sectionDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 具体时间
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: SoftMinimalistColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 14,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 周次
          Row(
            children: [
              const Icon(
                Icons.date_range,
                size: 16,
                color: SoftMinimalistColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _course.weeksDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建提醒卡片
  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: Row(
        children: [
          Icon(
            _course.reminderMinutes != null
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            size: 20,
            color: _course.reminderMinutes != null
                ? SoftMinimalistColors.accentRed
                : SoftMinimalistColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '课程提醒',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SoftMinimalistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _course.reminderDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SoftMinimalistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建备注卡片
  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notes,
                size: 18,
                color: SoftMinimalistColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                '备注',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SoftMinimalistColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _course.note!,
            style: const TextStyle(
              fontSize: 14,
              color: SoftMinimalistColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建相关日程卡片
  Widget _buildRelatedEventsCard() {
    // 使用Consumer获取相关日程
    return Consumer(
      builder: (context, ref, child) {
        final eventsAsync = ref.watch(eventListProvider);

        return eventsAsync.when(
          data: (events) {
            // 筛选与该课程相关的日程
            final relatedEvents = events.where((event) {
              // 检查标题是否包含课程名
              if (event.title.contains(_course.name)) return true;
              // 检查描述是否包含课程关联标记
              if (event.description != null &&
                  event.description!.contains('【${_course.name}】')) {
                return true;
              }
              return false;
            }).toList();

            // 按开始时间排序
            relatedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

            // 只显示未来的事件（最多5个）
            final now = DateTime.now();
            final upcomingEvents = relatedEvents
                .where((e) => e.endTime.isAfter(now))
                .take(5)
                .toList();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SoftMinimalistColors.surface,
                borderRadius: BorderRadius.circular(
                  SoftMinimalistSizes.cardRadius,
                ),
                boxShadow: const [SoftMinimalistSizes.cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_note,
                        size: 18,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '相关日程',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SoftMinimalistColors.textPrimary,
                          ),
                        ),
                      ),
                      if (relatedEvents.length > 5)
                        Text(
                          '共${relatedEvents.length}个',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (upcomingEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '暂无相关日程',
                        style: TextStyle(
                          fontSize: 13,
                          color: SoftMinimalistColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...upcomingEvents.map((event) => _buildEventItem(event)),
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SoftMinimalistColors.surface,
              borderRadius: BorderRadius.circular(
                SoftMinimalistSizes.cardRadius,
              ),
              boxShadow: const [SoftMinimalistSizes.cardShadow],
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SoftMinimalistColors.surface,
              borderRadius: BorderRadius.circular(
                SoftMinimalistSizes.cardRadius,
              ),
              boxShadow: const [SoftMinimalistSizes.cardShadow],
            ),
            child: const Text(
              '加载日程失败',
              style: TextStyle(color: SoftMinimalistColors.textSecondary),
            ),
          ),
        );
      },
    );
  }

  /// 构建单个日程项
  Widget _buildEventItem(Event event) {
    final color = event.color != null
        ? Color(event.color!)
        : SoftMinimalistColors.accentRed;
    final now = DateTime.now();
    final isToday =
        event.startTime.year == now.year &&
        event.startTime.month == now.month &&
        event.startTime.day == now.day;
    final isPast = event.endTime.isBefore(now);

    return InkWell(
      onTap: () => _viewEvent(event),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // 颜色指示条
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: isPast ? color.withValues(alpha: 0.4) : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 日程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPast
                          ? SoftMinimalistColors.textSecondary
                          : SoftMinimalistColors.textPrimary,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatEventTime(event, isToday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? SoftMinimalistColors.accentRed
                          : SoftMinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 箭头图标
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

  /// 格式化事件时间
  String _formatEventTime(Event event, bool isToday) {
    final startTime = event.startTime;
    final endTime = event.endTime;

    if (event.allDay) {
      if (isToday) return '今天 全天';
      return '${startTime.month}/${startTime.day} 全天';
    }

    final timeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - '
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    if (isToday) return '今天 $timeStr';
    return '${startTime.month}/${startTime.day} $timeStr';
  }

  /// 查看日程详情
  Future<void> _viewEvent(Event event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );

    if (result == true && mounted) {
      // 刷新页面
      ref.read(calendarControllerProvider).refreshEvents();
      setState(() {});
    }
  }

  /// 构建添加相关日程按钮
  Widget _buildAddEventButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addRelatedEvent,
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SoftMinimalistColors.softRedBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: SoftMinimalistColors.accentRed,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '添加相关日程',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: SoftMinimalistColors.accentRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: SoftMinimalistColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: SoftMinimalistColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? SoftMinimalistColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取文字颜色
  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// 编辑课程
  Future<void> _editCourse() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseFormScreen(schedule: widget.schedule, course: _course),
      ),
    );

    if (result == true && mounted) {
      // 刷新课程数据 - 使用带参数的provider避免依赖链问题
      ref.invalidate(coursesByScheduleProvider(widget.schedule.id));
      try {
        final courses = await ref.read(
          coursesByScheduleProvider(widget.schedule.id).future,
        );
        final updated = courses.where((c) => c.id == _course.id).firstOrNull;
        if (updated != null && mounted) {
          setState(() {
            _course = updated;
          });
        } else if (mounted) {
          // 课程被删除了，返回上一页
          Navigator.pop(context, true);
        }
      } catch (e) {
        // 如果获取失败，直接返回上一页并刷新
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除"${_course.name}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: SoftMinimalistColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteCourse();
    }
  }

  /// 删除课程
  Future<void> _deleteCourse() async {
    try {
      // 取消课程提醒
      if (_course.reminderMinutes != null) {
        final reminderService = ref.read(courseReminderServiceProvider);
        await reminderService.cancelCourseReminders(_course);
      }

      await ref.read(courseListProvider.notifier).deleteCourse(_course.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('课程已删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  /// 添加相关日程
  Future<void> _addRelatedEvent() async {
    // 计算课程时间
    final startSlot = widget.schedule.getTimeSlot(_course.startSection);
    final endSlot = widget.schedule.getTimeSlot(_course.endSection);

    if (startSlot == null || endSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法获取课程时间信息')));
      return;
    }

    // 计算下一次上课的日期
    final now = DateTime.now();
    DateTime courseDate = _getNextCourseDate(now);

    // 构建开始和结束时间
    final startTime = DateTime(
      courseDate.year,
      courseDate.month,
      courseDate.day,
      startSlot.startTime.hour,
      startSlot.startTime.minute,
    );
    final endTime = DateTime(
      courseDate.year,
      courseDate.month,
      courseDate.day,
      endSlot.endTime.hour,
      endSlot.endTime.minute,
    );

    // 创建初始值
    final initialValues = EventFormInitialValues(
      title: '${_course.name} - ',
      description: '与课程【${_course.name}】相关',
      location: _course.location,
      startTime: startTime,
      endTime: endTime,
      color: _course.color,
    );

    // 跳转到日程表单
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(initialValues: initialValues),
      ),
    );

    if (result == true && mounted) {
      // 刷新日历事件数据
      ref.read(calendarControllerProvider).refreshEvents();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日程已创建')));
      // 刷新当前页面以显示新添加的相关日程
      setState(() {});
    }
  }

  /// 获取下一次上课的日期
  DateTime _getNextCourseDate(DateTime from) {
    // 获取当前星期几 (1-7, 周一到周日)
    final currentDay = from.weekday;
    final courseDay = _course.dayOfWeek;

    int daysToAdd;
    if (courseDay > currentDay) {
      // 本周的课还没上
      daysToAdd = courseDay - currentDay;
    } else if (courseDay < currentDay) {
      // 本周的课已经过了，下周
      daysToAdd = 7 - currentDay + courseDay;
    } else {
      // 今天就是上课日
      // 检查时间是否已过
      final startSlot = widget.schedule.getTimeSlot(_course.startSection);
      if (startSlot != null) {
        final courseTime = DateTime(
          from.year,
          from.month,
          from.day,
          startSlot.startTime.hour,
          startSlot.startTime.minute,
        );
        if (from.isAfter(courseTime)) {
          // 今天的课已经过了，下周
          daysToAdd = 7;
        } else {
          daysToAdd = 0;
        }
      } else {
        daysToAdd = 0;
      }
    }

    return from.add(Duration(days: daysToAdd));
  }
}
