// 今日课程概览卡片组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/course_status_utils.dart';
import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../models/semester.dart';
import '../../providers/course_provider.dart';
import '../../screens/course/course_schedule_screen.dart';

/// 今日课程概览卡片
class TodayCoursesCard extends ConsumerWidget {
  /// 点击课程的回调
  final void Function(Course course)? onCourseTap;

  const TodayCoursesCard({super.key, this.onCourseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesterAsync = ref.watch(currentSemesterProvider);
    final scheduleAsync = ref.watch(currentScheduleProvider);

    return semesterAsync.when(
      data: (semester) {
        if (semester == null) {
          return _buildEmptyState(context, '请先设置学期');
        }

        return scheduleAsync.when(
          data: (schedule) {
            if (schedule == null) {
              return _buildEmptyState(context, '请先创建课程表');
            }

            return _TodayCoursesContent(
              semester: semester,
              schedule: schedule,
              onCourseTap: onCourseTap,
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, s) => _buildEmptyState(context, '加载失败'),
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildEmptyState(context, '加载失败'),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseScheduleScreen(),
                ),
              );
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}

/// 今日课程内容组件
class _TodayCoursesContent extends ConsumerWidget {
  final Semester semester;
  final CourseSchedule schedule;
  final void Function(Course course)? onCourseTap;

  const _TodayCoursesContent({
    required this.semester,
    required this.schedule,
    this.onCourseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(courseListProvider);

    return coursesAsync.when(
      data: (courses) {
        final todayCourses = CourseStatusUtils.getTodayCourses(
          courses: courses,
          semester: semester,
        );

        if (todayCourses.isEmpty) {
          return _buildNoCourseToday(context);
        }

        final summary = CourseStatusUtils.getTodayCourseSummary(
          todayCourses: todayCourses,
          schedule: schedule,
        );

        final ongoingCourse = CourseStatusUtils.getOngoingCourse(
          todayCourses: todayCourses,
          schedule: schedule,
        );

        final nextCourse = CourseStatusUtils.getNextCourse(
          todayCourses: todayCourses,
          schedule: schedule,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：今日课程统计
              _buildHeader(context, summary, ongoingCourse),
              const Divider(height: 1),
              // 课程列表
              ...todayCourses.map(
                (course) => _buildCourseItem(
                  context,
                  course,
                  isOngoing: course == ongoingCourse,
                  isNext: course == nextCourse,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoCourseToday(BuildContext context) {
    final now = DateTime.now();
    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final currentWeek = semester.getWeekNumber(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.celebration_outlined,
              color: Colors.green.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今天没有课程',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '第$currentWeek周 · ${weekdayNames[now.weekday]}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseScheduleScreen(),
                ),
              );
            },
            child: const Text('查看课表'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ({int total, int completed, int remaining}) summary,
    Course? ongoingCourse,
  ) {
    final now = DateTime.now();
    final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final currentWeek = semester.getWeekNumber(now);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ongoingCourse != null
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ongoingCourse != null
                  ? Icons.play_circle_outline
                  : Icons.school_outlined,
              color: ongoingCourse != null
                  ? Colors.green.shade600
                  : Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ongoingCourse != null
                      ? '正在上课：${ongoingCourse.name}'
                      : '今日 ${summary.total} 节课',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '第$currentWeek周 · ${weekdayNames[now.weekday]} · '
                  '已上${summary.completed}节，剩余${summary.remaining}节',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseScheduleScreen(),
                ),
              );
            },
            tooltip: '查看课表',
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(
    BuildContext context,
    Course course, {
    bool isOngoing = false,
    bool isNext = false,
  }) {
    final color = Color(course.color);
    final timeStr = CourseStatusUtils.getCourseTimeString(
      course: course,
      schedule: schedule,
    );

    // 判断课程是否已完成
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final endSlot = schedule.getTimeSlot(course.endSection);
    final isCompleted =
        endSlot != null &&
        nowMinutes > (endSlot.endTime.hour * 60 + endSlot.endTime.minute);

    return InkWell(
      onTap: onCourseTap != null ? () => onCourseTap!(course) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOngoing ? Colors.green.shade50 : null,
        ),
        child: Row(
          children: [
            // 状态指示条
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey.shade300
                    : isOngoing
                    ? Colors.green
                    : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // 课程信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isCompleted ? Colors.grey : null,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '进行中',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (isNext && !isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '下一节',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$timeStr · ${course.sectionDescription}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (course.location != null &&
                          course.location!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          course.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
