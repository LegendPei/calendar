// 农历模块测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/lunar_date.dart';
import 'package:calender_app/services/lunar_service.dart';
import 'package:calender_app/core/constants/lunar_constants.dart';

void main() {
  late LunarService lunarService;

  setUp(() {
    lunarService = LunarService();
    lunarService.clearCache();
  });

  group('LunarDate', () {
    test('should return correct month name', () {
      final lunar = LunarDate(
        year: 2025,
        month: 1,
        day: 1,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.monthName, '正月');
    });

    test('should return correct leap month name', () {
      final lunar = LunarDate(
        year: 2025,
        month: 6,
        day: 1,
        isLeapMonth: true,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.monthName, '闰六月');
    });

    test('should return correct day name', () {
      final lunar = LunarDate(
        year: 2025,
        month: 1,
        day: 1,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.dayName, '初一');
    });

    test('should return correct day name for various days', () {
      for (int day = 1; day <= 30; day++) {
        final lunar = LunarDate(
          year: 2025,
          month: 1,
          day: day,
          yearGanZhi: '乙巳',
          yearZodiac: '蛇',
        );
        expect(lunar.dayName, LunarConstants.lunarDayNames[day - 1]);
      }
    });

    test('displayText should return festival first', () {
      final lunar = LunarDate(
        year: 2025,
        month: 1,
        day: 1,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
        festival: '春节',
        solarTerm: '立春',
      );

      expect(lunar.displayText, '春节');
    });

    test('displayText should return solarTerm if no festival', () {
      final lunar = LunarDate(
        year: 2025,
        month: 1,
        day: 15,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
        solarTerm: '雨水',
      );

      expect(lunar.displayText, '雨水');
    });

    test('displayText should return monthName for day 1', () {
      final lunar = LunarDate(
        year: 2025,
        month: 2,
        day: 1,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.displayText, '二月');
    });

    test('displayText should return dayName for other days', () {
      final lunar = LunarDate(
        year: 2025,
        month: 1,
        day: 15,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.displayText, '十五');
    });

    test('fullName should return month and day', () {
      final lunar = LunarDate(
        year: 2025,
        month: 8,
        day: 15,
        yearGanZhi: '乙巳',
        yearZodiac: '蛇',
      );

      expect(lunar.fullName, '八月十五');
    });
  });

  group('LunarService', () {
    test('should convert 2025-01-29 to Spring Festival', () {
      // 2025年1月29日是农历乙巳年正月初一（春节）
      final date = DateTime(2025, 1, 29);
      final lunar = lunarService.solarToLunar(date);

      expect(lunar.year, 2025);
      expect(lunar.month, 1);
      expect(lunar.day, 1);
      expect(lunar.festival, '春节');
    });

    test('should get correct GanZhi for 2025', () {
      final ganZhi = lunarService.getYearGanZhi(2025);
      expect(ganZhi, '乙巳');
    });

    test('should get correct GanZhi for 2024', () {
      final ganZhi = lunarService.getYearGanZhi(2024);
      expect(ganZhi, '甲辰');
    });

    test('should get correct zodiac for 2025', () {
      final zodiac = lunarService.getZodiac(2025);
      expect(zodiac, '蛇');
    });

    test('should get correct zodiac for 2024', () {
      final zodiac = lunarService.getZodiac(2024);
      expect(zodiac, '龙');
    });

    test('should get correct zodiac for all 12 years', () {
      final expectedZodiacs = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
      for (int i = 0; i < 12; i++) {
        final year = 2020 + i; // 2020是鼠年
        final zodiac = lunarService.getZodiac(year);
        expect(zodiac, expectedZodiacs[i], reason: '$year 年应该是 ${expectedZodiacs[i]} 年');
      }
    });

    test('should identify Lantern Festival (元宵节)', () {
      // 2025年2月12日是农历正月十五
      final date = DateTime(2025, 2, 12);
      final lunar = lunarService.solarToLunar(date);

      expect(lunar.month, 1);
      expect(lunar.day, 15);
      expect(lunar.festival, '元宵节');
    });

    test('should identify Mid-Autumn Festival (中秋节)', () {
      // 需要找到2025年的中秋节日期
      // 农历八月十五
      final lunar = lunarService.solarToLunar(DateTime(2025, 10, 6));

      expect(lunar.month, 8);
      expect(lunar.day, 15);
      expect(lunar.festival, '中秋节');
    });

    test('should identify solar festival (国庆节)', () {
      final date = DateTime(2025, 10, 1);
      final lunar = lunarService.solarToLunar(date);

      expect(lunar.festival, '国庆节');
    });

    test('should identify solar festival (元旦)', () {
      final date = DateTime(2025, 1, 1);
      final lunar = lunarService.solarToLunar(date);

      expect(lunar.festival, '元旦');
    });

    test('should convert dates within valid range', () {
      // 测试边界年份
      expect(() => lunarService.solarToLunar(DateTime(1900, 2, 1)), returnsNormally);
      expect(() => lunarService.solarToLunar(DateTime(2100, 12, 31)), returnsNormally);
    });

    test('should throw for dates outside valid range', () {
      expect(
        () => lunarService.solarToLunar(DateTime(1899, 12, 31)),
        throwsArgumentError,
      );
    });

    test('should cache results', () {
      final date = DateTime(2025, 5, 1);
      final lunar1 = lunarService.solarToLunar(date);
      final lunar2 = lunarService.solarToLunar(date);

      expect(identical(lunar1, lunar2), true);
    });
  });

  group('Solar Terms', () {
    test('should identify Lichun (立春)', () {
      // 2025年立春大约在2月3日或4日
      final dates = [DateTime(2025, 2, 3), DateTime(2025, 2, 4)];
      bool found = false;

      for (final date in dates) {
        final lunar = lunarService.solarToLunar(date);
        if (lunar.solarTerm == '立春') {
          found = true;
          break;
        }
      }

      expect(found, true, reason: '应该在2月3日或4日找到立春');
    });

    test('should identify Qingming (清明)', () {
      // 清明节通常在4月4日或5日
      final dates = [DateTime(2025, 4, 4), DateTime(2025, 4, 5)];
      bool found = false;

      for (final date in dates) {
        final solarTerm = lunarService.getSolarTerm(date);
        if (solarTerm == '清明') {
          found = true;
          break;
        }
      }

      expect(found, true, reason: '应该在4月4日或5日找到清明');
    });
  });

  group('LunarConstants', () {
    test('should have 10 TianGan', () {
      expect(LunarConstants.tianGan.length, 10);
    });

    test('should have 12 DiZhi', () {
      expect(LunarConstants.diZhi.length, 12);
    });

    test('should have 12 zodiac animals', () {
      expect(LunarConstants.zodiac.length, 12);
    });

    test('should have 12 lunar month names', () {
      expect(LunarConstants.lunarMonthNames.length, 12);
    });

    test('should have 30 lunar day names', () {
      expect(LunarConstants.lunarDayNames.length, 30);
    });

    test('should have 24 solar terms', () {
      expect(LunarConstants.solarTerms.length, 24);
    });

    test('should have lunar festival definitions', () {
      expect(LunarConstants.lunarFestivals.containsKey('1-1'), true);
      expect(LunarConstants.lunarFestivals['1-1'], '春节');
      expect(LunarConstants.lunarFestivals.containsKey('8-15'), true);
      expect(LunarConstants.lunarFestivals['8-15'], '中秋节');
    });

    test('should have solar festival definitions', () {
      expect(LunarConstants.solarFestivals.containsKey('1-1'), true);
      expect(LunarConstants.solarFestivals['1-1'], '元旦');
      expect(LunarConstants.solarFestivals.containsKey('10-1'), true);
      expect(LunarConstants.solarFestivals['10-1'], '国庆节');
    });
  });
}

