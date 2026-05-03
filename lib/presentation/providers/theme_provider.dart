import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode_dark';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_kThemeKey) ?? false;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nowDark = state != ThemeMode.dark;
    state = nowDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kThemeKey, nowDark);
    } catch (_) {}
  }

  bool get isDark => state == ThemeMode.dark;
}
