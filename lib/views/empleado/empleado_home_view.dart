// lib/views/empleado/empleado_home_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/app_strings.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';
import '../auth/login_view.dart';
import 'chat_view.dart';
import 'configuracion_view.dart';
import 'mi_horario_view.dart';
import 'mis_horas_view.dart';
import 'perfil_empleado_view.dart';
import 'mi_qr_view.dart';

class EmpleadoHomeView extends StatefulWidget {
  const EmpleadoHomeView({super.key});

  @override
  State<EmpleadoHomeView> createState() => _EmpleadoHomeViewState();
}

class _EmpleadoHomeViewState extends State<EmpleadoHomeView> {
  int _selectedIndex = 0;
  String _nombre = '';
  String _avatarUrl = '';
  bool _isLoading = true;


  static const _navIcons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.calendar_month_rounded,
    Icons.timer_rounded,
    Icons.settings_rounded,
  ];

  // dynamic nav labels — built in build()
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
            _nombre = emp['nombre'] ?? 'Empleado';
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
    // Use read (not watch) — watch can only be called inside build()
    final lang = context.read<LanguageService>().languageCode;
    final s = AppStrings(lang);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.exit),
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
    'Chat',
    tr(context, 'Horario', 'Schedule'),
    tr(context, 'Horas', 'Hours'),
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
            _GlassNavRail(
              selectedIndex: _selectedIndex,
              icons: _navIcons,
              labels: _buildLabels(context),
              nombre: _nombre,
              avatarUrl: _avatarUrl,
              cs: cs,
              isDark: isDark,
              onTap: _selectTab,
              onAvatarTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilEmpleadoView()),
              ),
              onLogout: _cerrarSesion,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _DashboardPage(
                    nombre: _nombre,
                    avatarUrl: _avatarUrl,
                    cs: cs,
                    isDark: isDark,
                    onTabSelect: _selectTab,
                    onProfileTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PerfilEmpleadoView()),
                    ),
                  ),
                  const ChatView(),
                  const MiHorarioView(),
                  MisHorasView(),
                  const ConfiguracionEmpleadoView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Nav Rail ───────────────────────────────────────────────────────────

class _GlassNavRail extends StatelessWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final List<String> labels;
  final String nombre;
  final String avatarUrl;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<int> onTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onLogout;

  const _GlassNavRail({
    required this.selectedIndex,
    required this.icons,
    required this.labels,
    required this.nombre,
    required this.avatarUrl,
    required this.cs,
    required this.isDark,
    required this.onTap,
    required this.onAvatarTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 54,
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
                GestureDetector(
                  onTap: onAvatarTap,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: cs.primary.withAlpha(35),
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            nombre.isNotEmpty
                                ? nombre[0].toUpperCase()
                                : 'E',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      icons.length,
                      (i) => _NavItem(
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
                      child:
                          Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
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
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withAlpha(isDark ? 45 : 30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withAlpha(100),
                size: 22,
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 12,
                  bottom: 12,
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

// ─── Dashboard Page ───────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  final String nombre;
  final String avatarUrl;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<int> onTabSelect;
  final VoidCallback onProfileTap;

  const _DashboardPage({
    required this.nombre,
    required this.avatarUrl,
    required this.cs,
    required this.isDark,
    required this.onTabSelect,
    required this.onProfileTap,
  });

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
    final actions = [
      _Action(Icons.person_rounded, tr(context, 'Mi Perfil', 'My Profile'), const Color(0xFF6366F1),
          onProfileTap),
      _Action(Icons.calendar_month_rounded, tr(context, 'Horario', 'Schedule'),
          const Color(0xFFEC4899), () => onTabSelect(2)),
      _Action(Icons.timer_rounded, tr(context, 'Mis Horas', 'My Hours'), const Color(0xFFF97316),
          () => onTabSelect(3)),
      _Action(Icons.chat_bubble_rounded, 'Chat', const Color(0xFF10B981),
          () => onTabSelect(1)),
      _Action(Icons.qr_code_rounded, tr(context, 'Mi QR', 'My QR'), const Color(0xFF8B5CF6),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiQrView()))),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
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
              nombre,
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

            // ── Status card ──
            _StatusCard(cs: cs, isDark: isDark, onVerHorario: () => onTabSelect(2)),
            const SizedBox(height: 20),

            // ── Quick actions ──
            Text(
              tr(context, 'ACCESO RÁPIDO', 'QUICK ACCESS'),
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
                  .map((a) => _ActionCard(action: a, cs: cs, isDark: isDark))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatefulWidget {
  final ColorScheme cs;
  final bool isDark;
  final VoidCallback onVerHorario;

  const _StatusCard({required this.cs, required this.isDark, required this.onVerHorario});

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  Map<String, dynamic>? _turnoHoy;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargarTurnoHoy();
  }

  Future<void> _cargarTurnoHoy() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) { setState(() => _loaded = true); return; }
      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = inicio.add(const Duration(days: 1));
      final res = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lt('entrada', fin.toIso8601String())
          .order('entrada')
          .limit(1);
      if (mounted) setState(() { _turnoHoy = res.isNotEmpty ? res.first : null; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    final cs = widget.cs;
    final en = context.read<LanguageService>().languageCode == 'en';
    String statusText;
    String subText;
    if (!_loaded) {
      statusText = '...';
      subText = '';
    } else if (_turnoHoy == null) {
      statusText = en ? 'No shift today' : 'Sin turno hoy';
      subText = en ? 'No shifts assigned' : 'No tienes turnos asignados';
    } else {
      final entrada = DateTime.parse(_turnoHoy!['entrada']);
      var salida = _turnoHoy!['salida'] != null ? DateTime.parse(_turnoHoy!['salida']) : null;
      final hh = entrada.hour.toString().padLeft(2, '0');
      final mm = entrada.minute.toString().padLeft(2, '0');
      statusText = en ? 'Shift: $hh:$mm' : 'Turno: $hh:$mm';
      if (salida != null) {
        final sh = salida.hour.toString().padLeft(2, '0');
        final sm = salida.minute.toString().padLeft(2, '0');
        subText = en ? 'Until $sh:$sm' : 'Hasta las $sh:$sm';
      } else {
        subText = en ? 'In progress' : 'En curso';
      }
    }

    return GestureDetector(
      onTap: widget.onVerHorario,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, cs.primary.withAlpha(200)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: cs.primary.withAlpha(80), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(context, 'Estado hoy', 'Today\'s status'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Text(statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  if (subText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subText, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tr(context, 'Ver horario →', 'View schedule →'),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.work_history_rounded, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Action(this.icon, this.label, this.color, this.onTap);
}

class _ActionCard extends StatelessWidget {
  final _Action action;
  final ColorScheme cs;
  final bool isDark;

  const _ActionCard(
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
          border: isDark
              ? Border.all(color: cs.primary.withAlpha(25))
              : null,
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
