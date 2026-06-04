// ignore_for_file: unused_field, dead_code

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Colores base de la app
class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const shadow  = Color(0x201A6FE8);
}

// Servicio de temas
class ThemeService {
  static const String _themeKey = 'selected_theme';
  
  static final Map<String, ThemeData> themes = {
    'claro': _buildLightTheme(),
    'oscuro': _buildDarkTheme(),
    'gta': _buildGTATheme(),
    'personalizado': _buildCustomTheme(),
    'lite': _buildLiteTheme(),
  };
  
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
        centerTitle: false,
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
  
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4D96FF),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4D96FF),
        secondary: Color(0xFF1A6FE8),
        surface: Color(0xFF1A1A2E),
        error: Colors.red,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
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
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0A1A),
        elevation: 5,
        shadowColor: Color(0xFF00FFD1),
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
    );
  }
  
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
        centerTitle: false,
      ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    
  }
  
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
        centerTitle: false,
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
  
  static Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }
  
  static Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'claro';
  }
}

// Pantalla principal de configuración
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with SingleTickerProviderStateMixin {
  // Configuración de la empresa
  int _maxHorasDiarias = 8;
  int _maxHorasSemanales = 40;
  bool _notificacionesPush = true;
  bool _qrUbicacion = true;
  double _radioUbicacion = 100;
  String _horarioCorte = '23:59';
  bool _isLoading = true;
  
  // Configuración de temas
  String _currentTheme = 'claro';
  final Color _customColor = const Color(0xFF6366F1);
  bool _showCustomColorPicker = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarConfiguracion();
    _cargarTema();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTema() async {
    final theme = await ThemeService.loadTheme();
    setState(() {
      _currentTheme = theme;
    });
  }

  Future<void> _cambiarTema(String themeName) async {
    setState(() {
      _currentTheme = themeName;
      _showCustomColorPicker = false;
    });
    await ThemeService.saveTheme(themeName);
    
    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tema cambiado a ${_getThemeName(themeName)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    // Recargar la app para aplicar el tema
    if (mounted) {
      // Forzar rebuild de la app
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {});
    }
  }

  String _getThemeName(String themeKey) {
    switch (themeKey) {
      case 'claro': return 'Claro';
      case 'oscuro': return 'Oscuro';
      case 'gta': return 'GTA';
      case 'personalizado': return 'Personalizado';
      case 'lite': return 'Lite';
      default: return 'Claro';
    }
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final config = await Supabase.instance.client
          .from('configuracion')
          .select()
          .maybeSingle();
      if (config != null) {
        setState(() {
          _maxHorasDiarias = config['max_horas_diarias'] ?? 8;
          _maxHorasSemanales = config['max_horas_semanales'] ?? 40;
          _notificacionesPush = config['notificaciones_push'] ?? true;
          _qrUbicacion = config['qr_ubicacion_requerida'] ?? true;
          _radioUbicacion = (config['radio_ubicacion'] ?? 100).toDouble();
          _horarioCorte = config['horario_corte'] ?? '23:59';
        });
      }
    } catch (e) {
      print('Error cargando configuración: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);
    try {
      final existing = await Supabase.instance.client
          .from('configuracion')
          .select()
          .maybeSingle();
      final data = {
        'max_horas_diarias': _maxHorasDiarias,
        'max_horas_semanales': _maxHorasSemanales,
        'notificaciones_push': _notificacionesPush,
        'qr_ubicacion_requerida': _qrUbicacion,
        'radio_ubicacion': _radioUbicacion,
        'horario_corte': _horarioCorte,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (existing != null) {
        await Supabase.instance.client
            .from('configuracion')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('configuracion')
            .insert(data);
      }
      _showSnack('Configuración guardada', success: true);
    } catch (e) {
      _showSnack('Error al guardar', success: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: success ? const Color(0xFF00C853) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  children: [
                    // Selector de temas
                    _buildThemeSelector(),
                    const SizedBox(height: 16),
                    
                    // Límites de Horas
                    _buildSection(
                      icon: Icons.access_time_rounded,
                      title: 'Límites de Horas',
                      children: [
                        _SliderTile(
                          label: 'Horas máximas por día',
                          value: _maxHorasDiarias.toDouble(),
                          min: 4, max: 12,
                          suffix: 'h/día',
                          color: _C.primary,
                          onChanged: (v) => setState(() => _maxHorasDiarias = v.toInt()),
                        ),
                        _Divider(),
                        _SliderTile(
                          label: 'Horas máximas por semana',
                          value: _maxHorasSemanales.toDouble(),
                          min: 20, max: 60,
                          suffix: 'h/sem',
                          color: _C.primary,
                          onChanged: (v) => setState(() => _maxHorasSemanales = v.toInt()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Configuración QR
                    _buildSection(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Configuración QR',
                      children: [
                        _SwitchTile(
                          label: 'Requerir ubicación al marcar',
                          sub: 'Valida la posición GPS del empleado',
                          value: _qrUbicacion,
                          onChanged: (v) => setState(() => _qrUbicacion = v),
                        ),
                        if (_qrUbicacion) ...[
                          _Divider(),
                          _SliderTile(
                            label: 'Radio permitido (metros)',
                            value: _radioUbicacion,
                            min: 50, max: 500,
                            suffix: 'm',
                            color: const Color(0xFF00BFAE),
                            onChanged: (v) => setState(() => _radioUbicacion = v),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Notificaciones
                    _buildSection(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notificaciones',
                      children: [
                        _SwitchTile(
                          label: 'Notificaciones Push',
                          sub: 'Recibir alertas en el dispositivo',
                          value: _notificacionesPush,
                          onChanged: (v) => setState(() => _notificacionesPush = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Horario de Corte
                    _buildSection(
                      icon: Icons.schedule_rounded,
                      title: 'Horario de Corte',
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bedtime_rounded,
                                color: Color(0xFF7C4DFF), size: 20),
                          ),
                          title: const Text('Hora de cierre',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _C.text)),
                          subtitle: Text(_horarioCorte,
                              style: const TextStyle(color: _C.primary, fontWeight: FontWeight.w700)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _C.divider),
                            ),
                            child: const Text('Cambiar',
                                style: TextStyle(fontSize: 12, color: _C.primary, fontWeight: FontWeight.w600)),
                          ),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(_horarioCorte.split(':')[0]),
                                minute: int.parse(_horarioCorte.split(':')[1]),
                              ),
                              builder: (ctx, child) => Theme(
                                data: Theme.of(ctx).copyWith(
                                  colorScheme: const ColorScheme.light(primary: _C.primary),
                                ),
                                child: child!,
                              ),
                            );
                            if (t != null) {
                              setState(() {
                                _horarioCorte =
                                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    // Botón guardar
                    GestureDetector(
                      onTap: _guardar,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A6FE8), Color(0xFF4D96FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _C.primary.withOpacity(0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Guardar Configuración',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildThemeSelector() {
    final themes = {
      'claro': {'name': 'Claro', 'icon': Icons.light_mode, 'color': Colors.amber},
      'oscuro': {'name': 'Oscuro', 'icon': Icons.dark_mode, 'color': Colors.blueGrey},
      'gta': {'name': 'GTA', 'icon': Icons.sports_esports, 'color': const Color(0xFF00FFD1)},
      'personalizado': {'name': 'Personalizado', 'icon': Icons.color_lens, 'color': const Color(0xFF6366F1)},
      'lite': {'name': 'Lite', 'icon': Icons.auto_awesome, 'color': Colors.blue},
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.palette_rounded, color: _C.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Apariencia',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _C.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona un tema',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: themes.entries.map((entry) {
                    final isSelected = _currentTheme == entry.key;
                    return GestureDetector(
                      onTap: () => _cambiarTema(entry.key),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 60) / 3,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _C.primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _C.primary : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              entry.value['icon'] as IconData,
                              color: entry.value['color'] as Color,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.value['name'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? _C.primary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Configuración',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _C.text)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _guardar,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _C.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _C.divider),
          ...children,
        ],
      ),
    );
  }

  Widget _Divider() =>
      Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 1, color: _C.divider);
}

// Widget Slider personalizado
class _SliderTile extends StatelessWidget {
  final String label, suffix;
  final double value, min, max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13, color: _C.textSub, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${value.toInt()} $suffix',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min)).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Switch personalizado
class _SwitchTile extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.text,
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(fontSize: 12, color: _C.textSub)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _C.primary,
          ),
        ],
      ),
    );
  }
}