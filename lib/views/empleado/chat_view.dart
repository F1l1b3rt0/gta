// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'asistente_ia_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/perfil_service.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _mensajeController = TextEditingController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _isLoading = true;
  String _empleadoId = '';
  String _empleadoNombre = '';
  String _empleadoAvatar = '';
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
    _cargarDatosUsuario();
    _cargarMensajes();
    _suscribirMensajes();
  }

  @override
  void dispose() {
    _chatService.cancelarSuscripcion();
    _mensajeController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final perfil = await Supabase.instance.client
          .from('empleados')
          .select('id, nombre, avatar_url')
          .eq('id', user.id)
          .single();
      setState(() {
        _empleadoId = perfil['id'];
        _empleadoNombre = perfil['nombre'];
        _empleadoAvatar = perfil['avatar_url'] ?? '';
      });
    }
  }

  Future<void> _cargarMensajes() async {
    final mensajes = await _chatService.obtenerMensajes();
    setState(() {
      _mensajes = mensajes.reversed.toList();
      _isLoading = false;
    });
  }

  void _suscribirMensajes() {
    _chatService.suscribirMensajes((nuevoMensaje) {
      if (mounted) {
        setState(() {
          _mensajes.add(nuevoMensaje);
        });
      }
    });
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _mensajeController.text.trim();
    if (mensaje.isEmpty) return;

    _mensajeController.clear();

    await _chatService.enviarMensaje(
      _empleadoId,
      _empleadoNombre,
      _empleadoAvatar,
      mensaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chat del Equipo',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_mensajes.length} mensajes',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botón Asistente IA
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AsistenteIAView(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botón Refresh
                              GestureDetector(
                                onTap: _cargarMensajes,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(150),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ========== MENSAJES ==========
                        Expanded(
                          child: _mensajes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade200
                                                  .withAlpha(50),
                                              blurRadius: 20,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.chat_bubble_outline,
                                          size: 48,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Sin mensajes',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1a1a1a),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Sé el primero en escribir',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    16,
                                    12,
                                    16,
                                  ),
                                  itemCount: _mensajes.length,
                                  itemBuilder: (context, index) {
                                    final mensaje =
                                        _mensajes[_mensajes.length - 1 - index];
                                    final esMiMensaje =
                                        mensaje['empleado_id'] == _empleadoId;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: _buildMensajeTile(
                                        mensaje,
                                        esMiMensaje,
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
                                  controller: _mensajeController,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe un mensaje...',
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
                                    onTap: _enviarMensaje,
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

  Widget _buildMensajeTile(Map<String, dynamic> mensaje, bool esMiMensaje) {
    return Align(
      alignment: esMiMensaje ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: esMiMensaje
                ? LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  )
                : null,
            color: esMiMensaje ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: esMiMensaje
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!esMiMensaje)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      mensaje['empleado_nombre'] ?? 'Empleado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: esMiMensaje
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                Text(
                  mensaje['mensaje'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: esMiMensaje ? Colors.white : const Color(0xFF1a1a1a),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(DateTime.parse(mensaje['created_at'])),
                  style: TextStyle(
                    fontSize: 10,
                    color: esMiMensaje ? Colors.white60 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
