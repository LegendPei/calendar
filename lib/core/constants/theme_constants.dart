/// 主题常量定义 - 柔和极简主义风格
import 'package:flutter/material.dart';

/// 柔和极简主义色彩系统
class SoftMinimalistColors {
  SoftMinimalistColors._();

  // ===== 基础色 (Foundations) =====
  /// 全局背景色 - 非纯白，带有微弱冷调的亮灰
  static const Color background = Color(0xFFF5F6F8);

  /// 卡片/悬浮层背景 - 纯白
  static const Color surface = Color(0xFFFFFFFF);

  /// 主要文字 - 深灰，不用纯黑
  static const Color textPrimary = Color(0xFF222222);

  /// 次要文字 - 用于农历、节气、非本月日期
  static const Color textSecondary = Color(0xFF95979E);

  /// 禁用/占位文字
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ===== 强调色 (Accents) =====
  /// 重点提醒 - 用于"今天"高亮、重要节日、周末
  static const Color accentRed = Color(0xFFE05D5D);

  /// 选中态背景 - 用于胶囊标签选中态
  static const Color softRedBg = Color(0xFFFEE9EA);

  /// 次要标记背景 - 用于"休/班"等文字
  static const Color badgeGray = Color(0xFFEAEAEA);

  /// 装饰色 - 用于插画背景
  static const Color softPurple = Color(0xFFBFAEE3);

  // ===== 功能色 =====
  /// 事件指示点
  static const Color eventIndicator = Color(0xFF4CAF50);

  /// 成功色
  static const Color success = Color(0xFF43A047);

  /// 警告色
  static const Color warning = Color(0xFFFF9800);

  /// 警告色浅色背景
  static const Color warningLight = Color(0xFFFFF3E0);

  /// 错误色
  static const Color error = Color(0xFFE53935);

  /// 错误色浅色背景
  static const Color errorLight = Color(0xFFFFEBEE);
}

/// 日历颜色常量 (基于柔和极简主义)
class CalendarColors {
  CalendarColors._();

  /// 今日颜色 - 红色强调
  static const Color today = SoftMinimalistColors.accentRed;

  /// 选中日期背景色
  static const Color selected = SoftMinimalistColors.softRedBg;

  /// 选中日期文字色
  static const Color selectedText = SoftMinimalistColors.accentRed;

  /// 周末颜色
  static const Color weekend = SoftMinimalistColors.accentRed;

  /// 农历文字颜色
  static const Color lunarText = SoftMinimalistColors.textSecondary;

  /// 事件指示点颜色
  static const Color eventIndicator = SoftMinimalistColors.eventIndicator;

  /// 非当月日期颜色
  static const Color otherMonth = SoftMinimalistColors.textDisabled;

  /// 节日颜色
  static const Color festival = SoftMinimalistColors.accentRed;

  /// 节气颜色
  static const Color solarTerm = SoftMinimalistColors.success;

  /// 星期表头颜色
  static const Color weekdayHeader = SoftMinimalistColors.textSecondary;
}

/// 柔和极简主义尺寸常量
class SoftMinimalistSizes {
  SoftMinimalistSizes._();

  /// 卡片圆角
  static const double cardRadius = 20.0;

  /// 胶囊圆角 (完全圆角)
  static const double pillRadius = 999.0;

  /// 网格间距
  static const double gridSpacing = 24.0;

  /// FAB按钮大小
  static const double fabSize = 56.0;

  /// 卡片阴影
  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A000000), // rgba(0,0,0,0.04)
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  /// FAB阴影
  static const BoxShadow fabShadow = BoxShadow(
    color: Color(0x14000000), // rgba(0,0,0,0.08)
    blurRadius: 16,
    offset: Offset(0, 6),
  );
}

/// 日历尺寸常量
class CalendarSizes {
  CalendarSizes._();

  /// 日期单元格大小
  static const double dayCellSize = 48.0;

  /// 日期单元格内边距
  static const double dayCellPadding = 4.0;

  /// 农历字体大小 - 极小
  static const double lunarFontSize = 10.0;

  /// 公历字体大小 - 标准
  static const double solarFontSize = 18.0;

  /// 今日公历字体大小 - 加大加粗
  static const double todaySolarFontSize = 24.0;

  /// 事件指示点大小
  static const double eventIndicatorSize = 6.0;

  /// 时间槽高度
  static const double timeSlotHeight = 60.0;

  /// 头部高度
  static const double headerHeight = 56.0;

  /// 星期行高度
  static const double weekdayRowHeight = 32.0;

  /// 日期行间距 - 增加宽敞感
  static const double dayRowSpacing = 20.0;

  /// 胶囊标签高度
  static const double capsuleTabHeight = 32.0;

  /// 胶囊标签水平内边距
  static const double capsuleTabPaddingH = 12.0;
}

/// 颜色工具类
class ColorUtils {
  ColorUtils._();

  /// 根据背景色计算合适的文字颜色
  /// 如果颜色太亮，返回深色文字；如果颜色够深，返回原色
  static Color getContrastingTextColor(Color color) {
    // 计算颜色的相对亮度 (luminance)
    final luminance = color.computeLuminance();

    // 如果亮度超过阈值，使用深色文字
    if (luminance > 0.5) {
      // 返回颜色的深色版本
      return HSLColor.fromColor(color)
          .withLightness(
            (HSLColor.fromColor(color).lightness * 0.4).clamp(0.0, 1.0),
          )
          .toColor();
    }

    return color;
  }

  /// 判断颜色是否为亮色
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// 获取事件文字颜色（确保在浅色背景上可读）
  static Color getEventTextColor(Color eventColor) {
    final luminance = eventColor.computeLuminance();

    // 如果颜色太亮（如黄色、浅绿色等），使用更深的版本
    if (luminance > 0.4) {
      final hsl = HSLColor.fromColor(eventColor);
      // 降低亮度，增加饱和度
      return hsl
          .withLightness((hsl.lightness * 0.5).clamp(0.15, 0.45))
          .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
          .toColor();
    }

    return eventColor;
  }
}

/// 应用主题
class AppTheme {
  AppTheme._();

  /// 亮色主题 - 柔和极简主义风格
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SoftMinimalistColors.accentRed,
        brightness: Brightness.light,
        surface: SoftMinimalistColors.surface,
      ),
      scaffoldBackgroundColor: SoftMinimalistColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: SoftMinimalistColors.background,
        foregroundColor: SoftMinimalistColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: SoftMinimalistColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoftMinimalistSizes.cardRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SoftMinimalistColors.surface,
        foregroundColor: SoftMinimalistColors.textPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: SoftMinimalistColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: SoftMinimalistColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: SoftMinimalistColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: SoftMinimalistColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: SoftMinimalistColors.textSecondary,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SoftMinimalistColors.textSecondary,
        ),
      ),
    );
  }

  /// 暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SoftMinimalistColors.accentRed,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
      ),
    );
  }
}
