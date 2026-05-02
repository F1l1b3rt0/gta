import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const primary      = Color(0xFF1A6FE8);
  // ignore: unused_field
  static const primaryLight = Color(0xFF4D96FF);
  static const text         = Color(0xFF0D1B3E);
  static const textSub      = Color(0xFF6B80A3);
  static const divider      = Color(0xFFE0ECFF);
  // ignore: unused_field
  static const shadow       = Color(0x201A6FE8);
}

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen>
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marcarComoLeida(String id) async {
    try {
      await Supabase.instance.client
          .from('alertas')
          .update({'leida': true}).eq('id', id);
      await _cargarAlertas();
    } catch (_) {}
  }

  Future<void> _eliminarAlerta(String id) async {
    try {
      await Supabase.instance.client
          .from('alertas')
          .delete()
          .eq('id', id);
      await _cargarAlertas();
      if (mounted) {
        _showSnack('Alerta eliminada', color: Colors.redAccent);
      }
    } catch (_) {}
  }

  void _showSnack(String msg, {Color color = const Color(0xFF1A6FE8)}) {
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
    if (_filtro == 'no_leidas') {
      return _alertas.where((a) => a['leida'] == false).toList();
    }
    return _alertas;
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'horas_extra':    return Icons.timer_rounded;
      case 'limite_semanal': return Icons.warning_amber_rounded;
      case 'nuevo_horario':  return Icons.event_available_rounded;
      default:               return Icons.notifications_rounded;
    }
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'horas_extra':    return const Color(0xFFFF9800);
      case 'limite_semanal': return const Color(0xFFE53935);
      case 'nuevo_horario':  return const Color(0xFF00C853);
      default:               return _C.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = _alertas.where((a) => a['leida'] == false).length;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(noLeidas),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _C.primary),
                    )
                  : _alertasFiltradas.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _alertasFiltradas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final alerta = _alertasFiltradas[index];
                            return _AlertaTile(
                              alerta: alerta,
                              icon: _iconForTipo(alerta['tipo'] ?? ''),
                              color: _colorForTipo(alerta['tipo'] ?? ''),
                              onRead: () => _marcarComoLeida(alerta['id']),
                              onDelete: () => _eliminarAlerta(alerta['id']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(int noLeidas) {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _C.text,
            ),
          ),
          if (noLeidas > 0)
            Text(
              '$noLeidas sin leer',
              style: const TextStyle(fontSize: 12, color: _C.textSub),
            ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.divider),
              ),
              child: const Icon(Icons.refresh_rounded, color: _C.primary, size: 18),
            ),
            onPressed: _cargarAlertas,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _C.bg,
      child: Row(
        children: [
          _Chip(label: 'Todas', value: 'todas', selected: _filtro == 'todas',
              onTap: () => setState(() => _filtro = 'todas')),
          const SizedBox(width: 8),
          _Chip(label: 'No leídas', value: 'no_leidas', selected: _filtro == 'no_leidas',
              onTap: () => setState(() => _filtro = 'no_leidas')),
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
              border: Border.all(color: _C.divider, width: 1.5),
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: _C.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Sin alertas', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: _C.text,
          )),
          const SizedBox(height: 6),
          const Text('No hay alertas en este filtro', style: TextStyle(
            fontSize: 13, color: _C.textSub,
          )),
        ],
      ),
    );
  }
}

// ─── Tile de alerta ──────────────────────────────────────────────────────────

class _AlertaTile extends StatelessWidget {
  final Map<String, dynamic> alerta;
  final IconData icon;
  final Color color;
  final VoidCallback onRead;
  final VoidCallback onDelete;

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
          color: leida ? const Color(0xFFE0ECFF) : color.withOpacity(0.25),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: leida
                ? const Color(0x121A6FE8)
                : color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono
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
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerta['mensaje'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: leida ? FontWeight.w500 : FontWeight.w700,
                      color: const Color(0xFF0D1B3E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (empleado != null)
                    Text(
                      empleado['nombre'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B80A3),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${fecha.day}/${fecha.month}/${fecha.year}  ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9BAACB)),
                  ),
                ],
              ),
            ),
            // Acciones
            Column(
              children: [
                if (!leida)
                  _ActionIcon(
                    icon: Icons.done_all_rounded,
                    color: const Color(0xFF00C853),
                    onTap: onRead,
                  ),
                const SizedBox(height: 4),
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

  const _ActionIcon({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A6FE8) : const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF1A6FE8) : const Color(0xFFE0ECFF),
            width: 1.4,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: const Color(0xFF1A6FE8).withOpacity(0.25),
                  blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B80A3),
          ),
        ),
      ),
    );
  }
}