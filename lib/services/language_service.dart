import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const _key = 'app_language';
  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  static Future<LanguageService> create() async {
    final service = LanguageService();
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'es';
    service._locale = Locale(lang);
    return service;
  }

  Future<void> setLanguage(String langCode) async {
    if (_locale.languageCode == langCode) return;
    _locale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langCode);
    notifyListeners();
  }
}
