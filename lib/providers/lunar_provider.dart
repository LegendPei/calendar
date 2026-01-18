/// 农历Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lunar_date.dart';
import '../services/lunar_service.dart';

/// 农历服务Provider
final lunarServiceProvider = Provider<LunarService>((ref) {
  return LunarService();
});

/// 指定日期的农历信息Provider
final lunarDateProvider = Provider.family<LunarDate, DateTime>((ref, date) {
  final service = ref.watch(lunarServiceProvider);
  return service.solarToLunar(date);
});

/// 当前选中日期的农历信息Provider
final selectedLunarDateProvider = Provider<LunarDate>((ref) {
  // 这里需要从calendar_provider获取selectedDate
  // 为了避免循环依赖，使用当前日期作为默认值
  final now = DateTime.now();
  final service = ref.watch(lunarServiceProvider);
  return service.solarToLunar(now);
});

/// 指定年份的生肖Provider
final zodiacProvider = Provider.family<String, int>((ref, year) {
  final service = ref.watch(lunarServiceProvider);
  return service.getZodiac(year);
});

/// 指定年份的干支Provider
final ganZhiProvider = Provider.family<String, int>((ref, year) {
  final service = ref.watch(lunarServiceProvider);
  return service.getYearGanZhi(year);
});

/// 月份农历日期列表Provider
final monthLunarDatesProvider = Provider.family<List<LunarDate>, MonthKey>((
  ref,
  key,
) {
  final service = ref.watch(lunarServiceProvider);
  return service.getLunarDatesForMonth(key.year, key.month);
});

/// 月份键
class MonthKey {
  final int year;
  final int month;

  const MonthKey(this.year, this.month);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthKey && other.year == year && other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}
