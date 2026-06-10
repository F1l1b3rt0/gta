// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_strings.dart';
import '../../services/language_service.dart';
import '../../services/theme_notifier.dart';
import '../auth/login_view.dart';

class ConfiguracionEmpleadoView extends StatefulWidget {
  const ConfiguracionEmpleadoView({super.key});

  @override
  State<ConfiguracionEmpleadoView> createState() =>
      _ConfiguracionEmpleadoViewState();
}

class _ConfiguracionEmpleadoViewState extends State<ConfiguracionEmpleadoView>
    with SingleTickerProviderStateMixin {
  bool _notificacionesPush = true;
  bool _sonido = true;
  bool _vibrar = true;
  String _idioma = 'es';
  String _tema = 'claro';
  bool _isLoading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      if (!mounted) return;
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final langService = Provider.of<LanguageService>(context, listen: false);
      setState(() {
        _tema = themeNotifier.themeName;
        _idioma = langService.languageCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarTema(String nuevoTema, AppStrings s) async {
    setState(() => _tema = nuevoTema);
    await Provider.of<ThemeNotifier>(context, listen: false).setTheme(nuevoTema);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.themeChanged),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade400,
                        Colors.indigo.shade600,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  height: 200,
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // HEADER
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(200),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 18,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  s.configuration,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // CONTENIDO
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // APARIENCIA
                                _buildSectionCard(
                                  title: s.appearance,
                                  icon: Icons.palette_rounded,
                                  color: Colors.purple,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.brightness_6,
                                      title: s.theme,
                                      subtitle: _getTemaLabel(_tema, s),
                                      child: DropdownButton<String>(
                                        value: _tema,
                                        underline: const SizedBox(),
                                        dropdownColor: Theme.of(context).colorScheme.surface,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                        items: [
                                          DropdownMenuItem(
                                            value: 'claro',
                                            child: Text(s.themeLight),
                                          ),
                                          DropdownMenuItem(
                                            value: 'oscuro',
                                            child: Text(s.themeDark),
                                          ),
                                          const DropdownMenuItem(
                                            value: 'gta',
                                            child: Text('GTA'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) _cambiarTema(value, s);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // NOTIFICACIONES
                                _buildSectionCard(
                                  title: s.notifications,
                                  icon: Icons.notifications_rounded,
                                  color: Colors.orange,
                                  children: [
                                    _buildSwitchTile(
                                      icon: Icons.notifications_active,
                                      title: s.pushNotifications,
                                      subtitle: s.pushSubtitle,
                                      value: _notificacionesPush,
                                      onChanged: (v) => setState(() => _notificacionesPush = v),
                                    ),
                                    const Divider(height: 16),
                                    _buildSwitchTile(
                                      icon: Icons.volume_up_rounded,
                                      title: s.sound,
                                      subtitle: s.soundSubtitle,
                                      value: _sonido,
                                      onChanged: (v) => setState(() => _sonido = v),
                                    ),
                                    const Divider(height: 16),
                                    _buildSwitchTile(
                                      icon: Icons.vibration,
                                      title: s.vibration,
                                      subtitle: s.vibrationSubtitle,
                                      value: _vibrar,
                                      onChanged: (v) => setState(() => _vibrar = v),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // PREFERENCIAS
                                _buildSectionCard(
                                  title: s.preferences,
                                  icon: Icons.language_rounded,
                                  color: Colors.green,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.language,
                                      title: s.language,
                                      subtitle: s.currentLangLabel,
                                      child: Icon(Icons.chevron_right,
                                          color: Colors.grey.shade400),
                                      onTap: () => _mostrarDialogoIdioma(s),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // INFORMACIÓN
                                _buildSectionCard(
                                  title: s.information,
                                  icon: Icons.info_rounded,
                                  color: Colors.blue,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.info_outline,
                                      title: s.aboutGta,
                                      subtitle: '${s.version} 1.0.0',
                                      child: Icon(Icons.chevron_right,
                                          color: Colors.grey.shade400),
                                      onTap: () => _mostrarAcercaDe(s),
                                    ),
                                    const Divider(height: 16),
                                    _buildOptionTile(
                                      icon: Icons.privacy_tip_rounded,
                                      title: s.privacyPolicy,
                                      subtitle: s.privacySubtitle,
                                      child: Icon(Icons.chevron_right,
                                          color: Colors.grey.shade400),
                                      onTap: () => _mostrarPrivacidad(s),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _cerrarSesion(s),
                                    icon: const Icon(Icons.logout_rounded, size: 20),
                                    label: Text(s.logout),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: cs.primary.withAlpha(40), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? cs.primary.withAlpha(30) : Colors.grey.shade100;
    final iconColor = isDark ? cs.secondary : Colors.grey.shade700;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(140))),
              ],
            ),
          ),
          ?child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? cs.primary.withAlpha(30) : Colors.grey.shade100;
    final iconColor = isDark ? cs.secondary : Colors.grey.shade700;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withAlpha(140))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
          activeTrackColor: Colors.green.withAlpha(100),
        ),
      ],
    );
  }

  String _getTemaLabel(String tema, AppStrings s) {
    switch (tema) {
      case 'claro': return s.themeLight;
      case 'oscuro': return s.themeDark;
      case 'gta': return 'GTA';
      default: return s.themeLight;
    }
  }

  void _mostrarDialogoIdioma(AppStrings s) {
    final langService = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.selectLanguage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Radio<String>(
                value: 'es',
                groupValue: _idioma,
                activeColor: Colors.green,
                onChanged: (value) async {
                  setState(() => _idioma = value!);
                  Navigator.pop(dialogContext);
                  await langService.setLanguage('es');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.languageChanged('Español')),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              title: Text(s.spanish),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'en',
                groupValue: _idioma,
                activeColor: Colors.green,
                onChanged: (value) async {
                  setState(() => _idioma = value!);
                  Navigator.pop(dialogContext);
                  await langService.setLanguage('en');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.languageChanged('English')),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              title: Text(s.english),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAcercaDe(AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.aboutGta),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.qr_code, size: 60, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            const Text('GTA',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Gestión de Turnos y Asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('${s.version} 1.0.0'),
            const SizedBox(height: 8),
            const Text('© 2024 GTA App'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _mostrarPrivacidad(AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.privacyPolicy),
        content: SingleChildScrollView(
          child: Text(
            s.privacyText,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion(AppStrings s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logoutTitle),
        content: Text(s.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: Text(s.exit),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: Colors.red.shade600),
          );
        }
      }
    }
  }
}
