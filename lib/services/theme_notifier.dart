import 'package:flutter/material.dart';
import 'theme_service.dart';

class ThemeNotifier extends ChangeNotifier {
  String _themeName = 'claro';

  String get themeName => _themeName;
  ThemeData get themeData =>
      ThemeService.themes[_themeName] ?? ThemeService.themes['claro']!;

  static Future<ThemeNotifier> create() async {
    final notifier = ThemeNotifier();
    notifier._themeName = await ThemeService.loadTheme();
    return notifier;
  }

  Future<void> setTheme(String name) async {
    if (!ThemeService.themes.containsKey(name)) return;
    _themeName = name;
    await ThemeService.saveTheme(name);
    notifyListeners();
  }
}
