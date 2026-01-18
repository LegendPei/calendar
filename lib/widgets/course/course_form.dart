/// 课程表单组件
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../providers/course_provider.dart';
import 'section_picker.dart';
import 'week_selector.dart';

/// 课程表单组件
class CourseForm extends ConsumerStatefulWidget {
  /// 初始课程（编辑模式）
  final Course? initialCourse;

  /// 课程表配置
  final CourseSchedule schedule;

  /// 保存回调
  final void Function(CourseFormState formState) onSave;

  /// 取消回调
  final VoidCallback? onCancel;

  const CourseForm({
    super.key,
    this.initialCourse,
    required this.schedule,
    required this.onSave,
    this.onCancel,
  });

  @override
  ConsumerState<CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends ConsumerState<CourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTextControllers();
  }

  /// 初始化文本控制器（仅设置初始值，不初始化表单Provider）
  void _initTextControllers() {
    if (widget.initialCourse != null) {
      _nameController.text = widget.initialCourse!.name;
      _teacherController.text = widget.initialCourse!.teacher ?? '';
      _locationController.text = widget.initialCourse!.location ?? '';
      _noteController.text = widget.initialCourse!.note ?? '';
    }
    // 表单Provider的初始化由CourseFormScreen负责
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(courseFormProvider);
    final formNotifier = ref.read(courseFormProvider.notifier);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 课程名称
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '课程名称 *',
              hintText: '请输入课程名称',
              prefixIcon: Icon(Icons.book),
            ),
            onChanged: formNotifier.updateName,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入课程名称';
              }
              if (value.length > 50) {
                return '课程名称不能超过50个字符';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 教师
          TextFormField(
            controller: _teacherController,
            decoration: const InputDecoration(
              labelText: '教师',
              hintText: '请输入教师姓名',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: formNotifier.updateTeacher,
          ),
          const SizedBox(height: 16),

          // 地点
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: '地点',
              hintText: '请输入上课地点',
              prefixIcon: Icon(Icons.location_on),
            ),
            onChanged: formNotifier.updateLocation,
          ),
          const SizedBox(height: 24),

          // 星期选择
          _buildSectionTitle('上课时间'),
          const SizedBox(height: 12),
          _buildDaySelector(formState, formNotifier),
          const SizedBox(height: 16),

          // 节次选择（复选框多选模式）
          SectionGridPicker(
            startSection: formState.startSection,
            endSection: formState.endSection,
            selectedSections: formState.selectedSections,
            schedule: widget.schedule,
            onSectionsChanged: (sections) {
              formNotifier.updateSelectedSections(sections);
            },
          ),
          const SizedBox(height: 24),

          // 周次选择
          _buildSectionTitle('上课周次'),
          const SizedBox(height: 12),
          WeekRangePicker(
            selectedWeeks: formState.weeks,
            totalWeeks: 20,
            onChanged: formNotifier.updateWeeks,
          ),
          const SizedBox(height: 24),

          // 颜色选择
          _buildSectionTitle('课程颜色'),
          const SizedBox(height: 12),
          _buildColorPicker(formState, formNotifier),
          const SizedBox(height: 24),

          // 备注
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '请输入备注信息',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            onChanged: formNotifier.updateNote,
          ),
          const SizedBox(height: 32),

          // 错误提示
          if (formState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // 按钮
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('取消'),
                  ),
                ),
              if (widget.onCancel != null) const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: formState.isLoading ? null : _onSave,
                  child: formState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.initialCourse != null ? '保存' : '添加'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDaySelector(
    CourseFormState formState,
    CourseFormNotifier notifier,
  ) {
    final dayNames = widget.schedule.dayNames;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(widget.schedule.daysPerWeek, (index) {
        final day = index + 1;
        final isSelected = formState.dayOfWeek == day;

        return ChoiceChip(
          label: Text(dayNames[index]),
          selected: isSelected,
          onSelected: (_) => notifier.updateDayOfWeek(day),
        );
      }),
    );
  }

  Widget _buildColorPicker(
    CourseFormState formState,
    CourseFormNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Course.presetColors.map((color) {
        final isSelected = formState.color == color;

        return GestureDetector(
          onTap: () => notifier.updateColor(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final formState = ref.read(courseFormProvider);
      final error = formState.validate();
      if (error != null) {
        ref.read(courseFormProvider.notifier).setError(error);
        return;
      }
      widget.onSave(formState);
    }
  }
}
