import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';
  
  // Lista de temas disponibles
  static final Map<String, ThemeData> themes = {
    'claro': _buildLightTheme(),
    'oscuro': _buildDarkTheme(),
    'gta': _buildGTATheme(),
    'personalizado': _buildCustomTheme(),
    'lite': _buildLiteTheme(),
  };
  
  // Tema Claro (default)
  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1A6FE8),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A6FE8),
        secondary: Color(0xFF4D96FF),
        surface: Color(0xFFF4F8FF),
        error: Colors.red,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A6FE8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  
  // Tema Oscuro
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF0D1B3E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4D96FF),
        secondary: Color(0xFF1A6FE8),
        surface: Color(0xFF1A1A2E),
        error: Colors.red,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  
  // Tema GTA (neones y azules)
  static ThemeData _buildGTATheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF00FFD1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FFD1),
        secondary: Color(0xFF00B4D8),
        surface: Color(0xFF0A0A1A),
        error: Color(0xFFFF006E),
      ),
      scaffoldBackgroundColor: const Color(0xFF05050F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A1A),
        foregroundColor: Color(0xFF00FFD1),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0A1A),
        elevation: 5,
        shadowColor: const Color(0xFF00FFD1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00FFD1), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A0A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00FFD1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00B4D8)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF00FFD1)),
        bodyMedium: TextStyle(color: Color(0xFF00B4D8)),
      ),
    );
  }
  
  // Tema Personalizado (editable por el usuario)
  static ThemeData _buildCustomTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        surface: Color(0xFFF9FAFB),
        error: Colors.red,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
  
  // Tema Lite (minimalista)
  static ThemeData _buildLiteTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        secondary: Color(0xFF3B82F6),
        surface: Color(0xFFF8FAFC),
        error: Colors.red,
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
  
  // Guardar tema seleccionado
  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }
  
  // Cargar tema guardado
  static Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'claro';
  }
}