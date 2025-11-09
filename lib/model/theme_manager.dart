
import 'package:flutter/material.dart';
import 'package:get_x_storage/get_x_storage.dart';

class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final storage = GetXStorage();
  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  void init() {
    final themeValue = storage.read<String>(key: 'theme');
    themeNotifier.value = themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    await storage.write(key: 'theme', value: isDark ? 'light' : 'dark');
  }

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
}