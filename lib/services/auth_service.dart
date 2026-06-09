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
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'rol': 'empleado',
          'nombre': nombre,
          'salario_por_hora': salarioPorHora.toString(),
        },
      );

      final user = response.user;
      if (user == null) throw Exception('Error al crear usuario');

      // El trigger ya insertó en 'empleados', solo lo consultamos
      final empleadoResponse = await _supabase
          .from('empleados')
          .select()
          .eq('id', user.id)
          .single();

      return Empleado.fromJson(empleadoResponse);
    } on AuthException catch (e) {
      throw Exception('Fallo en auth.signUp: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Fallo al obtener empleado: ${e.message}');
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
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'rol': 'gerente',
        'nombre': nombre,
        'nivel': Gerente.nivelToString(nivel),
      },
    );

    final user = response.user;
    if (user == null) throw Exception('Error al crear usuario');

    // Esperar a que el trigger inserte el registro
    await Future.delayed(const Duration(milliseconds: 500));

    // Retry hasta 3 veces
    for (int i = 0; i < 3; i++) {
      final gerenteResponse = await _supabase
          .from('gerentes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle(); // ← maybeSingle en lugar de single

      if (gerenteResponse != null) {
        return Gerente.fromJson(gerenteResponse);
      }

      // Esperar antes del siguiente intento
      await Future.delayed(const Duration(milliseconds: 500));
    }

    throw Exception('No se encontró el perfil del gerente tras el registro');

  } on AuthException catch (e) {
    throw Exception('Fallo en auth.signUp: ${e.message}');
  } on PostgrestException catch (e) {
    throw Exception('Fallo al obtener gerente: ${e.message}');
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

      if (gerente != null) return UserRole.gerente;

      // Verificar si es empleado
      final empleado = await _supabase
          .from('empleados')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (empleado != null) return UserRole.empleado;

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
        .eq('id', user.id)
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

      final gerente = await _supabase
          .from('gerentes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (gerente != null) return 'gerente';

      final empleado = await _supabase
          .from('empleados')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (empleado != null) return 'empleado';

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