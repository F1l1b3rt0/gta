// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF0F2DA6);
  static const primaryLight = Color(0xFF1A4FD8);
  static const textPrimary = Color(0xFF1A2A4A);
  static const textSecondary = Color(0xFF5A7DBA);
  static const border = Color(0xFFC8DEFF);
  static const divider = Color(0xFFDDEEFF);
  static const shadowSm = Color(0x201A4FD8);
}

class AlertasView extends StatefulWidget {
  const AlertasView({super.key});
  @override
  State<AlertasView> createState() => _AlertasViewState();
}

class _AlertasViewState extends State<AlertasView>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = true;
  String _filtro = 'todas';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarAlertas();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAlertas() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('alertas')
          .select('*, empleados(nombre)')
          .order('fecha', ascending: false);
      setState(() {
        _alertas = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarComoLeida(String id) async {
    try {
      await Supabase.instance.client
          .from('alertas')
          .update({'leida': true})
          .eq('id', id);
      await _cargarAlertas();
    } catch (_) {}
  }

  Future<void> _eliminarAlerta(String id) async {
    try {
      await Supabase.instance.client.from('alertas').delete().eq('id', id);
      await _cargarAlertas();
      if (mounted) _showSnack('Alerta eliminada', color: Colors.redAccent);
    } catch (_) {}
  }

  void _showSnack(String msg, {Color color = _C.primaryLight}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> get _alertasFiltradas {
    if (_filtro == 'no_leidas')
      return _alertas.where((a) => a['leida'] == false).toList();
    return _alertas;
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'horas_extra':
        return Icons.timer_rounded;
      case 'limite_semanal':
        return Icons.warning_amber_rounded;
      case 'nuevo_horario':
        return Icons.event_available_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'horas_extra':
        return const Color(0xFFFF9800);
      case 'limite_semanal':
        return const Color(0xFFE53935);
      case 'nuevo_horario':
        return const Color(0xFF00C853);
      default:
        return _C.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = _alertas.where((a) => a['leida'] == false).length;
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
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
                _buildTopBar(noLeidas),
                _buildFiltros(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _C.primaryLight,
                            ),
                          )
                        : _alertasFiltradas.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                            itemCount: _alertasFiltradas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final a = _alertasFiltradas[i];
                              return _AlertaTile(
                                alerta: a,
                                icon: _iconForTipo(a['tipo'] ?? ''),
                                color: _colorForTipo(a['tipo'] ?? ''),
                                onRead: () => _marcarComoLeida(a['id']),
                                onDelete: () => _eliminarAlerta(a['id']),
                              );
                            },
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

  Widget _buildTopBar(int noLeidas) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _ScaleBtn(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alertas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.textPrimary,
                ),
              ),
              if (noLeidas > 0)
                Text(
                  '$noLeidas sin leer',
                  style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                ),
            ],
          ),
          const Spacer(),
          _ScaleBtn(
            onPressed: _cargarAlertas,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _C.shadowSm,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _C.primaryLight,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            selected: _filtro == 'todas',
            onTap: () => setState(() => _filtro = 'todas'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'No leídas',
            selected: _filtro == 'no_leidas',
            onTap: () => setState(() => _filtro = 'no_leidas'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border, width: 1.5),
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: _C.primaryLight,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin alertas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No hay alertas en este filtro',
            style: TextStyle(fontSize: 13, color: _C.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AlertaTile extends StatelessWidget {
  final Map<String, dynamic> alerta;
  final IconData icon;
  final Color color;
  final VoidCallback onRead, onDelete;
  const _AlertaTile({
    required this.alerta,
    required this.icon,
    required this.color,
    required this.onRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final leida = alerta['leida'] == true;
    final empleado = alerta['empleados'];
    final fecha = DateTime.tryParse(alerta['fecha'] ?? '') ?? DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: leida ? Colors.white : color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: leida ? const Color(0xFFC8DEFF) : color.withOpacity(0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: leida ? const Color(0x121A4FD8) : color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta['mensaje'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: leida ? FontWeight.w500 : FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  if (empleado != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      empleado['nombre'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year}  ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _C.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (!leida)
                  _ActionIcon(
                    icon: Icons.done_all_rounded,
                    color: const Color(0xFF00C853),
                    onTap: onRead,
                  ),
                if (!leida) const SizedBox(height: 4),
                _ActionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 17),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _C.primaryLight : _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _C.primaryLight : _C.border,
          width: 1.4,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: _C.primaryLight.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _C.textSecondary,
        ),
      ),
    ),
  );
}

class _ScaleBtn extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _ScaleBtn({required this.onPressed, required this.child});
  @override
  State<_ScaleBtn> createState() => _ScaleBtnState();
}

class _ScaleBtnState extends State<_ScaleBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.reverse(),
    onTapUp: (_) {
      _c.forward();
      widget.onPressed?.call();
    },
    onTapCancel: () => _c.forward(),
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: _c.value, child: child),
      child: widget.child,
    ),
  );
}

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
