import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'gap_theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    _mode = switch (stored) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => _platformIsDark ? ThemeMode.dark : ThemeMode.light,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  bool get _platformIsDark =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      mode = _platformIsDark ? ThemeMode.dark : ThemeMode.light;
    }
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  /// Faqat kunduz (yorug') va tun (tungi) o'rtasida almashtirish.
  void toggleDayNight() {
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  String get modeLabel => isDark ? 'Tun' : 'Kun';

  IconData get modeIcon =>
      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
}
