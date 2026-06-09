// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/horario_service.dart';
import '../../services/alerta_service.dart';

class _C {
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF0F2DA6);
  static const primaryLight = Color(0xFF1A4FD8);
  static const success = Color(0xFF00C853);
  static const textPrimary = Color(0xFF1A2A4A);
  static const textSecondary = Color(0xFF5A7DBA);
  static const border = Color(0xFFC8DEFF);
  static const divider = Color(0xFFDDEEFF);
  static const shadowSm = Color(0x201A4FD8);
}

class GestionHorariosView extends StatefulWidget {
  const GestionHorariosView({super.key});
  @override
  State<GestionHorariosView> createState() => _GestionHorariosViewState();
}

class _GestionHorariosViewState extends State<GestionHorariosView>
    with SingleTickerProviderStateMixin {
  final HorarioService _horarioService = HorarioService();
  final AlertaService _alertaService = AlertaService();
  DateTime _semana = DateTime.now();
  List<Map<String, dynamic>> _horarios = [];
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoading = true;
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
    _cargar();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    _empleados = await _horarioService.obtenerEmpleados();
    _horarios = await _horarioService.obtenerHorariosSemana(_semana);
    setState(() => _isLoading = false);
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
            boxShadow: [
              BoxShadow(color: _C.primary.withOpacity(0.20), blurRadius: 30),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _C.primaryLight),
              SizedBox(height: 16),
              Text(
                'Asignando horarios...',
                style: TextStyle(color: _C.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
    final ids = _empleados.map((e) => e['id'] as String).toList();
    final generados = await _horarioService.asignarHorariosAutomaticos(
      _semana,
      ids,
    );
    Navigator.pop(context);
    _showSnack('${generados.length} horarios asignados');
    await _cargar();
    for (var h in generados) {
      await _alertaService.notificarNuevoHorario(
        h['empleado_id'],
        h['dia'],
        h['entrada'],
        h['salida'],
      );
    }
  }

  void _editarHorario(Map<String, dynamic> horario) {
    DateTime entrada = DateTime.parse(horario['entrada']);
    DateTime salida = DateTime.parse(horario['salida']);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Editar Horario',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _C.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeTile(
                label: 'Entrada',
                time: entrada,
                icon: Icons.login_rounded,
                color: _C.success,
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(entrada),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: _C.primaryLight,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null)
                    setS(
                      () => entrada = DateTime(
                        entrada.year,
                        entrada.month,
                        entrada.day,
                        t.hour,
                        t.minute,
                      ),
                    );
                },
              ),
              const SizedBox(height: 12),
              _TimeTile(
                label: 'Salida',
                time: salida,
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(salida),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: _C.primaryLight,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (t != null)
                    setS(
                      () => salida = DateTime(
                        salida.year,
                        salida.month,
                        salida.day,
                        t.hour,
                        t.minute,
                      ),
                    );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _C.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _horarioService.editarHorario(
                  horario['id'],
                  entrada,
                  salida,
                );
                _showSnack('Horario actualizado');
                await _cargar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
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
        backgroundColor: _C.primaryLight,
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
                _buildTopBar(),
                _buildSemanaSelector(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_horarios.length} turno${_horarios.length != 1 ? 's' : ''} esta semana',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _C.primaryLight,
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: _horarios.isEmpty
                              ? _buildEmpty()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    60,
                                  ),
                                  itemCount: _horarios.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) => _HorarioTile(
                                    horario: _horarios[i],
                                    onEdit: () => _editarHorario(_horarios[i]),
                                    onDelete: () async {
                                      await _horarioService.eliminarHorario(
                                        _horarios[i]['id'],
                                      );
                                      _showSnack('Horario eliminado');
                                      await _cargar();
                                    },
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

  Widget _buildTopBar() => Padding(
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
        const Text(
          'Gestión de Horarios',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        const Spacer(),
        _ScaleBtn(
          onPressed: _asignarAutomaticos,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primary, _C.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSemanaSelector() => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border, width: 1.2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            setState(() => _semana = _semana.subtract(const Duration(days: 7)));
            _cargar();
          },
        ),
        Column(
          children: [
            const Text(
              'Semana del',
              style: TextStyle(fontSize: 11, color: _C.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy').format(_semana),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _C.textPrimary,
              ),
            ),
          ],
        ),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            setState(() => _semana = _semana.add(const Duration(days: 7)));
            _cargar();
          },
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
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
            Icons.calendar_today_rounded,
            color: _C.primaryLight,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sin horarios',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Usa el botón ✨ para asignar automáticamente',
          style: TextStyle(fontSize: 13, color: _C.textSecondary),
        ),
      ],
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(color: _C.shadowSm, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: _C.primaryLight, size: 20),
    ),
  );
}

class _HorarioTile extends StatelessWidget {
  final Map<String, dynamic> horario;
  final VoidCallback onEdit, onDelete;
  const _HorarioTile({
    required this.horario,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final emp = horario['empleados'];
    final entrada = DateTime.parse(horario['entrada']);
    final salida = DateTime.parse(horario['salida']);
    final horas = salida.difference(entrada).inMinutes / 60.0;
    final initial = emp != null && (emp['nombre'] as String).isNotEmpty
        ? (emp['nombre'] as String)[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.4),
        boxShadow: const [
          BoxShadow(color: _C.shadowSm, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.primary, _C.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp != null ? emp['nombre'] : 'Empleado',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: _C.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(entrada),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.textSecondary,
                        ),
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
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: _C.textSecondary,
                        ),
                      ),
                      _TimeChip(
                        time: DateFormat('HH:mm').format(salida),
                        icon: Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.primaryLight.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${horas.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _C.primaryLight,
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
                _Btn(
                  icon: Icons.edit_rounded,
                  color: _C.primaryLight,
                  onTap: onEdit,
                ),
                const SizedBox(height: 6),
                _Btn(
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

class _TimeChip extends StatelessWidget {
  final String time;
  final IconData icon;
  final Color color;
  const _TimeChip({
    required this.time,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(
        time,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
  );
}

class _TimeTile extends StatelessWidget {
  final String label;
  final DateTime time;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TimeTile({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: _C.textSecondary),
              ),
              Text(
                DateFormat('HH:mm').format(time),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
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

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
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
