// 日期工具类测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/core/utils/date_utils.dart';

void main() {
  group('DateUtils', () {
    group('isSameDay', () {
      test('should return true for same day', () {
        final date1 = DateTime(2025, 12, 27, 10, 30);
        final date2 = DateTime(2025, 12, 27, 18, 45);
        expect(DateUtils.isSameDay(date1, date2), isTrue);
      });

      test('should return false for different days', () {
        final date1 = DateTime(2025, 12, 27);
        final date2 = DateTime(2025, 12, 28);
        expect(DateUtils.isSameDay(date1, date2), isFalse);
      });

      test('should return false when one is null', () {
        final date1 = DateTime(2025, 12, 27);
        expect(DateUtils.isSameDay(date1, null), isFalse);
        expect(DateUtils.isSameDay(null, date1), isFalse);
      });
    });

    group('isWeekend', () {
      test('should return true for Saturday', () {
        final saturday = DateTime(2025, 12, 27); // 2025-12-27 is Saturday
        expect(DateUtils.isWeekend(saturday), isTrue);
      });

      test('should return true for Sunday', () {
        final sunday = DateTime(2025, 12, 28); // 2025-12-28 is Sunday
        expect(DateUtils.isWeekend(sunday), isTrue);
      });

      test('should return false for weekday', () {
        final monday = DateTime(2025, 12, 29); // 2025-12-29 is Monday
        expect(DateUtils.isWeekend(monday), isFalse);
      });
    });

    group('firstDayOfMonth', () {
      test('should return first day of month', () {
        final date = DateTime(2025, 12, 15);
        final firstDay = DateUtils.firstDayOfMonth(date);
        expect(firstDay.year, 2025);
        expect(firstDay.month, 12);
        expect(firstDay.day, 1);
      });
    });

    group('lastDayOfMonth', () {
      test('should return last day of month', () {
        final date = DateTime(2025, 12, 15);
        final lastDay = DateUtils.lastDayOfMonth(date);
        expect(lastDay.year, 2025);
        expect(lastDay.month, 12);
        expect(lastDay.day, 31);
      });

      test('should handle February correctly', () {
        final date = DateTime(2025, 2, 15);
        final lastDay = DateUtils.lastDayOfMonth(date);
        expect(lastDay.day, 28); // 2025 is not a leap year
      });

      test('should handle leap year February', () {
        final date = DateTime(2024, 2, 15);
        final lastDay = DateUtils.lastDayOfMonth(date);
        expect(lastDay.day, 29); // 2024 is a leap year
      });
    });

    group('daysInMonth', () {
      test('should return correct days for December', () {
        final date = DateTime(2025, 12, 1);
        expect(DateUtils.daysInMonth(date), 31);
      });

      test('should return correct days for November', () {
        final date = DateTime(2025, 11, 1);
        expect(DateUtils.daysInMonth(date), 30);
      });
    });

    group('getMonthViewDates', () {
      test('should return 42 dates', () {
        final date = DateTime(2025, 12, 1);
        final dates = DateUtils.getMonthViewDates(date);
        expect(dates.length, 42);
      });

      test('should start from correct day', () {
        // December 2025 starts on Monday
        final date = DateTime(2025, 12, 1);
        final dates = DateUtils.getMonthViewDates(date);
        expect(dates.first.day, 1);
        expect(dates.first.month, 12);
      });
    });

    group('getWeekViewDates', () {
      test('should return 7 dates', () {
        final date = DateTime(2025, 12, 27);
        final dates = DateUtils.getWeekViewDates(date);
        expect(dates.length, 7);
      });

      test('should start from Monday', () {
        final date = DateTime(2025, 12, 27); // Saturday
        final dates = DateUtils.getWeekViewDates(date);
        expect(dates.first.weekday, DateTime.monday);
      });
    });

    group('formatYearMonth', () {
      test('should format correctly', () {
        final date = DateTime(2025, 12, 27);
        expect(DateUtils.formatYearMonth(date), '2025年12月');
      });
    });

    group('daysBetween', () {
      test('should return correct days difference', () {
        final from = DateTime(2025, 12, 25);
        final to = DateTime(2025, 12, 27);
        expect(DateUtils.daysBetween(from, to), 2);
      });

      test('should return negative for past dates', () {
        final from = DateTime(2025, 12, 27);
        final to = DateTime(2025, 12, 25);
        expect(DateUtils.daysBetween(from, to), -2);
      });
    });
  });
}

