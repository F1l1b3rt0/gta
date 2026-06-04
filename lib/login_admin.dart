import 'package:flutter/material.dart';

// --- AQUÍ SE DEFINE LA CLASE QUE TE FALTABA ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Turnos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

// Una pantalla de Login básica para probar que todo compile
class LoginAdmin extends StatelessWidget {
  const LoginAdmin({super.key});

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
              const Icon(Icons.business_center, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                'Sistema de Turnos 2026',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(decoration: const InputDecoration(labelText: 'Nip'), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ingresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}