/// 主题常量定义
import 'package:flutter/material.dart';

/// 日历颜色常量
class CalendarColors {
  CalendarColors._();

  /// 今日颜色
  static const Color today = Color(0xFF1976D2);

  /// 选中日期颜色
  static const Color selected = Color(0xFF42A5F5);

  /// 周末颜色
  static const Color weekend = Color(0xFFE57373);

  /// 农历文字颜色
  static const Color lunarText = Color(0xFF757575);

  /// 事件指示点颜色
  static const Color eventIndicator = Color(0xFF4CAF50);

  /// 非当月日期颜色
  static const Color otherMonth = Color(0xFFBDBDBD);

  /// 节日颜色
  static const Color festival = Color(0xFFE53935);

  /// 节气颜色
  static const Color solarTerm = Color(0xFF43A047);
}

/// 日历尺寸常量
class CalendarSizes {
  CalendarSizes._();

  /// 日期单元格大小
  static const double dayCellSize = 48.0;

  /// 日期单元格内边距
  static const double dayCellPadding = 4.0;

  /// 农历字体大小
  static const double lunarFontSize = 10.0;

  /// 公历字体大小
  static const double solarFontSize = 16.0;

  /// 事件指示点大小
  static const double eventIndicatorSize = 6.0;

  /// 时间槽高度
  static const double timeSlotHeight = 60.0;

  /// 头部高度
  static const double headerHeight = 56.0;

  /// 星期行高度
  static const double weekdayRowHeight = 32.0;
}

/// 应用主题
class AppTheme {
  AppTheme._();

  /// 亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CalendarColors.today,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
      ),
    );
  }

  /// 暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CalendarColors.today,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}

