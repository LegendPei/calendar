/// 农历服务
import '../core/constants/lunar_constants.dart';
import '../models/lunar_date.dart';

class LunarService {
  /// 单例
  static final LunarService _instance = LunarService._internal();
  factory LunarService() => _instance;
  LunarService._internal();

  /// 缓存
  final Map<DateTime, LunarDate> _cache = {};

  /// 公历转农历
  LunarDate solarToLunar(DateTime date) {
    // 规范化日期（去除时间部分）
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 检查缓存
    if (_cache.containsKey(normalizedDate)) {
      return _cache[normalizedDate]!;
    }

    // 检查范围
    if (date.year < LunarConstants.minYear || date.year > LunarConstants.maxYear) {
      throw ArgumentError('日期超出支持范围 (${LunarConstants.minYear}-${LunarConstants.maxYear})');
    }

    // 计算农历
    final lunar = _calculateLunar(normalizedDate);

    // 获取节气
    final solarTerm = getSolarTerm(normalizedDate);

    // 获取节日
    final festival = getFestival(normalizedDate, lunar);

    // 构建完整的农历日期
    final result = lunar.copyWith(
      solarTerm: solarTerm,
      festival: festival,
    );

    // 缓存结果
    _cache[normalizedDate] = result;

    return result;
  }

  /// 计算农历日期
  LunarDate _calculateLunar(DateTime date) {
    // 计算与基准日期的天数差
    int offset = date.difference(LunarConstants.baseDate).inDays;

    int lunarYear = LunarConstants.minYear;
    int lunarMonth = 1;
    int lunarDay = 1;
    bool isLeapMonth = false;

    // 计算农历年
    int daysInYear;
    while (lunarYear <= LunarConstants.maxYear) {
      daysInYear = _getLunarYearDays(lunarYear);
      if (offset < daysInYear) {
        break;
      }
      offset -= daysInYear;
      lunarYear++;
    }

    // 计算农历月
    int leapMonth = _getLeapMonth(lunarYear);
    bool hasLeapMonth = leapMonth > 0;
    bool passedLeapMonth = false;

    for (int m = 1; m <= 12; m++) {
      int daysInMonth;

      // 检查是否是闰月
      if (hasLeapMonth && m == leapMonth + 1 && !passedLeapMonth) {
        // 这个月是闰月
        daysInMonth = _getLeapMonthDays(lunarYear);
        isLeapMonth = true;
        passedLeapMonth = true;

        if (offset < daysInMonth) {
          lunarMonth = leapMonth;
          break;
        }
        offset -= daysInMonth;
        isLeapMonth = false;
      }

      // 普通月份
      daysInMonth = _getLunarMonthDays(lunarYear, m);
      if (offset < daysInMonth) {
        lunarMonth = m;
        break;
      }
      offset -= daysInMonth;
    }

    // 农历日
    lunarDay = offset + 1;

    // 获取干支和生肖
    final yearGanZhi = getYearGanZhi(lunarYear);
    final yearZodiac = getZodiac(lunarYear);

    return LunarDate(
      year: lunarYear,
      month: lunarMonth,
      day: lunarDay,
      isLeapMonth: isLeapMonth,
      yearGanZhi: yearGanZhi,
      yearZodiac: yearZodiac,
    );
  }

  /// 获取农历年的总天数
  int _getLunarYearDays(int year) {
    int sum = 348; // 12个月 * 29天
    final info = LunarConstants.lunarInfo[year - LunarConstants.minYear];

    // 加上大月的天数
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      if ((info & i) != 0) {
        sum += 1;
      }
    }

    // 加上闰月天数
    sum += _getLeapMonthDays(year);

