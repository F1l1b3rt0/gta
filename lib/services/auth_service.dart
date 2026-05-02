import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/empleado.dart';
import '../models/gerente.dart';

enum UserRole { empleado, gerente, none }

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Registrar empleado
  Future<Empleado> registerEmpleado({
    required String email,
    required String password,
    required String nombre,
    required double salarioPorHora,
  }) async {
    try {
      // 1. Registrar en auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) throw Exception('Error al crear usuario');
      
      // 2. Crear perfil en tabla empleados
      final empleadoData = {
        'user_id': user.id,
        'nombre': nombre,
        'email': email,
        'salario_por_hora': salarioPorHora,
      };
      
      final empleadoResponse = await _supabase
          .from('empleados')
          .insert(empleadoData)
          .select()
          .single();
      
      return Empleado.fromJson(empleadoResponse);
    } catch (e) {
      throw Exception('Error al registrar empleado: $e');
    }
  }
  
  // Registrar gerente
  Future<Gerente> registerGerente({
    required String email,
    required String password,
    required String nombre,
    NivelGerente nivel = NivelGerente.senior,
  }) async {
    try {
      // 1. Registrar en auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) throw Exception('Error al crear usuario');
      
      // 2. Crear perfil en tabla gerentes
      final permisosBase = {
        'ver_reportes': true,
        'editar_turnos': true,
        'gestionar_empleados': true,
        'ver_estadisticas': true,
        'configurar_sistema': nivel == NivelGerente.director,
      };
      
      final gerenteData = {
        'user_id': user.id,
        'nombre': nombre,
        'email': email,
        'nivel': Gerente.nivelToString(nivel),
        'permisos': permisosBase,
      };
      
      final gerenteResponse = await _supabase
          .from('gerentes')
          .insert(gerenteData)
          .select()
          .single();
      
      return Gerente.fromJson(gerenteResponse);
    } catch (e) {
      throw Exception('Error al registrar gerente: $e');
    }
  }
  
  // Iniciar sesión y obtener rol
  Future<UserRole> signIn(String email, String password, Map<String, Object> userData) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) throw Exception('Credenciales inválidas');
      
      // Verificar si es gerente
      final gerente = await _supabase
          .from('gerentes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (gerente != null) {
        return UserRole.gerente;
      }
      
      // Verificar si es empleado
      final empleado = await _supabase
          .from('empleados')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (empleado != null) {
        return UserRole.empleado;
      }
      
      return UserRole.none;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
  
  // Obtener usuario actual
  Future<({UserRole role, dynamic data})?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    
    final user = session.user;
    
    // Buscar en gerentes
    final gerente = await _supabase
        .from('gerentes')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    if (gerente != null) {
      return (role: UserRole.gerente, data: Gerente.fromJson(gerente));
    }
    
    // Buscar en empleados
    final empleado = await _supabase
        .from('empleados')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    
    if (empleado != null) {
      return (role: UserRole.empleado, data: Empleado.fromJson(empleado));
    }
    
    return null;
  }
  
  // Obtener tipo de usuario (simplificado)
  Future<String?> getUserType() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final user = session.user;

      // Verificar si es gerente
      final gerente = await _supabase
          .from('gerentes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (gerente != null) {
        return 'gerente';
      }

      // Verificar si es empleado
      final empleado = await _supabase
          .from('empleados')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (empleado != null) {
        return 'empleado';
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener tipo de usuario: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}