import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';

/// Holds the active light/dark mode, persists it, and keeps the global
/// [ThemeState] flag (used by AppTheme/DriverDark color tokens) in sync.
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'chapgo_theme_dark';
  bool _isDark = true;

  ThemeProvider() {
    ThemeState.setDark(_isDark);
    _load();
  }

  bool get isDark => _isDark;
  ThemeMode get mode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    ThemeState.setDark(_isDark);
    notifyListeners();
  }

  Future<void> toggle() => setDark(!_isDark);

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    ThemeState.setDark(_isDark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
