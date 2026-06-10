// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';

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
  AlertasView({super.key});
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
      duration: Duration(milliseconds: 500),
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
      if (mounted) _showSnack(trStatic(context, 'Alerta eliminada', 'Alert deleted'), color: Colors.redAccent);
    } catch (_) {}
  }

  void _showSnack(String msg, {Color? color}) {
    final snackColor = color ?? Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: snackColor,
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
        return Color(0xFFFF9800);
      case 'limite_semanal':
        return Color(0xFFE53935);
      case 'nuevo_horario':
        return Color(0xFF00C853);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    final noLeidas = _alertas.where((a) => a['leida'] == false).length;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : _alertasFiltradas.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                            itemCount: _alertasFiltradas.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 10),
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
          Visibility(
            visible: Navigator.canPop(context),
            maintainSize: true, maintainAnimation: true, maintainState: true,
            child: _ScaleBtn(
              onPressed: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withAlpha(40).withOpacity(0.4),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'Alertas', 'Alerts'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (noLeidas > 0)
                Text(
                  tr(context, '$noLeidas sin leer', '$noLeidas unread'),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                ),
            ],
          ),
          Spacer(),
          _ScaleBtn(
            onPressed: _cargarAlertas,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withAlpha(15),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.primary,
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
            label: tr(context, 'Todas', 'All'),
            selected: _filtro == 'todas',
            onTap: () => setState(() => _filtro = 'todas'),
          ),
          SizedBox(width: 8),
          _FilterChip(
            label: tr(context, 'No leídas', 'Unread'),
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
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
          ),
          SizedBox(height: 16),
          Text(
            tr(context, 'Sin alertas', 'No alerts'),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6),
          Text(
            tr(context, 'No hay alertas en este filtro', 'No alerts for this filter'),
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
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
          color: leida ? Color(0xFFC8DEFF) : color.withOpacity(0.28),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: leida ? Color(0x121A4FD8) : color.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 3),
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
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta['mensaje'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: leida ? FontWeight.w500 : FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (empleado != null) ...[
                    SizedBox(height: 3),
                    Text(
                      empleado['nombre'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                  SizedBox(height: 2),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year}  ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
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
                    color: Color(0xFF00C853),
                    onTap: onRead,
                  ),
                if (!leida) SizedBox(height: 4),
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
      duration: Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withAlpha(40),
          width: 1.4,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(150),
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
      duration: Duration(milliseconds: 120),
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
        ..color = Color(0xFFDDEEFF).withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
