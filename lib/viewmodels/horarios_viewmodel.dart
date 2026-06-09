import 'base_viewmodel.dart';
import '../services/horario_service.dart';
import '../services/alerta_service.dart';

class HorariosViewModel extends BaseViewModel {
  final HorarioService _horarioService = HorarioService();
  final AlertaService _alertaService = AlertaService();
  
  // Estado de horarios
  DateTime _semanaActual = DateTime.now();
  List<Map<String, dynamic>> _horarios = [];
  List<Map<String, dynamic>> _empleados = [];
  bool _asignandoAutomatico = false;
  String? _horarioEditandoId;
  
  // Getters
  DateTime get semanaActual => _semanaActual;
  List<Map<String, dynamic>> get horarios => _horarios;
  List<Map<String, dynamic>> get empleados => _empleados;
  bool get asignandoAutomatico => _asignandoAutomatico;
  String? get horarioEditandoId => _horarioEditandoId;
  
  String get rangoSemana {
    final inicio = _semanaActual.subtract(Duration(days: _semanaActual.weekday - 1));
    final fin = inicio.add(const Duration(days: 6));
    return '${inicio.day}/${inicio.month} - ${fin.day}/${fin.month}';
  }
  
  // Cargar horarios
  Future<void> cargarHorarios() async {
    await runSafe(() async {
      _horarios = await _horarioService.obtenerHorariosSemana(_semanaActual);
    });
  }
  
  // Cargar empleados
  Future<void> cargarEmpleados() async {
    await runSafe(() async {
      _empleados = await _horarioService.obtenerEmpleados();
    });
  }
  
  // Cambiar semana
  void cambiarSemana(int delta) {
    _semanaActual = _semanaActual.add(Duration(days: delta * 7));
    notifyListeners();
  }
  
  // Asignar horarios automáticos
  Future<int> asignarHorariosAutomaticos() async {
    setAsignandoAutomatico(true);
    try {
      final ids = _empleados.map((e) => e['id'] as String).toList();
      final generados = await _horarioService.asignarHorariosAutomaticos(_semanaActual, ids);
      
      // Enviar notificaciones a los empleados
      for (var horario in generados) {
        await _alertaService.notificarNuevoHorario(
          horario['empleado_id'],
          horario['dia'],
          horario['entrada'],
          horario['salida'],
        );
      }
      
      await cargarHorarios();
      return generados.length;
    } finally {
      setAsignandoAutomatico(false);
    }
  }
  
  // Editar horario
  Future<bool> editarHorario(String turnoId, DateTime nuevaEntrada, DateTime nuevaSalida) async {
    setHorarioEditando(turnoId);
    try {
      await _horarioService.editarHorario(turnoId, nuevaEntrada, nuevaSalida);
      await cargarHorarios();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setHorarioEditando(null);
    }
  }
  
  // Eliminar horario
  Future<bool> eliminarHorario(String turnoId) async {
    try {
      await _horarioService.eliminarHorario(turnoId);
      await cargarHorarios();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
  
  // Obtener horarios de un empleado específico
  List<Map<String, dynamic>> getHorariosPorEmpleado(String empleadoId) {
    return _horarios.where((h) => h['empleado_id'] == empleadoId).toList();
  }
  
  // Verificar si un empleado tiene horario en un día específico
  bool empleadoTieneHorario(String empleadoId, DateTime dia) {
    final diaInicio = DateTime(dia.year, dia.month, dia.day, 0, 0);
    final diaFin = DateTime(dia.year, dia.month, dia.day, 23, 59);
    
    return _horarios.any((h) {
      final entrada = DateTime.parse(h['entrada']);
      return h['empleado_id'] == empleadoId && 
             entrada.isAfter(diaInicio) && 
             entrada.isBefore(diaFin);
    });
  }
  
  // Obtener resumen de horarios
  Map<String, dynamic> getResumenHorarios() {
    int totalHorarios = _horarios.length;
    int horariosCompletados = _horarios.where((h) => h['salida'] != null).length;
    int horariosPendientes = totalHorarios - horariosCompletados;
    int horariosExtra = _horarios.where((h) => h['es_extra'] == true).length;
    
    return {
      'total': totalHorarios,
      'completados': horariosCompletados,
      'pendientes': horariosPendientes,
      'extras': horariosExtra,
    };
  }
  
  // Obtener horas totales de la semana
  double getHorasTotalesSemana() {
    double totalHoras = 0;
    for (var horario in _horarios) {
      if (horario['salida'] != null) {
        final entrada = DateTime.parse(horario['entrada']);
        final salida = DateTime.parse(horario['salida']);
        totalHoras += salida.difference(entrada).inHours;
      }
    }
    return totalHoras;
  }
  
  // Setters privados
  void setAsignandoAutomatico(bool value) {
    _asignandoAutomatico = value;
    notifyListeners();
  }
  
  void setHorarioEditando(String? id) {
    _horarioEditandoId = id;
    notifyListeners();
  }
  
  // Cargar todos los datos iniciales
  Future<void> cargarDatosIniciales() async {
    await cargarEmpleados();
    await cargarHorarios();
  }
}