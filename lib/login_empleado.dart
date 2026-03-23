import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vdgwzdrgovqidbmgpnfo.supabase.co', 
    anonKey: 'sb_publishable_1Obk82kv4ylSvV_y2pVr_A_1TuvKUtx',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp ({super.key});


@override
Widget build(BuildContext context) {
  return MaterialApp(debugShowCheckedModeBanner: false,
      title: 'inicio de sesion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        ),
      );
}
}

class LoginEmpleado extends StatelessWidget {
  const LoginEmpleado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center, size: 80, color: Color.fromARGB(255, 22, 223, 223)),
            const SizedBox(height: 20),
            const Text('login empleado',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40,),
            TextField(decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(decoration: const InputDecoration(labelText: 'nip'),obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              Navigator.pop(context);
            },
             child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    ),
    );
  }
}