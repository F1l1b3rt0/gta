// ignore_for_file: unused_field, dead_code, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/language_service.dart';
import '../../services/theme_notifier.dart';


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
  String _claveRegistro = '';
  bool _isLoading = true;
  bool _isSaving = false;

  // Temas
  String _currentTheme = 'claro';
  String _idioma = 'es';

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
    await Future.microtask(() {});
    if (mounted) {
      setState(() {
        _currentTheme = Provider.of<ThemeNotifier>(context, listen: false).themeName;
        _idioma = Provider.of<LanguageService>(context, listen: false).languageCode;
      });
    }
  }

  Future<void> _cambiarIdioma(String code) async {
    setState(() => _idioma = code);
    await Provider.of<LanguageService>(context, listen: false).setLanguage(code);
    if (!mounted) return;
    _showSnack(code == 'es' ? '🇪🇸 Idioma: Español' : '🇺🇸 Language: English', success: true);
  }

  Future<void> _cambiarTema(String key) async {
    setState(() => _currentTheme = key);
    await Provider.of<ThemeNotifier>(context, listen: false).setTheme(key);
    if (!mounted) return;
    _showSnack(
      _t('Tema: ', 'Theme: ') + (_themes[key]!['name'] as String),
      success: true,
    );
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final gerenteRow = userId != null
          ? await Supabase.instance.client
              .from('gerentes')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle()
          : null;
      final gerenteId = gerenteRow?['id'];

      final cfg = gerenteId != null
          ? await Supabase.instance.client
              .from('configuracion')
              .select()
              .eq('gerente_id', gerenteId)
              .maybeSingle()
          : await Supabase.instance.client
              .from('configuracion')
              .select()
              .maybeSingle();
      if (cfg != null && mounted) {
        setState(() {
          _maxHorasDiarias = cfg['max_horas_diarias'] ?? 8;
          _maxHorasSemanales = cfg['max_horas_semanales'] ?? 40;
          _horarioCorte = cfg['hora_corte'] ?? '23:59';
          _claveRegistro = cfg['clave_registro'] ?? '';
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
      // Get gerente record id via auth user
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showSnack(_t('No hay sesión activa', 'No active session'), success: false);
        return;
      }
      final gerenteRow = await Supabase.instance.client
          .from('gerentes')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      final gerenteId = gerenteRow?['id'];

      final existing = gerenteId != null
          ? await Supabase.instance.client
              .from('configuracion')
              .select('id')
              .eq('gerente_id', gerenteId)
              .maybeSingle()
          : await Supabase.instance.client
              .from('configuracion')
              .select('id')
              .maybeSingle();

      final data = {
        'max_horas_diarias': _maxHorasDiarias,
        'max_horas_semanales': _maxHorasSemanales,
        'hora_corte': _horarioCorte,
        'updated_at': DateTime.now().toIso8601String(),
        if (gerenteId != null) 'gerente_id': gerenteId,
        if (_claveRegistro.isNotEmpty) 'clave_registro': _claveRegistro,
      };

      if (existing != null) {
        await Supabase.instance.client
            .from('configuracion')
            .update(data)
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('configuracion').insert(data);
      }
      _showSnack(_t('Configuración guardada', 'Settings saved'), success: true);
    } catch (e) {
      _showSnack('Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── i18n helper ─────────────────────────────────────────────────────────
  bool get _en => _idioma == 'en';
  String _t(String es, String en) => _en ? en : es;

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
    // Watch language so UI rebuilds when language changes
    final currentLang = context.watch<LanguageService>().languageCode;
    if (_idioma != currentLang) _idioma = currentLang;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ola inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 60),
              painter: _WavePainter(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
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
                                  title: _t('Límites de Horas', 'Hour Limits'),
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  children: [
                                    _SliderTile(
                                      label: _t('Horas máximas por día', 'Max hours per day'),
                                      value: _maxHorasDiarias.toDouble(),
                                      min: 4,
                                      max: 12,
                                      suffix: _t('h/día', 'h/day'),
                                      color: Theme.of(context).colorScheme.primary,
                                      onChanged: (v) => setState(
                                        () => _maxHorasDiarias = v.toInt(),
                                      ),
                                    ),
                                    _buildDivider(),
                                    _SliderTile(
                                      label: _t('Horas máximas por semana', 'Max hours per week'),
                                      value: _maxHorasSemanales.toDouble(),
                                      min: 20,
                                      max: 60,
                                      suffix: _t('h/sem', 'h/wk'),
                                      color: Theme.of(context).colorScheme.primary,
                                      onChanged: (v) => setState(
                                        () => _maxHorasSemanales = v.toInt(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.qr_code_scanner_rounded,
                                  title: _t('Configuración QR', 'QR Settings'),
                                  iconColor: const Color(0xFF00BFAE),
                                  children: [
                                    _SwitchTile(
                                      label: _t('Requerir ubicación al marcar', 'Require location on check-in'),
                                      sub: _t('Valida la posición GPS del empleado', 'Validates employee GPS position'),
                                      value: _qrUbicacion,
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      onChanged: (v) =>
                                          setState(() => _qrUbicacion = v),
                                    ),
                                    if (_qrUbicacion) ...[
                                      _buildDivider(),
                                      _SliderTile(
                                        label: _t('Radio permitido (metros)', 'Allowed radius (meters)'),
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
                                  icon: Icons.schedule_rounded,
                                  title: _t('Horario de Corte', 'Cut-off Time'),
                                  iconColor: const Color(0xFF7C4DFF),
                                  children: [_buildHorarioCorte()],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.vpn_key_rounded,
                                  title: _t('Clave de Registro Gerente', 'Manager Registration Key'),
                                  iconColor: const Color(0xFFE91E63),
                                  children: [_buildClaveRegistro()],
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.language_rounded,
                                  title: 'Idioma / Language',
                                  iconColor: const Color(0xFF10B981),
                                  children: [
                                    _buildLangOption('es', 'Español', '🇪🇸'),
                                    _buildDivider(),
                                    _buildLangOption('en', 'English', '🇺🇸'),
                                  ],
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _t('Configuración', 'Settings'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(90),
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
      title: _t('Apariencia', 'Appearance'),
      iconColor: Theme.of(context).colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Selecciona un tema', 'Select a theme'),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: _themes.entries.map((e) {
                  final cs = Theme.of(context).colorScheme;
                  final isSelected = _currentTheme == e.key;
                  final themeColor = e.value['color'] as Color;
                  return _ScaleButton(
                    onPressed: () => _cambiarTema(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withAlpha(20)
                            : cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.primary.withAlpha(50),
                          width: isSelected ? 2.0 : 1.4,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: cs.primary.withAlpha(45),
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
                            color: isSelected ? cs.primary : themeColor,
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
                                  ? cs.primary
                                  : cs.onSurface.withAlpha(150),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? cs.primary.withAlpha(40) : cs.primary.withAlpha(30),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(isDark ? 15 : 20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: cs.onSurface.withAlpha(20)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
  );

  Widget _buildLangOption(String code, String label, String flag) {
    final selected = _idioma == code;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _cambiarIdioma(code),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
          ],
        ),
      ),
    );
  }

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
              color: const Color(0xFF7C4DFF).withAlpha(25),
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
                Text(
                  _t('Hora de cierre', 'Cut-off time'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _horarioCorte,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
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
                builder: (ctx, child) => child!,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withAlpha(60),
                  width: 1.4,
                ),
              ),
              child: Text(
                _t('Cambiar', 'Change'),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Clave de registro ────────────────────────────────────────────────────

  Widget _buildClaveRegistro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Contraseña requerida para registrarse como gerente', 'Password required to register as manager'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _claveRegistro,
            onChanged: (v) => setState(() => _claveRegistro = v),
            decoration: InputDecoration(
              hintText: _t('Ej: MI-EMPRESA-2024', 'Ex: MY-COMPANY-2024'),
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(80)),
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: const Color(0xFFE91E63)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            _t('Deja vacío para deshabilitar registro como gerente', 'Leave empty to disable manager registration'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Botón guardar ────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _guardar,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withAlpha(90),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _t('Guardar Configuración', 'Save Settings'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
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
              inactiveTrackColor: color.withAlpha(38),
              thumbColor: color,
              overlayColor: color.withAlpha(38),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withAlpha(65),
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
  final Color color;
  const _WavePainter({required this.color});

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
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.color != color;
}
