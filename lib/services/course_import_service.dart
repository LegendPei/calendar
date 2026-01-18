/// 课程导入服务
import 'dart:io';
import 'package:uuid/uuid.dart';

import '../models/course.dart';

/// 课程导入结果
class CourseImportResult {
  /// 识别到的课程列表
  final List<Course> courses;

  /// 原始OCR文本
  final String rawText;

  /// 解析日志
  final List<String> logs;

  /// 是否成功
  final bool success;

  /// 错误信息
  final String? error;

  const CourseImportResult({
    required this.courses,
    required this.rawText,
    required this.logs,
    required this.success,
    this.error,
  });

  factory CourseImportResult.success({
    required List<Course> courses,
    required String rawText,
    required List<String> logs,
  }) {
    return CourseImportResult(
      courses: courses,
      rawText: rawText,
      logs: logs,
      success: true,
    );
  }

  factory CourseImportResult.failure(String error) {
    return CourseImportResult(
      courses: [],
      rawText: '',
      logs: [],
      success: false,
      error: error,
    );
  }
}

/// 课程导入服务
class CourseImportService {
  /// 从图片导入课程（需要外部OCR服务）
  ///
  /// 由于OCR需要第三方服务或设备API，这里提供一个解析框架
  /// 实际使用时需要接入OCR SDK（如百度OCR、腾讯OCR、Google ML Kit等）
  Future<CourseImportResult> importFromImage(
    File imageFile,
    String scheduleId,
  ) async {
    try {
      // TODO: 调用OCR服务获取文本
      // 这里需要接入实际的OCR服务
      // final ocrText = await _performOCR(imageFile);

      // 模拟OCR文本（实际使用时替换为真实OCR结果）
      const ocrText = '''
      星期一 星期二 星期三 星期四 星期五
      1-2 高等数学 数据结构 英语 操作系统 软件工程
      3-4 线性代数 计算机网络 高等数学 数据库
      5-6 大学物理 马克思主义 体育 电子技术
      ''';

      final result = await parseOCRText(ocrText, scheduleId);
      return result;
    } catch (e) {
      return CourseImportResult.failure('图片处理失败: $e');
    }
  }

  /// 解析OCR文本为课程列表
  Future<CourseImportResult> parseOCRText(
    String ocrText,
    String scheduleId,
  ) async {
    final logs = <String>[];
    final courses = <Course>[];

    try {
      logs.add('开始解析OCR文本...');

      // 预处理文本
      final lines = ocrText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      logs.add('共${lines.length}行文本');

      // 尝试识别课程表格式
      // 这里提供一个简单的解析逻辑，实际需要根据OCR结果调整
      final dayNames = [
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '周一',
        '周二',
        '周三',
        '周四',
        '周五',
      ];
      final sectionPatterns = [
        RegExp(r'(\d)-(\d)节?'),
        RegExp(r'第(\d)-(\d)节'),
        RegExp(r'(\d)[-~](\d)'),
      ];

      int colorIndex = 0;
      final now = DateTime.now();

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        logs.add('处理第${i + 1}行: $line');

        // 尝试匹配课程信息
        for (int day = 1; day <= 5; day++) {
          final dayName = dayNames[day - 1];
          if (line.contains(dayName)) {
            // 找到了星期标记，尝试提取课程
            logs.add('发现星期标记: $dayName');
          }
        }

        // 尝试匹配节次
        for (final pattern in sectionPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final startSection = int.tryParse(match.group(1) ?? '');
            final endSection = int.tryParse(match.group(2) ?? '');
            if (startSection != null && endSection != null) {
              logs.add('发现节次: $startSection-$endSection');
            }
          }
        }

        // 简单的课程名称识别（实际需要更复杂的NLP处理）
        final possibleCourseNames = _extractCourseNames(line);
        for (final name in possibleCourseNames) {
          if (name.length >= 2 && name.length <= 20) {
            final course = Course(
              id: const Uuid().v4(),
              scheduleId: scheduleId,
              name: name,
              dayOfWeek: (colorIndex % 5) + 1,
              startSection: 1,
              endSection: 2,
              weeks: List.generate(16, (i) => i + 1),
              color:
                  Course.presetColors[colorIndex % Course.presetColors.length],
              createdAt: now,
              updatedAt: now,
            );
            courses.add(course);
            colorIndex++;
            logs.add('识别课程: $name');
          }
        }
      }

      logs.add('解析完成，共识别${courses.length}门课程');

