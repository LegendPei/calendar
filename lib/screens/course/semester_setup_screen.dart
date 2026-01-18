/// 学期设置页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/semester.dart';
import '../../providers/course_provider.dart';

class SemesterSetupScreen extends ConsumerStatefulWidget {
  /// 编辑时传入的学期
  final Semester? semester;

  const SemesterSetupScreen({super.key, this.semester});

  @override
  ConsumerState<SemesterSetupScreen> createState() =>
      _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends ConsumerState<SemesterSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late DateTime _startDate;
  int _totalWeeks = 20;
  bool _isCurrent = true;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.semester != null;

    if (_isEditing) {
      _nameController.text = widget.semester!.name;
      _startDate = widget.semester!.startDate;
      _totalWeeks = widget.semester!.totalWeeks;
      _isCurrent = widget.semester!.isCurrent;
    } else {
      // 默认为下个周一
      final now = DateTime.now();
      final daysUntilMonday = (8 - now.weekday) % 7;
      _startDate = DateTime(now.year, now.month, now.day + daysUntilMonday);
      _generateDefaultName();
    }
  }

  void _generateDefaultName() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    String name;
    if (month >= 2 && month <= 7) {
      name = '$year春季学期';
    } else if (month >= 8) {
      name = '$year秋季学期';
    } else {
      name = '${year - 1}秋季学期';
    }
    _nameController.text = name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semesterNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑学期' : '设置学期'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteConfirmation,
              tooltip: '删除',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 学期名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '学期名称 *',
                hintText: '例如: 2025春季学期',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入学期名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 开学日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('开学日期'),
              subtitle: Text(
                DateFormat('yyyy年MM月dd日 (EEEE)', 'zh_CN').format(_startDate),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectStartDate,
            ),
            const Divider(),

            // 总周数
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: const Text('学期周数'),
              subtitle: Text('$_totalWeeks 周'),
              trailing: SizedBox(
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _totalWeeks > 1
                          ? () => setState(() => _totalWeeks--)
                          : null,
                    ),
                    Text(
                      '$_totalWeeks',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _totalWeeks < 30
                          ? () => setState(() => _totalWeeks++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),

            // 设为当前学期
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.star),
              title: const Text('设为当前学期'),
              subtitle: const Text('在课程表中默认显示此学期'),
              value: _isCurrent,
              onChanged: (value) => setState(() => _isCurrent = value),
            ),
            const Divider(),

            const SizedBox(height: 24),

            // 学期信息预览
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '学期信息',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      '开学日期',
                      DateFormat('yyyy-MM-dd').format(_startDate),
                    ),
                    _buildInfoRow(
                      '结束日期',
                      DateFormat('yyyy-MM-dd').format(
                        _startDate.add(Duration(days: _totalWeeks * 7 - 1)),
                      ),
                    ),
                    _buildInfoRow('总周数', '$_totalWeeks 周'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 保存按钮
            FilledButton(
              onPressed: _isLoading ? null : _saveSemester,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '保存' : '创建学期'),
            ),

            // 已有学期列表
            if (!_isEditing) ...[
              const SizedBox(height: 32),
              const Text(
                '已有学期',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              semestersAsync.when(
                data: (semesters) {
                  if (semesters.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无学期',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }
                  return Column(
                    children: semesters
                        .map((s) => _buildSemesterTile(s))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('加载失败: $e'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSemesterTile(Semester semester) {
    return ListTile(
      leading: semester.isCurrent
          ? const Icon(Icons.star, color: Colors.amber)
          : const Icon(Icons.school_outlined),
      title: Text(semester.name),
      subtitle: Text(
        '${DateFormat('yyyy-MM-dd').format(semester.startDate)} · ${semester.totalWeeks}周',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SemesterSetupScreen(semester: semester),
              ),
            );
          } else if (value == 'setCurrent') {
            _setCurrentSemester(semester.id);
          } else if (value == 'delete') {
            _deleteSemester(semester);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          if (!semester.isCurrent)
            const PopupMenuItem(value: 'setCurrent', child: Text('设为当前')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 选择开学日期
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  /// 保存学期
  Future<void> _saveSemester() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(semesterNotifierProvider.notifier);
      final semester = Semester(
        id: widget.semester?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        startDate: _startDate,
        totalWeeks: _totalWeeks,
        isCurrent: _isCurrent,
        createdAt: widget.semester?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await notifier.updateSemester(semester);
      } else {
        await notifier.addSemester(semester);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_isEditing ? '学期已更新' : '学期已创建')));
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

  /// 设为当前学期
  Future<void> _setCurrentSemester(String id) async {
    try {
      await ref.read(semesterNotifierProvider.notifier).setCurrentSemester(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已设为当前学期')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('设置失败: $e')));
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学期'),
        content: const Text('删除学期将同时删除该学期的课程表和所有课程，确定要删除吗？'),
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
      await _deleteSemesterById(widget.semester!.id);
    }
  }

  /// 删除学期
  Future<void> _deleteSemester(Semester semester) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学期'),
        content: Text('确定要删除"${semester.name}"吗？'),
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
      await _deleteSemesterById(semester.id);
    }
  }

  Future<void> _deleteSemesterById(String id) async {
    try {
      await ref.read(semesterNotifierProvider.notifier).deleteSemester(id);
      if (mounted) {
        if (_isEditing) {
          Navigator.pop(context, true);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('学期已删除')));
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
