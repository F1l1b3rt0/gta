import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/environment.dart';
import 'views/auth/login_view.dart';
import 'views/empleado/empleado_home_view.dart';
import 'views/gerente/gerente_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Environment.init();
  
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );
  
  runApp(const GTAApp());
}

class GTAApp extends StatelessWidget {
  const GTAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GTA - Gestión de Turnos',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Verificar si es gerente o empleado
      return FutureBuilder(
        future: Supabase.instance.client
            .from('empleados')
            .select('rol')
            .eq('id', session.user.id)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            final rol = snapshot.data!['rol'];
            if (rol == 'gerente') {
              return const GerenteHomeView();
            }
          }
          return const EmpleadoHomeView();
        },
      );
    }
    
    return const LoginView();
  }
}