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
  
  Future<bool> login() async {
    try {
      await runSafe(() => _authService.signIn(_email, _password, {}));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> register() async {
    if (_password != _confirmPassword) {
      setError('Las contraseñas no coinciden');
      return false;
    }
    
    try {
      final userData = {
        'nombre': _nombre,
        'rol': _rol,
        'salario_por_hora': _rol == 'gerente' ? 0 : _salarioPorHora,
      };
      await runSafe(() => _authService.signIn(_email, _password, userData));
      return true;
    } catch (e) {
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