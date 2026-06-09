// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/theme_service.dart';
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
      final tema = await ThemeService.loadTheme();
      setState(() {
        _tema = tema;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarTema(String nuevoTema) async {
    setState(() => _tema = nuevoTema);
    await ThemeService.saveTheme(nuevoTema);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Tema cambiado correctamente'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Fondo con gradiente
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
                          // ========== HEADER ==========
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
                                const Text(
                                  'Configuración',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ========== CONTENIDO ==========
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // ========== SECCIÓN APARIENCIA ==========
                                _buildSectionCard(
                                  title: 'Apariencia',
                                  icon: Icons.palette_rounded,
                                  color: Colors.purple,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.brightness_6,
                                      title: 'Tema',
                                      subtitle: _getTemaLabel(_tema),
                                      child: DropdownButton<String>(
                                        value: _tema,
                                        underline: const SizedBox(),
                                        dropdownColor: Colors.white,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'claro',
                                            child: Text('Claro'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'oscuro',
                                            child: Text('Oscuro'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'gta',
                                            child: Text('GTA'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'lite',
                                            child: Text('Lite'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            _cambiarTema(value);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // ========== SECCIÓN NOTIFICACIONES ==========
                                _buildSectionCard(
                                  title: 'Notificaciones',
                                  icon: Icons.notifications_rounded,
                                  color: Colors.orange,
                                  children: [
                                    _buildSwitchTile(
                                      icon: Icons.notifications_active,
                                      title: 'Notificaciones Push',
                                      subtitle: 'Recibir alertas del sistema',
                                      value: _notificacionesPush,
                                      onChanged: (value) {
                                        setState(
                                          () => _notificacionesPush = value,
                                        );
                                        _guardarPreferencia(
                                          'notificaciones',
                                          value,
                                        );
                                      },
                                    ),
                                    const Divider(height: 16),
                                    _buildSwitchTile(
                                      icon: Icons.volume_up_rounded,
                                      title: 'Sonido',
                                      subtitle:
                                          'Reproducir sonido en notificaciones',
                                      value: _sonido,
                                      onChanged: (value) {
                                        setState(() => _sonido = value);
                                        _guardarPreferencia('sonido', value);
                                      },
                                    ),
                                    const Divider(height: 16),
                                    _buildSwitchTile(
                                      icon: Icons.vibration,
                                      title: 'Vibración',
                                      subtitle:
                                          'Vibrar al recibir notificaciones',
                                      value: _vibrar,
                                      onChanged: (value) {
                                        setState(() => _vibrar = value);
                                        _guardarPreferencia('vibrar', value);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // ========== SECCIÓN PREFERENCIAS ==========
                                _buildSectionCard(
                                  title: 'Preferencias',
                                  icon: Icons.language_rounded,
                                  color: Colors.green,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.language,
                                      title: 'Idioma',
                                      subtitle: _idioma == 'es'
                                          ? 'Español'
                                          : 'English',
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade400,
                                      ),
                                      onTap: () => _mostrarDialogoIdioma(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // ========== SECCIÓN INFORMACIÓN ==========
                                _buildSectionCard(
                                  title: 'Información',
                                  icon: Icons.info_rounded,
                                  color: Colors.blue,
                                  children: [
                                    _buildOptionTile(
                                      icon: Icons.info_outline,
                                      title: 'Acerca de GTA',
                                      subtitle: 'Versión 1.0.0',
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade400,
                                      ),
                                      onTap: () => _mostrarAcercaDe(),
                                    ),
                                    const Divider(height: 16),
                                    _buildOptionTile(
                                      icon: Icons.privacy_tip_rounded,
                                      title: 'Política de Privacidad',
                                      subtitle: 'Ver términos y condiciones',
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade400,
                                      ),
                                      onTap: () => _mostrarPrivacidad(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                // ========== BOTÓN CERRAR SESIÓN ==========
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _cerrarSesion,
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('Cerrar Sesión'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
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
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a1a1a),
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
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
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

  String _getTemaLabel(String tema) {
    switch (tema) {
      case 'claro':
        return 'Claro';
      case 'oscuro':
        return 'Oscuro';
      case 'gta':
        return 'GTA';
      case 'lite':
        return 'Lite';
      default:
        return 'Claro';
    }
  }

  void _guardarPreferencia(String key, bool value) {
    // Aquí se puede guardar en SharedPreferences o en la base de datos
    debugPrint('Guardando $key: $value');
  }

  void _mostrarDialogoIdioma() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Radio<String>(
                value: 'es',
                groupValue: _idioma,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => _idioma = value!);
                  Navigator.pop(context);
                },
              ),
              title: const Text('Español'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'en',
                groupValue: _idioma,
                activeColor: Colors.green,
                onChanged: (value) {
                  setState(() => _idioma = value!);
                  Navigator.pop(context);
                },
              ),
              title: const Text('English'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Acerca de GTA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.qr_code,
                size: 60,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'GTA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestión de Turnos y Asistencia',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Versión 1.0.0'),
            const SizedBox(height: 8),
            const Text('© 2024 GTA App'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarPrivacidad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Política de Privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'GTA se compromete a proteger tu privacidad. Tus datos personales '
            'son utilizados únicamente para la gestión de horarios y asistencia. '
            'No compartimos tu información con terceros sin tu consentimiento.\n\n'
            'Tus datos están protegidos con los más altos estándares de seguridad.',
            style: TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Salir'),
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
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }
}
