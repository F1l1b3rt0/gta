// ignore_for_file: unused_field, dead_code, avoid_print

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Paleta de colores (misma que login/register/gerente_home) ────────────────
class _C {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const surfaceCard = Color(0xFFFFFFFF);

  static const primary = Color(0xFF0F2DA6);
  static const primaryMid = Color(0xFF1A3ABF);
  static const primaryLight = Color(0xFF1A4FD8);
  static const accent = Color(0xFF2196F3);

  static const textPrimary = Color(0xFF1A2A4A);
  static const textSecondary = Color(0xFF5A7DBA);
  static const textHint = Color(0xFFAABFE0);

  static const border = Color(0xFFC8DEFF);
  static const divider = Color(0xFFDDEEFF);
  static const shadowSm = Color(0x201A4FD8);
}

// ─── Servicio de temas ────────────────────────────────────────────────────────
class ThemeService {
  static const String _themeKey = 'selected_theme';

  static final Map<String, ThemeData> themes = {
    'claro': _buildLightTheme(),
    'oscuro': _buildDarkTheme(),
    'gta': _buildGTATheme(),
    'personalizado': _buildCustomTheme(),
    'lite': _buildLiteTheme(),
  };

  static ThemeData _buildLightTheme() => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1A4FD8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A4FD8),
      secondary: Color(0xFF2196F3),
      surface: Color(0xFFF4F8FF),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData _buildDarkTheme() => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4D96FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4D96FF),
      secondary: Color(0xFF1A6FE8),
      surface: Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A2E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData _buildGTATheme() => ThemeData(
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
      color: const Color(0xFF0A0A1A),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00FFD1), width: 0.5),
      ),
    ),
  );

  static ThemeData _buildCustomTheme() => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6366F1),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6366F1),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFFF9FAFB),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData _buildLiteTheme() => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      secondary: Color(0xFF3B82F6),
      surface: Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
  );

  static Future<void> saveTheme(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, name);
  }

  static Future<String> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'claro';
  }
}

// ─── Pantalla de Configuración ────────────────────────────────────────────────
class ConfiguracionView extends StatefulWidget {
  const ConfiguracionView({super.key});

  @override
  State<ConfiguracionView> createState() => _ConfiguracionViewState();
}

