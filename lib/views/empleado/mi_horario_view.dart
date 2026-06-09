// ignore_for_file: unused_field, deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  static const success = Color(0xFF00C853);
  static const warn = Color(0xFFFF9800);
}

class MiHorarioView extends StatefulWidget {
  const MiHorarioView({super.key});
  @override
  State<MiHorarioView> createState() => _MiHorarioViewState();
}

class _MiHorarioViewState extends State<MiHorarioView>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _horarios = [];
  bool _isLoading = true;
  DateTime _semana = DateTime.now();
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final inicio = _semana.subtract(Duration(days: _semana.weekday - 1));
      final fin = inicio.add(const Duration(days: 7));
      final r = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .order('entrada');
      setState(() {
        _horarios = List<Map<String, dynamic>>.from(r);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _nombreDia(int w) => [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ][w - 1];

  @override
  Widget build(BuildContext context) {
    final inicioSemana = _semana.subtract(Duration(days: _semana.weekday - 1));
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildSemanaSelector(inicioSemana),
                  _buildMiniCalendario(inicioSemana),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                        : _horarios.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 60),
                            itemCount: _horarios.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _HorarioTile(
                              horario: _horarios[i],
                              nombreDia: _nombreDia,
                            ),
                          ),
                  ),
                ],
              ),
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
          'Mi Horario',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _C.textPrimary,
          ),
        ),
        const Spacer(),
        _ScaleBtn(
          onPressed: _cargar,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.border, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: _C.shadowSm,
                  blurRadius: 8,
                  offset: Offset(0, 2),
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

  Widget _buildSemanaSelector(DateTime ini) => Container(
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
              DateFormat('dd/MM/yyyy').format(ini),
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

  Widget _buildMiniCalendario(DateTime ini) {
    final hoy = DateTime.now();
    final diasConTurno = _horarios.map((h) {
      final e = DateTime.parse(h['entrada']);
      return DateTime(e.year, e.month, e.day);
    }).toSet();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border, width: 1.2),
        boxShadow: const [
          BoxShadow(color: _C.shadowSm, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final dia = ini.add(Duration(days: i));
          final esHoy =
              dia.year == hoy.year &&
              dia.month == hoy.month &&
              dia.day == hoy.day;
          final tieneTurno = diasConTurno.contains(
            DateTime(dia.year, dia.month, dia.day),
          );
          const abrevs = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
          return Column(
            children: [
              Text(
                abrevs[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: esHoy ? _C.primaryLight : _C.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: esHoy ? _C.primaryLight : Colors.transparent,
                  shape: BoxShape.circle,
                  border: esHoy
                      ? null
                      : Border.all(
                          color: tieneTurno
                              ? _C.primaryLight.withOpacity(0.30)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                ),
                child: Center(
                  child: Text(
                    '${dia.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: esHoy
                          ? Colors.white
                          : (tieneTurno ? _C.primaryLight : _C.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tieneTurno ? _C.primaryLight : Colors.transparent,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

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
            Icons.event_busy_rounded,
            color: _C.primaryLight,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sin turnos esta semana',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'No tienes horarios asignados',
          style: TextStyle(fontSize: 13, color: _C.textSecondary),
        ),
      ],
    ),
  );
}

class _HorarioTile extends StatelessWidget {
  final Map<String, dynamic> horario;
  final String Function(int) nombreDia;
  const _HorarioTile({required this.horario, required this.nombreDia});
  @override
  Widget build(BuildContext context) {
    final entrada = DateTime.parse(horario['entrada']);
    final salida = horario['salida'] != null
        ? DateTime.parse(horario['salida'])
        : null;
    final esExtra = horario['es_extra'] == true;
    final completado = salida != null;
    final horas = salida != null
        ? salida.difference(entrada).inMinutes / 60.0
        : null;
    final color = esExtra
        ? _C.warn
        : completado
        ? _C.success
        : _C.primaryLight;
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['L', 'M', 'X', 'J', 'V', 'S', 'D'][entrada.weekday - 1],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${entrada.day}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${nombreDia(entrada.weekday)} ${entrada.day}/${entrada.month}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _TimeChip(
                        icon: Icons.login_rounded,
                        time: DateFormat('HH:mm').format(entrada),
                        color: _C.success,
                      ),
                      if (salida != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: _C.textSecondary,
                          ),
                        ),
                        _TimeChip(
                          icon: Icons.logout_rounded,
                          time: DateFormat('HH:mm').format(salida),
                          color: Colors.redAccent,
                        ),
                      ],
                    ],
                  ),
                  if (horas != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${horas.toStringAsFixed(1)} horas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _C.textSecondary,
                      ),
                    ),
                  ],
                  if (esExtra) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _C.warn.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Hora extra',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.warn,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            completado
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: _C.success,
                    size: 26,
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _C.warn.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _C.warn.withOpacity(0.30)),
                    ),
                    child: const Text(
                      'Activo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _C.warn,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String time;
  final Color color;
  const _TimeChip({
    required this.icon,
    required this.time,
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
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ],
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
