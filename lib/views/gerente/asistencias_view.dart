// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../services/tr.dart';

class AsistenciasView extends StatefulWidget {
  const AsistenciasView({super.key});
  @override
  State<AsistenciasView> createState() => _AsistenciasViewState();
}

class _AsistenciasViewState extends State<AsistenciasView> {
  final MobileScannerController _cam = MobileScannerController();
  bool _scanning = true;
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await Supabase.instance.client
          .from('asistencias')
          .select('*, empleados(nombre)')
          .eq('fecha', hoy)
          .order('hora_entrada', ascending: false);
      if (mounted) setState(() {
        _asistencias = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onQrDetected(String value) async {
    if (!_scanning) return;
    setState(() => _scanning = false);
    final empleadoId = value.trim();
    // Pre-resolve translated strings before async gaps
    final msgQrNoReconocido = trStatic(context, 'QR no reconocido', 'QR not recognized');
    final msgProcesando = trStatic(context, '⚠️ Tardanza', '⚠️ Late');
    final msgPresente = trStatic(context, '✅ Presente', '✅ Present');
    final msgYaRegistro = trStatic(context, 'ya registró asistencia hoy', 'already registered today');
    try {
      final emp = await Supabase.instance.client
          .from('empleados')
          .select('id, nombre')
          .eq('id', empleadoId)
          .maybeSingle();

      if (emp == null) {
        if (mounted) _showSnack(msgQrNoReconocido, isError: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _scanning = true);
        return;
      }

      final nombre = emp['nombre'] as String? ?? 'Empleado';
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if already registered today
      final existing = await Supabase.instance.client
          .from('asistencias')
          .select('id, estado')
          .eq('empleado_id', empleadoId)
          .eq('fecha', hoy)
          .maybeSingle();

      if (existing != null) {
        if (mounted) _showSnack('$nombre $msgYaRegistro', isWarn: true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _scanning = true);
        return;
      }

      // Determine estado: check scheduled shift time
      String estado = 'presente';
      final horaActual = DateTime.now();
      final turno = await Supabase.instance.client
          .from('turnos')
          .select('entrada')
          .eq('empleado_id', empleadoId)
          .gte('entrada', '${hoy}T00:00:00')
          .lte('entrada', '${hoy}T23:59:59')
          .maybeSingle();

      if (turno != null && turno['entrada'] != null) {
        final horaEntradaTurno = DateTime.parse(turno['entrada']);
        // 15 min tolerance
        if (horaActual.isAfter(horaEntradaTurno.add(const Duration(minutes: 15)))) {
          estado = 'tardanza';
        }
      }

      // hora_entrada is stored as TIME (HH:mm:ss)
      final horaStr = DateFormat('HH:mm:ss').format(horaActual);
      await Supabase.instance.client.from('asistencias').insert({
        'empleado_id': empleadoId,
        'fecha': hoy,
        'hora_entrada': horaStr,
        'estado': estado,
      });

      final hora = DateFormat('HH:mm').format(horaActual);
      final estadoLabel = estado == 'tardanza' ? msgProcesando : msgPresente;
      if (mounted) _showSnack('$nombre — $estadoLabel ($hora)', isSuccess: estado == 'presente');
      await _cargar();
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _scanning = true);
  }

  Future<void> _marcarFaltas() async {
    // Pre-resolve strings before async gap
    final msgFaltasSingular = trStatic(context, 'falta marcada', 'absence marked');
    final msgFaltasPlural = trStatic(context, 'faltas marcadas', 'absences marked');
    try {
      final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final turnos = await Supabase.instance.client
          .from('turnos')
          .select('empleado_id')
          .gte('entrada', '${hoy}T00:00:00')
          .lte('entrada', '${hoy}T23:59:59');

      final yaRegistrados = _asistencias.map((a) => a['empleado_id'] as String).toSet();
      int count = 0;

      for (final t in turnos as List) {
        final eid = t['empleado_id'] as String;
        if (!yaRegistrados.contains(eid)) {
          try {
            await Supabase.instance.client.from('asistencias').upsert({
              'empleado_id': eid,
              'fecha': hoy,
              'hora_entrada': null,
              'estado': 'falta',
            }, onConflict: 'empleado_id,fecha');
            count++;
          } catch (_) {}
        }
      }

      if (mounted) _showSnack('$count ${count != 1 ? msgFaltasPlural : msgFaltasSingular}');
      await _cargar();
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false, bool isWarn = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError
          ? Colors.redAccent
          : isWarn
          ? const Color(0xFFFF9800)
          : isSuccess
          ? const Color(0xFF00C853)
          : cs.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 4 : 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(children: [
          _buildTopBar(cs),
          kIsWeb ? _buildWebPlaceholder(cs) : _buildScanner(cs),
          _buildStats(cs),
          Expanded(child: _buildLista(cs)),
        ]),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Row(children: [
      Visibility(
        visible: Navigator.canPop(context),
        maintainSize: true, maintainAnimation: true, maintainState: true,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withAlpha(40), width: 1.5)),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: cs.primary)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(
        tr(context, 'Asistencias de hoy', "Today's Attendance"),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface))),
      GestureDetector(
        onTap: _marcarFaltas,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.redAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.redAccent.withAlpha(80))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_rounded, color: Colors.redAccent, size: 15),
            const SizedBox(width: 4),
            Text(tr(context, 'Marcar faltas', 'Mark absent'),
              style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _cargar,
        child: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.primary.withAlpha(40))),
          child: Icon(Icons.refresh_rounded, color: cs.primary, size: 18)),
      ),
    ]),
  );

  Widget _buildWebPlaceholder(ColorScheme cs) => Container(
    height: 130,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.primary.withAlpha(40))),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.qr_code_scanner_rounded, size: 40, color: cs.primary.withAlpha(150)),
      const SizedBox(height: 8),
      Text(tr(context, 'Escáner no disponible en web\nUsa la app móvil', 'Scanner not available on web\nUse mobile app'),
        style: TextStyle(color: cs.onSurface.withAlpha(150), fontSize: 13), textAlign: TextAlign.center),
    ])),
  );

  Widget _buildScanner(ColorScheme cs) => Container(
    height: 170,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cs.primary.withAlpha(60), width: 1.5)),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      MobileScanner(
        controller: _cam,
        onDetect: (capture) {
          if (!_scanning) return;
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final val = barcodes.first.rawValue ?? '';
            if (val.isNotEmpty) _onQrDetected(val);
          }
        },
      ),
      if (!_scanning)
        Container(
          color: Colors.black45,
          child: const Center(child: CircularProgressIndicator(color: Colors.white))),
      Positioned(bottom: 10, left: 0, right: 0,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
          child: Text(
            _scanning
              ? tr(context, 'Apunta al QR del empleado', "Point at employee's QR")
              : tr(context, 'Procesando...', 'Processing...'),
            style: const TextStyle(color: Colors.white, fontSize: 12))))),
    ]),
  );

  Widget _buildStats(ColorScheme cs) {
    final presentes = _asistencias.where((a) => a['estado'] == 'presente').length;
    final tardanzas = _asistencias.where((a) => a['estado'] == 'tardanza').length;
    final faltas = _asistencias.where((a) => a['estado'] == 'falta').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        _StatChip(label: tr(context, 'Presentes', 'Present'), value: presentes, color: const Color(0xFF00C853)),
        const SizedBox(width: 8),
        _StatChip(label: tr(context, 'Tardanzas', 'Late'), value: tardanzas, color: const Color(0xFFFF9800)),
        const SizedBox(width: 8),
        _StatChip(label: tr(context, 'Faltas', 'Absent'), value: faltas, color: Colors.redAccent),
      ]),
    );
  }

  Widget _buildLista(ColorScheme cs) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: cs.primary));
    if (_asistencias.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.event_available_rounded, size: 48, color: cs.primary.withAlpha(100)),
      const SizedBox(height: 12),
      Text(tr(context, 'Sin registros hoy', 'No records today'),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
      const SizedBox(height: 6),
      Text(tr(context, 'Escanea los QR de los empleados', 'Scan employee QR codes'),
        style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(150))),
    ]));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: _asistencias.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AsistenciaTile(asistencia: _asistencias[i]),
    );
  }
}

