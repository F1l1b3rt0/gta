// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reporte_service.dart';
import '../../services/nomina_service.dart';

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

class ReportesNominaView extends StatefulWidget {
  const ReportesNominaView({super.key});
  @override
  State<ReportesNominaView> createState() => _ReportesNominaViewState();
}

class _ReportesNominaViewState extends State<ReportesNominaView>
    with SingleTickerProviderStateMixin {
  final ReporteService _reporteService = ReporteService();
  final NominaService _nominaService = NominaService();
  DateTime _mes = DateTime.now();
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoading = true, _exportLoading = false;
  String? _generando;
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
    final data = await _nominaService.obtenerEmpleados();
    setState(() {
      _empleados = data;
      _isLoading = false;
    });
  }

  Future<void> _exportarGeneral() async {
    setState(() => _exportLoading = true);
    final excel = await _reporteService.generarReporteGeneral(_mes);
    await _reporteService.guardarYCompartirExcel(
      excel,
      'reporte_general_${DateFormat('yyyyMM').format(_mes)}',
    );
    setState(() => _exportLoading = false);
    _showSnack('Reporte general exportado');
  }

  Future<void> _exportarEmpleado(Map<String, dynamic> emp) async {
    setState(() => _generando = emp['id']);
    final excel = await _reporteService.generarReporteNomina(_mes, emp['id']);
    await _reporteService.guardarYCompartirExcel(
      excel,
      'reporte_${emp['nombre']}_${DateFormat('yyyyMM').format(_mes)}',
    );
    setState(() => _generando = null);
    _showSnack('Reporte de ${emp['nombre']} generado');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  0,
                                ),
                                child: _buildMesSelector(),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  0,
                                ),
                                child: _buildExportarGeneral(),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'REPORTES INDIVIDUALES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      '${_empleados.length} empleados',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    6,
                                    16,
                                    60,
                                  ),
                                  itemCount: _empleados.length,
                                  separatorBuilder: (_, _) =>
                                      SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final emp = _empleados[i];
                                    return _EmpleadoNominaTile(
                                      empleado: emp,
                                      isGenerating: _generando == emp['id'],
                                      onTap: () => _exportarEmpleado(emp),
                                    );
                                  },
                                ),
                              ),
                            ],
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
              border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(40).withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
          'Reportes de Nómina',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );

  Widget _buildMesSelector() => Container(
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
          onTap: () =>
              setState(() => _mes = DateTime(_mes.year, _mes.month - 1)),
        ),
        Column(
          children: [
            Text(
              'Período seleccionado',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
            ),
            SizedBox(height: 2),
            Text(
              DateFormat('MMMM yyyy').format(_mes),
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
          onTap: () =>
              setState(() => _mes = DateTime(_mes.year, _mes.month + 1)),
        ),
      ],
    ),
  );

  Widget _buildExportarGeneral() => _ScaleBtn(
    onPressed: _exportLoading ? null : _exportarGeneral,
    child: Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _exportLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 20,
                ),
          SizedBox(width: 10),
          Text(
            'Exportar Reporte General',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(40)),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
    ),
  );
}

class _EmpleadoNominaTile extends StatelessWidget {
  final Map<String, dynamic> empleado;
  final bool isGenerating;
  final VoidCallback onTap;
  const _EmpleadoNominaTile({
    required this.empleado,
    required this.isGenerating,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final initial = (empleado['nombre'] as String).isNotEmpty
        ? (empleado['nombre'] as String)[0].toUpperCase()
        : '?';
    return GestureDetector(
      onTap: isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isGenerating
              ? Theme.of(context).colorScheme.primary.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGenerating ? Theme.of(context).colorScheme.primary.withOpacity(0.30) : Theme.of(context).colorScheme.primary.withAlpha(40),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.primary.withAlpha(15), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00C853), const Color(0xFF00C853).withOpacity(0.70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                      empleado['nombre'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                        ),
                        Text(
                          '\$${empleado['salario_por_hora']}/hora',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00C853).withOpacity(0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: const Color(0xFF00C853),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Exportar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00C853),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
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
