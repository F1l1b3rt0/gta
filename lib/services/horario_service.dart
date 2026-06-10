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
      
      // disponibilidad can be a Map {"lunes":{...}} or List [{dia:"lunes",...}] or null
      final rawDisp = empleado['disponibilidad'];
      final maxHoras = (empleado['max_horas_diarias'] ?? 8) as int;

      // Normalize to Map<String, Map> regardless of storage format
      Map<String, Map<String, dynamic>> dispMap = {};
      if (rawDisp is Map) {
        rawDisp.forEach((k, v) {
          if (v is Map) dispMap[k.toString()] = Map<String, dynamic>.from(v);
        });
      } else if (rawDisp is List) {
        for (final item in rawDisp) {
          if (item is Map && item['dia'] != null) {
            dispMap[item['dia'].toString()] = Map<String, dynamic>.from(item);
          }
        }
      }

      if (dispMap.isEmpty) continue; // No availability configured, skip employee

      // Generar horarios para 7 días
      for (int i = 0; i < 7; i++) {
        final dia = inicioSemana.add(Duration(days: i));
        final diaSemana = _getDiaSemana(dia.weekday);

        if (!dispMap.containsKey(diaSemana)) continue;
        final horario = dispMap[diaSemana]!;

        final horaInicioMin = (horario['hora_inicio'] as num?)?.toInt() ?? 0;
        final horaFinMin = (horario['hora_fin'] as num?)?.toInt() ?? 0;

        final entrada = DateTime(dia.year, dia.month, dia.day,
            horaInicioMin ~/ 60, horaInicioMin % 60);
        final salida = DateTime(dia.year, dia.month, dia.day,
            horaFinMin ~/ 60, horaFinMin % 60);

        final horasDia = salida.difference(entrada).inHours;
        if (horasDia <= 0) continue;

        final esExtra = horasDia > maxHoras;
        final turno = await _supabase.from('turnos').insert({
          'empleado_id': empleadoId,
          'entrada': entrada.toIso8601String(),
          'salida': salida.toIso8601String(),
          'es_extra': esExtra,
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
    
    return horariosGenerados;
  }
  
  // Crear turno manual — auto-marks as extra if exceeds max_horas_diarias
  Future<void> crearTurnoManual(String empleadoId, DateTime entrada, DateTime salida) async {
    final empleado = await _supabase
        .from('empleados')
        .select('max_horas_diarias')
        .eq('id', empleadoId)
        .maybeSingle();
    final maxHoras = (empleado?['max_horas_diarias'] ?? 8) as int;
    final horasDia = salida.difference(entrada).inHours;
    final esExtra = horasDia > maxHoras;

    await _supabase.from('turnos').insert({
      'empleado_id': empleadoId,
      'entrada': entrada.toIso8601String(),
      'salida': salida.toIso8601String(),
      'es_extra': esExtra,
    });
  }

  // Editar horario manualmente
  Future<void> editarHorario(String turnoId, DateTime nuevaEntrada, DateTime nuevaSalida) async {
    await _supabase.from('turnos').update({
      'entrada': nuevaEntrada.toIso8601String(),
      'salida': nuevaSalida.toIso8601String(),
    }).match({'id': turnoId});
  }
  
  // Eliminar horario
  Future<void> eliminarHorario(String turnoId) async {
    await _supabase.from('turnos').delete().match({'id': turnoId});
  }
  
  // Obtener horarios de la semana
  Future<List<Map<String, dynamic>>> obtenerHorariosSemana(DateTime inicioSemana) async {
    // Use midnight to avoid time-of-day cutting off same-day shifts
    final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    final fin = inicio.add(const Duration(days: 7));

    final response = await _supabase
        .from('turnos')
        .select('*, empleados(nombre)')
        .gte('entrada', inicio.toIso8601String())
        .lt('entrada', fin.toIso8601String())
        .order('entrada');

    return response;
  }
  
  String _getDiaSemana(int weekday) {
    const dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return dias[weekday - 1];
  }
}