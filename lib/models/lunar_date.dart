/// 农历日期模型
import '../core/constants/lunar_constants.dart';

class LunarDate {
  /// 农历年
  final int year;

  /// 农历月 (1-12)
  final int month;

  /// 农历日 (1-30)
  final int day;

  /// 是否闰月
  final bool isLeapMonth;

  /// 干支纪年
  final String yearGanZhi;

  /// 生肖
  final String yearZodiac;

  /// 节气 (如果当天是节气)
  final String? solarTerm;

  /// 节日 (农历或公历节日)
  final String? festival;

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
    required this.yearGanZhi,
    required this.yearZodiac,
    this.solarTerm,
    this.festival,
  });

  /// 获取月名
  String get monthName {
    if (isLeapMonth) {
      return '闰${LunarConstants.lunarMonthNames[month - 1]}';
    }
    return LunarConstants.lunarMonthNames[month - 1];
  }

  /// 获取日名
  String get dayName {
    if (day < 1 || day > 30) return '';
    return LunarConstants.lunarDayNames[day - 1];
  }

  /// 获取完整名称 (月+日)
  String get fullName => '$monthName$dayName';

  /// 获取显示文本 (优先显示节日、节气，否则显示日名)
  String get displayText {
    if (festival != null && festival!.isNotEmpty) {
      return festival!;
    }
    if (solarTerm != null && solarTerm!.isNotEmpty) {
      return solarTerm!;
    }
    // 初一显示月份
    if (day == 1) {
      return monthName;
    }
    return dayName;
  }

  /// 获取年份描述
  String get yearDescription {
    return '$yearGanZhi年 ($yearZodiac年)';
  }

  /// 获取完整描述
  String get fullDescription {
    final buffer = StringBuffer();
    buffer.write('$yearGanZhi年');
    buffer.write(' $monthName');
    buffer.write(dayName);
    if (solarTerm != null) {
      buffer.write(' $solarTerm');
    }
    if (festival != null) {
      buffer.write(' $festival');
    }
    return buffer.toString();
  }

  /// 是否是重要节日
  bool get isImportantFestival {
    const importantFestivals = ['春节', '元宵节', '端午节', '中秋节', '国庆节', '元旦'];
    return festival != null && importantFestivals.contains(festival);
  }

  /// 复制并修改
  LunarDate copyWith({
    int? year,
    int? month,
    int? day,
    bool? isLeapMonth,
    String? yearGanZhi,
    String? yearZodiac,
    String? solarTerm,
    String? festival,
  }) {
    return LunarDate(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      yearGanZhi: yearGanZhi ?? this.yearGanZhi,
      yearZodiac: yearZodiac ?? this.yearZodiac,
      solarTerm: solarTerm ?? this.solarTerm,
      festival: festival ?? this.festival,
    );
  }

  @override
  String toString() {
    return 'LunarDate($year年$monthName$dayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LunarDate &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.isLeapMonth == isLeapMonth;
  }

  @override
  int get hashCode {
    return Object.hash(year, month, day, isLeapMonth);
  }
}

