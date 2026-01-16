import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app theme mode
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService: Error loading theme mode: $e');
    }
  }

  /// Save theme mode to storage
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      debugPrint('ThemeService: Error saving theme mode: $e');
    }
  }

  /// Toggle theme mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveThemeMode();
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }
}
