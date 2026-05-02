import 'package:flutter/material.dart';
import 'package:gta/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/auth/login_view.dart';
import 'views/empleado/empleado_home_view.dart';
import 'views/gerente/gerente_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://vdgwzdrgovqidbmgpnfo.supabase.co',
    anonKey: 'sb_publishable_1Obk82kv4ylSvV_y2pVr_A_1TuvKUtx',
  );
  
  runApp(const GTAApp());
}

class GTAApp extends StatelessWidget {
  const GTAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTA - Gestión de Turnos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/empleado_home': (context) => const EmpleadoHomeScreen(),
        '/gerente_home': (context) => const GerenteHomeScreen(),
      },
    );
  }
}
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget? _pantallaDestino;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) _verificarSesion();
    });
  }

  Future<void> _verificarSesion() async {
    setState(() => _isLoading = true);
    
    final authService = AuthService();
    final currentUser = await authService.getCurrentUser();
    
    if (currentUser != null && mounted) {
      if (currentUser.role == UserRole.gerente) {
        _pantallaDestino = const GerenteHomeScreen();
      } else if (currentUser.role == UserRole.empleado) {
        _pantallaDestino = const EmpleadoHomeScreen();
      } else {
        _pantallaDestino = const LoginScreen();
      }
    } else {
      _pantallaDestino = const LoginScreen();
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _pantallaDestino!;
  }
}