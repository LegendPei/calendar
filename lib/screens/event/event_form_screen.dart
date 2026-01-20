/// 事件表单页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../models/event.dart';
import '../../providers/conflict_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../widgets/event/color_picker.dart';
import '../../widgets/event/recurrence_picker.dart';
import '../../widgets/event/reminder_picker.dart';
import '../../widgets/event/scroll_datetime_picker.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  /// 编辑时传入的事件
  final Event? event;

  /// 指定日期（新建时使用）
  final DateTime? initialDate;

  /// 初始值（从课程创建日程时使用）
  final EventFormInitialValues? initialValues;

  const EventFormScreen({
    super.key,
    this.event,
    this.initialDate,
    this.initialValues,
  });

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.event != null;

    // 初始化表单
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        ref.read(eventFormProvider.notifier).initForEdit(widget.event!);
        _titleController.text = widget.event!.title;
        _descriptionController.text = widget.event!.description ?? '';
        _locationController.text = widget.event!.location ?? '';
      } else if (widget.initialValues != null) {
        // 使用初始值创建（从课程创建日程）
        ref
            .read(eventFormProvider.notifier)
            .initForCreateWithValues(widget.initialValues!);
        _titleController.text = widget.initialValues!.title ?? '';
        _descriptionController.text = widget.initialValues!.description ?? '';
        _locationController.text = widget.initialValues!.location ?? '';
      } else {
        ref.read(eventFormProvider.notifier).initForCreate(widget.initialDate);
      }
      // 初始检查冲突
      _checkConflicts();
    });
  }

  /// 检查时间冲突
  void _checkConflicts() {
    final formState = ref.read(eventFormProvider);
    ref
        .read(conflictNotifierProvider.notifier)
        .checkConflict(
          startTime: formState.startTime,
          endTime: formState.endTime,
          excludeEventId: widget.event?.id,
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(eventFormProvider);
    final notifier = ref.read(eventFormProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑事件' : '新建事件'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: '删除',
            ),
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题输入
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '添加标题',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入事件标题';
                }
                if (value.length > 100) {
                  return '标题不能超过100个字符';
                }
                return null;
              },
              onChanged: notifier.updateTitle,
            ),
            const SizedBox(height: 16),

            // 全天开关
            SwitchListTile(
              title: const Text('全天'),
              secondary: const Icon(Icons.wb_sunny_outlined),
              value: formState.allDay,
              onChanged: notifier.updateAllDay,
            ),
            const Divider(),

            // 开始时间
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('开始'),
              subtitle: Text(
                formState.allDay
                    ? app_date_utils.DateUtils.formatDate(formState.startTime)
                    : app_date_utils.DateUtils.formatDateTime(
                        formState.startTime,
                      ),
              ),
              onTap: () => _selectDateTime(
                context,
                formState.startTime,
                formState.allDay,
                (dt) {
                  notifier.updateStartTime(dt);
                  _checkConflicts();
                },
              ),
            ),

            // 结束时间
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('结束'),
              subtitle: Text(
                formState.allDay
                    ? app_date_utils.DateUtils.formatDate(formState.endTime)
                    : app_date_utils.DateUtils.formatDateTime(
                        formState.endTime,
                      ),
              ),
              onTap: () => _selectDateTime(
                context,
                formState.endTime,
                formState.allDay,
                (dt) {
                  notifier.updateEndTime(dt);
                  _checkConflicts();
                },
              ),
            ),

            // 冲突提示
            _buildConflictWarning(),

            const Divider(),

            // 重复
            RecurrencePicker(
              selectedRRule: formState.rrule,
              onChanged: notifier.updateRRule,
            ),
            const Divider(),

            // 提醒
            Consumer(
              builder: (context, ref, _) {
                final selectedReminders = ref.watch(selectedRemindersProvider);
                return ReminderPicker(
                  selectedReminders: selectedReminders,
                  onChanged: (reminders) {
                    ref.read(selectedRemindersProvider.notifier).state =
                        reminders;
                  },
                );
              },
            ),
            const Divider(),

            // 地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '地点',
                hintText: '添加地点',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: notifier.updateLocation,
            ),
            const SizedBox(height: 16),

            // 描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '添加描述',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: notifier.updateDescription,
            ),
            const SizedBox(height: 16),

            // 颜色选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '事件颜色',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ColorPicker(
                      selectedColor: formState.color,
                      onColorSelected: notifier.updateColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建冲突警告
  Widget _buildConflictWarning() {
    final conflictState = ref.watch(conflictNotifierProvider);
    final scheduleAsync = ref.watch(currentScheduleProvider);

    if (conflictState.isChecking) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SoftMinimalistColors.badgeGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              '正在检查课程冲突...',
              style: TextStyle(
                fontSize: 13,
                color: SoftMinimalistColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (!conflictState.hasConflict) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoftMinimalistColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SoftMinimalistColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: SoftMinimalistColors.warning,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '该时间段存在课程',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: SoftMinimalistColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...conflictState.conflictingCourses.map((course) {
            String timeStr = course.sectionDescription;
            // 尝试获取具体时间
            scheduleAsync.whenData((schedule) {
              if (schedule != null) {
                timeStr = getCourseTimeDescription(course, schedule);
              }
            });
            return Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(course.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${course.name} · $timeStr',
                      style: const TextStyle(
                        fontSize: 13,
                        color: SoftMinimalistColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (course.location != null && course.location!.isNotEmpty)
                    Text(
                      ' @ ${course.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: SoftMinimalistColors.textSecondary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 选择日期时间
  Future<void> _selectDateTime(
    BuildContext context,
    DateTime initial,
    bool dateOnly,
    ValueChanged<DateTime> onSelected,
  ) async {
    final result = await showScrollDateTimePicker(
      context: context,
      initialDateTime: initial,
      dateOnly: dateOnly,
    );

    if (result != null && mounted) {
      onSelected(result);
    }
  }

  /// 保存事件
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(eventFormProvider);
    final error = formState.validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // 检查是否有冲突
    final conflictState = ref.read(conflictNotifierProvider);
    if (conflictState.hasConflict) {
      final confirmed = await _showConflictConfirmation(conflictState);
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final event = formState.toEvent(widget.event);
      final eventNotifier = ref.read(eventListProvider.notifier);
      final reminderService = ref.read(reminderServiceProvider);
      final selectedReminders = ref.read(selectedRemindersProvider);

      if (_isEditing) {
        await eventNotifier.updateEvent(event);
        // 更新提醒
        await reminderService.setRemindersForEvent(event, selectedReminders);
      } else {
        await eventNotifier.addEvent(event);
        // 添加提醒
        if (selectedReminders.isNotEmpty) {
          await reminderService.setRemindersForEvent(event, selectedReminders);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditing ? '事件已更新' : '事件已创建')));
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

  /// 显示冲突确认对话框
  Future<bool?> _showConflictConfirmation(ConflictState conflictState) {
    final courses = conflictState.conflictingCourses;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: SoftMinimalistColors.warning,
            ),
            const SizedBox(width: 8),
            const Text('时间冲突'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('该日程与以下课程时间冲突：'),
            const SizedBox(height: 12),
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(course.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${course.name}（${course.sectionDescription}）',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '是否仍要保存该日程？',
              style: TextStyle(color: SoftMinimalistColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: SoftMinimalistColors.warning,
            ),
            child: const Text('仍要保存'),
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
        title: const Text('删除事件'),
        content: const Text('确定要删除这个事件吗？此操作无法撤销。'),
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
      await _deleteEvent();
    }
  }

  /// 删除事件
  Future<void> _deleteEvent() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(eventListProvider.notifier).deleteEvent(widget.event!.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('事件已删除')));
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
