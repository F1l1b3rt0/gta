// lib/views/gerente/gerente_home_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';
import '../auth/login_view.dart';
import 'alertas_view.dart';
import 'configuracion_view.dart';
import 'empleados_view.dart';
import 'estadisticas_view.dart';
import 'gestion_horarios_view.dart';
import 'asistencias_view.dart';
import 'gerente_chat_view.dart';

class GerenteHomeView extends StatefulWidget {
  const GerenteHomeView({super.key});

  @override
  State<GerenteHomeView> createState() => _GerenteHomeViewState();
}

class _GerenteHomeViewState extends State<GerenteHomeView> {
  int _selectedIndex = 0;
  String _nombre = '';
  String _avatarUrl = '';
  bool _isLoading = true;


  static const _navIcons = [
    Icons.home_rounded,
    Icons.people_rounded,
    Icons.calendar_month_rounded,
    Icons.bar_chart_rounded,
    Icons.notifications_rounded,
    Icons.chat_bubble_rounded,
    Icons.settings_rounded,
  ];

  // _navLabels is now dynamic — built in build() via _buildLabels(context)
  static const _navLabels = <String>[]; // unused placeholder

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final emp = await Supabase.instance.client
            .from('empleados')
            .select('nombre, avatar_url')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _nombre = emp['nombre'] ?? 'Gerente';
            _avatarUrl = emp['avatar_url'] ?? '';
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context, 'Cerrar Sesión', 'Log Out')),
        content: Text(tr(context, '¿Deseas cerrar sesión?', 'Do you want to log out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(context, 'Cancelar', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'Salir', 'Exit')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (_) => false,
        );
      }
    }
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  List<String> _buildLabels(BuildContext context) => [
    tr(context, 'Inicio', 'Home'),
    tr(context, 'Empleados', 'Employees'),
    tr(context, 'Horarios', 'Schedules'),
    tr(context, 'Estadísticas', 'Statistics'),
    tr(context, 'Alertas', 'Alerts'),
    'Chat',
    tr(context, 'Config', 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        body: Row(
          children: [
            // Glass nav rail
            _GerenteNavRail(
              selectedIndex: _selectedIndex,
              icons: _navIcons,
              labels: _buildLabels(context),
              nombre: _nombre,
              avatarUrl: _avatarUrl,
              cs: cs,
              isDark: isDark,
              onTap: _selectTab,
              onLogout: _cerrarSesion,
            ),
            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _GerenteDashboard(
                    nombre: _nombre,
                    cs: cs,
                    isDark: isDark,
                    onTabSelect: _selectTab,
                    onQrTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AsistenciasView()),
                    ),
                  ),
                  EmpleadosView(),
                  GestionHorariosView(),
                  EstadisticasView(),
                  AlertasView(),
                  const GerenteChatView(),
                  ConfiguracionView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Nav Rail (Gerente) ─────────────────────────────────────────────────

class _GerenteNavRail extends StatelessWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final List<String> labels;
  final String nombre;
  final String avatarUrl;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _GerenteNavRail({
    required this.selectedIndex,
    required this.icons,
    required this.labels,
    required this.nombre,
    required this.avatarUrl,
    required this.cs,
    required this.isDark,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 68,
          decoration: BoxDecoration(
            color: isDark
                ? cs.surface.withAlpha(200)
                : Colors.white.withAlpha(220),
            border: Border(
              right: BorderSide(color: cs.primary.withAlpha(isDark ? 35 : 25)),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar initials
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.primary.withAlpha(35),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'G',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'GERENTE', 'MANAGER'),
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: cs.primary.withAlpha(180),
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 20,
                  height: 1,
                  color: cs.primary.withAlpha(40),
                ),
                // Nav items (scrollable for 7 items)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      children: List.generate(
                        icons.length,
                        (i) => _RailItem(
                          icon: icons[i],
                          label: labels[i],
                          isSelected: selectedIndex == i,
                          cs: cs,
                          isDark: isDark,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onLogout,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.logout_rounded,
                          color: Colors.red.shade400, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.cs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
          width: 48,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withAlpha(isDark ? 45 : 30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurface.withAlpha(100),
                size: 21,
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Gerente Dashboard Page ───────────────────────────────────────────────────

class _GerenteDashboard extends StatefulWidget {
  final String nombre;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onQrTap;

  const _GerenteDashboard({
    required this.nombre,
    required this.cs,
    required this.isDark,
    required this.onTabSelect,
    required this.onQrTap,
  });

  @override
  State<_GerenteDashboard> createState() => _GerenteDashboardState();
}

class _GerenteDashboardState extends State<_GerenteDashboard> {
  int _totalEmpleados = 0;
  int _tardanzasHoy = 0;
  int _registradosHoy = 0;

  @override
  void initState() {
    super.initState();
    _cargarStats();
  }

  Future<void> _cargarStats() async {
    try {
      final emps = await Supabase.instance.client.from('empleados').select('id');
      final hoy = DateTime.now();
      final hoyStr = '${hoy.year}-${hoy.month.toString().padLeft(2,'0')}-${hoy.day.toString().padLeft(2,'0')}';
      final tardanzas = await Supabase.instance.client
          .from('asistencias').select('id').eq('estado', 'tardanza').eq('fecha', hoyStr);
      final registrados = await Supabase.instance.client
          .from('asistencias').select('id')
          .eq('fecha', hoyStr)
          .neq('estado', 'falta');
      if (mounted) setState(() {
        _totalEmpleados = (emps as List).length;
        _tardanzasHoy = (tardanzas as List).length;
        _registradosHoy = (registrados as List).length;
      });
    } catch (_) {}
  }

  String _greeting(BuildContext context) {
    final h = DateTime.now().hour;
    final en = context.read<LanguageService>().languageCode == 'en';
    if (h < 12) return en ? 'Good morning' : 'Buenos días';
    if (h < 19) return en ? 'Good afternoon' : 'Buenas tardes';
    return en ? 'Good evening' : 'Buenas noches';
  }

  String _formatDate(BuildContext context) {
    final d = DateTime.now();
    final en = context.read<LanguageService>().languageCode == 'en';
    const daysEs = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const daysEn = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const monthsEs = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    const monthsEn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = en ? daysEn : daysEs;
    final months = en ? monthsEn : monthsEs;
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    final cs = widget.cs;
    final isDark = widget.isDark;
    final actions = [
      _GAction(Icons.people_rounded, tr(context, 'Empleados', 'Employees'),
          const Color(0xFF6366F1), () => widget.onTabSelect(1)),
      _GAction(Icons.calendar_month_rounded, tr(context, 'Horarios', 'Schedules'),
          const Color(0xFFEC4899), () => widget.onTabSelect(2)),
      _GAction(Icons.bar_chart_rounded, tr(context, 'Estadísticas', 'Statistics'),
          const Color(0xFFF97316), () => widget.onTabSelect(3)),
      _GAction(Icons.notifications_rounded, tr(context, 'Alertas', 'Alerts'),
          const Color(0xFFEF4444), () => widget.onTabSelect(4)),
      _GAction(Icons.chat_bubble_rounded, 'Chat',
          const Color(0xFF10B981), () => widget.onTabSelect(5)),
      _GAction(Icons.qr_code_scanner_rounded, tr(context, 'Escanear QR', 'Scan QR'),
          const Color(0xFF0EA5E9), widget.onQrTap),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(context),
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withAlpha(130),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nombre,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(context),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(90),
              ),
            ),
            const SizedBox(height: 20),

            // Summary cards row
            Row(
              children: [
                _StatCard(
                  label: tr(context, 'Empleados', 'Employees'),
                  value: '$_totalEmpleados',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF6366F1),
                  cs: cs,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: tr(context, 'Tardanzas hoy', "Late today"),
                  value: '$_tardanzasHoy',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFFF9800),
                  cs: cs,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: tr(context, 'Registrados hoy', 'Checked in'),
                  value: '$_registradosHoy',
                  icon: Icons.how_to_reg_rounded,
                  color: const Color(0xFF00C853),
                  cs: cs,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              tr(context, 'PANEL DE CONTROL', 'CONTROL PANEL'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withAlpha(100),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: actions
                  .map((a) => _GActionCard(action: a, cs: cs, isDark: isDark))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              isDark ? Border.all(color: cs.primary.withAlpha(25)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 6),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withAlpha(110),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GAction(this.icon, this.label, this.color, this.onTap);
}

class _GActionCard extends StatelessWidget {
  final _GAction action;
  final ColorScheme cs;
  final bool isDark;

  const _GActionCard(
      {required this.action, required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              isDark ? Border.all(color: cs.primary.withAlpha(25)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 8),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const Spacer(),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