    return sum;
  }

  /// 获取闰月月份 (0表示无闰月)
  int _getLeapMonth(int year) {
    return LunarConstants.lunarInfo[year - LunarConstants.minYear] & 0xf;
  }

  /// 获取闰月天数
  int _getLeapMonthDays(int year) {
    if (_getLeapMonth(year) == 0) return 0;
    return (LunarConstants.lunarInfo[year - LunarConstants.minYear] & 0x10000) != 0 ? 30 : 29;
  }

  /// 获取农历月天数
  int _getLunarMonthDays(int year, int month) {
    final info = LunarConstants.lunarInfo[year - LunarConstants.minYear];
    return (info & (0x10000 >> month)) != 0 ? 30 : 29;
  }

  /// 获取干支纪年
  String getYearGanZhi(int lunarYear) {
    final ganIndex = (lunarYear - 4) % 10;
    final zhiIndex = (lunarYear - 4) % 12;
    return '${LunarConstants.tianGan[ganIndex]}${LunarConstants.diZhi[zhiIndex]}';
  }

  /// 获取生肖
  String getZodiac(int lunarYear) {
    return LunarConstants.zodiac[(lunarYear - 4) % 12];
  }

  /// 获取节气
  String? getSolarTerm(DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // 每月有两个节气
    final termIndex1 = (month - 1) * 2;
    final termIndex2 = termIndex1 + 1;

    // 计算节气日期
    final termDay1 = _getSolarTermDay(year, termIndex1);
    final termDay2 = _getSolarTermDay(year, termIndex2);

    if (day == termDay1) {
      return LunarConstants.solarTerms[termIndex1];
    }
    if (day == termDay2) {
      return LunarConstants.solarTerms[termIndex2];
    }

    return null;
  }

  /// 计算节气日期 (使用寿星公式)
  int _getSolarTermDay(int year, int termIndex) {
    final century = year ~/ 100;
    final y = year % 100;

    List<double> cTable;
    if (century == 19) {
      cTable = LunarConstants.solarTermC20;
    } else {
      cTable = LunarConstants.solarTermC21;
    }

    final c = cTable[termIndex];
    int d = (y * 0.2422 + c).floor() - ((y - 1) ~/ 4);

    // 特殊年份修正
    d = _adjustSolarTerm(year, termIndex, d);

    return d;
  }

  /// 节气日期修正
  int _adjustSolarTerm(int year, int termIndex, int day) {
    // 一些特殊年份的修正
    // 这里只列出常见的修正，完整的修正表较长
    if (termIndex == 0) { // 小寒
      if (year == 2019) return day - 1;
    } else if (termIndex == 2) { // 立春
      if (year == 2026) return day + 1;
    } else if (termIndex == 6) { // 清明
      if (year == 2019) return day + 1;
    }
    return day;
  }

  /// 获取节日
  String? getFestival(DateTime date, LunarDate lunar) {
    // 先检查公历节日
    final solarKey = '${date.month}-${date.day}';
    if (LunarConstants.solarFestivals.containsKey(solarKey)) {
      return LunarConstants.solarFestivals[solarKey];
    }

    // 检查农历节日
    final lunarKey = '${lunar.month}-${lunar.day}';
    if (!lunar.isLeapMonth && LunarConstants.lunarFestivals.containsKey(lunarKey)) {
      return LunarConstants.lunarFestivals[lunarKey];
    }

    // 特殊处理除夕 (腊月最后一天)
    if (lunar.month == 12 && !lunar.isLeapMonth) {
      final nextYear = lunar.year + 1;
      if (nextYear <= LunarConstants.maxYear) {
        // 检查腊月是大月(30天)还是小月(29天)
        final daysInMonth = _getLunarMonthDays(lunar.year, 12);
        if (lunar.day == daysInMonth) {
          return '除夕';
        }
      }
    }

    return null;
  }

  /// 获取指定月份所有日期的农历信息
  List<LunarDate> getLunarDatesForMonth(int year, int month) {
    final dates = <LunarDate>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      dates.add(solarToLunar(DateTime(year, month, day)));
    }

    return dates;
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }
}

