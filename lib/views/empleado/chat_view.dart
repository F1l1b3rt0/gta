// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'asistente_ia_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/app_strings.dart';
import '../../services/notification_service.dart';
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
    if (user == null) return;
    try {
      // Try id = auth.uid() first
      var perfil = await Supabase.instance.client
          .from('empleados')
          .select('id, nombre, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      // Fallback: try user_id field
      perfil ??= await Supabase.instance.client
          .from('empleados')
          .select('id, nombre, avatar_url')
          .eq('user_id', user.id)
          .maybeSingle();
      if (perfil != null && mounted) {
        setState(() {
          _empleadoId = perfil!['id'] ?? '';
          _empleadoNombre = perfil['nombre'] ?? '';
          _empleadoAvatar = perfil['avatar_url'] ?? '';
        });
      }
    } catch (_) {}
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
        setState(() => _mensajes.add(nuevoMensaje));
        // Notificación solo si el mensaje es de otra persona
        final esAjeno = nuevoMensaje['empleado_id'] != _empleadoId;
        if (esAjeno) {
          final nombre = nuevoMensaje['empleado_nombre'] ?? 'Chat';
          final texto = nuevoMensaje['mensaje'] ?? '';
          NotificationService().showChatMessage(nombre, texto);
        }
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

  void _mostrarOpcionesMensaje(Map<String, dynamic> mensaje) {
    final s = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
              ),
              title: Text(s.editMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogoEditar(mensaje);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_rounded, color: Colors.red.shade600),
              ),
              title: Text(s.deleteMessage,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminar(mensaje);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditar(Map<String, dynamic> mensaje) {
    final s = AppStrings.of(context);
    final controller = TextEditingController(text: mensaje['mensaje'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.editMessage),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final nuevoTexto = controller.text.trim();
              if (nuevoTexto.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final ok = await _chatService.editarMensaje(
                  mensaje['id'].toString(), nuevoTexto);
              if (ok && mounted) {
                await _cargarMensajes();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(s.messageEdited),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(Map<String, dynamic> mensaje) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.deleteMessage),
        content: Text(s.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final ok = await _chatService
                  .eliminarMensaje(mensaje['id'].toString());
              if (ok && mounted) {
                await _cargarMensajes();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(s.messageDeleted),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(s.deleteMessage),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                                    Text(
                                      s.teamChat,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.messagesCount(_mensajes.length),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                          child: ClipRect(child: _mensajes.isEmpty
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
                                      Text(
                                        s.noMessages,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1a1a1a),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s.beFirst,
                                        style: const TextStyle(
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
                        )),
                        // ========== INPUT ==========
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Builder(builder: (context) {
                                  final cs = Theme.of(context).colorScheme;
                                  final isDark = Theme.of(context).brightness == Brightness.dark;
                                  return TextField(
                                    controller: _mensajeController,
                                    style: TextStyle(color: cs.onSurface),
                                    decoration: InputDecoration(
                                      hintText: s.typeMessage,
                                      hintStyle: TextStyle(color: cs.onSurface.withAlpha(100)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(color: cs.primary.withAlpha(isDark ? 60 : 40)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(color: cs.primary.withAlpha(isDark ? 60 : 40)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide(color: cs.primary, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      filled: true,
                                      fillColor: isDark ? cs.surface : Colors.grey.shade50,
                                    ),
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _enviarMensaje(),
                                  );
                                }),
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
                                      color:
                                          Colors.blue.shade300.withAlpha(50),
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
    final avatarUrl = mensaje['empleado_avatar'] ?? '';
    final nombre = mensaje['empleado_nombre'] ?? 'Empleado';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E';

    Widget avatar = CircleAvatar(
      radius: 16,
      backgroundColor:
          esMiMensaje ? Colors.blue.shade100 : Colors.grey.shade200,
      backgroundImage:
          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              inicial,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: esMiMensaje
                    ? Colors.blue.shade700
                    : Colors.grey.shade700,
              ),
            )
          : null,
    );

    Widget bubble = GestureDetector(
      onLongPress: esMiMensaje ? () => _mostrarOpcionesMensaje(mensaje) : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: esMiMensaje
                ? LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  )
                : null,
            color: esMiMensaje
                ? null
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: (!esMiMensaje &&
                    Theme.of(context).brightness == Brightness.dark)
                ? Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(40))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: esMiMensaje
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!esMiMensaje)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(160),
                      ),
                    ),
                  ),
                Text(
                  mensaje['mensaje'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: esMiMensaje
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(DateTime.parse(mensaje['created_at'])),
                  style: TextStyle(
                    fontSize: 10,
                    color: esMiMensaje
                        ? Colors.white60
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (esMiMensaje) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubble,
          const SizedBox(width: 8),
          avatar,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          avatar,
          const SizedBox(width: 8),
          bubble,
        ],
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
