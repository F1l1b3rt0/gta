// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/horario_service.dart';
import '../../services/alerta_service.dart';
import '../../services/tr.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';

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
  GestionHorariosView({super.key});
  @override
  State<GestionHorariosView> createState() => _GestionHorariosViewState();
}

class _GestionHorariosViewState extends State<GestionHorariosView>
    with SingleTickerProviderStateMixin {
  final HorarioService _horarioService = HorarioService();
  final AlertaService _alertaService = AlertaService();
  DateTime _semana = () {
    final now = DateTime.now();
    // Start of current week (Monday at midnight)
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }();
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
      duration: Duration(milliseconds: 500),
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

  void _asignarAutomaticos() {
    if (_empleados.isEmpty) {
      _showSnack(trStatic(context, 'No hay empleados cargados', 'No employees loaded'), error: true);
      return;
    }
    final seleccionados = <String>{..._empleados.map((e) => e['id'] as String)};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(tr(context, 'Asignación automática', 'Auto-assignment'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(context, 'Semana', 'Week')}: ${DateFormat('dd/MM/yyyy').format(_semana)} – ${DateFormat('dd/MM/yyyy').format(_semana.add(const Duration(days: 6)))}',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(160)),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'Se usará la disponibilidad configurada de cada empleado.', "Each employee's configured availability will be used."),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
                ),
                const SizedBox(height: 14),
                Text(tr(context, 'Empleados a incluir:', 'Employees to include:'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _empleados.map((e) {
                        final id = e['id'] as String;
                        final nombre = e['nombre'] as String? ?? id;
                        final checked = seleccionados.contains(id);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: checked,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: Text(nombre, style: const TextStyle(fontSize: 14)),
                          onChanged: (v) => setS(() {
                            if (v == true) seleccionados.add(id); else seleccionados.remove(id);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(context, 'Cancelar', 'Cancel'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
            ),
            ElevatedButton.icon(
              onPressed: seleccionados.isEmpty ? null : () async {
                Navigator.pop(ctx);
                await _ejecutarAsignacion(seleccionados.toList());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
              label: Text(tr(context, 'Asignar', 'Assign'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ejecutarAsignacion(List<String> ids) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(tr(context, 'Asignando horarios...', 'Assigning schedules...'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ]),
          ),
        ),
      ),
    );
    try {
      final generados = await _horarioService.asignarHorariosAutomaticos(_semana, ids);
      if (mounted) Navigator.pop(context);
      _showSnack(trStatic(context, '${generados.length} turnos asignados correctamente', '${generados.length} shifts assigned successfully'));
      await _cargar();
      for (var h in generados) {
        await _alertaService.notificarNuevoHorario(h['empleado_id'], h['dia'], h['entrada'], h['salida']);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack(trStatic(context, 'Error al asignar: $e', 'Error assigning: $e'), error: true);
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
          title: Text(
            tr(context, 'Editar Horario', 'Edit Schedule'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeTile(
                label: tr(context, 'Entrada', 'Entry'),
                time: entrada,
                icon: Icons.login_rounded,
                color: Color(0xFF00C853),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(entrada),
                    builder: (c, child) => child!,
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
              SizedBox(height: 12),
              _TimeTile(
                label: tr(context, 'Salida', 'Exit'),
                time: salida,
                icon: Icons.logout_rounded,
                color: Colors.redAccent,
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(salida),
                    builder: (c, child) => child!,
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
              child: Text(
                tr(context, 'Cancelar', 'Cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
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
                _showSnack(trStatic(context, 'Horario actualizado', 'Schedule updated'));
                await _cargar();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                tr(context, 'Guardar', 'Save'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _crearTurno() {
    String? empleadoSelId;
    String? empleadoSelNombre;
    DateTime fecha = _semana;
    TimeOfDay entradaTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay salidaTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            tr(context, 'Nuevo Turno', 'New Shift'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Employee selector
                DropdownButtonFormField<String>(
                  value: empleadoSelId,
                  decoration: InputDecoration(
                    labelText: tr(context, 'Empleado', 'Employee'),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _empleados.map((e) => DropdownMenuItem<String>(
                    value: e['id'] as String,
                    child: Text(e['nombre'] as String),
                  )).toList(),
                  onChanged: (v) => setS(() {
                    empleadoSelId = v;
                    empleadoSelNombre = _empleados.firstWhere((e) => e['id'] == v)['nombre'];
                  }),
                ),
                const SizedBox(height: 12),
                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  subtitle: Text(tr(context, 'Fecha', 'Date'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(130), fontSize: 12)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => fecha = d);
                  },
                ),
                const SizedBox(height: 4),
                _TimeTile(
                  label: tr(context, 'Entrada', 'Entry'),
                  time: DateTime(fecha.year, fecha.month, fecha.day, entradaTime.hour, entradaTime.minute),
                  icon: Icons.login_rounded,
                  color: const Color(0xFF00C853),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: entradaTime, builder: (c, child) => child!);
                    if (t != null) setS(() => entradaTime = t);
                  },
                ),
                const SizedBox(height: 12),
                _TimeTile(
                  label: tr(context, 'Salida', 'Exit'),
                  time: DateTime(fecha.year, fecha.month, fecha.day, salidaTime.hour, salidaTime.minute),
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: salidaTime, builder: (c, child) => child!);
                    if (t != null) setS(() => salidaTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(context, 'Cancelar', 'Cancel'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
            ),
            ElevatedButton(
              onPressed: empleadoSelId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final entrada = DateTime(fecha.year, fecha.month, fecha.day, entradaTime.hour, entradaTime.minute);
                      final salida = DateTime(fecha.year, fecha.month, fecha.day, salidaTime.hour, salidaTime.minute);
                      if (!salida.isAfter(entrada)) {
                        _showSnack(trStatic(context, 'La salida debe ser después de la entrada', 'Exit must be after entry'), error: true);
                        return;
                      }
                      try {
                        await _horarioService.crearTurnoManual(empleadoSelId!, entrada, salida);
                        _showSnack(trStatic(context, 'Turno creado para $empleadoSelNombre', 'Shift created for $empleadoSelNombre'));
                        await _cargar();
                      } catch (e) {
                        _showSnack(trStatic(context, 'Error al crear turno: $e', 'Error creating shift: $e'), error: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(tr(context, 'Crear', 'Create'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: error ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: error ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>(); // rebuild on lang change
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearTurno,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(tr(context, 'Nuevo turno', 'New shift'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
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
                      tr(context,
                        '${_horarios.length} turno${_horarios.length != 1 ? 's' : ''} esta semana',
                        '${_horarios.length} shift${_horarios.length != 1 ? 's' : ''} this week'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
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
                                      SizedBox(height: 10),
                                  itemBuilder: (_, i) => _HorarioTile(
                                    horario: _horarios[i],
                                    onEdit: () => _editarHorario(_horarios[i]),
                                    onDelete: () async {
                                      await _horarioService.eliminarHorario(
                                        _horarios[i]['id'],
                                      );
                                      _showSnack(trStatic(context, 'Horario eliminado', 'Schedule deleted'));
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
        Visibility(
          visible: Navigator.canPop(context),
          maintainSize: true, maintainAnimation: true, maintainState: true,
          child: _ScaleBtn(
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
        Text(
          tr(context, 'Gestión de Horarios', 'Schedule Management'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Spacer(),
        _ScaleBtn(
          onPressed: _asignarAutomaticos,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
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
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          onTap: () {
            setState(() => _semana = _semana.subtract(Duration(days: 7)));
            _cargar();
          },
        ),
        Column(
          children: [
            Text(
              tr(context, 'Semana del', 'Week of'),
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            ),
            SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy').format(_semana),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: () {
            setState(() => _semana = _semana.add(Duration(days: 7)));
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
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 36,
          ),
        ),
        SizedBox(height: 16),
        Text(
          tr(context, 'Sin horarios', 'No schedules'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 6),
        Text(
          tr(context, 'Usa el botón ✨ para asignar automáticamente', 'Use the ✨ button to auto-assign'),
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40)),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
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
    var salida = DateTime.parse(horario['salida']);
    // Handle overnight shifts
    if (salida.isBefore(entrada)) salida = salida.add(const Duration(days: 1));
    final horas = salida.difference(entrada).inMinutes / 60.0;
    final initial = emp != null && (emp['nombre'] as String).isNotEmpty
        ? (emp['nombre'] as String)[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.4),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 10, offset: Offset(0, 3)),
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
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.30),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp != null ? emp['nombre'] : 'Empleado',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(entrada),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _TimeChip(
                        time: DateFormat('HH:mm').format(entrada),
                        icon: Icons.login_rounded,
                        color: Color(0xFF00C853),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      _TimeChip(
                        time: DateFormat('HH:mm').format(salida),
                        icon: Icons.logout_rounded,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${horas.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.primary,
                  onTap: onEdit,
                ),
                SizedBox(height: 6),
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
      SizedBox(width: 3),
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
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
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
          Spacer(),
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
