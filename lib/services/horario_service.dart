import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class HorarioService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Obtener todos los empleados
  Future<List<Map<String, dynamic>>> obtenerEmpleados() async {
    final response = await _supabase
        .from('empleados')
        .select('id, nombre, rol, max_horas_diarias, disponibilidad')
        .neq('rol', 'gerente');
    return response;
  }
  
  // Asignar horario automático
  Future<List<Map<String, dynamic>>> asignarHorariosAutomaticos(
    DateTime inicioSemana,
    List<String> empleadosIds
  ) async {
    final horariosGenerados = <Map<String, dynamic>>[];
    
    for (var empleadoId in empleadosIds) {
      // Obtener disponibilidad del empleado
      final empleado = await _supabase
          .from('empleados')
          .select('disponibilidad, max_horas_diarias')
          .eq('id', empleadoId)
          .single();
      
      final disponibilidad = empleado['disponibilidad'] ?? {};
      final maxHoras = empleado['max_horas_diarias'] ?? 8;
      
      // Generar horarios para 7 días
      for (int i = 0; i < 7; i++) {
        final dia = inicioSemana.add(Duration(days: i));
        final diaSemana = _getDiaSemana(dia.weekday);
        
        if (disponibilidad.containsKey(diaSemana)) {
          final horario = disponibilidad[diaSemana];
          final entrada = DateTime(
            dia.year, dia.month, dia.day,
            horario['hora_inicio'] ~/ 60,
            horario['hora_inicio'] % 60,
          );
          final salida = DateTime(
            dia.year, dia.month, dia.day,
            horario['hora_fin'] ~/ 60,
            horario['hora_fin'] % 60,
          );
          
          // Verificar que no exceda horas máximas
          final horasDia = salida.difference(entrada).inHours;
          if (horasDia <= maxHoras) {
            final turno = await _supabase.from('turnos').insert({
              'empleado_id': empleadoId,
              'entrada': entrada.toIso8601String(),
              'salida': salida.toIso8601String(),
              'es_extra': false,
              'asignado_automaticamente': true,
            }).select();
            
            horariosGenerados.add({
              'empleado_id': empleadoId,
              'dia': dia,
              'entrada': entrada,
              'salida': salida,
              'turno_id': turno[0]['id'],
            });
          }
        }
      }
    }
    
    return horariosGenerados;
  }
  
  // Editar horario manualmente
  Future<void> editarHorario(String turnoId, DateTime nuevaEntrada, DateTime nuevaSalida) async {
    await _supabase.from('turnos').update({
      'entrada': nuevaEntrada.toIso8601String(),
      'salida': nuevaSalida.toIso8601String(),
      'modificado_manualmente': true,
    }).match({'id': turnoId});
  }
  
  // Eliminar horario
  Future<void> eliminarHorario(String turnoId) async {
    await _supabase.from('turnos').delete().match({'id': turnoId});
  }
  
  // Obtener horarios de la semana
  Future<List<Map<String, dynamic>>> obtenerHorariosSemana(DateTime inicioSemana) async {
    final finSemana = inicioSemana.add(const Duration(days: 7));
    
    final response = await _supabase
        .from('turnos')
        .select('*, empleados(nombre)')
        .gte('entrada', inicioSemana.toIso8601String())
        .lte('entrada', finSemana.toIso8601String())
        .order('entrada');
    
    return response;
  }
  
  String _getDiaSemana(int weekday) {
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return dias[weekday - 1];
  }
}