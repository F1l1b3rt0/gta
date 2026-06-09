import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class QRGeneratorService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  String _generarCodigoUnico(String empleadoId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rawData = 'GTA|$empleadoId|$timestamp';
    final base64Str = base64.encode(utf8.encode(rawData));
    return base64Str.substring(0, 32);
  }
  
  Future<Map<String, dynamic>> generarQREmpleado(String empleadoId) async {
    try {
      final codigoUnico = _generarCodigoUnico(empleadoId);
      final qrData = {
        'type': 'asistencia',
        'empleado_id': empleadoId,
        'code': codigoUnico,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('empleados')
          .update({
            'qr_code': codigoUnico,
            'qr_generado_en': DateTime.now().toIso8601String(),
          })
          .eq('id', empleadoId);
      
      return {
        'success': true,
        'qr_code': codigoUnico,
        'qr_data': jsonEncode(qrData),
        'message': 'QR generado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al generar QR: $e',
      };
    }
  }
  
  Future<Map<String, dynamic>> obtenerQREmpleado(String empleadoId) async {
    try {
      final empleado = await _supabase
          .from('empleados')
          .select('qr_code, qr_generado_en')
          .eq('id', empleadoId)
          .single();
      
      if (empleado['qr_code'] == null) {
        return await generarQREmpleado(empleadoId);
      }
      
      final qrData = {
        'type': 'asistencia',
        'empleado_id': empleadoId,
        'code': empleado['qr_code'],
        'timestamp': empleado['qr_generado_en'],
      };
      
      return {
        'success': true,
        'qr_code': empleado['qr_code'],
        'qr_data': jsonEncode(qrData),
        'generado_en': empleado['qr_generado_en'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al obtener QR: $e',
      };
    }
  }
  
  Future<Map<String, dynamic>> regenerarQREmpleado(String empleadoId) async {
    return await generarQREmpleado(empleadoId);
  }
}