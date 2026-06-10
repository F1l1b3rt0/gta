// ignore_for_file: curly_braces_in_flow_control_structures, unused_field, deprecated_member_use, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/app_strings.dart';

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

class MisHorasView extends StatefulWidget {
  MisHorasView({super.key});
  @override
  State<MisHorasView> createState() => _MisHorasScreenState();
}

class _MisHorasScreenState extends State<MisHorasView>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _turnos = [];
  bool _isLoading = true;
  String _periodo = 'mes';
  double _totalNormales = 0, _totalExtras = 0, _totalPago = 0, _salario = 0;
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final emp = await Supabase.instance.client
          .from('empleados')
          .select('salario_por_hora')
          .eq('id', user.id)
          .single();
      _salario = (emp['salario_por_hora'] ?? 0).toDouble();
      final fin = DateTime.now();
      final inicio = _periodo == 'semana'
          ? fin.subtract(Duration(days: fin.weekday - 1))
          : DateTime(fin.year, fin.month, 1);
      final r = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .not('salida', 'is', null)
          .order('entrada', ascending: false);
      setState(() {
        _turnos = List<Map<String, dynamic>>.from(r);
        _calcular();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _calcular() {
    double n = 0, e = 0;
    for (var t in _turnos) {
      final entrada = DateTime.parse(t['entrada']);
      var salida = DateTime.parse(t['salida']);
      if (salida.isBefore(entrada)) salida = salida.add(const Duration(days: 1));
      final h = salida.difference(entrada).inMinutes / 60.0;
      if (h <= 0) continue;
      if (t['es_extra'] == true)
        e += h;
      else
        n += h;
    }
    _totalNormales = n;
    _totalExtras = e;
    _totalPago = (n * _salario) + (e * _salario * 1.5);
  }

  @override
  Widget build(BuildContext context) {
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
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPeriodo(),
                                SizedBox(height: 20),
                                _buildResumen(),
                                SizedBox(height: 20),
                                _buildPagoCard(),
                                SizedBox(height: 24),
                                _sectionLabel('Detalle de turnos'),
                                SizedBox(height: 12),
                                if (_turnos.isEmpty)
                                  _buildEmpty()
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        NeverScrollableScrollPhysics(),
                                    itemCount: _turnos.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(height: 10),
                                    itemBuilder: (_, i) => _TurnoTile(
                                      turno: _turnos[i],
                                      salario: _salario,
                                    ),
                                  ),
                              ],
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
        SizedBox(width: 14),
        Text(
          AppStrings.of(context).myHoursTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Spacer(),
        _ScaleBtn(
          onPressed: _cargar,
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

  Widget _sectionLabel(String l) => Text(
    l.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
      letterSpacing: 2.0,
    ),
  );

  Widget _buildPeriodo() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.2),
    ),
    child: Row(
      children: [_PTab('Esta semana', 'semana'), _PTab('Este mes', 'mes')],
    ),
  );

  Widget _PTab(String label, String value) {
    final sel = _periodo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _periodo = value);
          _cargar();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.30),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumen() => Row(
    children: [
      Expanded(
        child: _StatCard(
          label: AppStrings.of(context).normalHours,
          value: '${_totalNormales.toInt()}h',
          icon: Icons.access_time_rounded,
          color: Color(0xFF00C853),
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          label: AppStrings.of(context).extraHours,
          value: '${_totalExtras.toInt()}h',
          icon: Icons.timer_rounded,
          color: Color(0xFFFF9800),
        ),
      ),
    ],
  );

  Widget _buildPagoCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white70,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Total a cobrar',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '\$${_totalPago.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '\$${_salario.toStringAsFixed(2)}/h normal · \$${(_salario * 1.5).toStringAsFixed(2)}/h extra',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
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
              Icons.history_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
          ),
          SizedBox(height: 16),
          Text(
            AppStrings.of(context).noHoursRecorded,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No hay turnos en este período',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
          ),
        ],
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.4),
      boxShadow: [
        BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 10, offset: Offset(0, 3)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
        ),
      ],
    ),
  );
}

class _TurnoTile extends StatelessWidget {
  final Map<String, dynamic> turno;
  final double salario;
  const _TurnoTile({required this.turno, required this.salario});
  @override
  Widget build(BuildContext context) {
    final entrada = DateTime.parse(turno['entrada']);
    var salida = DateTime.parse(turno['salida']);
    if (salida.isBefore(entrada)) salida = salida.add(const Duration(days: 1));
    final horas = salida.difference(entrada).inMinutes / 60.0;
    final esExtra = turno['es_extra'] == true;
    final pago = horas * salario * (esExtra ? 1.5 : 1);
    final color = esExtra ? Color(0xFFFF9800) : Color(0xFF00C853);
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.70)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _fmtH(horas),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy', 'es_ES').format(entrada),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 12,
                        color: Color(0xFF00C853),
                      ),
                      SizedBox(width: 3),
                      Text(
                        DateFormat('HH:mm').format(entrada),
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00C853),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      Icon(
                        Icons.logout_rounded,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 3),
                      Text(
                        DateFormat('HH:mm').format(salida),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (esExtra) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF9800).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.of(context).extra,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${pago.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  _fmtH(horas),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatea horas decimales → "Xh" o "Xh Ym"
String _fmtH(double h) {
  final totalMin = (h * 60).round();
  final hrs = totalMin ~/ 60;
  final min = totalMin % 60;
  if (min == 0) return '${hrs}h';
  return '${hrs}h ${min}m';
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
