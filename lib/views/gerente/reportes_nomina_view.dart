import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reporte_service.dart';
import '../../services/nomina_service.dart';

class _C {
  static const bg      = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F8FF);
  static const primary = Color(0xFF1A6FE8);
  static const success = Color(0xFF00C853);
  static const text    = Color(0xFF0D1B3E);
  static const textSub = Color(0xFF6B80A3);
  static const divider = Color(0xFFE0ECFF);
  static const shadow  = Color(0x201A6FE8);
}

class ReportesNominaScreen extends StatefulWidget {
  const ReportesNominaScreen({super.key});

  @override
  State<ReportesNominaScreen> createState() => _ReportesNominaScreenState();
}

class _ReportesNominaScreenState extends State<ReportesNominaScreen>
    with SingleTickerProviderStateMixin {
  final ReporteService _reporteService = ReporteService();
  final NominaService  _nominaService  = NominaService();

  DateTime _mesSeleccionado = DateTime.now();
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoading     = true;
  bool _exportLoading = false;
  String? _generando;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarEmpleados();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => _isLoading = true);
    final data = await _nominaService.obtenerEmpleados();
    setState(() {
      _empleados = data;
      _isLoading = false;
    });
  }

  Future<void> _exportarGeneral() async {
    setState(() => _exportLoading = true);
    final excel = await _reporteService.generarReporteGeneral(_mesSeleccionado);
    await _reporteService.guardarYCompartirExcel(
      excel,
      'reporte_general_${DateFormat('yyyyMM').format(_mesSeleccionado)}',
    );
    setState(() => _exportLoading = false);
    _showSnack('Reporte general exportado');
  }

  Future<void> _exportarEmpleado(Map<String, dynamic> empleado) async {
    setState(() => _generando = empleado['id']);
    final excel = await _reporteService.generarReporteNomina(
      _mesSeleccionado, empleado['id'],
    );
    await _reporteService.guardarYCompartirExcel(
      excel,
      'reporte_${empleado['nombre']}_${DateFormat('yyyyMM').format(_mesSeleccionado)}',
    );
    setState(() => _generando = null);
    _showSnack('Reporte de ${empleado['nombre']} generado');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _C.success,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildMesSelector(),
                  _buildExportarGeneral(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reportes individuales',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _C.textSub,
                              letterSpacing: 2,
                            )),
                        Text('${_empleados.length} empleados',
                            style: const TextStyle(fontSize: 12, color: _C.textSub)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: _empleados.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final emp = _empleados[i];
                        final isGen = _generando == emp['id'];
                        return _EmpleadoNominaTile(
                          empleado: emp,
                          isGenerating: isGen,
                          onTap: () => _exportarEmpleado(emp),
                        );
                      },
                    ),
                  ),
                ],
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
      title: const Text('Reportes de Nómina',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _C.text)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
    );
  }

  Widget _buildMesSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(
            icon: Icons.chevron_left_rounded,
            onTap: () => setState(() {
              _mesSeleccionado = DateTime(
                  _mesSeleccionado.year, _mesSeleccionado.month - 1);
            }),
          ),
          Column(
            children: [
              const Text('Período seleccionado',
                  style: TextStyle(fontSize: 11, color: _C.textSub)),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM yyyy').format(_mesSeleccionado),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16, color: _C.text),
              ),
            ],
          ),
          _NavBtn(
            icon: Icons.chevron_right_rounded,
            onTap: () => setState(() {
              _mesSeleccionado = DateTime(
                  _mesSeleccionado.year, _mesSeleccionado.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildExportarGeneral() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: _exportLoading ? null : _exportarGeneral,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A6FE8), Color(0xFF4D96FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_exportLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              else
                const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
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
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.divider),
          boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: _C.primary, size: 20),
      ),
    );
  }
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
          color: isGenerating ? _C.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGenerating ? _C.primary.withOpacity(0.30) : _C.divider,
            width: 1.2,
          ),
          boxShadow: const [BoxShadow(color: _C.shadow, blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.success,
                      _C.success.withOpacity(0.70),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.success.withOpacity(0.30),
                      blurRadius: 10, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                      )),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empleado['nombre'],
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _C.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.attach_money_rounded, size: 14, color: _C.textSub),
                        Text(
                          '\$${empleado['salario_por_hora']}/hora',
                          style: const TextStyle(fontSize: 12, color: _C.textSub),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón exportar
              if (isGenerating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: _C.primary, strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _C.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _C.success.withOpacity(0.25), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          color: _C.success, size: 16),
                      SizedBox(width: 4),
                      Text('Exportar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.success,
                          )),
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