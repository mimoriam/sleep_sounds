import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultTimer = 'default_timer_minutes';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  final SharedPreferences _prefs;

  bool _hasCompletedOnboarding = false;
  ThemeMode _themeMode = ThemeMode.dark;
  int? _defaultTimerMinutes;
  bool _notificationsEnabled = true;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  ThemeMode get themeMode => _themeMode;
  int? get defaultTimerMinutes => _defaultTimerMinutes;
  bool get notificationsEnabled => _notificationsEnabled;

  void _loadSettings() {
    _hasCompletedOnboarding = _prefs.getBool(_keyOnboardingCompleted) ?? false;
    
    final themeString = _prefs.getString(_keyThemeMode);
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    _defaultTimerMinutes = _prefs.getInt(_keyDefaultTimer);
    _notificationsEnabled = _prefs.getBool(_keyNotificationsEnabled) ?? true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool(_keyOnboardingCompleted, true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_keyThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setDefaultTimerMinutes(int? minutes) async {
    _defaultTimerMinutes = minutes;
    if (minutes == null) {
      await _prefs.remove(_keyDefaultTimer);
    } else {
      await _prefs.setInt(_keyDefaultTimer, minutes);
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
    notifyListeners();
  }
}
