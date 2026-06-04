import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../services/auth_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();
  
  // Estado del formulario
  String _email = '';
  String _password = '';
  String _nombre = '';
  String _rol = 'empleado';
  double _salarioPorHora = 0;
  
  // Getters
  String get email => _email;
  String get password => _password;
  String get nombre => _nombre;
  String get rol => _rol;
  double get salarioPorHora => _salarioPorHora;
  bool get isGerente => _rol == 'gerente';
  
  // Setters con notificación
  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }
  
  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }
  
  void setNombre(String value) {
    _nombre = value;
    notifyListeners();
  }
  
  void setRol(String value) {
    _rol = value;
    notifyListeners();
    if (value == 'gerente') {
      setSalarioPorHora(0);
    }
  }
  
  void setSalarioPorHora(double value) {
    _salarioPorHora = value;
    notifyListeners();
  }
  
  // Acciones
  Future<bool> login() async {
    try {
      await runSafe(() => _authService.signIn(
        _email,
        _password,
        {}, // ← UserData vacío para login (solo autenticación)
      ));
      return true;
    } catch (e) {
      debugPrint('Error en login: $e');
      return false;
    }
  }
  
  Future<bool> register() async {
    try {
      final userData = {
        'nombre': _nombre,
        'rol': _rol,
        'salario_por_hora': _rol == 'gerente' ? 0 : _salarioPorHora,
      };
      await runSafe(() => _authService.signIn(
        _email,
        _password,
        userData, // ← Datos del usuario para registro
      ));
      return true;
    } catch (e) {
      debugPrint('Error en registro: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    await runSafe(() => _authService.signOut());
  }
  
  Future<String?> getCurrentUserRol() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await Supabase.instance.client
          .from('empleados')
          .select('rol')
          .eq('id', user.id)
          .single();
      return response['rol'] as String?;
    } catch (e) {
      return null;
    }
  }
  
  void validarFormularioLogin() {
    // Validaciones aquí
  }
}