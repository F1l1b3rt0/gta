import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const shadow  = Color(0x201A6FE8);
}

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;
  String _periodo = 'mes';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _isLoading = true);
    try {
      final empleados = await Supabase.instance.client
          .from('empleados')
          .select('id, rol');
      final totalEmpleados = empleados.length;
      final gerentes = empleados.where((e) => e['rol'] == 'gerente').length;

      DateTime inicio;
      final fin = DateTime.now();
      if (_periodo == 'semana') {
        inicio = fin.subtract(const Duration(days: 7));
      } else if (_periodo == 'mes') {
        inicio = DateTime(fin.year, fin.month - 1, fin.day);
      } else {
        inicio = DateTime(fin.year - 1, fin.month, fin.day);
      }

      final turnos = await Supabase.instance.client
          .from('turnos')
          .select('*, empleados(nombre, salario_por_hora)')
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .not('salida', 'is', null);

      double normales = 0, extras = 0, nomina = 0;
      for (var t in turnos) {
        final entrada = DateTime.parse(t['entrada']);
        final salida  = DateTime.parse(t['salida']);
        final horas   = salida.difference(entrada).inHours.toDouble();
        final esExtra = t['es_extra'] ?? false;
        final salario = (t['empleados']['salario_por_hora'] ?? 0).toDouble();
        if (esExtra) {
          extras += horas;
          nomina += horas * salario * 1.5;
        } else {
          normales += horas;
          nomina   += horas * salario;
        }
      }

      setState(() {
        _estadisticas = {
          'total_empleados': totalEmpleados,
          'empleados_activos': totalEmpleados - gerentes,
          'gerentes': gerentes,
          'horas_normales': normales,
          'horas_extras': extras,
          'total_horas': normales + extras,
          'nomina_total': nomina,
          'turnos_totales': turnos.length,
        };
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
                    _buildSectionTitle('Resumen general'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Distribución de horas'),
                    const SizedBox(height: 12),
                    _buildHorasCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Nómina estimada'),
                    const SizedBox(height: 12),
                    _buildNominaCard(),
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
      title: const Text('Estadísticas',
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
            onPressed: _cargarEstadisticas,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _C.textSub,
        letterSpacing: 2.0,
      ),
    );
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
          _PTab('Semana', 'semana'),
          _PTab('Mes', 'mes'),
          _PTab('Año', 'año'),
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
          _cargarEstadisticas();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? _C.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [BoxShadow(
                    color: _C.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 3))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : _C.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatData(
        label: 'Empleados',
        value: '${_estadisticas['total_empleados'] ?? 0}',
        sub: '${_estadisticas['empleados_activos'] ?? 0} activos',
        icon: Icons.people_alt_rounded,
        color: _C.primary,
      ),
      _StatData(
        label: 'Horas',
        value: '${(_estadisticas['total_horas'] ?? 0).toInt()}h',
        sub: '${(_estadisticas['horas_extras'] ?? 0).toInt()} extras',
        icon: Icons.timer_rounded,
        color: const Color(0xFFFF9800),
      ),
      _StatData(
        label: 'Nómina',
        value: '\$${(_estadisticas['nomina_total'] ?? 0).toStringAsFixed(0)}',
        sub: 'Total período',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF00C853),
      ),
      _StatData(
        label: 'Turnos',
        value: '${_estadisticas['turnos_totales'] ?? 0}',
        sub: 'Registrados',
        icon: Icons.event_note_rounded,
        color: const Color(0xFF7C4DFF),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _StatCard(data: cards[i]),
    );
  }

  Widget _buildHorasCard() {
    final normales = (_estadisticas['horas_normales'] ?? 0).toDouble();
    final extras   = (_estadisticas['horas_extras']   ?? 0).toDouble();
    final total    = (_estadisticas['total_horas']    ?? 1).toDouble();
    final pct      = (extras / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HBar(
                label: 'Normales',
                value: normales,
                total: total,
                color: _C.primary,
              ),
              const SizedBox(width: 24),
              _HBar(
                label: 'Extras',
                value: extras,
                total: total,
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso personalizada
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: _C.primary.withOpacity(0.15),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${normales.toInt()}h normales',
                  style: const TextStyle(fontSize: 12, color: _C.primary, fontWeight: FontWeight.w600)),
              Text('${(pct * 100).toStringAsFixed(0)}% extras',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNominaCard() {
    final nomina = (_estadisticas['nomina_total'] ?? 0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6FE8), Color(0xFF4D96FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('Nómina estimada del período',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\$${nomina.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Basado en ${_estadisticas['turnos_totales'] ?? 0} turnos registrados',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatData {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _StatData({required this.label, required this.value, required this.sub,
      required this.icon, required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.divider, width: 1.2),
        boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(data.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: data.color,
              )),
          Text(data.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.text)),
          const SizedBox(height: 2),
          Text(data.sub, style: const TextStyle(fontSize: 11, color: _C.textSub)),
        ],
      ),
    );
  }
}

class _HBar extends StatelessWidget {
  final String label;
  final double value, total;
  final Color color;

  const _HBar({
    required this.label, required this.value,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${value.toInt()}h',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, color: _C.textSub)),
        ],
      ),
    );
  }
}