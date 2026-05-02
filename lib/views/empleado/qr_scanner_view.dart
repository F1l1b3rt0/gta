import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const success = Color(0xFF00C853);
  static const warn    = Color(0xFFFF9800);
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _cameraCtrl = MobileScannerController();

  bool _isProcessing    = false;
  String? _empleadoId;
  bool _tieneTurnoHoy   = false;
  bool _yaMarcoEntrada  = false;
  Map<String, dynamic>? _turnoActual;
  String _horaEntrada   = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _obtenerEmpleadoId().then((_) => _verificarEstadoHoy());
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerEmpleadoId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() => _empleadoId = user.id);
    }
  }

  Future<void> _verificarEstadoHoy() async {
    if (_empleadoId == null) return;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final turno = await Supabase.instance.client
        .from('turnos')
        .select()
        .eq('empleado_id', _empleadoId!)
        .gte('entrada', '$hoy 00:00:00')
        .lte('entrada', '$hoy 23:59:59')
        .maybeSingle();

    if (mounted) {
      setState(() {
        _tieneTurnoHoy  = turno != null;
        _yaMarcoEntrada = turno != null && turno['salida'] == null;
        _turnoActual    = turno;
        if (turno != null && turno['entrada'] != null) {
          _horaEntrada = DateFormat('HH:mm').format(DateTime.parse(turno['entrada']));
        }
      });
    }
  }

  Future<void> _registrarEntrada() async {
    if (_isProcessing || _empleadoId == null) return;
    setState(() => _isProcessing = true);
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final existente = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', _empleadoId!)
          .gte('entrada', '$hoy 00:00:00')
          .lte('entrada', '$hoy 23:59:59')
          .maybeSingle();

      if (existente != null && existente['salida'] == null) {
        _showSnack('Ya tienes una entrada activa', isWarn: true);
        return;
      }
      if (existente != null && existente['salida'] != null) {
        _showSnack('Ya completaste tu turno hoy', isWarn: true);
        return;
      }

      await Supabase.instance.client.from('turnos').insert({
        'empleado_id': _empleadoId,
        'entrada': DateTime.now().toIso8601String(),
      }).select();

      _showSnack('Entrada registrada a las ${DateFormat('HH:mm').format(DateTime.now())}',
          isSuccess: true);
      await _verificarEstadoHoy();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _registrarSalida() async {
    if (_isProcessing || _turnoActual == null) return;
    setState(() => _isProcessing = true);
    try {
      await Supabase.instance.client
          .from('turnos')
          .update({'salida': DateTime.now().toIso8601String()})
          .eq('id', _turnoActual!['id']);

      _showSnack('Salida registrada a las ${DateFormat('HH:mm').format(DateTime.now())}',
          isSuccess: true);
      await _verificarEstadoHoy();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isWarn = false}) {
    final color = isSuccess ? _C.success : isWarn ? _C.warn : Colors.redAccent;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusBanner(),
          Expanded(child: _buildScanner()),
          _buildActionArea(),
        ],
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
      title: const Text('Registro de Asistencia',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _C.text)),
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
            onPressed: _verificarEstadoHoy,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final Color color;
    final IconData icon;
    final String titulo, subtitulo;

    if (!_tieneTurnoHoy) {
      color    = _C.textSub;
      icon     = Icons.event_busy_rounded;
      titulo   = 'Sin turno hoy';
      subtitulo = 'No tienes turno asignado para hoy';
    } else if (_yaMarcoEntrada) {
      color    = _C.success;
      icon     = Icons.check_circle_rounded;
      titulo   = 'Turno en curso';
      subtitulo = 'Entrada: $_horaEntrada · Escanea para registrar salida';
    } else if (_tieneTurnoHoy && !_yaMarcoEntrada && _turnoActual != null) {
      color    = _C.textSub;
      icon     = Icons.done_all_rounded;
      titulo   = 'Turno completado';
      subtitulo = 'Ya registraste entrada y salida hoy';
    } else {
      color    = _C.warn;
      icon     = Icons.schedule_rounded;
      titulo   = 'Turno pendiente';
      subtitulo = 'Escanea el QR para registrar tu entrada';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.4),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: (_tieneTurnoHoy && _yaMarcoEntrada) ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color,
                )),
                const SizedBox(height: 2),
                Text(subtitulo, style: const TextStyle(
                  fontSize: 12, color: _C.textSub,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.primary.withOpacity(0.30), width: 1.5),
        boxShadow: [BoxShadow(
          color: _C.primary.withOpacity(0.15),
          blurRadius: 24, offset: const Offset(0, 8),
        )],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          MobileScanner(
            controller: _cameraCtrl,
            onDetect: (capture) {
              // QR detectado — procesar si es necesario
            },
          ),
          // Overlay con visor
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Esquinas
                  Positioned(top: 0, left: 0, child: _Corner()),
                  Positioned(top: 0, right: 0, child: _Corner(flipH: true)),
                  Positioned(bottom: 0, left: 0, child: _Corner(flipV: true)),
                  Positioned(bottom: 0, right: 0, child: _Corner(flipH: true, flipV: true)),
                ],
              ),
            ),
          ),
          // Instrucción overlay
          Positioned(
            bottom: 16,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código QR del negocio',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        children: [
          if (!_tieneTurnoHoy || (_tieneTurnoHoy && _turnoActual != null && _turnoActual!['salida'] == null && !_yaMarcoEntrada))
            _ActionButton(
              label: 'Registrar Entrada',
              icon: Icons.login_rounded,
              color: _C.success,
              loading: _isProcessing,
              onTap: _registrarEntrada,
            ),
          if (_yaMarcoEntrada) ...[
            _ActionButton(
              label: 'Registrar Salida',
              icon: Icons.logout_rounded,
              color: Colors.redAccent,
              loading: _isProcessing,
              onTap: _registrarSalida,
            ),
          ],
          if (!_tieneTurnoHoy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'No tienes turno asignado para hoy',
                style: TextStyle(fontSize: 13, color: _C.textSub),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final bool flipH, flipV;

  const _Corner({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: SizedBox(
        width: 24, height: 24,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A6FE8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18, offset: const Offset(0, 6),
          )],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ),
    );
  }
}