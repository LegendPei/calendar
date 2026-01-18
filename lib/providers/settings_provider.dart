/// 应用设置Provider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
