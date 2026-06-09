// ignore_for_file: unused_field

import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../services/horario_service.dart';
import '../services/alerta_service.dart';

class EmpleadoViewModel extends BaseViewModel {
  final HorarioService _horarioService = HorarioService();
  final AlertaService _alertaService = AlertaService();
  
  // Estado del empleado
  String _nombre = '';
  String _rol = '';
  double _salarioPorHora = 0;
  bool _tieneTurnoHoy = false;
  bool _yaMarcoEntrada = false;
  List<Map<String, dynamic>> _misHorarios = [];
  List<Map<String, dynamic>> _misTurnos = [];
  
  // Getters
  String get nombre => _nombre;
  String get rol => _rol;
  double get salarioPorHora => _salarioPorHora;
  bool get tieneTurnoHoy => _tieneTurnoHoy;
  bool get yaMarcoEntrada => _yaMarcoEntrada;
  List<Map<String, dynamic>> get misHorarios => _misHorarios;
  List<Map<String, dynamic>> get misTurnos => _misTurnos;
  
  String get saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
  
  String get initial {
    return _nombre.isNotEmpty ? _nombre[0].toUpperCase() : 'E';
  }
  
  // Cargar datos del empleado
  Future<void> cargarDatosEmpleado() async {
    await runSafe(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final response = await Supabase.instance.client
          .from('empleados')
          .select('nombre, rol, salario_por_hora')
          .eq('id', user.id)
          .single();
      
      _nombre = response['nombre'];
      _rol = response['rol'];
      _salarioPorHora = (response['salario_por_hora'] ?? 0).toDouble();
      
      await verificarEstadoHoy();
    });
  }
  
  // Verificar estado del día
  Future<void> verificarEstadoHoy() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final turno = await Supabase.instance.client
        .from('turnos')
        .select()
        .eq('empleado_id', user.id)
        .gte('entrada', '$hoy 00:00:00')
        .lte('entrada', '$hoy 23:59:59')
        .maybeSingle();
    
    _tieneTurnoHoy = turno != null;
    _yaMarcoEntrada = turno != null && turno['salida'] == null;
    notifyListeners();
  }
  
  // Cargar horarios del empleado
  Future<void> cargarMisHorarios(DateTime semanaActual) async {
    await runSafe(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final inicio = semanaActual.subtract(Duration(days: semanaActual.weekday - 1));
      final fin = inicio.add(const Duration(days: 7));
      
      final response = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .order('entrada');
      
      _misHorarios = List<Map<String, dynamic>>.from(response);
    });
  }
  
  // Cargar horas trabajadas
  Future<void> cargarMisHoras(String periodo) async {
    await runSafe(() async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final fin = DateTime.now();
      final inicio = periodo == 'semana'
          ? fin.subtract(Duration(days: fin.weekday - 1))
          : DateTime(fin.year, fin.month, 1);
      
      final response = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', inicio.toIso8601String())
          .lte('entrada', fin.toIso8601String())
          .not('salida', 'is', null)
          .order('entrada', ascending: false);
      
      _misTurnos = List<Map<String, dynamic>>.from(response);
    });
  }
  
  // Registrar entrada
  Future<bool> registrarEntrada() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final existente = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', '$hoy 00:00:00')
          .lte('entrada', '$hoy 23:59:59')
          .maybeSingle();
      
      if (existente != null) return false;
      
      await Supabase.instance.client.from('turnos').insert({
        'empleado_id': user.id,
        'entrada': DateTime.now().toIso8601String(),
      });
      
      await verificarEstadoHoy();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
  
  // Registrar salida
  Future<bool> registrarSalida() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final turnoActivo = await Supabase.instance.client
          .from('turnos')
          .select()
          .eq('empleado_id', user.id)
          .gte('entrada', '$hoy 00:00:00')
          .lte('entrada', '$hoy 23:59:59')
          .filter('salida','is', null)
          .maybeSingle();
      
      if (turnoActivo == null) return false;
      
      await Supabase.instance.client
          .from('turnos')
          .update({'salida': DateTime.now().toIso8601String()})
          .eq('id', turnoActivo['id']);
      
      await verificarEstadoHoy();
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