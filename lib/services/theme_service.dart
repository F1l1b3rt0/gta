import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';

  static final Map<String, ThemeData> themes = {
    'claro': _buildLightTheme(),
    'oscuro': _buildDarkTheme(),
    'gta': _buildGTATheme(),
  };

  // ── Claro ──────────────────────────────────────────────────────────────────
  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
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

  // ── Oscuro ─────────────────────────────────────────────────────────────────
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
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

  // ── GTA (azul oscuro con detalles eléctricos) ──────────────────────────────
  static ThemeData _buildGTATheme() {
    const bgDeep    = Color(0xFF060D1F);   // fondo principal muy oscuro
    const bgCard    = Color(0xFF0D1830);   // fondo de tarjetas
    const bgSurface = Color(0xFF111E35);   // superficies secundarias
    const accent    = Color(0xFF3B82F6);   // azul eléctrico
    const accentBright = Color(0xFF60A5FA); // azul brillante para textos
    const border    = Color(0xFF1E3A5F);   // borde sutil azul

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentBright,
        surface: bgCard,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: bgDeep,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        foregroundColor: accentBright,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 4,
        shadowColor: accent.withAlpha(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: bgCard),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: TextStyle(color: accentBright.withAlpha(100)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: accentBright),
      ),
      iconTheme: const IconThemeData(color: accentBright),
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? accent.withAlpha(80)
                : Colors.grey.withAlpha(60)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  static Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey) ?? 'claro';
    // Si tenía 'lite' o 'personalizado' guardado, vuelve a 'claro'
    if (!themes.containsKey(saved)) return 'claro';
    return saved;
  }
}
