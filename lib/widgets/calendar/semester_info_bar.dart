// 学期信息栏组件 - 显示当前周次和今日课程概览
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/utils/course_status_utils.dart';
import '../../models/course.dart';
import '../../models/course_schedule.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.surface,
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
          boxShadow: const [SoftMinimalistSizes.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CalendarColors.selected,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 20,
                color: CalendarColors.selectedText,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设置学期',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '点击配置学期信息以显示周次',
                    style: TextStyle(
                      fontSize: 12,
                      color: SoftMinimalistColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: SoftMinimalistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 加载中
  Widget _buildLoadingView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.surface,
        borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        boxShadow: const [SoftMinimalistSizes.cardShadow],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CalendarColors.today,
            ),
          ),
          SizedBox(width: 12),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 14,
              color: SoftMinimalistColors.textSecondary,
            ),
          ),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.surface,
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
          boxShadow: const [SoftMinimalistSizes.cardShadow],
        ),
        child: Row(
          children: [
            // 周次徽章
            _buildWeekBadge(context, currentWeek),
            const SizedBox(width: 16),
            // 学期信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    semester.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: SoftMinimalistColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 今日课程概览
                  scheduleAsync.when(
                    data: (schedule) {
                      if (schedule == null) {
                        return Text(
                          '共${semester.totalWeeks}周',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SoftMinimalistColors.textSecondary,
                          ),
                        );
                      }
                      return _TodayCoursesInfo(
                        schedule: schedule,
                        semester: semester,
                        currentWeek: currentWeek,
                        totalWeeks: semester.totalWeeks,
                      );
                    },
                    loading: () => Text(
                      '共${semester.totalWeeks}周',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                    ),
                    error: (e, s) => Text(
                      '共${semester.totalWeeks}周',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: SoftMinimalistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 周次徽章 - 柔和极简风格（紧凑版）
  Widget _buildWeekBadge(BuildContext context, int currentWeek) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CalendarColors.selected,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '第',
            style: TextStyle(
              fontSize: 9,
              color: SoftMinimalistColors.textSecondary,
            ),
          ),
          Text(
            '$currentWeek',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CalendarColors.today,
              height: 1.1,
            ),
          ),
          const Text(
            '周',
            style: TextStyle(
              fontSize: 9,
              color: SoftMinimalistColors.textSecondary,
            ),
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
  final CourseSchedule schedule;
  final Semester semester;
  final int currentWeek;
  final int totalWeeks;

  const _TodayCoursesInfo({
    required this.schedule,
    required this.semester,
    required this.currentWeek,
    required this.totalWeeks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().weekday;
    final coursesAsync = ref.watch(
      coursesForDayProvider((
        scheduleId: schedule.id,
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
    Color textColor;

    if (courses.isEmpty) {
      if (isWeekend) {
        text = '周末，好好休息~';
      } else {
        text = '今天没有课程';
      }
      textColor = SoftMinimalistColors.textSecondary;
    } else {
      // 使用CourseStatusUtils获取准确的课程状态
      final summary = CourseStatusUtils.getTodayCourseSummary(
        todayCourses: courses,
        schedule: schedule,
        now: now,
      );

      final ongoingCourse = CourseStatusUtils.getOngoingCourse(
        todayCourses: courses,
        schedule: schedule,
        now: now,
      );

      final nextCourse = CourseStatusUtils.getNextCourse(
        todayCourses: courses,
        schedule: schedule,
        now: now,
      );

      if (ongoingCourse != null) {
        // 正在上课 - 使用强调色
        text = '今天${summary.total}节 · 正在上: ${ongoingCourse.name}';
        textColor = SoftMinimalistColors.success;
      } else if (nextCourse != null) {
        // 有下一节课
        text = '今天${summary.total}节 · 下一节: ${nextCourse.name}';
        textColor = SoftMinimalistColors.textSecondary;
      } else {
        // 课程已全部结束
        text = '今天${summary.total}节课 · 已全部上完';
        textColor = SoftMinimalistColors.textSecondary;
      }
    }

    return Text(
      text,
      style: TextStyle(fontSize: 12, color: textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDefaultText() {
    return Text(
      '共$totalWeeks周',
      style: const TextStyle(
        fontSize: 12,
        color: SoftMinimalistColors.textSecondary,
      ),
    );
  }
}
