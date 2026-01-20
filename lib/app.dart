/// App配置文件
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/theme_constants.dart';
import 'providers/settings_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/calendar/calendar_screen.dart';

class CalendarApp extends ConsumerStatefulWidget {
  const CalendarApp({super.key});

  @override
  ConsumerState<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends ConsumerState<CalendarApp> {
  @override
  void initState() {
    super.initState();
    // 延迟初始化自动同步，避免在 build 期间调用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAutoSync();
    });
  }

  void _initAutoSync() {
    // 启动订阅自动同步
    final syncManager = ref.read(syncManagerProvider);
    syncManager.startAutoSync();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CalendarScreen(),
    );
  }
}
