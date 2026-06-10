import 'package:supabase_flutter/supabase_flutter.dart';
import 'base_viewmodel.dart';
import '../services/auth_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _nombre = '';
  String _rol = 'empleado';
  double _salarioPorHora = 0;
  String _claveGerente = '';

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get nombre => _nombre;
  String get rol => _rol;
  double get salarioPorHora => _salarioPorHora;
  bool get isGerente => _rol == 'gerente';
  
  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }
  
  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }
  
  void setConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }
  
  void setNombre(String value) {
    _nombre = value;
    notifyListeners();
  }
  
  void setRol(String value) {
    _rol = value;
    if (value == 'gerente') {
      _salarioPorHora = 0;
    }
    notifyListeners();
  }
  
  void setSalarioPorHora(double value) {
    _salarioPorHora = value;
    notifyListeners();
  }

  void setClaveGerente(String value) {
    _claveGerente = value;
    notifyListeners();
  }

  Future<bool> login() async {
    try {
      await runSafe(() => _authService.signIn(_email, _password, {}));
      return true;
    } catch (e) {
      setError(_friendlyError(e.toString()));
      return false;
    }
  }

  String _friendlyError(String raw) {
    final r = raw.toLowerCase();
    if (r.contains('invalid login credentials') || r.contains('invalid_credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (r.contains('email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión';
    }
    if (r.contains('user already registered') || r.contains('already been registered')) {
      return 'Este correo ya está registrado';
    }
    if (r.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (r.contains('unable to validate email address')) {
      return 'Correo electrónico inválido';
    }
    if (r.contains('network') || r.contains('socketexception') || r.contains('connection')) {
      return 'Sin conexión. Revisa tu internet';
    }
    if (r.contains('infinite recursion') || r.contains('42p17')) {
      return 'Error del servidor. Contacta al administrador';
    }
    if (r.contains('row-level security') || r.contains('rls')) {
      return 'Sin permisos. Contacta al administrador';
    }
    // Fallback: don't show raw technical error
    return 'Ocurrió un error. Intenta de nuevo';
  }
  
  Future<bool> register() async {
    if (_password != _confirmPassword) {
      setError('Las contraseñas no coinciden');
      return false;
    }

    // Validate gerente key against configuracion table (public read required)
    if (_rol == 'gerente') {
      try {
        final rows = await Supabase.instance.client
            .from('configuracion')
            .select('clave_registro');
        final claveGuardada = (rows as List)
            .map((r) => (r['clave_registro'] as String? ?? '').trim())
            .firstWhere((c) => c.isNotEmpty, orElse: () => '');
        if (claveGuardada.isEmpty) {
          setError('No hay clave de gerente configurada. Contacta al administrador.');
          return false;
        }
        if (_claveGerente.trim() != claveGuardada) {
          setError('Clave de gerente incorrecta');
          return false;
        }
      } catch (e) {
        setError('Error verificando clave: $e');
        return false;
      }
    }

    try {
      if (_rol == 'gerente') {
        await runSafe(() => _authService.registerGerente(
          email: _email,
          password: _password,
          nombre: _nombre,
        ));
      } else {
        await runSafe(() => _authService.registerEmpleado(
          email: _email,
          password: _password,
          nombre: _nombre,
          salarioPorHora: _salarioPorHora,
        ));
      }
      return true;
    } catch (e) {
      setError(_friendlyError(e.toString()));
      return false;
    }
  }
  
  Future<void> logout() async {
    await runSafe(() => _authService.signOut());
  }
  
  Future<String?> getCurrentUserRol() async {
    return await _authService.getUserType();
  }
}