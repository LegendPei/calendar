// 课程导入页面
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/course.dart';
import '../../models/course_schedule.dart';
import '../../providers/course_provider.dart';
import '../../services/course_import_service.dart';

/// 课程导入服务Provider
final courseImportServiceProvider = Provider<CourseImportService>((ref) {
  return CourseImportService();
});

class CourseImportScreen extends ConsumerStatefulWidget {
  /// 课程表配置
  final CourseSchedule schedule;

  const CourseImportScreen({super.key, required this.schedule});

  @override
  ConsumerState<CourseImportScreen> createState() => _CourseImportScreenState();
}

class _CourseImportScreenState extends ConsumerState<CourseImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  CourseImportResult? _importResult;
  List<Course> _selectedCourses = [];
  bool _isLoading = false;
  bool _selectAll = true;

  /// 实时解析预览结果
  List<ParsedLinePreview> _previews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 监听文本变化，实时解析预览
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// 文本变化时实时解析预览
  void _onTextChanged() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _previews = []);
      return;
    }

    final importService = ref.read(courseImportServiceProvider);
    final previews = importService.parseTextPreview(text, widget.schedule.id);
    setState(() => _previews = previews);
  }

  /// 填充示例文本
  void _fillExample() {
    _textController.text = CourseImportService.exampleText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课程'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo_camera), text: '拍照识别'),
            Tab(icon: Icon(Icons.edit_note), text: '文本输入'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPhotoTab(), _buildTextTab()],
      ),
    );
  }

  /// 拍照识别Tab
  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 图片选择区域
          _buildImageSelector(),
          const SizedBox(height: 16),

          // 识别按钮
          if (_selectedImage != null && _importResult == null)
            FilledButton.icon(
              onPressed: _isLoading ? null : _recognizeImage,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? '识别中...' : '开始识别'),
            ),

          // 识别结果
          if (_importResult != null) ...[
            const SizedBox(height: 24),
            _buildImportResultView(),
          ],
        ],
      ),
    );
  }

  /// 文本输入Tab
  Widget _buildTextTab() {
    final successCount = _previews.where((p) => p.success).length;
    final failCount = _previews.where((p) => !p.success).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 格式说明卡片（带使用示例按钮）
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '输入格式说明',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // 使用示例按钮
                      TextButton.icon(
                        onPressed: _fillExample,
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: const Text('使用示例'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '每行一门课程，格式如下：\n'
                    '课程名 星期 节次 周次 [地点] [教师]\n\n'
                    '示例：\n'
                    '高等数学 周一 1-2节 1-16周 A101 张老师\n'
                    '数据结构 周二 3-4节 1-16周(单) B202\n'
                    '大学英语 周三 5-6节 2-17周(双)',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 文本输入框
          TextField(
            controller: _textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '在此输入课程信息，每行一门课程...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          // 实时解析预览
          if (_previews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '解析预览',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓ $successCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (failCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✗ $failCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 预览列表
            ..._previews.map(_buildPreviewItem),
          ],

          const SizedBox(height: 16),

          // 导入按钮（使用预览中成功的课程）
          if (_previews.isNotEmpty && successCount > 0)
            FilledButton.icon(
              onPressed: _isLoading ? null : _importFromPreview,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isLoading ? '导入中...' : '导入 $successCount 门课程'),
            )
          else if (_previews.isEmpty)
            FilledButton.icon(
              onPressed: _isLoading ? null : _parseText,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isLoading ? '解析中...' : '解析课程'),
            ),

          // 传统解析结果（兼容旧逻辑）
          if (_importResult != null) ...[
            const SizedBox(height: 24),
            _buildImportResultView(),
          ],
        ],
      ),
    );
  }

  /// 构建预览项
  Widget _buildPreviewItem(ParsedLinePreview preview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: preview.success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: preview.success ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            preview.success ? Icons.check_circle : Icons.error,
            size: 18,
            color: preview.success ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.success) ...[
                  Text(
                    preview.courseName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      preview.dayOfWeek,
                      preview.sections,
                      preview.weeks,
                      if (preview.location != null) preview.location,
                      if (preview.teacher != null) preview.teacher,
                    ].whereType<String>().join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ] else ...[
                  Text(
                    preview.line,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview.error ?? '解析失败',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 从预览导入课程
  Future<void> _importFromPreview() async {
    final coursesToImport = _previews
        .where((p) => p.success && p.course != null)
        .map((p) => p.course!)
        .toList();

    if (coursesToImport.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final courseNotifier = ref.read(courseListProvider.notifier);
      final report = await courseNotifier.importCourses(coursesToImport);

      if (mounted) {
        if (report.isSuccess) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入${report.successCount}门课程')),
          );
        } else {
          // 显示导入错误
          _showImportErrorDialog(report);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 图片选择器
  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _importResult = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '点击选择或拍摄课程表图片',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }

  /// 导入结果视图
  Widget _buildImportResultView() {
    final result = _importResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 结果统计
        Row(
          children: [
            Text(
              '识别结果',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '共${result.courses.length}门课程',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 全选开关
        if (result.courses.isNotEmpty)
          Row(
            children: [
              Checkbox(
                value: _selectAll,
                onChanged: (value) {
                  setState(() {
                    _selectAll = value ?? false;
                    if (_selectAll) {
                      _selectedCourses = List.from(result.courses);
                    } else {
                      _selectedCourses.clear();
                    }
                  });
                },
              ),
              const Text('全选'),
              const Spacer(),
              Text(
                '已选${_selectedCourses.length}门',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

        // 课程列表
        if (result.courses.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 48,
                  color: Colors.orange.shade300,
                ),
                const SizedBox(height: 12),
                const Text('未识别到任何课程'),
                if (result.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          )
        else
          ...result.courses.map((course) => _buildCourseCheckItem(course)),

        const SizedBox(height: 16),

        // 查看日志
        ExpansionTile(
          title: const Text('查看识别日志'),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.logs
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 导入按钮
        if (result.courses.isNotEmpty)
          FilledButton.icon(
            onPressed: _selectedCourses.isEmpty || _isLoading
                ? null
                : _importSelectedCourses,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(
              _isLoading ? '导入中...' : '导入选中课程(${_selectedCourses.length}门)',
            ),
          ),
      ],
    );
  }

  /// 课程选择项
  Widget _buildCourseCheckItem(Course course) {
    final isSelected = _selectedCourses.contains(course);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedCourses.add(course);
            } else {
              _selectedCourses.remove(course);
            }
            _selectAll =
                _selectedCourses.length == _importResult!.courses.length;
          });
        },
        secondary: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: Color(course.color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(course.name),
        subtitle: Text(
          '${course.dayOfWeekName} ${course.sectionDescription} · ${course.weeksDescription}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  /// 显示图片来源选项
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _importResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  /// 识别图片
  Future<void> _recognizeImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final importService = ref.read(courseImportServiceProvider);
      final result = await importService.importFromImage(
        _selectedImage!,
        widget.schedule.id,
      );

      setState(() {
        _importResult = result;
        _selectedCourses = List.from(result.courses);
        _selectAll = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('识别失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 解析文本
  Future<void> _parseText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入课程信息')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final importService = ref.read(courseImportServiceProvider);
      final result = await importService.parseManualInput(
        text,
        widget.schedule.id,
      );

      setState(() {
        _importResult = result;
        _selectedCourses = List.from(result.courses);
        _selectAll = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解析失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 导入选中的课程
  Future<void> _importSelectedCourses() async {
    if (_selectedCourses.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final courseNotifier = ref.read(courseListProvider.notifier);
      final report = await courseNotifier.importCourses(_selectedCourses);

      if (mounted) {
        if (report.isSuccess) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入${report.successCount}门课程')),
          );
        } else {
          // 显示导入错误
          _showImportErrorDialog(report);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示导入错误对话框
  void _showImportErrorDialog(CourseImportReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('导入结果'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('共 ${report.totalCount} 门课程'),
              Text('成功: ${report.successCount} 门'),
              Text('失败: ${report.failedCount} 门'),
              if (report.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '错误详情:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...report.errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $e',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
