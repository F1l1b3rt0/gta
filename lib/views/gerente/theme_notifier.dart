import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Temas disponibles
final Map<String, ThemeData> appThemes = {
  'claro': ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1A4FD8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A4FD8),
      secondary: Color(0xFF2196F3),
      surface: Color(0xFFF4F8FF),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  'oscuro': ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4D96FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4D96FF),
      secondary: Color(0xFF1A6FE8),
      surface: Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A2E), elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  'gta': ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF00FFD1),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FFD1),
      secondary: Color(0xFF00B4D8),
      surface: Color(0xFF0A0A1A),
      error: Color(0xFFFF006E),
    ),
    scaffoldBackgroundColor: const Color(0xFF05050F),
    cardTheme: CardThemeData(
      color: const Color(0xFF0A0A1A), elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00FFD1), width: 0.5),
      ),
    ),
  ),
  'personalizado': ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6366F1),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFFF9FAFB),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  ),
  'lite': ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF000000),
      secondary: const Color(0xFF3B82F6),
      surface: const Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white, elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
  ),
};

// Notifier global — accesible desde cualquier parte de la app
final themeNotifier = ValueNotifier<String>('claro');

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('selected_theme') ?? 'claro';
  themeNotifier.value = saved;
}

Future<void> saveAndApplyTheme(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selected_theme', key);
  themeNotifier.value = key; // dispara rebuild automático en toda la app
}