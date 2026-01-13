# 模块06: 农历模块
## 1. 模块概述
农历模块负责公历与农历的转换、二十四节气计算、传统节日识别等功能。
## 2. 功能需求
### 2.1 农历转换
- 公历日期转农历日期
- 显示农历年月日
- 显示干支纪年
### 2.2 节气计算
- 二十四节气计算
- 节气日期标注
### 2.3 节日识别
- 传统农历节日（春节、元宵、端午、中秋等）
- 公历节日（元旦、劳动节、国庆等）
## 3. 文件结构
lib/
├── models/
│   └── lunar_date.dart
├── core/utils/
│   └── lunar_utils.dart
└── services/
    └── lunar_service.dart
## 4. 数据模型
### 4.1 LunarDate模型
class LunarDate {
  final int year;           // 农历年
  final int month;          // 农历月(1-12)
  final int day;            // 农历日(1-30)
  final bool isLeapMonth;   // 是否闰月
  final String yearGanZhi;  // 干支纪年 如"甲子"
  final String yearZodiac;  // 生肖 如"鼠"
  final String monthName;   // 月名 如"正月"
  final String dayName;     // 日名 如"初一"
  final String? solarTerm;  // 节气 如"立春"
  final String? festival;   // 节日 如"春节"
  String get fullName => monthName + dayName;
  String get displayText => festival ?? solarTerm ?? dayName;
}
## 5. 常量定义
// 天干
const List<String> tianGan = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
// 地支
const List<String> diZhi = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
// 生肖
const List<String> zodiac = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪'];
// 农历月名
const List<String> lunarMonthNames = ['正月','二月','三月','四月','五月','六月','七月','八月','九月','十月','冬月','腊月'];
// 农历日名
const List<String> lunarDayNames = ['初一','初二',...,'三十'];
// 二十四节气
const List<String> solarTerms = ['小寒','大寒','立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至'];
// 农历节日
const Map<String, String> lunarFestivals = {
  '1-1': '春节',
  '1-15': '元宵节',
  '5-5': '端午节',
  '7-7': '七夕节',
  '7-15': '中元节',
  '8-15': '中秋节',
  '9-9': '重阳节',
  '12-30': '除夕',
};
// 公历节日
const Map<String, String> solarFestivals = {
  '1-1': '元旦',
  '2-14': '情人节',
  '3-8': '妇女节',
  '5-1': '劳动节',
  '6-1': '儿童节',
  '10-1': '国庆节',
  '12-25': '圣诞节',
};
## 6. Service设计
class LunarService {
  // 农历数据表(1900-2100年)
  static const List<int> lunarInfo = [...];
  // 公历转农历
  LunarDate solarToLunar(DateTime date) {
    // 计算距离1900年1月31日的天数
    // 根据lunarInfo计算农历年月日
  }
  // 获取干支纪年
  String getYearGanZhi(int lunarYear) {
    int ganIndex = (lunarYear - 4) % 10;
    int zhiIndex = (lunarYear - 4) % 12;
    return tianGan[ganIndex] + diZhi[zhiIndex];
  }
  // 获取生肖
  String getZodiac(int lunarYear) {
    return zodiac[(lunarYear - 4) % 12];
  }
  // 获取节气
  String? getSolarTerm(DateTime date) {
    // 根据节气计算公式判断
  }
  // 获取节日
  String? getFestival(DateTime date, LunarDate lunar) {
    // 先检查公历节日
    final solarKey = date.month.toString() + '-' + date.day.toString();
    if (solarFestivals.containsKey(solarKey)) {
      return solarFestivals[solarKey];
    }
    // 再检查农历节日
    final lunarKey = lunar.month.toString() + '-' + lunar.day.toString();
    return lunarFestivals[lunarKey];
  }
}
## 7. 节气计算算法
// 节气计算(简化版)
DateTime getSolarTermDate(int year, int termIndex) {
  // 使用寿星公式计算
  // termIndex: 0-23 对应24节气
  double c;
  if (termIndex < 4) {
    // 小寒到雨水在上一年
    c = getTermC(year, termIndex);
  } else {
    c = getTermC(year, termIndex);
  }
  int d = (c - (year % 100 - 1) / 4).floor();
  return DateTime(year, (termIndex / 2).floor() + 1, d);
}
## 8. Provider设计
final lunarServiceProvider = Provider<LunarService>((ref) {
  return LunarService();
});
// 指定日期的农历信息
final lunarDateProvider = Provider.family<LunarDate, DateTime>((ref, date) {
  return ref.watch(lunarServiceProvider).solarToLunar(date);
});
## 9. 测试用例
### 9.1 单元测试
| 测试文件 | 测试内容 |
|---------|---------|
| lunar_date_test.dart | 模型测试 |
| lunar_service_test.dart | 转换算法测试 |
### 9.2 测试用例清单
group('LunarService', () {
  test('should convert 2025-01-29 to lunar new year');
  test('should get correct GanZhi for year');
  test('should get correct zodiac for year');
  test('should identify Spring Festival');
  test('should calculate solar terms correctly');
});
group('LunarDate', () {
  test('should display correct month name');
  test('should display correct day name');
  test('should handle leap month');
});
## 10. 农历数据说明
lunarInfo数组存储1900-2100年的农历数据
每个元素为一个整数，包含以下信息：
- bit0-3: 闰月月份(0表示无闰月)
- bit4: 闰月大小(0=29天, 1=30天)
- bit5-16: 1-12月大小(0=29天, 1=30天)
示例: 0x04bd8
二进制: 0100 1011 1101 1000
- 闰月: 8月
- 各月天数: 30,29,30,29,30,30,29,30,30,29,30,29
## 11. 注意事项
1. 农历计算范围限于1900-2100年
2. 闰月需要特殊处理
3. 除夕可能是腊月二十九或三十
4. 节气日期每年不固定，需要计算
5. 缓存常用日期的农历数据提高性能
