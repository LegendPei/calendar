// RecurrenceRule模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/recurrence_rule.dart';

void main() {
  group('RecurrenceRule', () {
    group('fromRRule', () {
      test('should parse FREQ=DAILY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=DAILY');
        expect(rule.frequency, RecurrenceFrequency.daily);
        expect(rule.interval, 1);
      });

      test('should parse FREQ=WEEKLY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=WEEKLY');
        expect(rule.frequency, RecurrenceFrequency.weekly);
      });

      test('should parse FREQ=MONTHLY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=MONTHLY');
        expect(rule.frequency, RecurrenceFrequency.monthly);
      });

      test('should parse FREQ=YEARLY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=YEARLY');
        expect(rule.frequency, RecurrenceFrequency.yearly);
      });

      test('should parse INTERVAL correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=DAILY;INTERVAL=3');
        expect(rule.interval, 3);
      });

      test('should parse COUNT correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=DAILY;COUNT=10');
        expect(rule.count, 10);
      });

      test('should parse BYDAY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=WEEKLY;BYDAY=MO,WE,FR');
        expect(rule.byDay, [1, 3, 5]);
      });

      test('should parse BYMONTHDAY correctly', () {
        final rule = RecurrenceRule.fromRRule('FREQ=MONTHLY;BYMONTHDAY=15');
        expect(rule.byMonthDay, [15]);
      });
    });

    group('toRRule', () {
      test('should serialize daily rule correctly', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        expect(rule.toRRule(), 'FREQ=DAILY');
      });

      test('should serialize weekly rule correctly', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        expect(rule.toRRule(), 'FREQ=WEEKLY');
      });

      test('should serialize with interval correctly', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        expect(rule.toRRule(), 'FREQ=DAILY;INTERVAL=3');
      });

      test('should serialize with count correctly', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          count: 10,
        );
        expect(rule.toRRule(), 'FREQ=DAILY;COUNT=10');
      });

      test('should serialize with byDay correctly', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          byDay: [1, 3, 5],
        );
        expect(rule.toRRule(), 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
      });
    });

    group('displayText', () {
      test('should return correct text for daily', () {
        expect(RecurrenceRule.daily.displayText, '每天');
      });

      test('should return correct text for weekly', () {
        expect(RecurrenceRule.weekly.displayText, '每周');
      });

      test('should return correct text for monthly', () {
        expect(RecurrenceRule.monthly.displayText, '每月');
      });

      test('should return correct text for yearly', () {
        expect(RecurrenceRule.yearly.displayText, '每年');
      });

      test('should return correct text for interval > 1', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        expect(rule.displayText, '每3天');
      });
    });

    group('generateOccurrences', () {
      test('should generate daily occurrences correctly', () {
        const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        final start = DateTime(2025, 12, 1);
        final rangeStart = DateTime(2025, 12, 1);
        final rangeEnd = DateTime(2025, 12, 5);

        final occurrences = rule.generateOccurrences(start, rangeStart, rangeEnd);

        expect(occurrences.length, 5);
        expect(occurrences[0], DateTime(2025, 12, 1));
        expect(occurrences[4], DateTime(2025, 12, 5));
      });

      test('should respect COUNT limit', () {
        const rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          count: 3,
        );
        final start = DateTime(2025, 12, 1);
        final rangeStart = DateTime(2025, 12, 1);
        final rangeEnd = DateTime(2025, 12, 10);

        final occurrences = rule.generateOccurrences(start, rangeStart, rangeEnd);

        expect(occurrences.length, 3);
      });

      test('should respect UNTIL date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          until: DateTime(2025, 12, 3),
        );
        final start = DateTime(2025, 12, 1);
        final rangeStart = DateTime(2025, 12, 1);
        final rangeEnd = DateTime(2025, 12, 10);

        final occurrences = rule.generateOccurrences(start, rangeStart, rangeEnd);

        expect(occurrences.length, 3);
        expect(occurrences.last, DateTime(2025, 12, 3));
      });
    });

    group('presets', () {
      test('daily preset should work', () {
        expect(RecurrenceRule.daily.frequency, RecurrenceFrequency.daily);
      });

      test('weekly preset should work', () {
        expect(RecurrenceRule.weekly.frequency, RecurrenceFrequency.weekly);
      });

      test('weekdays preset should work', () {
        expect(RecurrenceRule.weekdays.byDay, [1, 2, 3, 4, 5]);
      });
    });
  });
}