class _ConfiguracionViewState extends State<ConfiguracionView>
    with SingleTickerProviderStateMixin {
  // Config empresa
  int _maxHorasDiarias = 8;
  int _maxHorasSemanales = 40;
  bool _notificacionesPush = true;
  bool _qrUbicacion = true;
  double _radioUbicacion = 100;
  String _horarioCorte = '23:59';
  bool _isLoading = true;
  bool _isSaving = false;

  // Temas
  String _currentTheme = 'claro';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Mapa de temas para la UI
  final _themes = const {
    'claro': {
      'name': 'Claro',
      'icon': Icons.light_mode,
      'color': Color(0xFFFFB300),
    },
    'oscuro': {
      'name': 'Oscuro',
      'icon': Icons.dark_mode,
      'color': Color(0xFF546E7A),
    },
    'gta': {
      'name': 'GTA',
      'icon': Icons.sports_esports,
      'color': Color(0xFF00FFD1),
    },
    'personalizado': {
      'name': 'Custom',
      'icon': Icons.color_lens,
      'color': Color(0xFF6366F1),
    },
    'lite': {
      'name': 'Lite',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF3B82F6),
    },
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarConfiguracion();
    _cargarTema();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Carga / guarda ───────────────────────────────────────────────────────

  Future<void> _cargarTema() async {
    final t = await ThemeService.loadTheme();
    if (mounted) setState(() => _currentTheme = t);
  }

  Future<void> _cambiarTema(String key) async {
    setState(() => _currentTheme = key);
    await ThemeService.saveTheme(key);
    if (!mounted) return;
    _showSnack(
      'Tema cambiado a ${(_themes[key]!['name'] as String)}',
      success: true,
    );
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final cfg = await Supabase.instance.client
          .from('configuracion')
          .select()
          .maybeSingle();
      if (cfg != null && mounted) {
        setState(() {
          _maxHorasDiarias = cfg['max_horas_diarias'] ?? 8;
          _maxHorasSemanales = cfg['max_horas_semanales'] ?? 40;
          _notificacionesPush = cfg['notificaciones_push'] ?? true;
          _qrUbicacion = cfg['qr_ubicacion_requerida'] ?? true;
          _radioUbicacion = (cfg['radio_ubicacion'] ?? 100).toDouble();
          _horarioCorte = cfg['horario_corte'] ?? '23:59';
        });
      }
    } catch (e) {
      print('Error cargando configuración: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _guardar() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
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
        await Supabase.instance.client.from('configuracion').insert(data);
      }
      _showSnack('Configuración guardada', success: true);
    } catch (e) {
      _showSnack('Error al guardar', success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    if (!mounted) return;
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Ola inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 60),
              painter: _WavePainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _C.primaryLight,
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                            child: Column(
                              children: [
                                _buildThemeSection(),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.access_time_rounded,
                                  title: 'Límites de Horas',
                                  iconColor: _C.primaryLight,
                                  children: [
                                    _SliderTile(
                                      label: 'Horas máximas por día',
                                      value: _maxHorasDiarias.toDouble(),
                                      min: 4,
                                      max: 12,
                                      suffix: 'h/día',
                                      color: _C.primaryLight,
                                      onChanged: (v) => setState(
                                        () => _maxHorasDiarias = v.toInt(),
                                      ),
                                    ),
                                    _buildDivider(),
                                    _SliderTile(
                                      label: 'Horas máximas por semana',
                                      value: _maxHorasSemanales.toDouble(),
                                      min: 20,
                                      max: 60,
                                      suffix: 'h/sem',
                                      color: _C.primaryLight,
                                      onChanged: (v) => setState(
                                        () => _maxHorasSemanales = v.toInt(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.qr_code_scanner_rounded,
                                  title: 'Configuración QR',
                                  iconColor: const Color(0xFF00BFAE),
                                  children: [
                                    _SwitchTile(
                                      label: 'Requerir ubicación al marcar',
                                      sub:
                                          'Valida la posición GPS del empleado',
                                      value: _qrUbicacion,
                                      activeColor: _C.primaryLight,
                                      onChanged: (v) =>
                                          setState(() => _qrUbicacion = v),
                                    ),
                                    if (_qrUbicacion) ...[
                                      _buildDivider(),
                                      _SliderTile(
                                        label: 'Radio permitido (metros)',
                                        value: _radioUbicacion,
                                        min: 50,
                                        max: 500,
                                        suffix: 'm',
                                        color: const Color(0xFF00BFAE),
                                        onChanged: (v) =>
                                            setState(() => _radioUbicacion = v),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.notifications_active_rounded,
                                  title: 'Notificaciones',
                                  iconColor: const Color(0xFFFF6D00),
                                  children: [
                                    _SwitchTile(
                                      label: 'Notificaciones Push',
                                      sub: 'Recibir alertas en el dispositivo',
                                      value: _notificacionesPush,
                                      activeColor: _C.primaryLight,
                                      onChanged: (v) => setState(
                                        () => _notificacionesPush = v,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.schedule_rounded,
                                  title: 'Horario de Corte',
                                  iconColor: const Color(0xFF7C4DFF),
                                  children: [_buildHorarioCorte()],
                                ),
                                const SizedBox(height: 28),
                                _buildSaveButton(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _ScaleButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _C.border.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: _C.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          // Botón guardar rápido en top bar
          _ScaleButton(
            onPressed: _isSaving ? null : _guardar,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.primary, _C.primaryLight],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Selector de temas ────────────────────────────────────────────────────

  Widget _buildThemeSection() {
    return _buildSection(
      icon: Icons.palette_rounded,
      title: 'Apariencia',
      iconColor: _C.primaryLight,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un tema',
                style: TextStyle(
                  fontSize: 13,
                  color: _C.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Grid de temas 3 columnas
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: _themes.entries.map((e) {
                  final isSelected = _currentTheme == e.key;
                  final themeColor = e.value['color'] as Color;
                  return _ScaleButton(
                    onPressed: () => _cambiarTema(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _C.primaryLight.withOpacity(0.08)
                            : _C.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _C.primaryLight : _C.border,
                          width: isSelected ? 2.0 : 1.4,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _C.primaryLight.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            e.value['icon'] as IconData,
                            color: isSelected ? _C.primaryLight : themeColor,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e.value['name'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? _C.primaryLight
                                  : _C.textSecondary,
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
    );
  }

  // ─── Sección genérica ─────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border, width: 1.4),
        boxShadow: const [
          BoxShadow(color: _C.shadowSm, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
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

  Widget _buildDivider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: _C.divider,
  );

  // ─── Horario de corte ─────────────────────────────────────────────────────

  Widget _buildHorarioCorte() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bedtime_rounded,
              color: Color(0xFF7C4DFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hora de cierre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _horarioCorte,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _C.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _ScaleButton(
            onPressed: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(_horarioCorte.split(':')[0]),
                  minute: int.parse(_horarioCorte.split(':')[1]),
                ),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _C.primaryLight,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (t != null && mounted) {
                setState(
                  () => _horarioCorte =
                      '${t.hour.toString().padLeft(2, '0')}:'
                      '${t.minute.toString().padLeft(2, '0')}',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.4),
              ),
              child: const Text(
                'Cambiar',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botón guardar ────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return _ScaleButton(
      onPressed: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _C.primary,
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isSaving
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Guardar Configuración',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Widget: Slider ───────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Switch ───────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final String label, sub;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.25),
            inactiveThumbColor: _C.textHint,
            inactiveTrackColor: _C.border,
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Botón con scale ──────────────────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _ScaleButton({required this.onPressed, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Painter: Ola inferior ────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.5)
        ..cubicTo(
          size.width * 0.25,
          size.height * 0.15,
          size.width * 0.75,
          size.height * 0.85,
          size.width,
          size.height * 0.43,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..color = const Color(0xFFDDEEFF).withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
