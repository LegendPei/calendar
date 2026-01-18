/// 学期信息栏组件 - 显示当前周次和今日课程概览
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course.dart';
import '../../models/semester.dart';
import '../../providers/course_provider.dart';
import '../../screens/course/course_schedule_screen.dart';

/// 学期信息栏 - 带错误边界保护
class SemesterInfoBar extends StatelessWidget {
  const SemesterInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用错误边界保护，防止Provider错误导致整个页面崩溃
    return const _SemesterInfoBarContent();
  }
}

/// 学期信息栏内容
class _SemesterInfoBarContent extends ConsumerWidget {
  const _SemesterInfoBarContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final semesterAsync = ref.watch(currentSemesterProvider);

      return semesterAsync.when(
        data: (semester) {
          if (semester == null) {
            return _buildNoSemesterView(context);
          }
          final currentWeekAsync = ref.watch(currentWeekProvider);
          return currentWeekAsync.when(
            data: (currentWeek) =>
                _buildSemesterInfo(context, ref, semester, currentWeek),
            loading: () => _buildLoadingView(),
            error: (e, s) => _buildSemesterInfo(context, ref, semester, 1),
          );
        },
        loading: () => _buildLoadingView(),
        error: (e, s) => _buildNoSemesterView(context),
      );
    } catch (e) {
      // 捕获任何意外错误，显示默认视图
      return _buildNoSemesterView(context);
    }
  }

  /// 无学期时的提示
  Widget _buildNoSemesterView(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToCourseSchedule(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.school_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '设置学期以显示周次',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 加载中
  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('加载中...', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  /// 学期信息主体
  Widget _buildSemesterInfo(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
    int currentWeek,
  ) {
    final scheduleAsync = ref.watch(currentScheduleProvider);

    return GestureDetector(
      onTap: () => _navigateToCourseSchedule(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5),
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            // 周次徽章
            _buildWeekBadge(context, currentWeek),
            const SizedBox(width: 12),
            // 学期信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    semester.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 今日课程概览
                  scheduleAsync.when(
                    data: (schedule) {
                      if (schedule == null) {
                        return Text(
                          '共${semester.totalWeeks}周',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }
                      return _TodayCoursesInfo(
                        scheduleId: schedule.id,
                        currentWeek: currentWeek,
                        totalWeeks: semester.totalWeeks,
                      );
                    },
                    loading: () => Text(
                      '共${semester.totalWeeks}周',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    error: (e, s) => Text(
                      '共${semester.totalWeeks}周',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  /// 周次徽章
  Widget _buildWeekBadge(BuildContext context, int currentWeek) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '第',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
          Text(
            '$currentWeek',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const Text(
            '周',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 跳转到课程表
  void _navigateToCourseSchedule(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CourseScheduleScreen()),
    );
  }
}

/// 今日课程信息组件
class _TodayCoursesInfo extends ConsumerWidget {
  final String scheduleId;
  final int currentWeek;
  final int totalWeeks;

  const _TodayCoursesInfo({
    required this.scheduleId,
    required this.currentWeek,
    required this.totalWeeks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().weekday;
    final coursesAsync = ref.watch(
      coursesForDayProvider((
        scheduleId: scheduleId,
        week: currentWeek,
        dayOfWeek: today,
      )),
    );

    return coursesAsync.when(
      data: (courses) => _buildCoursesText(courses),
      loading: () => _buildDefaultText(),
      error: (e, s) => _buildDefaultText(),
    );
  }

  Widget _buildCoursesText(List<Course> courses) {
    final now = DateTime.now();
    final isWeekend = now.weekday > 5;

    String text;
    Color? textColor;

    if (courses.isEmpty) {
      if (isWeekend) {
        text = '今天是周末，好好休息 🎉';
      } else {
        text = '今天没有课程';
      }
      textColor = Colors.grey.shade600;
    } else {
      final nextCourse = _getNextCourse(courses, now);
      if (nextCourse != null) {
        text = '今天${courses.length}节课 · 下一节: ${nextCourse.name}';
      } else {
        text = '今天${courses.length}节课 · 已全部上完';
      }
      textColor = Colors.grey.shade700;
    }

    return Text(
      text,
      style: TextStyle(fontSize: 11, color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDefaultText() {
    return Text(
      '共$totalWeeks周',
      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
    );
  }

  /// 获取下一节课
  Course? _getNextCourse(List<Course> courses, DateTime now) {
    // 简化处理：返回第一门还没上完的课
    // 实际应该根据节次时间判断
    final currentHour = now.hour;
    for (final course in courses) {
      // 假设下午课程在13点之后
      if (course.startSection > 4 && currentHour < 13) {
        return course;
      }
      // 假设晚上课程在17点之后
      if (course.startSection > 8 && currentHour < 17) {
        return course;
      }
    }
    return null;
  }
}
