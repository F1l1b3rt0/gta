import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Tablas
  static const String tablaEmpleados = 'empleados';
  static const String tablaTurnos = 'turnos';
  static const String tablaConfiguracion = 'configuracion';
  
  // Roles
  static const String rolGerente = 'gerente';
  static const String rolEmpleado = 'empleado';
}