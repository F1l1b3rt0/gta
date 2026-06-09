// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const primary      = Color(0xFF0F2DA6);
  static const primaryLight = Color(0xFF1A4FD8);
  static const textPrimary  = Color(0xFF1A2A4A);
  static const textSecondary= Color(0xFF5A7DBA);
  static const border       = Color(0xFFC8DEFF);
  static const divider      = Color(0xFFDDEEFF);
  static const shadowSm     = Color(0x201A4FD8);
}

class EstadisticasView extends StatefulWidget {
  const EstadisticasView({super.key});
  @override State<EstadisticasView> createState() => _EstadisticasViewState();
}

class _EstadisticasViewState extends State<EstadisticasView> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _periodo = 'mes';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargar();
  }
  @override void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final empleados = await Supabase.instance.client.from('empleados').select('id, rol');
      final total = empleados.length;
      final gerentes = empleados.where((e) => e['rol'] == 'gerente').length;
      final fin = DateTime.now();
      final inicio = _periodo == 'semana' ? fin.subtract(const Duration(days: 7))
          : _periodo == 'mes' ? DateTime(fin.year, fin.month - 1, fin.day)
          : DateTime(fin.year - 1, fin.month, fin.day);
      final turnos = await Supabase.instance.client.from('turnos')
          .select('*, empleados(nombre, salario_por_hora)')
          .gte('entrada', inicio.toIso8601String()).lte('entrada', fin.toIso8601String())
          .not('salida', 'is', null);
      double normales = 0, extras = 0, nomina = 0;
      for (var t in turnos) {
        final h = DateTime.parse(t['salida']).difference(DateTime.parse(t['entrada'])).inHours.toDouble();
        final salario = (t['empleados']['salario_por_hora'] ?? 0).toDouble();
        if (t['es_extra'] == true) { extras += h; nomina += h * salario * 1.5; }
        else { normales += h; nomina += h * salario; }
      }
      setState(() {
        _stats = {'total_empleados': total, 'empleados_activos': total - gerentes, 'gerentes': gerentes,
          'horas_normales': normales, 'horas_extras': extras, 'total_horas': normales + extras,
          'nomina_total': nomina, 'turnos_totales': turnos.length};
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0,
          child: CustomPaint(size: Size(MediaQuery.of(context).size.width, 60), painter: _WavePainter())),
        SafeArea(child: Column(children: [
          _buildTopBar(),
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _C.primaryLight))
            : FadeTransition(opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildPeriodoSelector(),
                    const SizedBox(height: 20),
                    _sectionLabel('Resumen general'),
                    const SizedBox(height: 12),
                    _buildGrid(),
                    const SizedBox(height: 24),
                    _sectionLabel('Distribución de horas'),
                    const SizedBox(height: 12),
                    _buildHorasCard(),
                    const SizedBox(height: 24),
                    _sectionLabel('Nómina estimada'),
                    const SizedBox(height: 12),
                    _buildNominaCard(),
                  ])))),
        ])),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(children: [
      _ScaleBtn(onPressed: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.5),
            boxShadow: [BoxShadow(color: _C.border.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _C.primaryLight))),
      const SizedBox(width: 14),
      const Text('Estadísticas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _C.textPrimary)),
      const Spacer(),
      _ScaleBtn(onPressed: _cargar,
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.2),
            boxShadow: [BoxShadow(color: _C.shadowSm, blurRadius: 8, offset: const Offset(0, 2))]),
          child: const Icon(Icons.refresh_rounded, color: _C.primaryLight, size: 18))),
    ]));

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textSecondary, letterSpacing: 2.0));

  Widget _buildPeriodoSelector() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border, width: 1.2)),
    child: Row(children: [_PTab('Semana','semana'), _PTab('Mes','mes'), _PTab('Año','año')]));

  Widget _PTab(String label, String value) {
    final sel = _periodo == value;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _periodo = value); _cargar(); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _C.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: sel ? [BoxShadow(color: _C.primaryLight.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 3))] : []),
        child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: sel ? Colors.white : _C.textSecondary))))));
  }

  Widget _buildGrid() {
    final cards = [
      _SD('Empleados','${_stats['total_empleados']??0}','${_stats['empleados_activos']??0} activos',Icons.people_alt_rounded,_C.primaryLight),
      _SD('Horas','${(_stats['total_horas']??0).toInt()}h','${(_stats['horas_extras']??0).toInt()} extras',Icons.timer_rounded,const Color(0xFFFF9800)),
      _SD('Nómina','\$${(_stats['nomina_total']??0).toStringAsFixed(0)}','Total período',Icons.attach_money_rounded,const Color(0xFF00C853)),
      _SD('Turnos','${_stats['turnos_totales']??0}','Registrados',Icons.event_note_rounded,const Color(0xFF7C4DFF)),
    ];
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25),
      itemCount: cards.length, itemBuilder: (_, i) => _StatCard(data: cards[i]));
  }

  Widget _buildHorasCard() {
    final normales = (_stats['horas_normales']??0).toDouble();
    final extras   = (_stats['horas_extras']??0).toDouble();
    final total    = (_stats['total_horas']??1).toDouble();
    final pct      = (extras/total).clamp(0.0,1.0);
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border, width: 1.4),
        boxShadow: const [BoxShadow(color: _C.shadowSm, blurRadius: 12, offset: Offset(0, 4))]),
      child: Column(children: [
        Row(children: [
          _HBar('Normales', normales, total, _C.primaryLight),
          const SizedBox(width: 24),
          _HBar('Extras', extras, total, const Color(0xFFFF9800)),
        ]),
        const SizedBox(height: 20),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            Container(height: 12, color: _C.primaryLight.withOpacity(0.15)),
            FractionallySizedBox(widthFactor: pct,
              child: Container(height: 12, decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFF6F00)])))),
          ])),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${normales.toInt()}h normales', style: const TextStyle(fontSize: 12, color: _C.primaryLight, fontWeight: FontWeight.w600)),
          Text('${(pct*100).toStringAsFixed(0)}% extras', style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800), fontWeight: FontWeight.w600)),
        ]),
      ]));
  }

  Widget _buildNominaCard() {
    final nomina = (_stats['nomina_total']??0).toDouble();
    return Container(width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_C.primary, _C.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _C.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 20),
          SizedBox(width: 8),
          Text('Nómina estimada del período', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        Text('\$${nomina.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('Basado en ${_stats['turnos_totales']??0} turnos registrados', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]));
  }
}

class _SD { final String label,value,sub; final IconData icon; final Color color;
  const _SD(this.label,this.value,this.sub,this.icon,this.color); }

class _StatCard extends StatelessWidget {
  final _SD data; const _StatCard({required this.data});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.border, width: 1.4),
      boxShadow: const [BoxShadow(color: _C.shadowSm, blurRadius: 10, offset: Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: data.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(data.icon, color: data.color, size: 22)),
      const SizedBox(height: 10),
      Text(data.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: data.color)),
      Text(data.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.textPrimary)),
      const SizedBox(height: 2),
      Text(data.sub, style: const TextStyle(fontSize: 11, color: _C.textSecondary)),
    ]));
}

class _HBar extends StatelessWidget {
  final String label; final double value,total; final Color color;
  const _HBar(this.label,this.value,this.total,this.color);
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value/total : 0.0;
    return Expanded(child: Column(children: [
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      const SizedBox(height: 6),
      Text('${value.toInt()}h', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text('${(pct*100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: _C.textSecondary)),
    ]));
  }
}

class _ScaleBtn extends StatefulWidget {
  final VoidCallback? onPressed; final Widget child;
  const _ScaleBtn({required this.onPressed, required this.child});
  @override State<_ScaleBtn> createState() => _ScaleBtnState();
}
class _ScaleBtnState extends State<_ScaleBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.94, upperBound: 1.0, value: 1.0); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.reverse(), onTapUp: (_) { _c.forward(); widget.onPressed?.call(); }, onTapCancel: () => _c.forward(),
    child: AnimatedBuilder(animation: _c, builder: (_, child) => Transform.scale(scale: _c.value, child: child), child: widget.child));
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.25, size.height * 0.15, size.width * 0.75, size.height * 0.85, size.width, size.height * 0.43)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close(),
      Paint()..color = const Color(0xFFDDEEFF).withOpacity(0.7)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter _) => false;
}