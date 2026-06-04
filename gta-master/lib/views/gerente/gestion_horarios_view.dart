import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/horario_service.dart';
import '../../services/alerta_service.dart';

class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const shadow  = Color(0x201A6FE8);
  static const success = Color(0xFF00C853);
}

class GestionHorariosScreen extends StatefulWidget {
  const GestionHorariosScreen({super.key});

  @override
  State<GestionHorariosScreen> createState() => _GestionHorariosScreenState();
}

class _GestionHorariosScreenState extends State<GestionHorariosScreen>
    with SingleTickerProviderStateMixin {
  final HorarioService _horarioService = HorarioService();
  final AlertaService  _alertaService  = AlertaService();

  DateTime _semanaActual = DateTime.now();
  List<Map<String, dynamic>> _horarios  = [];
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoading = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarDatos();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final empleados = await _horarioService.obtenerEmpleados();
    final horarios  = await _horarioService.obtenerHorariosSemana(_semanaActual);
    setState(() {
      _empleados = empleados;
      _horarios  = horarios;
      _isLoading = false;
    });
  }

  Future<void> _asignarAutomaticos() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.20), blurRadius: 30)],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _C.primary),
              SizedBox(height: 16),
              Text('Asignando horarios...', style: TextStyle(color: _C.text)),
            ],
          ),
        ),
      ),
    );

    final ids = _empleados.map((e) => e['id'] as String).toList();
    final generados = await _horarioService.asignarHorariosAutomaticos(_semanaActual, ids);

    Navigator.pop(context);
    _showSnack('${generados.length} horarios asignados');
    await _cargarDatos();

    for (var h in generados) {
      await _alertaService.notificarNuevoHorario(
        h['empleado_id'], h['dia'], h['entrada'], h['salida'],
      );
    }
  }

  void _editarHorario(Map<String, dynamic> horario) {
    DateTime nuevaEntrada = DateTime.parse(horario['entrada']);
    DateTime nuevaSalida  = DateTime.parse(horario['salida']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _C.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar Horario',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: _C.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeTile(
                label: 'Entrada',
                time: nuevaEntrada,
                icon: Icons.login_rounded,
                color: _C.success,
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(nuevaEntrada),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: _C.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null) {
                    setS(() {
                      nuevaEntrada = DateTime(nuevaEntrada.year, nuevaEntrada.month,
                          nuevaEntrada.day, t.hour, t.minute);
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _TimeTile(
                label: 'Salida',
                time: nuevaSalida,
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(nuevaSalida),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: _C.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null) {
                    setS(() {
                      nuevaSalida = DateTime(nuevaSalida.year, nuevaSalida.month,
                          nuevaSalida.day, t.hour, t.minute);
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: _C.textSub)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _horarioService.editarHorario(
                    horario['id'], nuevaEntrada, nuevaSalida);
                _showSnack('Horario actualizado');
                await _cargarDatos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildSemanaSelector(),
                  // Contador
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_horarios.length} turno${_horarios.length != 1 ? 's' : ''} esta semana',
                        style: const TextStyle(fontSize: 12, color: _C.textSub),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _horarios.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            itemCount: _horarios.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _HorarioTile(
                              horario: _horarios[i],
                              onEdit: () => _editarHorario(_horarios[i]),
                              onDelete: () async {
                                await _horarioService.eliminarHorario(_horarios[i]['id']);
                                _showSnack('Horario eliminado');
                                await _cargarDatos();
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.text, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Gestión de Horarios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _C.text)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                    color: _C.primary.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            onPressed: _asignarAutomaticos,
            tooltip: 'Asignar automático',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildSemanaSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              setState(() => _semanaActual =
                  _semanaActual.subtract(const Duration(days: 7)));
              _cargarDatos();
            },
          ),
          Column(
            children: [
              const Text('Semana del',
                  style: TextStyle(fontSize: 11, color: _C.textSub)),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy').format(_semanaActual),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _C.text,
                ),
              ),
            ],
          ),
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              setState(() =>
                  _semanaActual = _semanaActual.add(const Duration(days: 7)));
              _cargarDatos();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.calendar_today_rounded,
                color: _C.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Sin horarios',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _C.text)),
          const SizedBox(height: 6),
          const Text('Usa el botón ✨ para asignar automáticamente',
              style: TextStyle(fontSize: 13, color: _C.textSub)),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.divider),
          boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: _C.primary, size: 20),
      ),
    );
  }
}

class _HorarioTile extends StatelessWidget {
  final Map<String, dynamic> horario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HorarioTile({
    required this.horario,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final empleado = horario['empleados'];
    final entrada  = DateTime.parse(horario['entrada']);
    final salida   = DateTime.parse(horario['salida']);
    final horas    = salida.difference(entrada).inMinutes / 60.0;
    final initial  = empleado != null && (empleado['nombre'] as String).isNotEmpty
        ? (empleado['nombre'] as String)[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.primary, Color(0xFF4D96FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: _C.primary.withOpacity(0.30),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado != null ? empleado['nombre'] : 'Empleado',
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _C.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 12, color: _C.textSub),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(entrada),
                        style: const TextStyle(fontSize: 12, color: _C.textSub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TimeChip(
                        time: DateFormat('HH:mm').format(entrada),
                        icon: Icons.login_rounded,
                        color: _C.success,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: _C.textSub),
                      ),
                      _TimeChip(
                        time: DateFormat('HH:mm').format(salida),
                        icon: Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${horas.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _C.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _Btn(icon: Icons.edit_rounded, color: _C.primary, onTap: onEdit),
                const SizedBox(height: 6),
                _Btn(icon: Icons.delete_outline_rounded, color: Colors.redAccent, onTap: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final IconData icon;
  final Color color;

  const _TimeChip({required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(time, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: color,
        )),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label, required this.time,
    required this.icon, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _C.textSub)),
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_rounded, color: color.withOpacity(0.60), size: 16),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}