      return CourseImportResult.success(
        courses: courses,
        rawText: ocrText,
        logs: logs,
      );
    } catch (e) {
      logs.add('解析错误: $e');
      return CourseImportResult(
        courses: courses,
        rawText: ocrText,
        logs: logs,
        success: false,
        error: '解析失败: $e',
      );
    }
  }

  /// 从文本行中提取可能的课程名称
  List<String> _extractCourseNames(String text) {
    final names = <String>[];

    // 移除常见的非课程词汇
    final excludeWords = [
      '星期',
      '周',
      '节',
      '上午',
      '下午',
      '晚上',
      '教室',
      '老师',
      '教师',
      '地点',
      '备注',
    ];

    // 分割文本
    final parts = text.split(RegExp(r'[\s,，、;；]+'));

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      // 检查是否为排除词
      bool isExcluded = false;
      for (final word in excludeWords) {
        if (trimmed.contains(word)) {
          isExcluded = true;
          break;
        }
      }

      if (!isExcluded && trimmed.length >= 2) {
        // 简单过滤：只保留中文为主的文本
        final chineseCount = RegExp(
          r'[\u4e00-\u9fa5]',
        ).allMatches(trimmed).length;
        if (chineseCount >= trimmed.length * 0.5) {
          names.add(trimmed);
        }
      }
    }

    return names;
  }

  /// 手动解析用户输入的课程文本
  Future<CourseImportResult> parseManualInput(
    String text,
    String scheduleId,
  ) async {
    // 支持的格式示例：
    // 高等数学 周一 1-2节 1-16周 A101 张老师
    // 数据结构 周二 3-4节 1-16周(单) B202

    final logs = <String>[];
    final courses = <Course>[];
    final now = DateTime.now();

    try {
      logs.add('开始解析输入文本...');

      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      int colorIndex = 0;

      for (final line in lines) {
        logs.add('处理: $line');

        // 解析星期
        int? dayOfWeek;
        final dayPatterns = {
          '周一': 1,
          '周二': 2,
          '周三': 3,
          '周四': 4,
          '周五': 5,
          '周六': 6,
          '周日': 7,
          '星期一': 1,
          '星期二': 2,
          '星期三': 3,
          '星期四': 4,
          '星期五': 5,
          '星期六': 6,
          '星期日': 7,
        };
        for (final entry in dayPatterns.entries) {
          if (line.contains(entry.key)) {
            dayOfWeek = entry.value;
            break;
          }
        }

        // 解析节次
        int? startSection, endSection;
        final sectionMatch = RegExp(r'(\d+)[-~](\d+)节?').firstMatch(line);
        if (sectionMatch != null) {
          startSection = int.tryParse(sectionMatch.group(1) ?? '');
          endSection = int.tryParse(sectionMatch.group(2) ?? '');
        }

        // 解析周次
        List<int> weeks = List.generate(16, (i) => i + 1);
        final weeksMatch = RegExp(
          r'(\d+)[-~](\d+)周(\(([单双])\))?',
        ).firstMatch(line);
        if (weeksMatch != null) {
          final startWeek = int.tryParse(weeksMatch.group(1) ?? '') ?? 1;
          final endWeek = int.tryParse(weeksMatch.group(2) ?? '') ?? 16;
          final weekType = weeksMatch.group(4);

          if (weekType == '单') {
            weeks = Course.generateWeeks(startWeek, endWeek, type: 1);
          } else if (weekType == '双') {
            weeks = Course.generateWeeks(startWeek, endWeek, type: 2);
          } else {
            weeks = Course.generateWeeks(startWeek, endWeek, type: 0);
          }
        }

        // 提取课程名称（通常是第一个词）
        String? courseName;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          courseName = parts.first;
          // 如果第一个词是时间相关的，尝试下一个
          if (dayPatterns.containsKey(courseName) ||
              courseName.contains('节') ||
              courseName.contains('周')) {
            if (parts.length > 1) {
              courseName = parts[1];
            }
          }
        }

        // 如果解析到了必要信息，创建课程
        if (courseName != null &&
            courseName.length >= 2 &&
            dayOfWeek != null &&
            startSection != null &&
            endSection != null) {
          final course = Course(
            id: const Uuid().v4(),
            scheduleId: scheduleId,
            name: courseName,
            dayOfWeek: dayOfWeek,
            startSection: startSection,
            endSection: endSection,
            weeks: weeks,
            color: Course.presetColors[colorIndex % Course.presetColors.length],
            createdAt: now,
            updatedAt: now,
          );
          courses.add(course);
          colorIndex++;
          logs.add(
            '✓ 识别课程: $courseName (周$dayOfWeek $startSection-$endSection节)',
          );
        } else {
          logs.add('✗ 无法解析此行');
        }
      }

      logs.add('解析完成，共识别${courses.length}门课程');

      return CourseImportResult.success(
        courses: courses,
        rawText: text,
        logs: logs,
      );
    } catch (e) {
      logs.add('解析错误: $e');
      return CourseImportResult(
        courses: courses,
        rawText: text,
        logs: logs,
        success: false,
        error: '解析失败: $e',
      );
    }
  }
}
