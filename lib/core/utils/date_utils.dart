/// 日期工具类
import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断是否是今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// 判断是否是周末
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 获取月份的第一天
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取月份的最后一天
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取月份的天数
  static int daysInMonth(DateTime date) {
    return lastDayOfMonth(date).day;
  }

  /// 获取周的第一天（周一）
  static DateTime firstDayOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  /// 获取周的最后一天（周日）
  static DateTime lastDayOfWeek(DateTime date) {
    final diff = DateTime.sunday - date.weekday;
    return DateTime(date.year, date.month, date.day + diff);
  }

  /// 获取月视图需要显示的所有日期（6行7列=42天）
  static List<DateTime> getMonthViewDates(DateTime month) {
    final List<DateTime> dates = [];
    final firstDay = firstDayOfMonth(month);
    final lastDay = lastDayOfMonth(month);

    // 计算第一天是星期几（1=周一，7=周日）
    int startWeekday = firstDay.weekday;

    // 添加上月的日期
    for (int i = startWeekday - 1; i > 0; i--) {
      dates.add(firstDay.subtract(Duration(days: i)));
    }

    // 添加当月的日期
    for (int i = 0; i < lastDay.day; i++) {
      dates.add(DateTime(month.year, month.month, i + 1));
    }

    // 添加下月的日期，补齐到42天
    int remaining = 42 - dates.length;
    for (int i = 1; i <= remaining; i++) {
      dates.add(DateTime(month.year, month.month + 1, i));
    }

    return dates;
  }

  /// 获取周视图需要显示的日期（7天）
  static List<DateTime> getWeekViewDates(DateTime date) {
    final List<DateTime> dates = [];
    final firstDay = firstDayOfWeek(date);

    for (int i = 0; i < 7; i++) {
      dates.add(firstDay.add(Duration(days: i)));
    }

    return dates;
  }

  /// 格式化日期为"yyyy年M月"
  static String formatYearMonth(DateTime date) {
    return DateFormat('yyyy年M月').format(date);
  }

  /// 格式化日期为"M月d日"
  static String formatMonthDay(DateTime date) {
    return DateFormat('M月d日').format(date);
  }

  /// 格式化日期为"yyyy-MM-dd"
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 格式化时间为"HH:mm"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化日期时间为"yyyy-MM-dd HH:mm"
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// 获取日期的纯日期部分（去除时间）
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 判断日期是否在某个范围内
  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    final d = dateOnly(date);
    final s = dateOnly(start);
    final e = dateOnly(end);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  /// 获取两个日期之间的天数差
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = dateOnly(from);
    final toDate = dateOnly(to);
    return toDate.difference(fromDate).inDays;
  }
}
