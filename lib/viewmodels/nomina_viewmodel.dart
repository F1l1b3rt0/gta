import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../services/nomina_service.dart';
import '../services/reporte_service.dart';

class NominaViewModel extends BaseViewModel {
  final NominaService _nominaService = NominaService();
  final ReporteService _reporteService = ReporteService();
  
  // Estado de nómina
  List<Map<String, dynamic>> _empleados = [];
  DateTime _mesSeleccionado = DateTime.now();
  Map<String, dynamic> _resumenGeneral = {};
  double _totalNomina = 0;
  bool _exportando = false;
  String? _generandoReportePara;
  
  // Getters
  List<Map<String, dynamic>> get empleados => _empleados;
  DateTime get mesSeleccionado => _mesSeleccionado;
  Map<String, dynamic> get resumenGeneral => _resumenGeneral;
  double get totalNomina => _totalNomina;
  bool get exportando => _exportando;
  String? get generandoReportePara => _generandoReportePara;
  
  String get mesFormateado {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[_mesSeleccionado.month - 1]} ${_mesSeleccionado.year}';
  }
  
  // Cargar empleados
  Future<void> cargarEmpleados() async {
    await runSafe(() async {
      _empleados = await _nominaService.obtenerEmpleados();
    });
  }
  
  // Cambiar mes
  void cambiarMes(int delta) {
    _mesSeleccionado = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + delta,
    );
    notifyListeners();
  }
  
  // Calcular sueldo de un empleado específico
  Future<double> calcularSueldoEmpleado(String empleadoId) async {
    return await runSafe(() async {
      return await _nominaService.calcularSueldoEmpleado(empleadoId, _mesSeleccionado);
    });
  }
  
  // Obtener resumen general
  Future<void> obtenerResumenGeneral() async {
    await runSafe(() async {
      _resumenGeneral = await _nominaService.obtenerResumenGeneral(_mesSeleccionado);
      _totalNomina = _resumenGeneral['total_general'] ?? 0;
    });
  }
  
  // Exportar reporte general
  Future<bool> exportarReporteGeneral() async {
    setExportando(true);
    try {
      final excel = await _reporteService.generarReporteGeneral(_mesSeleccionado);
      await _reporteService.guardarYCompartirExcel(
        excel,
        'reporte_general_${_mesSeleccionado.year}${_mesSeleccionado.month.toString().padLeft(2, '0')}',
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setExportando(false);
    }
  }
  
  // Exportar reporte individual
  Future<bool> exportarReporteEmpleado(String empleadoId, String nombre) async {
    setGenerandoReporte(empleadoId);
    try {
      final excel = await _reporteService.generarReporteNomina(_mesSeleccionado, empleadoId);
      await _reporteService.guardarYCompartirExcel(
        excel,
        'reporte_${nombre}_${_mesSeleccionado.year}${_mesSeleccionado.month.toString().padLeft(2, '0')}',
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setGenerandoReporte(null);
    }
  }
  
  // Calcular horas del empleado
  Future<Map<String, double>> calcularHorasEmpleado(String empleadoId) async {
    final inicio = DateTime(_mesSeleccionado.year, _mesSeleccionado.month, 1);
    final fin = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 0);
    
    final turnos = await Supabase.instance.client
        .from('turnos')
        .select()
        .eq('empleado_id', empleadoId)
        .gte('entrada', inicio.toIso8601String())
        .lte('entrada', fin.toIso8601String())
        .not('salida', 'is', null);
    
    double horasNormales = 0;
    double horasExtras = 0;
    
    for (var turno in turnos) {
      final entrada = DateTime.parse(turno['entrada']);
      final salida = DateTime.parse(turno['salida']);
      final horas = salida.difference(entrada).inHours;
      
      if (turno['es_extra'] == true) {
        horasExtras += horas;
      } else {
        horasNormales += horas;
      }
    }
    
    return {
      'horasNormales': horasNormales,
      'horasExtras': horasExtras,
      'totalHoras': horasNormales + horasExtras,
    };
  }
  
  // Setters privados
  void setExportando(bool value) {
    _exportando = value;
    notifyListeners();
  }
  
  void setGenerandoReporte(String? empleadoId) {
    _generandoReportePara = empleadoId;
    notifyListeners();
  }
  
  // Cargar todos los datos iniciales
  Future<void> cargarDatosIniciales() async {
    await cargarEmpleados();
    await obtenerResumenGeneral();
  }
}