// 课程导入服务
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';

/// 单行解析预览结果
class ParsedLinePreview {
  /// 原始行文本
  final String line;

  /// 是否解析成功
  final bool success;

  /// 解析到的课程（成功时有值）
  final Course? course;

  /// 错误信息（失败时有值）
  final String? error;

  /// 解析到的字段（用于显示）
  final String? courseName;
  final String? dayOfWeek;
  final String? sections;
  final String? weeks;
  final String? location;
  final String? teacher;

  const ParsedLinePreview({
    required this.line,
    required this.success,
    this.course,
    this.error,
    this.courseName,
    this.dayOfWeek,
    this.sections,
    this.weeks,
    this.location,
    this.teacher,
  });

  factory ParsedLinePreview.success({
    required String line,
    required Course course,
    String? courseName,
    String? dayOfWeek,
    String? sections,
    String? weeks,
    String? location,
    String? teacher,
  }) {
    return ParsedLinePreview(
      line: line,
      success: true,
      course: course,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      sections: sections,
      weeks: weeks,
      location: location,
      teacher: teacher,
    );
  }

  factory ParsedLinePreview.failure({
    required String line,
    required String error,
    String? courseName,
    String? dayOfWeek,
    String? sections,
    String? weeks,
  }) {
    return ParsedLinePreview(
      line: line,
      success: false,
      error: error,
      courseName: courseName,
      dayOfWeek: dayOfWeek,
      sections: sections,
      weeks: weeks,
    );
  }
}

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
  /// 从图片导入课程
  ///
  /// 使用Google ML Kit进行OCR文字识别
  Future<CourseImportResult> importFromImage(
    File imageFile,
    String scheduleId,
  ) async {
    try {
      // 调用OCR服务获取文本
      final ocrText = await _performOCR(imageFile);

      if (ocrText.isEmpty) {
        return CourseImportResult.failure('未能从图片中识别到文字');
      }

      final result = await parseOCRText(ocrText, scheduleId);
      return result;
    } catch (e) {
      return CourseImportResult.failure('图片处理失败: $e');
    }
  }

  /// 执行OCR文字识别
  ///
  /// 使用Google ML Kit TextRecognizer进行中文文字识别
  /// 添加超时机制防止应用卡死
  Future<String> _performOCR(File imageFile) async {
    TextRecognizer? textRecognizer;

    try {
      // 检查文件是否存在
      if (!await imageFile.exists()) {
        throw Exception('图片文件不存在');
      }

      // 创建中文文字识别器 - 包裹在try-catch中防止初始化崩溃
      try {
        textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
      } catch (e) {
        throw Exception('文字识别器初始化失败，请检查网络连接后重试');
      }

      // 直接使用原图进行识别，避免 isolate 相关问题
      InputImage inputImage;
      try {
        inputImage = InputImage.fromFile(imageFile);
      } catch (e) {
        throw Exception('无法读取图片文件: $e');
      }

      // 执行文字识别，添加超时机制（30秒）
      RecognizedText recognizedText;
      try {
        recognizedText = await textRecognizer
            .processImage(inputImage)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('OCR识别超时，请尝试使用更清晰的图片或手动输入');
              },
            );
      } catch (e) {
        if (e.toString().contains('超时')) {
          rethrow;
        }
        throw Exception('图片识别处理失败: $e');
      }

      // 提取识别到的文本
      final StringBuffer buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      return buffer.toString();
    } on Exception catch (e) {
      // 重新抛出带有更友好提示的异常
      if (e.toString().contains('超时') ||
          e.toString().contains('初始化') ||
          e.toString().contains('无法读取')) {
        rethrow;
      }
      throw Exception('OCR识别失败: $e');
    } finally {
      // 释放识别器资源
      if (textRecognizer != null) {
        try {
          await textRecognizer.close();
        } catch (_) {
          // 忽略关闭时的错误
        }
      }
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

  /// 实时解析预览文本（返回每行的解析结果）
  List<ParsedLinePreview> parseTextPreview(String text, String scheduleId) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    int colorIndex = 0;
    final previews = <ParsedLinePreview>[];

    for (final line in lines) {
      final preview = parseLinePreview(line, scheduleId, colorIndex);
      previews.add(preview);
      if (preview.success) colorIndex++;
    }

    return previews;
  }

  /// 解析单行文本并返回预览结果
  ParsedLinePreview parseLinePreview(
    String line,
    String scheduleId,
    int colorIndex,
  ) {
    final now = DateTime.now();

    // 解析星期
    int? dayOfWeek;
    String? dayOfWeekStr;
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
        dayOfWeekStr = entry.key;
        break;
      }
    }

    // 解析节次
    int? startSection, endSection;
    String? sectionsStr;
    final sectionMatch = RegExp(r'(\d+)[-~](\d+)节?').firstMatch(line);
    if (sectionMatch != null) {
      startSection = int.tryParse(sectionMatch.group(1) ?? '');
      endSection = int.tryParse(sectionMatch.group(2) ?? '');
      if (startSection != null && endSection != null) {
        sectionsStr = '$startSection-$endSection节';
      }
    }

    // 解析周次
    List<int> weeks = List.generate(16, (i) => i + 1);
    String? weeksStr;
    final weeksMatch = RegExp(r'(\d+)[-~](\d+)周(\(([单双])\))?').firstMatch(line);
    if (weeksMatch != null) {
      final startWeek = int.tryParse(weeksMatch.group(1) ?? '') ?? 1;
      final endWeek = int.tryParse(weeksMatch.group(2) ?? '') ?? 16;
      final weekType = weeksMatch.group(4);

      if (weekType == '单') {
        weeks = Course.generateWeeks(startWeek, endWeek, type: 1);
        weeksStr = '$startWeek-$endWeek周(单)';
      } else if (weekType == '双') {
        weeks = Course.generateWeeks(startWeek, endWeek, type: 2);
        weeksStr = '$startWeek-$endWeek周(双)';
      } else {
        weeks = Course.generateWeeks(startWeek, endWeek, type: 0);
        weeksStr = '$startWeek-$endWeek周';
      }
    }

    // 解析地点和教师
    String? location;
    String? teacher;
    final locationMatch = RegExp(
      r'[A-Z]\d{2,4}|[东西南北]?\d{1,2}[号栋楼]?\d{2,4}',
    ).firstMatch(line);
    if (locationMatch != null) {
      location = locationMatch.group(0);
    }
    final teacherMatch = RegExp(r'(\S{1,4})老师').firstMatch(line);
    if (teacherMatch != null) {
      teacher = '${teacherMatch.group(1)}老师';
    }

    // 提取课程名称（第一个非时间词）
    String? courseName;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      courseName = parts.first;
      // 如果第一个词是时间相关的，尝试下一个
      if (dayPatterns.containsKey(courseName) ||
          courseName.contains('节') ||
          courseName.contains('周') ||
          RegExp(r'^\d').hasMatch(courseName)) {
        courseName = null;
        for (final part in parts) {
          if (!dayPatterns.containsKey(part) &&
              !part.contains('节') &&
              !part.contains('周') &&
              !RegExp(r'^\d').hasMatch(part) &&
              part.length >= 2) {
            courseName = part;
            break;
          }
        }
      }
    }

    // 检查必要字段并生成错误信息
    final missingFields = <String>[];
    if (courseName == null || courseName.length < 2) {
      missingFields.add('课程名');
    }
    if (dayOfWeek == null) {
      missingFields.add('星期');
    }
    if (startSection == null || endSection == null) {
      missingFields.add('节次');
    }
    if (weeksMatch == null) {
      missingFields.add('周次');
    }

    if (missingFields.isNotEmpty) {
      return ParsedLinePreview.failure(
        line: line,
        error: '缺少${missingFields.join("、")}',
        courseName: courseName,
        dayOfWeek: dayOfWeekStr,
        sections: sectionsStr,
        weeks: weeksStr,
      );
    }

    // 创建课程
    final course = Course(
      id: const Uuid().v4(),
      scheduleId: scheduleId,
      name: courseName!,
      dayOfWeek: dayOfWeek!,
      startSection: startSection!,
      endSection: endSection!,
      weeks: weeks,
      location: location,
      teacher: teacher,
      color: Course.presetColors[colorIndex % Course.presetColors.length],
      createdAt: now,
      updatedAt: now,
    );

    return ParsedLinePreview.success(
      line: line,
      course: course,
      courseName: courseName,
      dayOfWeek: dayOfWeekStr,
      sections: sectionsStr,
      weeks: weeksStr,
      location: location,
      teacher: teacher,
    );
  }

  /// 示例文本
  static const String exampleText = '''高等数学 周一 1-2节 1-16周 A101 张老师
数据结构 周二 3-4节 1-16周(单) B202 李老师
大学英语 周三 5-6节 2-17周 C303
线性代数 周四 7-8节 1-16周(双) D404
计算机网络 周五 1-2节 3-18周 E505 王老师''';

  /// 演示模式：返回预设的课程数据（模拟OCR识别成功）
  /// 数据来源：docs/picture/9.png
  CourseImportResult getDemoCourseData(String scheduleId) {
    final now = DateTime.now();
    final courses = <Course>[];
    int colorIndex = 0;

    Course createCourse({
      required String name,
      required int dayOfWeek,
      required int startSection,
      required int endSection,
      String? teacher,
      String? location,
    }) {
      final course = Course(
        id: const Uuid().v4(),
        scheduleId: scheduleId,
        name: name,
        teacher: teacher,
        location: location,
        dayOfWeek: dayOfWeek,
        startSection: startSection,
        endSection: endSection,
        weeks: List.generate(16, (i) => i + 1), // 1-16周
        color: Course.presetColors[colorIndex++ % Course.presetColors.length],
        createdAt: now,
        updatedAt: now,
      );
      return course;
    }

    // 周一课程
    courses.add(
      createCourse(
        name: '计算机网络',
        dayOfWeek: 1,
        startSection: 1,
        endSection: 2,
        teacher: '刘广聪',
        location: '教2-217',
      ),
    );
    courses.add(
      createCourse(
        name: '人工智能',
        dayOfWeek: 1,
        startSection: 3,
        endSection: 4,
        teacher: '张伯泉',
        location: '教2-224',
      ),
    );
    courses.add(
      createCourse(
        name: '走在前列的广东实践',
        dayOfWeek: 1,
        startSection: 6,
        endSection: 7,
        teacher: '张中鹏',
        location: '教3-103',
      ),
    );

    // 周二课程
    courses.add(
      createCourse(
        name: '计算机组成原理',
        dayOfWeek: 2,
        startSection: 1,
        endSection: 2,
        teacher: '陈龙',
        location: '教2-225',
      ),
    );
    courses.add(
      createCourse(
        name: '操作系统',
        dayOfWeek: 2,
        startSection: 3,
        endSection: 4,
        teacher: '丁国芳',
        location: '教4-204',
      ),
    );

    // 周三课程
    courses.add(
      createCourse(
        name: '计算机网络',
        dayOfWeek: 3,
        startSection: 1,
        endSection: 2,
        teacher: '刘广聪',
        location: '教2-220',
      ),
    );
    courses.add(
      createCourse(
        name: '计算机组成原理',
        dayOfWeek: 3,
        startSection: 3,
        endSection: 4,
        teacher: '陈龙',
        location: '教4-307',
      ),
    );
    courses.add(
      createCourse(
        name: 'JAVA程序设计',
        dayOfWeek: 3,
        startSection: 6,
        endSection: 7,
        teacher: '赵锐',
        location: '教3-304',
      ),
    );

    // 周四课程
    courses.add(
      createCourse(
        name: '算法设计与分析',
        dayOfWeek: 4,
        startSection: 1,
        endSection: 2,
        teacher: '乔杰',
        location: '教2-223',
      ),
    );
    courses.add(
      createCourse(
        name: '操作系统',
        dayOfWeek: 4,
        startSection: 3,
        endSection: 4,
        teacher: '丁国芳',
        location: '教2-221',
      ),
    );

    // 周五课程
    courses.add(
      createCourse(
        name: '体育(4)',
        dayOfWeek: 5,
        startSection: 3,
        endSection: 4,
        teacher: '龚建林',
        location: '体育馆',
      ),
    );
    courses.add(
      createCourse(
        name: '形势与政策',
        dayOfWeek: 5,
        startSection: 8,
        endSection: 9,
        teacher: '周健凯',
        location: '教3-306',
      ),
    );

    final logs = <String>[
      '📷 图片加载成功',
      '🔍 开始OCR文字识别...',
      '✅ 识别到课程表结构',
      '📊 解析周一课程: 3门',
      '📊 解析周二课程: 2门',
      '📊 解析周三课程: 3门',
      '📊 解析周四课程: 2门',
      '📊 解析周五课程: 2门',
      '🎉 识别完成，共${courses.length}门课程',
    ];

    return CourseImportResult.success(
      courses: courses,
      rawText: '【演示模式】模拟OCR识别结果',
      logs: logs,
    );
  }

  /// 是否启用演示模式
  bool _demoMode = false;

  /// 设置演示模式
  void setDemoMode(bool enabled) {
    _demoMode = enabled;
  }

  /// 获取演示模式状态
  bool get isDemoMode => _demoMode;

  /// 从图片导入课程（支持演示模式）
  Future<CourseImportResult> importFromImageWithDemo(
    File imageFile,
    String scheduleId, {
    bool forceDemo = false,
  }) async {
    // 如果是演示模式，直接返回预设数据
    if (_demoMode || forceDemo) {
      // 模拟识别延迟
      await Future.delayed(const Duration(milliseconds: 1500));
      return getDemoCourseData(scheduleId);
    }

    // 否则使用真实OCR
    return importFromImage(imageFile, scheduleId);
  }
}
