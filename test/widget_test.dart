// 日历App Widget测试
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calender_app/app.dart';

void main() {
  testWidgets('Calendar app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CalendarApp(),
      ),
    );

    // 验证日历标题显示
    expect(find.text('日历'), findsOneWidget);

    // 验证今天按钮存在
    expect(find.text('今天'), findsOneWidget);
  });
}
