import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar sesión")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: email,
              decoration: InputDecoration(labelText: "Correo"),
            ),

            TextField(
              controller: password,
              decoration: InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/menu');
              },
              child: Text("Iniciar sesión"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text("Crear cuenta"),
            )

          ],
        ),
      ),
    );
  }
}