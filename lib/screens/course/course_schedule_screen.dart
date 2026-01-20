/// 课程表主页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../models/semester.dart';
import '../../providers/course_provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/course/course_card.dart';
import '../../widgets/course/course_grid.dart';
import '../../widgets/course/week_selector.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';
import 'course_import_screen.dart';
import 'schedule_time_setup_screen.dart';
import 'semester_setup_screen.dart';
import '../event/event_form_screen.dart';

class CourseScheduleScreen extends ConsumerStatefulWidget {
  const CourseScheduleScreen({super.key});

  @override
  ConsumerState<CourseScheduleScreen> createState() =>
      _CourseScheduleScreenState();
}

class _CourseScheduleScreenState extends ConsumerState<CourseScheduleScreen> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final currentSemesterAsync = ref.watch(currentSemesterProvider);
    final currentScheduleAsync = ref.watch(currentScheduleProvider);
    final currentWeekAsync = ref.watch(currentWeekProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程表'),
        actions: [
          // 视图切换
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? '列表视图' : '网格视图',
          ),
          // 更多菜单
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'semester',
                child: Row(
                  children: [
                    Icon(Icons.school),
                    SizedBox(width: 8),
                    Text('学期设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_time',
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 8),
                    Text('作息时间设置'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.photo_camera),
                    SizedBox(width: 8),
                    Text('拍照导入'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('清空课程', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: currentSemesterAsync.when(
        data: (semester) {
          if (semester == null) {
            return _buildNoSemesterView();
          }
          return currentScheduleAsync.when(
            data: (schedule) {
              if (schedule == null) {
                return _buildNoScheduleView(semester);
              }
              return currentWeekAsync.when(
                data: (currentWeek) =>
                    _buildMainContent(semester, schedule, currentWeek),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('错误: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: currentScheduleAsync.value != null
          ? FloatingActionButton(
              onPressed: () => _addCourse(currentScheduleAsync.value!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// 没有学期时显示的视图
  Widget _buildNoSemesterView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '还没有设置学期',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _setupSemester,
            icon: const Icon(Icons.add),
            label: const Text('设置学期'),
          ),
        ],
      ),
    );
  }

  /// 没有课程表时显示的视图
  Widget _buildNoScheduleView(Semester semester) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有课程表',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '当前学期: ${semester.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _createSchedule(semester),
            icon: const Icon(Icons.add),
            label: const Text('创建课程表'),
          ),
        ],
      ),
    );
  }

  /// 主内容
  Widget _buildMainContent(
    Semester semester,
    CourseSchedule schedule,
    int currentWeek,
  ) {
    final selectedWeek = ref.watch(selectedWeekProvider);
    final coursesAsync = ref.watch(
      coursesForWeekProvider((scheduleId: schedule.id, week: selectedWeek)),
    );

    return Column(
      children: [
        // 学期信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text(
                semester.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '共${semester.totalWeeks}周',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // 周次选择器
        WeekSelector(
          selectedWeek: selectedWeek,
          totalWeeks: semester.totalWeeks,
          currentWeek: currentWeek,
          onWeekSelected: (week) {
            ref.read(selectedWeekProvider.notifier).state = week;
          },
        ),
        // 课程内容
        Expanded(
          child: coursesAsync.when(
            data: (courses) {
              if (_isGridView) {
                return CourseGrid(
                  schedule: schedule,
                  courses: courses,
                  currentWeek: selectedWeek,
                  semester: semester,
                  onCourseTap: (course) =>
                      _showCourseDetail(course, schedule, semester),
                  onEmptyCellTap: (day, section) =>
                      _addCourseAt(schedule, day, section),
                );
              } else {
                return _buildListView(courses, schedule);
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
          ),
        ),
      ],
    );
  }

  /// 列表视图
  Widget _buildListView(List<Course> courses, CourseSchedule schedule) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '本周没有课程',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // 按星期分组
    final grouped = <int, List<Course>>{};
    for (final course in courses) {
      grouped.putIfAbsent(course.dayOfWeek, () => []).add(course);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final day = grouped.keys.toList()..sort();
        final dayCourses = grouped[day[index]]!
          ..sort((a, b) => a.startSection.compareTo(b.startSection));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                schedule.dayNames[day[index] - 1],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...dayCourses.map(
              (course) => CourseDetailCard(
                course: course,
                schedule: schedule,
                onTap: () => _showCourseDetail(course, schedule),
                onEdit: () => _editCourse(course, schedule),
                onDelete: () => _deleteCourse(course),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 菜单选择
  void _onMenuSelected(String value) {
    switch (value) {
      case 'semester':
        _setupSemester();
        break;
      case 'schedule_time':
        _setupScheduleTime();
        break;
      case 'import':
        _importFromPhoto();
        break;
      case 'clear':
        _clearAllCourses();
        break;
    }
  }

  /// 设置学期
  void _setupSemester() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SemesterSetupScreen()),
    ).then((_) {
      ref.invalidate(currentSemesterProvider);
      ref.invalidate(currentScheduleProvider);
    });
  }

  /// 设置作息时间
  void _setupScheduleTime() {
    final schedule = ref.read(currentScheduleProvider).value;
    if (schedule == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先创建课程表')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleTimeSetupScreen(schedule: schedule),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(currentScheduleProvider);
      }
    });
  }

  /// 创建课程表
  Future<void> _createSchedule(Semester semester) async {
    try {
      await ref
          .read(scheduleNotifierProvider.notifier)
          .createSchedule(semester.id, semester.name);
      // 刷新当前课程表Provider以立即显示新创建的课程表
      ref.invalidate(currentScheduleProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('课程表已创建')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  /// 添加课程
  void _addCourse(CourseSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseFormScreen(schedule: schedule)),
    ).then((result) {
      if (result == true) {
        _refreshCourses(schedule.id);
      }
    });
  }

  /// 在指定位置添加课程
  void _addCourseAt(CourseSchedule schedule, int dayOfWeek, int section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(
          schedule: schedule,
          initialDayOfWeek: dayOfWeek,
          initialSection: section,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshCourses(schedule.id);
      }
    });
  }

  /// 刷新课程列表
  void _refreshCourses(String scheduleId) {
    ref.invalidate(courseListProvider);
    // 刷新当前选中周的课程
    final selectedWeek = ref.read(selectedWeekProvider);
    ref.invalidate(
      coursesForWeekProvider((scheduleId: scheduleId, week: selectedWeek)),
    );
  }

  /// 显示课程详情
  void _showCourseDetail(
    Course course,
    CourseSchedule schedule, [
    Semester? semesterParam,
  ]) {
    final semester = semesterParam ?? ref.read(currentSemesterProvider).value;
    showModalBottomSheet(
      context: context,
      builder: (context) => _CourseDetailSheet(
        course: course,
        schedule: schedule,
        semester: semester,
        onEdit: () {
          Navigator.pop(context);
          _editCourse(course, schedule);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteCourse(course);
        },
        onAddEvent: () {
          Navigator.pop(context);
          _addEventFromCourse(course, schedule, semester);
        },
        onViewDetail: () {
          Navigator.pop(context);
          _navigateToCourseDetail(course, schedule, semester);
        },
      ),
    );
  }

  /// 跳转到课程详情页
  void _navigateToCourseDetail(
    Course course,
    CourseSchedule schedule,
    Semester? semester,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          course: course,
          schedule: schedule,
          semester: semester,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _refreshCourses(schedule.id);
      }
    });
  }

  /// 从课程创建日程
  void _addEventFromCourse(
    Course course,
    CourseSchedule schedule,
    Semester? semester,
  ) {
    if (semester == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法获取学期信息')));
      return;
    }

    // 获取当前选中的周次
    final selectedWeek = ref.read(selectedWeekProvider);

    // 计算选中周的上课日期
    final semesterStart = semester.startDate;
    final weekdayOfStart = semesterStart.weekday;
    final firstMonday = semesterStart.subtract(
      Duration(days: weekdayOfStart - 1),
    );
    final targetWeekMonday = firstMonday.add(
      Duration(days: (selectedWeek - 1) * 7),
    );
    final classDate = targetWeekMonday.add(
      Duration(days: course.dayOfWeek - 1),
    );

    // 获取课程开始和结束时间
    final startSlot = schedule.getTimeSlot(course.startSection);
    final endSlot = schedule.getTimeSlot(course.endSection);

    if (startSlot == null || endSlot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法获取课程时间')));
      return;
    }

    final startTime = DateTime(
      classDate.year,
      classDate.month,
      classDate.day,
      startSlot.startTime.hour,
      startSlot.startTime.minute,
    );

    final endTime = DateTime(
      classDate.year,
      classDate.month,
      classDate.day,
      endSlot.endTime.hour,
      endSlot.endTime.minute,
    );

    // 创建初始值
    final initialValues = EventFormInitialValues(
      title: '${course.name} - 相关日程',
      description:
          '课程：${course.name}\n教师：${course.teacher ?? "未设置"}\n第$selectedWeek周 ${course.dayOfWeekName}',
      location: course.location,
      startTime: startTime,
      endTime: endTime,
      color: course.color,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventFormScreen(initialValues: initialValues),
      ),
    );
  }

  /// 编辑课程
  void _editCourse(Course course, CourseSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(schedule: schedule, course: course),
      ),
    ).then((result) {
      if (result == true) {
        _refreshCourses(schedule.id);
      }
    });
  }

  /// 删除课程
  Future<void> _deleteCourse(Course course, {String? scheduleId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除"${course.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(courseListProvider.notifier).deleteCourse(course.id);
        if (mounted) {
          final id = scheduleId ?? course.scheduleId;
          _refreshCourses(id);
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
  }

  /// 拍照导入
  void _importFromPhoto() {
    final schedule = ref.read(currentScheduleProvider).value;
    if (schedule == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先创建课程表')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseImportScreen(schedule: schedule)),
    ).then((result) {
      if (result == true) {
        _refreshCourses(schedule.id);
      }
    });
  }

  /// 清空所有课程
  Future<void> _clearAllCourses() async {
    final schedule = ref.read(currentScheduleProvider).value;
    if (schedule == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空课程'),
        content: const Text('确定要清空所有课程吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(courseListProvider.notifier)
            .deleteAllCourses(schedule.id);
        if (mounted) {
          _refreshCourses(schedule.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已清空所有课程')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('清空失败: $e')));
        }
      }
    }
  }
}

/// 课程详情底部弹窗
class _CourseDetailSheet extends StatelessWidget {
  final Course course;
  final CourseSchedule schedule;
  final Semester? semester;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddEvent;
  final VoidCallback onViewDetail;

  const _CourseDetailSheet({
    required this.course,
    required this.schedule,
    this.semester,
    required this.onEdit,
    required this.onDelete,
    required this.onAddEvent,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(course.color);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 时间
          _buildInfoRow(
            Icons.schedule,
            '${course.dayOfWeekName} ${course.sectionDescription}',
          ),

          // 周次
          _buildInfoRow(Icons.date_range, course.weeksDescription),

          // 地点
          if (course.location != null && course.location!.isNotEmpty)
            _buildInfoRow(Icons.location_on_outlined, course.location!),

          // 教师
          if (course.teacher != null && course.teacher!.isNotEmpty)
            _buildInfoRow(Icons.person_outline, course.teacher!),

          // 提醒
          _buildInfoRow(
            Icons.notifications_outlined,
            course.reminderDescription,
          ),

          // 备注
          if (course.note != null && course.note!.isNotEmpty)
            _buildInfoRow(Icons.note_outlined, course.note!),

          const SizedBox(height: 24),

          // 操作按钮 - 第一行
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddEvent,
                  icon: const Icon(Icons.event),
                  label: const Text('添加日程'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('查看详情'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 操作按钮 - 第二行
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
