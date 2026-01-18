/// 导入导出页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/icalendar_provider.dart';
import '../../providers/event_provider.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  DateTime? _exportStartDate;
  DateTime? _exportEndDate;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importNotifierProvider);
    final exportState = ref.watch(exportNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('导入/导出')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 导入部分
          _buildSectionHeader('导入', Icons.download),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_open),
                  title: const Text('从文件导入'),
                  subtitle: const Text('选择.ics文件导入日程'),
                  trailing: importState.status == ImportStatus.loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: importState.status == ImportStatus.loading
                      ? null
                      : () => _handleImport(),
                ),
              ],
            ),
          ),

          // 导入结果提示
          if (importState.status == ImportStatus.success &&
              importState.result != null)
            _buildResultCard(
              icon: Icons.check_circle,
              color: Colors.green,
              title: '导入成功',
              message: importState.result!.toString(),
            ),
          if (importState.status == ImportStatus.error)
            _buildResultCard(
              icon: Icons.error,
              color: Colors.red,
              title: '导入失败',
              message: importState.errorMessage ?? '未知错误',
            ),

          const SizedBox(height: 24),

          // 导出部分
          _buildSectionHeader('导出', Icons.upload),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('导出全部事件'),
                  subtitle: const Text('将所有日程导出为.ics文件'),
                  trailing: exportState.status == ExportStatus.loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: exportState.status == ExportStatus.loading
                      ? null
                      : () => _handleExportAll(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('按日期范围导出'),
                  subtitle: Text(_getDateRangeText()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDateRangePicker(),
                ),
              ],
            ),
          ),

          // 导出结果提示
          if (exportState.status == ExportStatus.success)
            _buildResultCard(
              icon: Icons.check_circle,
              color: Colors.green,
              title: '导出成功',
              message: '已导出${exportState.exportedCount}个事件',
            ),
          if (exportState.status == ExportStatus.error)
            _buildResultCard(
              icon: Icons.error,
              color: Colors.red,
              title: '导出失败',
              message: exportState.errorMessage ?? '未知错误',
            ),

          const SizedBox(height: 24),

          // 说明信息
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                ref.read(importNotifierProvider.notifier).reset();
                ref.read(exportNotifierProvider.notifier).reset();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '关于iCalendar格式',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• iCalendar (.ics) 是标准的日历数据交换格式\n'
              '• 支持与Google日历、Outlook等应用互导\n'
              '• 导入时会根据事件ID判断新增或更新\n'
              '• 支持重复事件和提醒的导入导出',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (_exportStartDate == null || _exportEndDate == null) {
      return '点击选择日期范围';
    }
    return '${_formatDate(_exportStartDate!)} - ${_formatDate(_exportEndDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleImport() async {
    await ref.read(importNotifierProvider.notifier).importFromFilePicker();

    // 刷新事件列表
    if (mounted) {
      ref.invalidate(eventListProvider);
    }
  }

  Future<void> _handleExportAll() async {
    await ref.read(exportNotifierProvider.notifier).exportAll();
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _exportStartDate ?? now.subtract(const Duration(days: 30)),
      end: _exportEndDate ?? now.add(const Duration(days: 30)),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
      helpText: '选择导出日期范围',
      cancelText: '取消',
      confirmText: '确定',
      saveText: '导出',
    );

    if (picked != null) {
      setState(() {
        _exportStartDate = picked.start;
        _exportEndDate = picked.end;
      });

      // 执行导出
      await ref
          .read(exportNotifierProvider.notifier)
          .exportDateRange(picked.start, picked.end);
    }
  }
}
