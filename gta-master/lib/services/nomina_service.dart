import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class NominaService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Obtener todos los empleados
  Future<List<Map<String, dynamic>>> obtenerEmpleados() async {
    final response = await _supabase
        .from('empleados')
        .select('id, nombre, rol, salario_por_hora')
        .neq('rol', 'gerente');
    return response;
  }
  
  // Calcular sueldo de un empleado
  Future<double> calcularSueldoEmpleado(String empleadoId, DateTime mes) async {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 0);
    
    final turnos = await _supabase
        .from('turnos')
        .select()
        .eq('empleado_id', empleadoId)
        .gte('entrada', inicio.toIso8601String())
        .lte('entrada', fin.toIso8601String())
        .not('salida', 'is', null);
    
    final empleado = await _supabase
        .from('empleados')
        .select('salario_por_hora')
        .eq('id', empleadoId)
        .single();
    
    final salarioPorHora = (empleado['salario_por_hora'] ?? 0) as double;
    double totalHorasNormales = 0;
    double totalHorasExtras = 0;
    
    for (var turno in turnos) {
      final entrada = DateTime.parse(turno['entrada']);
      final salida = DateTime.parse(turno['salida']);
      final horas = salida.difference(entrada).inHours;
      
      if (turno['es_extra'] == true) {
        totalHorasExtras += horas;
      } else {
        totalHorasNormales += horas;
      }
    }
    
    final totalNormal = totalHorasNormales * salarioPorHora;
    final totalExtra = totalHorasExtras * salarioPorHora * 1.5;
    
    return totalNormal + totalExtra;
  }
  
  // Obtener resumen general de todos los empleados
  Future<Map<String, dynamic>> obtenerResumenGeneral(DateTime mes) async {
    final empleados = await obtenerEmpleados();
    double totalGeneral = 0;
    final detalles = <Map<String, dynamic>>[];
    
    for (var empleado in empleados) {
      final sueldo = await calcularSueldoEmpleado(empleado['id'], mes);
      totalGeneral += sueldo;
      detalles.add({
        'nombre': empleado['nombre'],
        'sueldo': sueldo,
      });
    }
    
    return {
      'total_general': totalGeneral,
      'detalles': detalles,
      'mes': mes,
    };
  }
}