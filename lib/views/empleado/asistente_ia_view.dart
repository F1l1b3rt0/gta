// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/environment.dart';

class AsistenteIAView extends StatefulWidget {
  const AsistenteIAView({super.key});

  @override
  State<AsistenteIAView> createState() => _AsistenteIAViewState();
}

class _AsistenteIAViewState extends State<AsistenteIAView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _mensajes = [];
  bool _isLoading = false;
  bool _isCargandoPerfil = true;
  Map<String, dynamic> _perfilEmpleado = {};
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _cargarPerfil();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final perfil = await Supabase.instance.client
            .from('empleados')
            .select('nombre, rol, email, puesto')
            .eq('id', user.id)
            .single();
        setState(() {
          _perfilEmpleado = perfil;
          _isCargandoPerfil = false;
        });
      }
    } catch (e) {
      setState(() => _isCargandoPerfil = false);
    }
  }

  String _buildSystemPrompt() {
    final nombre = _perfilEmpleado['nombre'] ?? 'Empleado';
    final rol = _perfilEmpleado['rol'] ?? 'empleado';
    final puesto = _perfilEmpleado['puesto'] ?? 'No especificado';

    return '''Eres un asistente virtual de GTA (Gestión de Turnos y Asistencia). 
Eres amable, conciso y profesional. Ayudas a los empleados con dudas sobre la app.

Información del empleado actual:
- Nombre: $nombre
- Rol: $rol
- Puesto: $puesto

Puedes ayudar con:
- Dudas sobre cómo usar la app (Mi Horario, Mis Horas, Perfil, Configuración)
- Explicar qué significa cada sección
- Responder preguntas generales sobre turnos y asistencia

Si no tienes información específica (como el horario exacto del empleado), dilo claramente y sugiere dónde puede encontrarla en la app.
Responde siempre en español y de forma breve y clara.''';
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _mensajes.add({'role': 'user', 'content': texto});
      _isLoading = true;
    });
    _scrollAbajo();

    try {
      final historial = _mensajes
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': Environment.anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5',
          'max_tokens': 1024,
          'system': _buildSystemPrompt(),
          'messages': historial,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final respuesta = data['content'][0]['text'] as String;
        setState(() {
          _mensajes.add({'role': 'assistant', 'content': respuesta});
          _isLoading = false;
        });
        _scrollAbajo();
      } else {
        _mostrarError();
      }
    } catch (e) {
      _mostrarError();
    }
  }

  void _mostrarError() {
    setState(() {
      _mensajes.add({
        'role': 'assistant',
        'content':
            'Ocurrió un error al conectar con el asistente. Intenta de nuevo.',
      });
      _isLoading = false;
    });
    _scrollAbajo();
  }

  void _scrollAbajo() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Fondo gradiente igual al chat
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                        Colors.cyan.shade700,
                      ],
                    ),
                  ),
                  height: 200,
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        // ========== HEADER ==========
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(200),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Asistente IA',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Pregúntame lo que necesites',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ========== MENSAJES ==========
                        Expanded(
                          child: _mensajes.isEmpty
                              ? _buildEstadoVacio()
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    16,
                                    12,
                                    16,
                                  ),
                                  itemCount:
                                      _mensajes.length + (_isLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _mensajes.length &&
                                        _isLoading) {
                                      return _buildTypingIndicator();
                                    }
                                    final mensaje = _mensajes[index];
                                    final esUsuario = mensaje['role'] == 'user';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: _buildBurbuja(
                                        mensaje['content']!,
                                        esUsuario,
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // ========== INPUT ==========
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe tu pregunta...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _enviarMensaje(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade300.withAlpha(50),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isLoading ? null : _enviarMensaje,
                                    borderRadius: BorderRadius.circular(24),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEstadoVacio() {
    final nombre = _perfilEmpleado['nombre']?.split(' ').first ?? 'ahí';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withAlpha(50),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¡Hola, $nombre!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1a1a1a),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soy tu asistente de GTA. Puedo ayudarte con dudas sobre la app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chipSugerencia('¿Cómo veo mi horario?'),
                _chipSugerencia('¿Qué son mis horas?'),
                _chipSugerencia('¿Cómo actualizo mi perfil?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipSugerencia(String texto) {
    return GestureDetector(
      onTap: () {
        _controller.text = texto;
        _enviarMensaje();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
          boxShadow: [
            BoxShadow(color: Colors.blue.shade100.withAlpha(50), blurRadius: 8),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBurbuja(String texto, bool esUsuario) {
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: esUsuario
                ? LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  )
                : null,
            color: esUsuario ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: esUsuario
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!esUsuario)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Asistente IA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  color: esUsuario ? Colors.white : const Color(0xFF1a1a1a),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 150),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
