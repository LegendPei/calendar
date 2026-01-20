/// 课程表单页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../providers/course_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/course/course_form.dart';

class CourseFormScreen extends ConsumerStatefulWidget {
  /// 课程表配置
  final CourseSchedule schedule;

  /// 编辑时传入的课程
  final Course? course;

  /// 初始星期几（新建时使用）
  final int? initialDayOfWeek;

  /// 初始节次（新建时使用）
  final int? initialSection;

  const CourseFormScreen({
    super.key,
    required this.schedule,
    this.course,
    this.initialDayOfWeek,
    this.initialSection,
  });

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  bool _isEditing = false;
  // ignore: unused_field - 保留用于未来的加载状态UI
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.course != null;

    // 初始化表单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(courseFormProvider.notifier);
      if (_isEditing) {
        notifier.initForEdit(widget.course!);
      } else {
        notifier.initForCreate(totalWeeks: 20);
        // 设置初始值
        if (widget.initialDayOfWeek != null) {
          notifier.updateDayOfWeek(widget.initialDayOfWeek!);
        }
        if (widget.initialSection != null) {
          // 使用新的方法更新选中的节次
          notifier.updateSelectedSections([widget.initialSection!]);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑课程' : '添加课程'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: '删除',
            ),
        ],
      ),
      body: CourseForm(
        initialCourse: widget.course,
        schedule: widget.schedule,
        onSave: _saveCourse,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  /// 保存课程
  Future<void> _saveCourse(CourseFormState formState) async {
    setState(() => _isLoading = true);

    try {
      final courseNotifier = ref.read(courseListProvider.notifier);
      final now = DateTime.now();

      // 获取节次范围列表（可能有多个不连续的范围）
      final sectionRanges = formState.getSectionRanges();

      if (sectionRanges.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请至少选择一个节次')));
        }
        setState(() => _isLoading = false);
        return;
      }

      // 如果是编辑模式且有多个范围，需要特殊处理
      if (_isEditing && sectionRanges.length > 1) {
        // 编辑模式下如果选择了多个不连续范围，先删除原课程，再添加新的多个课程
        final confirmed = await _showMultiRangeEditDialog(sectionRanges.length);
        if (confirmed != true) {
          setState(() => _isLoading = false);
          return;
        }
        // 删除原课程
        await courseNotifier.deleteCourse(widget.course!.id);
      }

      // 构建课程列表（每个连续范围一个课程）
      final courses = <Course>[];
      for (int i = 0; i < sectionRanges.length; i++) {
        final range = sectionRanges[i];
        final course = Course(
          // 如果只有一个范围且是编辑模式，保留原ID；否则生成新ID
          id: (sectionRanges.length == 1 && _isEditing)
              ? widget.course!.id
              : const Uuid().v4(),
          scheduleId: widget.schedule.id,
          name: formState.name.trim(),
          teacher: formState.teacher?.trim(),
          location: formState.location?.trim(),
          dayOfWeek: formState.dayOfWeek,
          startSection: range.start,
          endSection: range.end,
          weeks: formState.weeks,
          color: formState.color,
          note: formState.note?.trim(),
          reminderMinutes: formState.reminderMinutes,
          createdAt: widget.course?.createdAt ?? now,
          updatedAt: now,
        );
        courses.add(course);
      }

      // 检查时间冲突（检查所有要添加的课程）
      final allConflicts = <Course>[];
      for (final course in courses) {
        final conflicts = await courseNotifier.checkConflicts(course);
        for (final c in conflicts) {
          if (!allConflicts.any((existing) => existing.id == c.id)) {
            allConflicts.add(c);
          }
        }
      }

      if (allConflicts.isNotEmpty) {
        if (mounted) {
          final proceed = await _showConflictDialog(allConflicts);
          if (proceed != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // 保存所有课程
      if (sectionRanges.length == 1 && _isEditing) {
        // 单个范围的编辑模式
        await courseNotifier.updateCourse(courses.first);
      } else {
        // 新建模式或多范围编辑模式
        for (final course in courses) {
          await courseNotifier.addCourse(course);
        }
      }

      // 调度课程提醒
      final semester = await ref.read(currentSemesterProvider.future);
      if (semester != null) {
        final reminderService = ref.read(courseReminderServiceProvider);
        for (final course in courses) {
          if (course.reminderMinutes != null) {
            await reminderService.updateCourseReminders(
              course: course,
              schedule: widget.schedule,
              semester: semester,
              oldCourse: _isEditing ? widget.course : null,
            );
          } else if (_isEditing && widget.course?.reminderMinutes != null) {
            // 如果编辑时取消了提醒，取消旧的提醒
            await reminderService.cancelCourseReminders(widget.course!);
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        final message = sectionRanges.length > 1
            ? '已添加${sectionRanges.length}个课程时间段'
            : (_isEditing ? '课程已更新' : '课程已添加');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示多范围编辑确认对话框
  Future<bool?> _showMultiRangeEditDialog(int rangeCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认修改'),
        content: Text(
          '您选择了$rangeCount个不连续的时间段。\n'
          '系统将删除原课程并创建$rangeCount个新的课程记录。\n'
          '是否继续?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  /// 显示冲突对话框
  Future<bool?> _showConflictDialog(List<Course> conflicts) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('时间冲突'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('以下课程与当前课程存在时间冲突:'),
            const SizedBox(height: 12),
            ...conflicts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(c.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${c.name} (${c.dayOfWeekName} ${c.sectionDescription})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('是否仍要保存?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('仍然保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除"${widget.course!.name}"吗？'),
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

    if (confirmed == true && mounted) {
      await _deleteCourse();
    }
  }

  /// 删除课程
  Future<void> _deleteCourse() async {
    setState(() => _isLoading = true);

    try {
      // 取消课程提醒
      if (widget.course!.reminderMinutes != null) {
        final reminderService = ref.read(courseReminderServiceProvider);
        await reminderService.cancelCourseReminders(widget.course!);
      }

      await ref
          .read(courseListProvider.notifier)
          .deleteCourse(widget.course!.id);

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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