// ─── Chips & Tiles ────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Column(children: [
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _AsistenciaTile extends StatelessWidget {
  final Map<String, dynamic> asistencia;
  const _AsistenciaTile({required this.asistencia});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estado = asistencia['estado'] as String? ?? 'presente';
    final nombre = (asistencia['empleados'] as Map?)?['nombre'] as String? ?? '—';
    final horaEntrada = asistencia['hora_entrada'];
    String horaStr = '';
    if (horaEntrada != null) {
      try { horaStr = DateFormat('HH:mm').format(DateTime.parse(horaEntrada).toLocal()); } catch (_) {}
    }

    final Color color;
    final IconData icon;
    final String label;
    switch (estado) {
      case 'tardanza':
        color = const Color(0xFFFF9800);
        icon = Icons.schedule_rounded;
        label = tr(context, 'Tardanza', 'Late');
        break;
      case 'falta':
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        label = tr(context, 'Falta', 'Absent');
        break;
      default:
        color = const Color(0xFF00C853);
        icon = Icons.check_circle_rounded;
        label = tr(context, 'Presente', 'Present');
    }

    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20), width: 1.4),
        boxShadow: [BoxShadow(color: cs.primary.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.12),
          child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nombre, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
          if (horaStr.isNotEmpty)
            Text('${tr(context, 'Entrada', 'Entry')}: $horaStr',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ]),
    );
  }
}
