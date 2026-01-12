// Calendar Provider测试
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calender_app/providers/calendar_provider.dart';
import 'package:calender_app/models/calendar_view_type.dart';

void main() {
  group('CalendarProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('selectedDateProvider', () {
      test('should initialize with current date', () {
        final selectedDate = container.read(selectedDateProvider);
        final now = DateTime.now();

        expect(selectedDate.year, now.year);
        expect(selectedDate.month, now.month);
        expect(selectedDate.day, now.day);
      });

      test('should update when set', () {
        final newDate = DateTime(2025, 1, 15);
        container.read(selectedDateProvider.notifier).state = newDate;

        final selectedDate = container.read(selectedDateProvider);
        expect(selectedDate, newDate);
      });
    });

    group('focusedDateProvider', () {
      test('should initialize with current date', () {
        final focusedDate = container.read(focusedDateProvider);
        final now = DateTime.now();

        expect(focusedDate.year, now.year);
        expect(focusedDate.month, now.month);
        expect(focusedDate.day, now.day);
      });
    });

    group('calendarViewTypeProvider', () {
      test('should initialize with month view', () {
        final viewType = container.read(calendarViewTypeProvider);
        expect(viewType, CalendarViewType.month);
      });

      test('should update when switched to week view', () {
        container.read(calendarViewTypeProvider.notifier).state = CalendarViewType.week;

        final viewType = container.read(calendarViewTypeProvider);
        expect(viewType, CalendarViewType.week);
      });

      test('should update when switched to day view', () {
        container.read(calendarViewTypeProvider.notifier).state = CalendarViewType.day;

        final viewType = container.read(calendarViewTypeProvider);
        expect(viewType, CalendarViewType.day);
      });
    });

    group('monthViewDatesProvider', () {
      test('should return 42 dates', () {
        final dates = container.read(monthViewDatesProvider);
        expect(dates.length, 42);
      });
    });

    group('weekViewDatesProvider', () {
      test('should return 7 dates', () {
        final dates = container.read(weekViewDatesProvider);
        expect(dates.length, 7);
      });
    });
  });
}

