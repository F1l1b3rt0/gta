// ignore_for_file: unused_field

import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'gestion_horarios_view.dart';
import 'reportes_nomina_view.dart';
import 'configuracion_view.dart';
import 'empleados_view.dart';
import 'estadisticas_view.dart';
import 'alertas_view.dart';
import '../auth/login_view.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
class AppColors {
  static const background   = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const surfaceCard  = Color(0xFFFFFFFF);
  static const primary      = Color(0xFF1A6FE8);
  static const primaryLight = Color(0xFF4D96FF);
  static const primaryDark  = Color(0xFF0D47A1);
  static const accent       = Color(0xFF00CFFF);
  static const textPrimary  = Color(0xFF0D1B3E);
  static const textSecondary= Color(0xFF6B80A3);
  static const divider      = Color(0xFFE0ECFF);
  static const shadowBlue   = Color(0x201A6FE8);
  static const shadowDeep   = Color(0x401A6FE8);
}

class GerenteHomeScreen extends StatefulWidget {
  const GerenteHomeScreen({super.key});

  @override
  State<GerenteHomeScreen> createState() => _GerenteHomeScreenState();
}

class _GerenteHomeScreenState extends State<GerenteHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String _nombreGerente = '';
  int _alertasNoLeidas = 0;

  late AnimationController _contentController;
  late AnimationController _waveController;
  late Animation<double> _contentOpacity;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _contentController.forward();
    });

    _cargarNombre();
    _cargarAlertas();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombre() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('empleados')
          .select('nombre')
          .eq('id', user.id)
          .single();
      if (mounted) {
        setState(() => _nombreGerente = response['nombre']);
      }
    }
  }

  Future<void> _cargarAlertas() async {
    try {
      final alertas = await Supabase.instance.client
          .from('alertas')
          .select('id')
          .eq('leida', false);
      if (mounted) setState(() => _alertasNoLeidas = alertas.length);
    } catch (_) {}
  }


Future<void> _cerrarSesion() async {
  // Diálogo de confirmación
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cerrar Sesión'),
      content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    ),
  );
  
  if (confirm != true) return;
  
  try {
    // Cerrar sesión
    await Supabase.instance.client.auth.signOut();
    
    if (mounted) {
      // Redirigir al login y limpiar historial
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    print('Error al cerrar sesión: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Decoración superior suave
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (_, _) => Transform.scale(
                scale: 1.0 + 0.04 * sin(_waveController.value * 2 * pi),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withOpacity(0.18),
                        AppColors.primary.withOpacity(0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                    child: AnimatedBuilder(
                      animation: _contentController,
                      builder: (_, _) => Opacity(
                        opacity: _contentOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _contentSlide.value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _buildHeader(),
                              const SizedBox(height: 32),
                              _buildSectionLabel('Panel de control'),
                              const SizedBox(height: 14),
                              _buildGrid(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
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

  // ─── AppBar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => _IconBtn(
              icon: Icons.menu_rounded,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 12),
          // Logo / Brand
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'GTA',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          // Badge alertas
          Stack(
            clipBehavior: Clip.none,
            children: [
              _IconBtn(
                icon: Icons.notifications_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertasScreen()),
                ),
              ),
              if (_alertasNoLeidas > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$_alertasNoLeidas',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.logout_rounded,
            onTap: _cerrarSesion,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hora = DateTime.now().hour;
    final saludo = hora < 12 ? 'Buenos días' : hora < 19 ? 'Buenas tardes' : 'Buenas noches';
    final initial = _nombreGerente.isNotEmpty ? _nombreGerente[0].toUpperCase() : 'G';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.20),
              border: Border.all(color: Colors.white.withOpacity(0.50), width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.80),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nombreGerente.isNotEmpty ? _nombreGerente : 'Gerente',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '● Gerente de turno',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 2.0,
      ),
    );
  }

  // ─── Grid de tarjetas ────────────────────────────────────────────────────────

  Widget _buildGrid() {
    final items = [
      _MenuItem(
        icon: Icons.group_rounded,
        title: 'Empleados',
        subtitle: 'Gestiona tu equipo',
        color: const Color(0xFF1A6FE8),
        onTap: () => Navigator.push(context, _route(const EmpleadosScreen())),
      ),
      _MenuItem(
        icon: Icons.calendar_month_rounded,
        title: 'Horarios',
        subtitle: 'Planifica turnos',
        color: const Color(0xFF00BFAE),
        onTap: () => Navigator.push(context, _route(const GestionHorariosScreen())),
      ),
      _MenuItem(
        icon: Icons.bar_chart_rounded,
        title: 'Estadísticas',
        subtitle: 'Métricas clave',
        color: const Color(0xFF7C4DFF),
        onTap: () => Navigator.push(context, _route(const EstadisticasScreen())),
      ),
      _MenuItem(
        icon: Icons.receipt_long_rounded,
        title: 'Nómina',
        subtitle: 'Reportes y pagos',
        color: const Color(0xFF00C853),
        onTap: () => Navigator.push(context, _route(const ReportesNominaScreen())),
      ),
      _MenuItem(
        icon: Icons.notifications_active_rounded,
        title: 'Alertas',
        subtitle: '$_alertasNoLeidas sin leer',
        color: const Color(0xFFFF6D00),
        onTap: () => Navigator.push(context, _route(const AlertasScreen())),
      ),
      _MenuItem(
        icon: Icons.tune_rounded,
        title: 'Configuración',
        subtitle: 'Ajustes del sistema',
        color: const Color(0xFF546E7A),
        onTap: () => Navigator.push(context, _route(const ConfiguracionScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuCard(item: items[i], delay: i * 80),
    );
  }

  PageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);

  // ─── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  _nombreGerente.isNotEmpty ? _nombreGerente : 'Gerente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gerente · GTA',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DrawerItem(Icons.group_rounded, 'Empleados', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const EmpleadosScreen()));
          }),
          _DrawerItem(Icons.calendar_month_rounded, 'Gestión de Horarios', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const GestionHorariosScreen()));
          }),
          _DrawerItem(Icons.bar_chart_rounded, 'Estadísticas', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const EstadisticasScreen()));
          }),
          _DrawerItem(Icons.receipt_long_rounded, 'Reportes de Nómina', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const ReportesNominaScreen()));
          }),
          _DrawerItem(Icons.notifications_rounded, 'Alertas', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const AlertasScreen()));
          }),
          _DrawerItem(Icons.tune_rounded, 'Configuración', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const ConfiguracionScreen()));
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _cerrarSesion,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlue,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem(this.icon, this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  final int delay;

  const _MenuCard({required this.item, required this.delay});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    Future.delayed(Duration(milliseconds: widget.delay + 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.item.onTap,
            child: AnimatedScale(
              scale: _pressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _pressed
                      ? widget.item.color.withOpacity(0.06)
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _pressed
                        ? widget.item.color.withOpacity(0.40)
                        : AppColors.divider,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _pressed
                          ? widget.item.color.withOpacity(0.20)
                          : AppColors.shadowBlue,
                      blurRadius: _pressed ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.item.icon, size: 24, color: widget.item.color),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}