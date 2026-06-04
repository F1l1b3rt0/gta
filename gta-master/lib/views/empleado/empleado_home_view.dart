import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'mi_horario_view.dart';
import 'qr_scanner_view.dart';
import 'mis_horas_view.dart';
// import 'mis_alertas_screen.dart';
import '../auth/login_view.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const primary      = Color(0xFF1A6FE8);
  static const primaryLight = Color(0xFF4D96FF);
  static const accent       = Color(0xFF00CFFF);
  static const text         = Color(0xFF0D1B3E);
  static const textSub      = Color(0xFF6B80A3);
  static const divider      = Color(0xFFE0ECFF);
  static const shadow       = Color(0x201A6FE8);
  static const success      = Color(0xFF00C853);
}

class EmpleadoHomeScreen extends StatefulWidget {
  const EmpleadoHomeScreen({super.key});

  @override
  State<EmpleadoHomeScreen> createState() => _EmpleadoHomeScreenState();
}

class _EmpleadoHomeScreenState extends State<EmpleadoHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  String _nombreEmpleado = '';
  String _rol = '';
  double _salarioPorHora = 0;
  bool _isLoading = true;
  bool _tieneTurnoHoy = false;
  bool _yaMarcoEntrada = false;

  late AnimationController _waveCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _contentOpacity;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut),
    );
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );

    _cargarDatos();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('empleados')
            .select('nombre, rol, salario_por_hora')
            .eq('id', user.id)
            .single();
        setState(() {
          _nombreEmpleado  = response['nombre'];
          _rol             = response['rol'];
          _salarioPorHora  = (response['salario_por_hora'] ?? 0).toDouble();
        });
        await _verificarEstadoHoy();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      _contentCtrl.forward(from: 0);
    }
  }

  Future<void> _verificarEstadoHoy() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final turno = await Supabase.instance.client
        .from('turnos')
        .select()
        .eq('empleado_id', user.id)
        .gte('entrada', '$hoy 00:00:00')
        .lte('entrada', '$hoy 23:59:59')
        .maybeSingle();
    if (mounted) {
      setState(() {
        _tieneTurnoHoy   = turno != null;
        _yaMarcoEntrada  = turno != null && turno['salida'] == null;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.w700, color: _C.text)),
        content: const Text('¿Seguro que deseas cerrar sesión?',
            style: TextStyle(color: _C.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _C.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  PageRoute _route(Widget page) => MaterialPageRoute(builder: (_) => page);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Orbes decorativos
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, _) => Transform.scale(
                scale: 1.0 + 0.04 * sin(_waveCtrl.value * 2 * pi),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _C.primaryLight.withOpacity(0.18),
                      _C.primary.withOpacity(0.06),
                      Colors.transparent,
                    ]),
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
                gradient: RadialGradient(colors: [
                  _C.accent.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _C.primary))
                : Column(
                    children: [
                      _buildAppBar(),
                      Expanded(
                        child: RefreshIndicator(
                          color: _C.primary,
                          onRefresh: _cargarDatos,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                            child: AnimatedBuilder(
                              animation: _contentCtrl,
                              builder: (_, _) => Opacity(
                                opacity: _contentOpacity.value,
                                child: Transform.translate(
                                  offset: Offset(0, _contentSlide.value),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      _buildHeader(),
                                      const SizedBox(height: 20),
                                      _buildStatusCard(),
                                      const SizedBox(height: 28),
                                      _buildSectionLabel('Mis acciones'),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primary, _C.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                color: _C.primary.withOpacity(0.35),
                blurRadius: 12, offset: const Offset(0, 4),
              )],
            ),
            child: const Text('GTA',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: 3,
              ),
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.refresh_rounded,
            onTap: _cargarDatos,
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
    final initial = _nombreEmpleado.isNotEmpty ? _nombreEmpleado[0].toUpperCase() : 'E';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.primary, _C.primaryLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: _C.primary.withOpacity(0.30),
          blurRadius: 24, offset: const Offset(0, 8),
        )],
      ),
      child: Row(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.20),
              border: Border.all(color: Colors.white.withOpacity(0.50), width: 2),
            ),
            child: Center(
              child: Text(initial, style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saludo, style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.80), letterSpacing: 0.5,
                )),
                const SizedBox(height: 4),
                Text(
                  _nombreEmpleado.isNotEmpty ? _nombreEmpleado : 'Empleado',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _rol == 'gerente' ? '● Gerente' : '● Empleado',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${_salarioPorHora.toStringAsFixed(2)}/h',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Card ─────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusSub;

    if (!_tieneTurnoHoy) {
      statusColor = _C.textSub;
      statusIcon  = Icons.event_busy_rounded;
      statusTitle = 'Sin turno hoy';
      statusSub   = 'No tienes turno asignado para hoy';
    } else if (_yaMarcoEntrada) {
      statusColor = _C.success;
      statusIcon  = Icons.check_circle_rounded;
      statusTitle = 'Turno en curso';
      statusSub   = 'Has marcado tu entrada · escanea para salir';
    } else {
      statusColor = const Color(0xFFFF9800);
      statusIcon  = Icons.schedule_rounded;
      statusTitle = 'Turno pendiente';
      statusSub   = 'Escanea el QR para marcar tu entrada';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.4),
        boxShadow: [BoxShadow(
          color: statusColor.withOpacity(0.10),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: statusColor,
                )),
                const SizedBox(height: 3),
                Text(statusSub, style: const TextStyle(
                  fontSize: 12, color: _C.textSub,
                )),
              ],
            ),
          ),
          if (_tieneTurnoHoy)
            GestureDetector(
              onTap: () => Navigator.push(
                context, _route(const QRScannerScreen()),
              ).then((_) => _verificarEstadoHoy()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: statusColor.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 3),
                  )],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Marcar', style: TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Grid ────────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: _C.textSub, letterSpacing: 2.0,
    ));
  }

  Widget _buildGrid() {
    final items = [
      _MenuItem(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Registrar',
        subtitle: 'Entrada / Salida',
        color: _C.primary,
        onTap: () => Navigator.push(context, _route(const QRScannerScreen()))
            .then((_) => _verificarEstadoHoy()),
      ),
      _MenuItem(
        icon: Icons.calendar_month_rounded,
        title: 'Mi Horario',
        subtitle: 'Ver mis turnos',
        color: const Color(0xFFFF9800),
        onTap: () => Navigator.push(context, _route(const MiHorarioScreen())),
      ),
      _MenuItem(
        icon: Icons.timer_rounded,
        title: 'Mis Horas',
        subtitle: 'Horas trabajadas',
        color: const Color(0xFF7C4DFF),
        onTap: () => Navigator.push(context, _route(const MisHorasScreen())),
      ),
      /*_MenuItem(
        icon: Icons.notifications_active_rounded,
        title: 'Mis Alertas',
        subtitle: 'Notificaciones',
        color: const Color(0xFFE53935),
        onTap: () => Navigator.push(context, _route(const MisAlertasScreen())),
      ),*/
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
      itemBuilder: (_, i) => _MenuCard(item: items[i], delay: i * 80),
    );
  }

  // ─── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _C.bg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.primary, _C.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.20),
                    border: Border.all(color: Colors.white.withOpacity(0.50), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _nombreEmpleado.isNotEmpty ? _nombreEmpleado[0].toUpperCase() : 'E',
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(_nombreEmpleado.isNotEmpty ? _nombreEmpleado : 'Empleado',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Empleado · GTA',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DrawerItem(Icons.home_rounded, 'Inicio', () => Navigator.pop(context)),
          _DrawerItem(Icons.qr_code_scanner_rounded, 'Registrar Asistencia', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const QRScannerScreen()))
                .then((_) => _verificarEstadoHoy());
          }),
          _DrawerItem(Icons.calendar_month_rounded, 'Mi Horario', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const MiHorarioScreen()));
          }),
          _DrawerItem(Icons.timer_rounded, 'Mis Horas', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const MisHorasScreen()));
          }),
          /*_DrawerItem(Icons.notifications_rounded, 'Mis Alertas', () {
            Navigator.pop(context);
            Navigator.push(context, _route(const MisAlertasScreen()));
          }),*/
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
                    Text('Cerrar sesión',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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

  const _IconBtn({required this.icon, required this.onTap, this.color = _C.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.divider, width: 1.2),
          boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 8, offset: Offset(0, 2))],
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
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: _C.primary),
      ),
      title: Text(title, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: _C.text,
      )),
      onTap: onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
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
  late Animation<double> _opacity, _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
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
                      : _C.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _pressed
                        ? widget.item.color.withOpacity(0.40)
                        : _C.divider,
                    width: 1.4,
                  ),
                  boxShadow: [BoxShadow(
                    color: _pressed
                        ? widget.item.color.withOpacity(0.20)
                        : _C.shadow,
                    blurRadius: _pressed ? 20 : 10,
                    offset: const Offset(0, 4),
                  )],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.item.icon, size: 24, color: widget.item.color),
                    ),
                    const SizedBox(height: 14),
                    Text(widget.item.title, style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: _C.text, letterSpacing: 0.1,
                    )),
                    const SizedBox(height: 3),
                    Text(widget.item.subtitle, style: const TextStyle(
                      fontSize: 11, color: _C.textSub,
                    )),
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