/// 应用设置Provider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// 是否显示农历（月视图）
final showLunarProvider = StateProvider<bool>((ref) => true);

/// 是否显示节假日（月视图）
final showHolidayProvider = StateProvider<bool>((ref) => true);
