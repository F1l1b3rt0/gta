// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const shadow  = Color(0x201A6FE8);
  static const success = Color(0xFF00C853);
  static const warn    = Color(0xFFFF9800);
  static const purple  = Color(0xFF7C4DFF);
}

class MisHorasScreen extends StatefulWidget {
  const MisHorasScreen({super.key});

  @override
  State<MisHorasScreen> createState() => _MisHorasScreenState();
}

class _MisHorasScreenState extends State<MisHorasScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _turnos = [];
  bool _isLoading = true;
  String _periodo = 'mes';
  double _totalNormales = 0;
  double _totalExtras   = 0;
  double _totalPago     = 0;
  double _salarioPorHora = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final emp = await Supabase.instance.client
          .from('empleados')
          .select('salario_por_hora')
          .eq('id', user.id)
          .single();
      _salarioPorHora = (emp['salario_por_hora'] ?? 0).toDouble();

      final fin = DateTime.now();
      final inicio = _periodo == 'semana'
          ? fin.subtract(Duration(days: fin.weekday - 1))
          : DateTime(fin.year, fin.month, 1);

      final resp = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .not('salida', 'is', null)
          .order('entrada', ascending: false);

      setState(() {
        _turnos = List<Map<String, dynamic>>.from(resp);
        _calcularTotales();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _calcularTotales() {
    double n = 0, e = 0;
    for (var t in _turnos) {
      final entrada = DateTime.parse(t['entrada']);
      final salida  = DateTime.parse(t['salida']);
      final horas   = salida.difference(entrada).inHours.toDouble();
      if (t['es_extra'] == true) {
        e += horas;
      } else {
        n += horas;
      }
    }
    _totalNormales = n;
    _totalExtras   = e;
    _totalPago     = (n * _salarioPorHora) + (e * _salarioPorHora * 1.5);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodoSelector(),
                    const SizedBox(height: 20),
                    _buildResumenCards(),
                    const SizedBox(height: 20),
                    _buildPagoCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Detalle de turnos'),
                    const SizedBox(height: 12),
                    if (_turnos.isEmpty)
                      _buildEmpty()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _turnos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _TurnoTile(
                          turno: _turnos[i],
                          salarioPorHora: _salarioPorHora,
                        ),
                      ),
                  ],
                ),
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
      title: const Text('Mis Horas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _C.text)),
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
            onPressed: _cargarDatos,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: _C.textSub, letterSpacing: 2.0,
    ));
  }

  Widget _buildPeriodoSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider, width: 1.2),
      ),
      child: Row(
        children: [
          _PTab('Esta semana', 'semana'),
          _PTab('Este mes', 'mes'),
        ],
      ),
    );
  }

  Widget _PTab(String label, String value) {
    final sel = _periodo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _periodo = value);
          _cargarDatos();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _C.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [BoxShadow(color: _C.primary.withOpacity(0.30),
                    blurRadius: 12, offset: const Offset(0, 3))]
                : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sel ? Colors.white : _C.textSub,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Horas normales',
            value: '${_totalNormales.toInt()}h',
            icon: Icons.access_time_rounded,
            color: _C.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Horas extras',
            value: '${_totalExtras.toInt()}h',
            icon: Icons.timer_rounded,
            color: _C.warn,
          ),
        ),
      ],
    );
  }

  Widget _buildPagoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.primary, Color(0xFF4D96FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: _C.primary.withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Total a cobrar', style: TextStyle(
                color: Colors.white70, fontSize: 13,
              )),
            ],
          ),
          const SizedBox(height: 10),
          Text('\$${_totalPago.toStringAsFixed(2)}', style: const TextStyle(
            color: Colors.white,
            fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5,
          )),
          const SizedBox(height: 6),
          Text(
            '\$${_salarioPorHora.toStringAsFixed(2)}/h normal · '
            '\$${(_salarioPorHora * 1.5).toStringAsFixed(2)}/h extra',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _C.surface, shape: BoxShape.circle,
                border: Border.all(color: _C.divider, width: 1.5),
              ),
              child: const Icon(Icons.history_rounded, color: _C.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Sin registros',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _C.text)),
            const SizedBox(height: 6),
            const Text('No hay turnos en este período',
                style: TextStyle(fontSize: 13, color: _C.textSub)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0ECFF), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x201A6FE8), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: color,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
            fontSize: 12, color: Color(0xFF6B80A3),
          )),
        ],
      ),
    );
  }
}

class _TurnoTile extends StatelessWidget {
  final Map<String, dynamic> turno;
  final double salarioPorHora;

  const _TurnoTile({required this.turno, required this.salarioPorHora});

  @override
  Widget build(BuildContext context) {
    final entrada  = DateTime.parse(turno['entrada']);
    final salida   = DateTime.parse(turno['salida']);
    final horas    = salida.difference(entrada).inHours;
    final esExtra  = turno['es_extra'] == true;
    final pago     = horas * salarioPorHora * (esExtra ? 1.5 : 1);
    final color    = esExtra ? const Color(0xFFFF9800) : const Color(0xFF00C853);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0ECFF), width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x201A6FE8), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Horas badge
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.70)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: color.withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 3),
                )],
              ),
              child: Center(
                child: Text('${horas}h', style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white,
                )),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd/MM/yyyy', 'es_ES').format(entrada),
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.login_rounded, size: 12, color: Color(0xFF00C853)),
                      const SizedBox(width: 3),
                      Text(DateFormat('HH:mm').format(entrada),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF00C853), fontWeight: FontWeight.w600)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF6B80A3)),
                      ),
                      const Icon(Icons.logout_rounded, size: 12, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Text(DateFormat('HH:mm').format(salida),
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (esExtra) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Hora extra', style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFFFF9800),
                      )),
                    ),
                  ],
                ],
              ),
            ),
            // Pago
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${pago.toStringAsFixed(2)}', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color,
                )),
                Text('$horas h', style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B80A3),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}