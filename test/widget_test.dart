// 日历App Widget测试
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calender_app/app.dart';

void main() {
  testWidgets('Calendar app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CalendarApp()));

    // 等待异步加载完成
    await tester.pumpAndSettle();

    // 验证今天按钮存在（可能有多个"今天"文本）
    expect(find.text('今天'), findsWidgets);

    // 验证日历视图已加载（应该能找到星期标题）
    expect(find.text('日'), findsWidgets);
  });
}
