// ignore_for_file: unused_field, curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class _C {
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF4F8FF);
  static const primary      = Color(0xFF0F2DA6);
  static const primaryLight = Color(0xFF1A4FD8);
  static const textPrimary  = Color(0xFF1A2A4A);
  static const textSecondary= Color(0xFF5A7DBA);
  static const border       = Color(0xFFC8DEFF);
  static const shadowSm     = Color(0x201A4FD8);
  static const success      = Color(0xFF00C853);
  static const warn         = Color(0xFFFF9800);
}

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});
  @override State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> with SingleTickerProviderStateMixin {
  final MobileScannerController _cam = MobileScannerController();
  bool _isProcessing = false;
  String? _empleadoId;
  bool _tieneTurnoHoy = false;
  bool _yaMarcoEntrada = false;
  Map<String,dynamic>? _turnoActual;
  String _horaEntrada = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _obtenerEmpleadoId().then((_) => _verificarEstadoHoy());
  }

  @override void dispose() { _cam.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _obtenerEmpleadoId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) setState(() => _empleadoId = user.id);
  }

  Future<void> _verificarEstadoHoy() async {
    if (_empleadoId == null) return;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final t = await Supabase.instance.client.from('turnos').select()
        .eq('empleado_id', _empleadoId!).gte('entrada','$hoy 00:00:00').lte('entrada','$hoy 23:59:59').maybeSingle();
    if (mounted) setState(() {
      _tieneTurnoHoy  = t != null;
      _yaMarcoEntrada = t != null && t['salida'] == null;
      _turnoActual    = t;
      if (t != null && t['entrada'] != null) _horaEntrada = DateFormat('HH:mm').format(DateTime.parse(t['entrada']));
    });
  }

  Future<void> _registrarEntrada() async {
    if (_isProcessing || _empleadoId == null) return;
    setState(() => _isProcessing = true);
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final existente = await Supabase.instance.client.from('turnos').select()
          .eq('empleado_id', _empleadoId!).gte('entrada','$hoy 00:00:00').lte('entrada','$hoy 23:59:59').maybeSingle();
      if (existente != null && existente['salida'] == null) { _showSnack('Ya tienes una entrada activa', isWarn: true); return; }
      if (existente != null && existente['salida'] != null) { _showSnack('Ya completaste tu turno hoy', isWarn: true); return; }
      await Supabase.instance.client.from('turnos').insert({'empleado_id': _empleadoId, 'entrada': DateTime.now().toIso8601String()}).select();
      _showSnack('Entrada registrada a las ${DateFormat('HH:mm').format(DateTime.now())}', isSuccess: true);
      await _verificarEstadoHoy();
    } catch (e) { _showSnack('Error: $e'); }
    finally { if (mounted) setState(() => _isProcessing = false); }
  }

  Future<void> _registrarSalida() async {
    if (_isProcessing || _turnoActual == null) return;
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client.from('turnos').update({'salida': DateTime.now().toIso8601String()}).eq('id', _turnoActual!['id']);
      _showSnack('Salida registrada a las ${DateFormat('HH:mm').format(DateTime.now())}', isSuccess: true);
      await _verificarEstadoHoy();
    } catch (e) { _showSnack('Error: $e'); }
    finally { if (mounted) setState(() => _isProcessing = false); }
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isWarn = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSuccess ? _C.success : isWarn ? _C.warn : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          backgroundColor: _C.primary,
          foregroundColor: Colors.white,
          title: const Text('Escáner QR'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _C.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner, size: 72, color: _C.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Escáner no disponible en web',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Usa la app móvil para registrar asistencia con QR.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _C.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        Positioned(bottom: 0, left: 0, right: 0,
          child: CustomPaint(size: Size(MediaQuery.of(context).size.width, 60), painter: _WavePainter())),
        SafeArea(child: Column(children: [
          _buildTopBar(),
          _buildStatusBanner(),
          Expanded(child: _buildScanner()),
          _buildActionArea(),
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
      const Text('Registro de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _C.textPrimary)),
      const Spacer(),
      _ScaleBtn(onPressed: _verificarEstadoHoy,
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.2),
            boxShadow: const [BoxShadow(color: _C.shadowSm, blurRadius: 8, offset: Offset(0, 2))]),
          child: const Icon(Icons.refresh_rounded, color: _C.primaryLight, size: 18))),
    ]));

  Widget _buildStatusBanner() {
    final Color color; final IconData icon; final String title, sub;
    if (!_tieneTurnoHoy) {
      color = _C.textSecondary; icon = Icons.event_busy_rounded; title = 'Sin turno hoy'; sub = 'No tienes turno asignado para hoy';
    } else if (_yaMarcoEntrada) {
      color = _C.success; icon = Icons.check_circle_rounded; title = 'Turno en curso'; sub = 'Entrada: $_horaEntrada · Escanea para registrar salida';
    } else if (_tieneTurnoHoy && !_yaMarcoEntrada && _turnoActual != null) {
      color = _C.textSecondary; icon = Icons.done_all_rounded; title = 'Turno completado'; sub = 'Ya registraste entrada y salida hoy';
    } else {
      color = _C.warn; icon = Icons.schedule_rounded; title = 'Turno pendiente'; sub = 'Escanea el QR para registrar tu entrada';
    }
    return Container(margin: const EdgeInsets.fromLTRB(16,8,16,0), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.4)),
      child: Row(children: [
        AnimatedBuilder(animation: _pulseAnim,
          builder: (_, child) => Transform.scale(scale: (_tieneTurnoHoy && _yaMarcoEntrada) ? _pulseAnim.value : 1.0, child: child),
          child: Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 12, color: _C.textSecondary)),
        ])),
      ]));
  }

  Widget _buildScanner() => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _C.primaryLight.withOpacity(0.30), width: 1.5),
      boxShadow: [BoxShadow(color: _C.primaryLight.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))]),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      MobileScanner(controller: _cam, onDetect: (_) {}),
      Center(child: Container(width: 200, height: 200,
        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(16)),
        child: Stack(children: [
          Positioned(top: 0, left: 0, child: _Corner()),
          Positioned(top: 0, right: 0, child: _Corner(flipH: true)),
          Positioned(bottom: 0, left: 0, child: _Corner(flipV: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(flipH: true, flipV: true)),
        ]))),
      Positioned(bottom: 16, left: 0, right: 0,
        child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: const Text('Apunta al código QR del negocio', style: TextStyle(color: Colors.white, fontSize: 13))))),
    ]));

  Widget _buildActionArea() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
    child: Column(children: [
      if (!_tieneTurnoHoy || (_tieneTurnoHoy && _turnoActual != null && _turnoActual!['salida'] == null && !_yaMarcoEntrada))
        _ActionButton(label: 'Registrar Entrada', icon: Icons.login_rounded, color: _C.success, loading: _isProcessing, onTap: _registrarEntrada),
      if (_yaMarcoEntrada)
        _ActionButton(label: 'Registrar Salida', icon: Icons.logout_rounded, color: Colors.redAccent, loading: _isProcessing, onTap: _registrarSalida),
      if (!_tieneTurnoHoy)
        const Padding(padding: EdgeInsets.only(top: 12),
          child: Text('No tienes turno asignado para hoy', style: TextStyle(fontSize: 13, color: _C.textSecondary), textAlign: TextAlign.center)),
    ]));
}

class _Corner extends StatelessWidget {
  final bool flipH, flipV;
  const _Corner({this.flipH = false, this.flipV = false});
  @override
  Widget build(BuildContext context) => Transform.scale(scaleX: flipH ? -1 : 1, scaleY: flipV ? -1 : 1,
    child: SizedBox(width: 24, height: 24, child: CustomPaint(painter: _CornerPainter())));
}
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(Path()..moveTo(0, size.height)..lineTo(0, 0)..lineTo(size.width, 0),
      Paint()..color = _C.primaryLight..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
  }
  @override bool shouldRepaint(_) => false;
}

class _ActionButton extends StatelessWidget {
  final String label; final IconData icon; final Color color; final bool loading; final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.loading, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(onTap: loading ? null : onTap,
      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]))));
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
      ..moveTo(0, size.height * 0.5)..cubicTo(size.width * 0.25, size.height * 0.15, size.width * 0.75, size.height * 0.85, size.width, size.height * 0.43)
      ..lineTo(size.width, size.height)..lineTo(0, size.height)..close(),
      Paint()..color = const Color(0xFFDDEEFF).withOpacity(0.7)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(covariant CustomPainter _) => false;
}