import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class QRService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Verificar ubicación del empleado (debe estar en el local)
  Future<bool> verificarUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    Position position = await Geolocator.getCurrentPosition();
    // Coordenadas del local (ejemplo)
    double latLocal = 19.432608;
    double lonLocal = -99.133209;
    
    double distance = Geolocator.distanceBetween(
      position.latitude, position.longitude,
      latLocal, lonLocal
    );
    
    return distance <= 100; // Dentro de 100 metros
  }
  
  // Registrar entrada
  Future<Map<String, dynamic>> registrarEntrada(String empleadoId) async {
    try {
      // Verificar si ya entró hoy
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final turnoExistente = await _supabase
          .from('turnos')
          .select()
          .eq('empleado_id', empleadoId)
          .gte('entrada', '$hoy 00:00:00')
          .lte('entrada', '$hoy 23:59:59')
          .maybeSingle();
      
      if (turnoExistente != null && turnoExistente['salida'] == null) {
        return {'success': false, 'message': 'Ya tienes una entrada activa sin salida'};
      }
      
      if (turnoExistente != null && turnoExistente['salida'] != null) {
        return {'success': false, 'message': 'Ya registraste entrada y salida hoy'};
      }
      
      // Verificar ubicación
      bool ubicacionValida = await verificarUbicacion();
      if (!ubicacionValida) {
        return {'success': false, 'message': 'Debes estar en el local para marcar entrada'};
      }
      
      // Registrar entrada
      final response = await _supabase.from('turnos').insert({
        'empleado_id': empleadoId,
        'entrada': DateTime.now().toIso8601String(),
        'tipo_registro': 'qr',
      }).select();
      
      return {'success': true, 'message': 'Entrada registrada', 'data': response};
      
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // Registrar salida
  Future<Map<String, dynamic>> registrarSalida(String empleadoId) async {
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      
    // Obtener turno activo
final turnoActivo = await _supabase
    .from('turnos')
    .select()
    .eq('empleado_id', empleadoId)
    .gte('entrada', '$hoy 00:00:00')
    .lte('entrada', '$hoy 23:59:59')
    .filter('salida', 'is', 'null')
    .maybeSingle();
      
      if (turnoActivo == null) {
        return {'success': false, 'message': 'No hay entrada activa para hoy'};
      }
      
      // Verificar ubicación
      bool ubicacionValida = await verificarUbicacion();
      if (!ubicacionValida) {
        return {'success': false, 'message': 'Debes estar en el local para marcar salida'};
      }
      
      // Calcular horas trabajadas
      final entrada = DateTime.parse(turnoActivo['entrada']);
      final salida = DateTime.now();
      final horasTrabajadas = salida.difference(entrada).inHours;
      
      // Verificar si excede límite
      final empleado = await _supabase
          .from('empleados')
          .select()
          .eq('id', empleadoId)
          .single();
      
      bool esExtra = horasTrabajadas > (empleado['max_horas_diarias'] ?? 8);
      
      // Registrar salida
      await _supabase.from('turnos').update({
        'salida': salida.toIso8601String(),
        'horas_trabajadas': horasTrabajadas,
        'es_extra': esExtra,
      }).match({'id': turnoActivo['id']}).select();
      
      return {
        'success': true, 
        'message': 'Salida registrada - Horas: $horasTrabajadas',
        'horas': horasTrabajadas,
        'es_extra': esExtra
      };
      
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // Generar QR para el empleado (código único)
  String generarQRCode(String empleadoId, String tipo) {
    // Formato: GTA|EMPLEADO_ID|TIPO|TIMESTAMP
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'GTA|$empleadoId|$tipo|$timestamp';
  }
}