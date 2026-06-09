// ignore_for_file: unused_field

import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../services/horario_service.dart';
import '../services/nomina_service.dart';
import '../services/reporte_service.dart';

class GerenteViewModel extends BaseViewModel {
  final HorarioService _horarioService = HorarioService();
  final NominaService _nominaService = NominaService();
  final ReporteService _reporteService = ReporteService();
  
  String _nombre = '';
  int _alertasNoLeidas = 0;
  List<Map<String, dynamic>> _empleados = [];
  final Map<String, dynamic> _estadisticas = {};
  List<Map<String, dynamic>> _horarios = [];
  
  // Getters
  String get nombre => _nombre;
  int get alertasNoLeidas => _alertasNoLeidas;
  List<Map<String, dynamic>> get empleados => _empleados;
  Map<String, dynamic> get estadisticas => _estadisticas;
  List<Map<String, dynamic>> get horarios => _horarios;
  
  String get saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
  
  // Cargar datos del gerente
  Future<void> cargarDatosGerente() async {
    await runSafe(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final response = await Supabase.instance.client
          .from('empleados')
          .select('nombre')
          .eq('id', user.id)
          .single();
      
      _nombre = response['nombre'];
      await cargarAlertasNoLeidas();
    });
  }
  
  // Cargar alertas no leídas
  Future<void> cargarAlertasNoLeidas() async {
    final alertas = await Supabase.instance.client
        .from('alertas')
        .select('id')
        .eq('leida', false);
    _alertasNoLeidas = alertas.length;
    notifyListeners();
  }
  
  // Cargar empleados
  Future<void> cargarEmpleados() async {
    await runSafe(() async {
      final response = await Supabase.instance.client
          .from('empleados')
          .select('*')
          .order('nombre');
      _empleados = List<Map<String, dynamic>>.from(response);
    });
  }
  
  // Cargar horarios
  Future<void> cargarHorarios(DateTime semanaActual) async {
    await runSafe(() async {
      _horarios = await _horarioService.obtenerHorariosSemana(semanaActual);
    });
  }
  
  // Asignar horarios automáticos
  Future<int> asignarHorariosAutomaticos(DateTime semanaActual) async {
    await runSafe(() async {
      final empleados = await _horarioService.obtenerEmpleados();
      final ids = empleados.map((e) => e['id'] as String).toList();
      final generados = await _horarioService.asignarHorariosAutomaticos(semanaActual, ids);
      return generados.length;
    });
    return 0;
  }
  
  // Eliminar empleado
  Future<bool> eliminarEmpleado(String id) async {
    try {
      await Supabase.instance.client
          .from('empleados')
          .delete()
          .eq('id', id);
      await cargarEmpleados();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
  
  // Guardar configuración
  Future<bool> guardarConfiguracion(Map<String, dynamic> config) async {
    try {
      final existing = await Supabase.instance.client
          .from('configuracion')
          .select()
          .maybeSingle();
      
      if (existing != null) {
        await Supabase.instance.client
            .from('configuracion')
            .update(config)
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('configuracion')
            .insert(config);
      }
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
  
  // Cerrar sesión
  Future<void> logout() async {
    await runSafe(() async {
      await Supabase.instance.client.auth.signOut();
    });
  }
}